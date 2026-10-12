# ================================================
# 王国箭塔防线 - 一键生成脚本
# 运行方式：在项目文件夹打开 PowerShell，执行 .\setup.ps1
# ================================================

$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
if (-not $root) { $root = (Get-Location).Path }
Set-Location $root

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  王国箭塔防线 V0.1 - 项目生成" -ForegroundColor Yellow
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "目标目录: $root" -ForegroundColor Gray
Write-Host ""

# 创建目录结构
$dirs = @(
    "src\core", "src\render", "src\input", "src\platform",
    "src\storage", "src\ui", "src\data", "taptap", "docs"
)
foreach ($d in $dirs) {
    $p = Join-Path $root $d
    if (-not (Test-Path $p)) {
        New-Item -ItemType Directory -Path $p -Force | Out-Null
        Write-Host "  [DIR]  $d" -ForegroundColor DarkGray
    }
}

function Write-File {
    param([string]$Path, [string]$Content)
    $full = Join-Path $root $Path
    $dir = Split-Path -Parent $full
    if ($dir -and -not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    $utf8 = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($full, $Content, $utf8)
    Write-Host "  [FILE] $Path" -ForegroundColor Green
}

# ================================================
# 1. index.html
# ================================================
Write-File "index.html" @'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0,maximum-scale=1.0,user-scalable=no">
<meta name="apple-mobile-web-app-capable" content="yes">
<title>王国箭塔防线</title>
<style>
* { margin:0; padding:0; box-sizing:border-box; }
html, body {
    width:100%; height:100%; overflow:hidden;
    background:#1a1a2e;
    font-family:-apple-system,'PingFang SC','Microsoft YaHei',sans-serif;
    -webkit-user-select:none; user-select:none;
    -webkit-tap-highlight-color:transparent;
    touch-action:none;
}
#game-container {
    position:relative; width:100vw; height:100vh;
    display:flex; align-items:center; justify-content:center; overflow:hidden;
}
#game-canvas { display:block; position:absolute; top:0; left:0; }
.ui-layer {
    position:absolute; top:0; left:0; width:100%; height:100%;
    pointer-events:none; z-index:10;
}
.menu-overlay {
    position:absolute; top:0; left:0; width:100%; height:100%;
    background:rgba(10,10,30,0.85);
    display:flex; flex-direction:column; align-items:center; justify-content:center;
    z-index:100; pointer-events:auto;
}
.menu-overlay.hidden { display:none; }
.menu-title {
    font-size:clamp(28px,8vw,56px); font-weight:900; color:#ffd700;
    text-shadow:0 4px 12px rgba(255,215,0,0.5);
    margin-bottom:8px; text-align:center;
}
.menu-subtitle {
    font-size:clamp(14px,3.5vw,18px); color:#aaa;
    margin-bottom:32px; text-align:center;
}
.btn-primary {
    padding:16px 48px; font-size:clamp(18px,4.5vw,24px);
    font-weight:700; color:#fff;
    background:linear-gradient(135deg,#ff6b35,#ff9f1c);
    border:none; border-radius:12px; cursor:pointer;
    box-shadow:0 6px 20px rgba(255,107,53,0.4);
    transition:transform 0.15s; pointer-events:auto;
}
.btn-primary:active { transform:scale(0.95); }
.btn-secondary {
    padding:12px 32px; font-size:clamp(14px,3.5vw,18px);
    font-weight:600; color:#ccc; background:rgba(255,255,255,0.1);
    border:1px solid rgba(255,255,255,0.2); border-radius:10px;
    cursor:pointer; margin-top:12px; pointer-events:auto;
}
.btn-secondary:active { transform:scale(0.95); }
.instructions {
    max-width:360px; color:#999;
    font-size:clamp(12px,3vw,15px); line-height:1.8;
    text-align:center; margin-bottom:28px; padding:0 20px;
}
.instructions strong { color:#ffd700; }
.loading-text {
    color:#ffd700; font-size:clamp(16px,4vw,22px);
    font-weight:700; animation:pulse 1.2s ease-in-out infinite;
}
@keyframes pulse { 0%,100%{opacity:1;} 50%{opacity:0.4;} }
</style>
</head>
<body>
<div id="game-container">
    <canvas id="game-canvas"></canvas>

    <div id="loading-screen" class="menu-overlay">
        <div class="loading-text">加载中...</div>
    </div>

    <div id="start-menu" class="menu-overlay hidden">
        <div class="menu-title">?? 王国箭塔防线</div>
        <div class="menu-subtitle">塔防 · 合成 · 生存</div>
        <div class="instructions">
            你有 <strong>180 秒</strong> 准备时间<br>
            建造 <strong>箭塔</strong> 抵御敌人进攻<br>
            <strong>拖动合并</strong> 相同等级箭塔升级<br>
            击败敌人获取金币<br>
            守住城堡，抵挡所有波次！
        </div>
        <button class="btn-primary" id="btn-start">开始游戏</button>
    </div>

    <div id="pause-menu" class="menu-overlay hidden">
        <div class="menu-title">? 已暂停</div>
        <button class="btn-primary" id="btn-resume">继续游戏</button>
        <button class="btn-secondary" id="btn-restart-from-pause">重新开始</button>
    </div>

    <div id="victory-screen" class="menu-overlay hidden">
        <div class="menu-title" style="color:#4ade80;">?? 胜利！</div>
        <div class="menu-subtitle">你成功守住了王国！</div>
        <div class="instructions" id="victory-stats"></div>
        <button class="btn-primary" id="btn-restart-victory">再来一局</button>
    </div>

    <div id="defeat-screen" class="menu-overlay hidden">
        <div class="menu-title" style="color:#ef4444;">?? 城堡陷落</div>
        <div class="menu-subtitle">敌人攻破了你的防线...</div>
        <div class="instructions" id="defeat-stats"></div>
        <button class="btn-primary" id="btn-restart-defeat">重新开始</button>
    </div>

    <div id="hud-container" class="ui-layer"></div>
</div>
<script type="module" src="./src/main.js"></script>
</body>
</html>
'@

# ================================================
# 2. src/data/towerConfig.js
# ================================================
Write-File "src\data\towerConfig.js" @'
export const TOWER_LEVELS = [
    { level:1, name:'木制箭塔', cost:25, damage:8, range:80, attackSpeed:1.0, projectileSpeed:300,
      color:'#8B6914', roofColor:'#A0522D', baseColor:'#6B4226', size:14 },
    { level:2, name:'强化木塔', cost:0, damage:16, range:95, attackSpeed:1.2, projectileSpeed:350,
      color:'#A0782C', roofColor:'#CD853F', baseColor:'#7B5B3A', size:16 },
    { level:3, name:'石制箭塔', cost:0, damage:30, range:110, attackSpeed:1.4, projectileSpeed:400,
      color:'#808080', roofColor:'#A9A9A9', baseColor:'#696969', size:18 },
    { level:4, name:'钢铁箭塔', cost:0, damage:55, range:125, attackSpeed:1.7, projectileSpeed:450,
      color:'#4A6FA5', roofColor:'#6B8CC7', baseColor:'#2E4A6E', size:20 },
    { level:5, name:'黄金箭塔', cost:0, damage:100, range:140, attackSpeed:2.0, projectileSpeed:500,
      color:'#DAA520', roofColor:'#FFD700', baseColor:'#B8860B', size:22 },
    { level:6, name:'魔法箭塔', cost:0, damage:200, range:160, attackSpeed:2.5, projectileSpeed:600,
      color:'#9B59B6', roofColor:'#E74C3C', baseColor:'#6C3483', size:24, magic:true }
];
export const TOWER_COST_LV1 = 25;
export function getTowerConfig(level) {
    return TOWER_LEVELS[level - 1] || TOWER_LEVELS[0];
}
export const MAX_TOWER_LEVEL = 6;
'@

# ================================================
# 3. src/data/enemyConfig.js
# ================================================
Write-File "src\data\enemyConfig.js" @'
export const ENEMY_TYPES = {
    goblin:     { name:'哥布林', hp:30, speed:40, damage:5, goldReward:8, size:10,
                  color:'#5D8A3C', accentColor:'#3A5C24', armor:0 },
    fastGoblin: { name:'迅捷哥布林', hp:20, speed:75, damage:4, goldReward:10, size:9,
                  color:'#7DBF4A', accentColor:'#4A8C2A', armor:0 },
    orc:        { name:'重甲兽人', hp:120, speed:25, damage:15, goldReward:20, size:14,
                  color:'#8B4513', accentColor:'#5C2E0A', armor:3 },
    boss:       { name:'魔王', hp:600, speed:18, damage:50, goldReward:100, size:22,
                  color:'#8B0000', accentColor:'#4A0000', armor:8, isBoss:true }
};
export function getEnemyConfig(type) {
    return ENEMY_TYPES[type] || ENEMY_TYPES.goblin;
}
'@

# ================================================
# 4. src/data/waveConfig.js
# ================================================
Write-File "src\data\waveConfig.js" @'
export const GAME_CONFIG = {
    prepTime: 180,
    castleMaxHp: 100,
    initialGold: 100,
    heroDamage: 12,
    heroRange: 100,
    heroAttackSpeed: 1.0,
    heroSkillCooldown: 20,
    heroSkillDamage: 80,
    heroSkillRadius: 100
};
export const WAVE_DATA = [
    { scout:true, count:2, type:'goblin', interval:2.0, delay:30 },
    { scout:true, count:3, type:'goblin', interval:1.5, delay:75 },
    { scout:true, count:2, type:'fastGoblin', interval:1.2, delay:120 },
    { count:5, type:'goblin', interval:1.0, delay:0 },
    { count:8, type:'goblin', interval:0.8, delay:3 },
    { count:6, type:'fastGoblin', interval:0.6, delay:3 },
    { count:10, type:'goblin', interval:0.7, delay:3 },
    { count:4, type:'orc', interval:1.5, delay:3 },
    { count:12, type:'goblin', interval:0.5, delay:3 },
    { count:8, type:'fastGoblin', interval:0.4, delay:3 },
    { count:6, type:'orc', interval:1.2, delay:3 },
    { count:1, type:'boss', interval:1.0, delay:5 },
    { count:15, type:'goblin', interval:0.4, delay:3 },
    { count:10, type:'fastGoblin', interval:0.35, delay:3 },
    { count:8, type:'orc', interval:1.0, delay:3 },
    { count:1, type:'boss', interval:1.0, delay:5 },
    { count:20, type:'goblin', interval:0.3, delay:2 },
    { count:12, type:'fastGoblin', interval:0.3, delay:2 },
    { count:10, type:'orc', interval:0.8, delay:2 }
];
'@

# ================================================
# 5. src/core/GameLoop.js
# ================================================
Write-File "src\core\GameLoop.js" @'
export class GameLoop {
    constructor(updateCallback, renderCallback) {
        this.updateCallback = updateCallback;
        this.renderCallback = renderCallback;
        this.step = 1 / 60;
        this.accumulator = 0;
        this.lastTime = 0;
        this.isRunning = false;
        this.requestId = null;
        this.boundLoop = this.loop.bind(this);
        this._platform = null;
    }
    setPlatform(platform) { this._platform = platform; }
    start() {
        if (this.isRunning) return;
        this.isRunning = true;
        this.lastTime = this._now();
        this.requestId = this._raf(this.boundLoop);
    }
    stop() {
        this.isRunning = false;
        if (this.requestId && this._platform) {
            this._platform.cancelAnimationFrame(this.requestId);
        }
        this.requestId = null;
    }
    _now() {
        if (this._platform) return this._platform.now();
        return typeof performance !== 'undefined' ? performance.now() : Date.now();
    }
    _raf(cb) {
        if (this._platform) return this._platform.requestAnimationFrame(cb);
        return requestAnimationFrame(cb);
    }
    loop(currentTime) {
        if (!this.isRunning) return;
        let deltaTime = (currentTime - this.lastTime) / 1000;
        this.lastTime = currentTime;
        if (deltaTime > 0.25) deltaTime = 0.25;
        this.accumulator += deltaTime;
        while (this.accumulator >= this.step) {
            this.updateCallback(this.step);
            this.accumulator -= this.step;
        }
        const alpha = this.accumulator / this.step;
        this.renderCallback(alpha);
        this.requestId = this._raf(this.boundLoop);
    }
}
'@

# ================================================
# 6. src/core/GameMap.js
# ================================================
Write-File "src\core\GameMap.js" @'
export const MAP_WIDTH = 960;
export const MAP_HEIGHT = 640;
export const ENEMY_PATH = [
    { x:880, y:560 }, { x:780, y:560 }, { x:780, y:420 },
    { x:620, y:420 }, { x:620, y:300 }, { x:460, y:300 },
    { x:460, y:180 }, { x:300, y:180 }, { x:300, y:100 },
    { x:160, y:100 }
];
export const BUILD_SPOTS = [
    { x:700, y:350 }, { x:700, y:490 },
    { x:560, y:350 }, { x:560, y:490 },
    { x:540, y:240 }, { x:680, y:240 },
    { x:400, y:240 }, { x:400, y:360 },
    { x:520, y:120 }, { x:360, y:120 },
    { x:240, y:240 }, { x:240, y:140 }
];
export const CASTLE_POS = { x:140, y:100 };

export class GameMap {
    constructor() {
        this.width = MAP_WIDTH;
        this.height = MAP_HEIGHT;
        this.path = ENEMY_PATH.map(p => ({ ...p }));
        this.buildSpots = BUILD_SPOTS.map(p => ({ ...p, occupied:false }));
        this.castlePos = { ...CASTLE_POS };
        this.pathLength = 0;
        this.pathSegments = [];
        for (let i = 0; i < this.path.length - 1; i++) {
            const a = this.path[i], b = this.path[i + 1];
            const dx = b.x - a.x, dy = b.y - a.y;
            const len = Math.sqrt(dx * dx + dy * dy);
            this.pathSegments.push({ from:a, to:b, length:len });
            this.pathLength += len;
        }
    }
    getPositionAtDistance(dist) {
        let remaining = dist;
        for (const seg of this.pathSegments) {
            if (remaining <= seg.length) {
                const t = remaining / seg.length;
                return {
                    x: seg.from.x + (seg.to.x - seg.from.x) * t,
                    y: seg.from.y + (seg.to.y - seg.from.y) * t
                };
            }
            remaining -= seg.length;
        }
        return { ...this.castlePos };
    }
    isOnPath(x, y, threshold = 40) {
        for (const seg of this.pathSegments) {
            const dist = this._pointToSegmentDist(x, y,
                seg.from.x, seg.from.y, seg.to.x, seg.to.y);
            if (dist < threshold) return true;
        }
        return false;
    }
    _pointToSegmentDist(px, py, x1, y1, x2, y2) {
        const dx = x2 - x1, dy = y2 - y1;
        const lenSq = dx * dx + dy * dy;
        if (lenSq === 0) return Math.sqrt((px - x1) ** 2 + (py - y1) ** 2);
        let t = ((px - x1) * dx + (py - y1) * dy) / lenSq;
        t = Math.max(0, Math.min(1, t));
        return Math.sqrt((px - (x1 + t * dx)) ** 2 + (py - (y1 + t * dy)) ** 2);
    }
    findNearestBuildSpot(x, y, maxDist = 50) {
        let best = null, bestDist = maxDist;
        for (const spot of this.buildSpots) {
            if (spot.occupied) continue;
            const d = Math.sqrt((x - spot.x) ** 2 + (y - spot.y) ** 2);
            if (d < bestDist) { bestDist = d; best = spot; }
        }
        return best;
    }
    freeBuildSpot(x, y) {
        for (const spot of this.buildSpots) {
            if (Math.abs(spot.x - x) < 2 && Math.abs(spot.y - y) < 2) {
                spot.occupied = false;
                return;
            }
        }
    }
    reset() { this.buildSpots.forEach(s => s.occupied = false); }
}
'@

# ================================================
# 7. src/core/Enemy.js
# ================================================
Write-File "src\core\Enemy.js" @'
import { getEnemyConfig } from '../data/enemyConfig.js';
let _enemyIdCounter = 0;

export class Enemy {
    constructor(type, pathTotalLength) {
        const cfg = getEnemyConfig(type);
        this.id = ++_enemyIdCounter;
        this.type = type;
        this.name = cfg.name;
        this.maxHp = cfg.hp;
        this.hp = cfg.hp;
        this.baseSpeed = cfg.speed;
        this.damage = cfg.damage;
        this.goldReward = cfg.goldReward;
        this.size = cfg.size;
        this.color = cfg.color;
        this.accentColor = cfg.accentColor;
        this.armor = cfg.armor || 0;
        this.isBoss = cfg.isBoss || false;
        this.pathTotalLength = pathTotalLength;
        this.distance = 0;
        this.x = 0;
        this.y = 0;
        this.alive = true;
        this.reachedCastle = false;
        this.slowTimer = 0;
        this.slowFactor = 1;
        this.animTime = 0;
        this.hitFlashTimer = 0;
        this.deathTimer = 0;
        this.isDying = false;
    }
    update(dt) {
        if (!this.alive) return;
        if (this.isDying) {
            this.deathTimer -= dt;
            if (this.deathTimer <= 0) this.alive = false;
            return;
        }
        if (this.slowTimer > 0) {
            this.slowTimer -= dt;
            if (this.slowTimer <= 0) this.slowFactor = 1;
        }
        if (this.hitFlashTimer > 0) this.hitFlashTimer -= dt;
        const speed = this.baseSpeed * this.slowFactor;
        this.distance += speed * dt;
        this.animTime += dt;
        if (this.distance >= this.pathTotalLength) {
            this.distance = this.pathTotalLength;
            this.reachedCastle = true;
        }
    }
    applySlow(factor, duration) {
        this.slowFactor = Math.min(this.slowFactor, factor);
        this.slowTimer = Math.max(this.slowTimer, duration);
    }
    takeDamage(amount) {
        if (!this.alive || this.isDying) return false;
        const actual = Math.max(1, amount - this.armor);
        this.hp -= actual;
        this.hitFlashTimer = 0.1;
        if (this.hp <= 0) {
            this.hp = 0;
            this.isDying = true;
            this.deathTimer = 0.3;
            return true;
        }
        return false;
    }
    updatePosition(map) {
        const pos = map.getPositionAtDistance(this.distance);
        this.x = pos.x;
        this.y = pos.y;
    }
}
export function resetEnemyIdCounter() { _enemyIdCounter = 0; }
'@

# ================================================
# 8. src/core/Tower.js
# ================================================
Write-File "src\core\Tower.js" @'
import { getTowerConfig, MAX_TOWER_LEVEL } from '../data/towerConfig.js';
let _towerIdCounter = 0;

export class Tower {
    constructor(level, gridX, gridY) {
        this.id = ++_towerIdCounter;
        this.level = Math.min(level, MAX_TOWER_LEVEL);
        this.x = gridX;
        this.y = gridY;
        this.alive = true;
        this.cooldown = 0;
        this.target = null;
        this.angle = 0;
        this.recoilTimer = 0;
        this._dragging = false;
        this._syncConfig();
    }
    _syncConfig() {
        const cfg = getTowerConfig(this.level);
        this.name = cfg.name;
        this.damage = cfg.damage;
        this.range = cfg.range;
        this.attackSpeed = cfg.attackSpeed;
        this.projectileSpeed = cfg.projectileSpeed;
        this.color = cfg.color;
        this.roofColor = cfg.roofColor;
        this.baseColor = cfg.baseColor;
        this.size = cfg.size;
        this.isMagic = cfg.magic || false;
    }
    update(dt, enemies) {
        if (!this.alive) return;
        if (this.recoilTimer > 0) this.recoilTimer -= dt;
        if (this.cooldown > 0) {
            this.cooldown -= dt;
            return;
        }
        this.target = this._findTarget(enemies);
        if (!this.target) return;
        const dx = this.target.x - this.x;
        const dy = this.target.y - this.y;
        this.angle = Math.atan2(dy, dx);
        this.cooldown = 1 / this.attackSpeed;
        this.recoilTimer = 0.15;
    }
    _findTarget(enemies) {
        let best = null, bestDist = this.range;
        for (const e of enemies) {
            if (!e.alive || e.isDying) continue;
            const d = Math.sqrt((e.x - this.x) ** 2 + (e.y - this.y) ** 2);
            if (d < bestDist) {
                if (!best || e.distance > best.distance) {
                    bestDist = d;
                    best = e;
                }
            }
        }
        return best;
    }
}
export function resetTowerIdCounter() { _towerIdCounter = 0; }
'@

# ================================================
# 9. src/core/Projectile.js
# ================================================
Write-File "src\core\Projectile.js" @'
export class Projectile {
    constructor(x, y, targetX, targetY, speed, damage, isMagic) {
        this.x = x;
        this.y = y;
        this.targetX = targetX;
        this.targetY = targetY;
        this.speed = speed;
        this.damage = damage;
        this.isMagic = isMagic || false;
        this.alive = true;
        this.hit = false;
        const dx = targetX - x, dy = targetY - y;
        const dist = Math.sqrt(dx * dx + dy * dy) || 1;
        this.dirX = dx / dist;
        this.dirY = dy / dist;
        this.totalDist = dist;
        this.traveled = 0;
        this.trail = [];
        this.maxTrail = 5;
    }
    update(dt) {
        if (!this.alive) return;
        const move = this.speed * dt;
        this.x += this.dirX * move;
        this.y += this.dirY * move;
        this.traveled += move;
        this.trail.push({ x:this.x, y:this.y });
        if (this.trail.length > this.maxTrail) this.trail.shift();
        if (this.traveled >= this.totalDist) {
            this.alive = false;
            this.hit = true;
        }
    }
    checkHit(enemies, hitRadius = 12) {
        if (!this.alive) return null;
        for (const e of enemies) {
            if (!e.alive || e.isDying) continue;
            const dx = e.x - this.x, dy = e.y - this.y;
            const dist = Math.sqrt(dx * dx + dy * dy);
            if (dist < hitRadius + e.size) {
                this.alive = false;
                this.hit = true;
                return e;
            }
        }
        return null;
    }
}
'@

# ================================================
# 10. src/core/Hero.js
# ================================================
Write-File "src\core\Hero.js" @'
import { GAME_CONFIG } from '../data/waveConfig.js';

export class Hero {
    constructor(x, y) {
        this.x = x;
        this.y = y;
        this.hp = 100;
        this.maxHp = 100;
        this.damage = GAME_CONFIG.heroDamage;
        this.range = GAME_CONFIG.heroRange;
        this.attackSpeed = GAME_CONFIG.heroAttackSpeed;
        this.cooldown = 0;
        this.target = null;
        this.angle = 0;
        this.animTime = 0;
        this.skillCooldown = 0;
        this.skillMaxCooldown = GAME_CONFIG.heroSkillCooldown;
        this.recoilTimer = 0;
    }
    update(dt, enemies) {
        this.animTime += dt;
        if (this.cooldown > 0) this.cooldown -= dt;
        if (this.skillCooldown > 0) this.skillCooldown -= dt;
        if (this.recoilTimer > 0) this.recoilTimer -= dt;
        if (this.cooldown <= 0) {
            this.target = this._findTarget(enemies);
            if (this.target) {
                const dx = this.target.x - this.x;
                const dy = this.target.y - this.y;
                this.angle = Math.atan2(dy, dx);
                this.cooldown = 1 / this.attackSpeed;
                this.recoilTimer = 0.15;
            }
        }
    }
    _findTarget(enemies) {
        let best = null, bestDist = this.range;
        for (const e of enemies) {
            if (!e.alive || e.isDying) continue;
            const d = Math.sqrt((e.x - this.x) ** 2 + (e.y - this.y) ** 2);
            if (d < bestDist) { bestDist = d; best = e; }
        }
        return best;
    }
    reset() {
        this.cooldown = 0;
        this.skillCooldown = 0;
        this.target = null;
        this.recoilTimer = 0;
        this.animTime = 0;
    }
}
'@

# ================================================
# 11. src/core/Economy.js
# ================================================
Write-File "src\core\Economy.js" @'
export class Economy {
    constructor(initialGold) {
        this.gold = initialGold;
        this.totalEarned = 0;
        this.totalSpent = 0;
        this.earnPopups = [];
    }
    canAfford(amount) { return this.gold >= amount; }
    spend(amount) {
        if (!this.canAfford(amount)) return false;
        this.gold -= amount;
        this.totalSpent += amount;
        return true;
    }
    earn(amount, x, y) {
        this.gold += amount;
        this.totalEarned += amount;
        if (x !== undefined && y !== undefined) {
            this.earnPopups.push({ x, y, amount, timer:0.8, maxTimer:0.8 });
        }
    }
    update(dt) {
        for (let i = this.earnPopups.length - 1; i >= 0; i--) {
            const p = this.earnPopups[i];
            p.timer -= dt;
            if (p.timer <= 0) this.earnPopups.splice(i, 1);
        }
    }
    reset(initialGold) {
        this.gold = initialGold;
        this.totalEarned = 0;
        this.totalSpent = 0;
        this.earnPopups = [];
    }
}
'@

# ================================================
# 12. src/core/MergeSystem.js
# ================================================
Write-File "src\core\MergeSystem.js" @'
import { Tower } from './Tower.js';
import { MAX_TOWER_LEVEL } from '../data/towerConfig.js';

export class MergeSystem {
    constructor() {
        this.dragState = null;
        this.particles = [];
    }
    startDrag(tower, worldX, worldY) {
        this.dragState = {
            tower, startX:worldX, startY:worldY,
            offsetX: tower.x - worldX, offsetY: tower.y - worldY,
            currentX: worldX, currentY: worldY,
            origX: tower.x, origY: tower.y
        };
        tower._dragging = true;
    }
    updateDrag(worldX, worldY) {
        if (!this.dragState) return;
        this.dragState.currentX = worldX;
        this.dragState.currentY = worldY;
        this.dragState.tower.x = worldX + this.dragState.offsetX;
        this.dragState.tower.y = worldY + this.dragState.offsetY;
    }
    endDrag(worldX, worldY, towers) {
        if (!this.dragState) return null;
        const dragTower = this.dragState.tower;
        const dragX = worldX + this.dragState.offsetX;
        const dragY = worldY + this.dragState.offsetY;
        let targetTower = null, bestDist = 60;
        for (const t of towers) {
            if (t === dragTower) continue;
            if (!t.alive) continue;
            if (t.level !== dragTower.level) continue;
            if (t.level >= MAX_TOWER_LEVEL) continue;
            const d = Math.sqrt((t.x - dragX) ** 2 + (t.y - dragY) ** 2);
            if (d < bestDist) { bestDist = d; targetTower = t; }
        }
        dragTower._dragging = false;
        if (targetTower) {
            const newLevel = dragTower.level + 1;
            const mergeX = targetTower.x, mergeY = targetTower.y;
            dragTower.alive = false;
            targetTower.alive = false;
            const newTower = new Tower(newLevel, mergeX, mergeY);
            this._spawnMergeParticles(mergeX, mergeY, newLevel);
            this.dragState = null;
            return { success:true, newTower };
        } else {
            dragTower.x = this.dragState.origX;
            dragTower.y = this.dragState.origY;
            this.dragState = null;
            return { success:false };
        }
    }
    _spawnMergeParticles(x, y, level) {
        const count = 15 + level * 5;
        const colors = ['#FFD700','#FFA500','#FFFACD','#FF8C00'];
        for (let i = 0; i < count; i++) {
            const angle = Math.random() * Math.PI * 2;
            const speed = 40 + Math.random() * 120;
            const life = 0.5 + Math.random() * 0.5;
            this.particles.push({
                x, y,
                vx: Math.cos(angle) * speed,
                vy: Math.sin(angle) * speed,
                life, maxLife: life,
                size: 3 + Math.random() * 4,
                color: colors[Math.floor(Math.random() * colors.length)]
            });
        }
    }
    update(dt) {
        for (let i = this.particles.length - 1; i >= 0; i--) {
            const p = this.particles[i];
            p.x += p.vx * dt;
            p.y += p.vy * dt;
            p.vy += 200 * dt;
            p.life -= dt;
            if (p.life <= 0) this.particles.splice(i, 1);
        }
    }
    reset() { this.dragState = null; this.particles = []; }
}
'@

# ================================================
# 13. src/core/WaveManager.js
# ================================================
Write-File "src\core\WaveManager.js" @'
import { WAVE_DATA, GAME_CONFIG } from '../data/waveConfig.js';

export class WaveManager {
    constructor() {
        this.prepTime = GAME_CONFIG.prepTime;
        this.countdown = this.prepTime;
        this.phase = 'preparation';
        this.currentWaveIndex = 0;
        this.waveTimer = 0;
        this.spawnQueue = [];
        this.spawnTimer = 0;
        this.allWavesCleared = false;
        this.scoutsSpawned = {};
        this.totalWaves = WAVE_DATA.filter(w => !w.scout).length;
        this.completedWaves = 0;
        this.bossAlive = false;
        this.onSpawnEnemy = null;
    }
    update(dt, enemies) {
        if (this.phase === 'preparation') {
            this.countdown -= dt;
            if (this.countdown <= 0) {
                this.countdown = 0;
                this.phase = 'combat';
                this.currentWaveIndex = 0;
                this._startNextWave();
            }
            this._updateScouts(dt);
        } else if (this.phase === 'combat') {
            this._updateCombat(dt, enemies);
        }
    }
    _updateScouts(dt) {
        for (let i = 0; i < WAVE_DATA.length; i++) {
            const wave = WAVE_DATA[i];
            if (!wave.scout) continue;
            if (this.scoutsSpawned[i]) continue;
            if (this.prepTime - this.countdown >= (wave.delay || 0)) {
                this.scoutsSpawned[i] = true;
                for (let j = 0; j < wave.count; j++) {
                    this.spawnQueue.push({ type: wave.type, interval: wave.interval });
                }
            }
        }
    }
    _updateCombat(dt, enemies) {
        if (this.spawnQueue.length > 0) {
            this.spawnTimer -= dt;
            if (this.spawnTimer <= 0) {
                const next = this.spawnQueue.shift();
                if (this.onSpawnEnemy) this.onSpawnEnemy(next.type);
                this.spawnTimer = next.interval || 0.5;
            }
            return;
        }
        const aliveEnemies = enemies.filter(e => e.alive && !e.isDying);
        if (aliveEnemies.length === 0) {
            this.waveTimer -= dt;
            if (this.waveTimer <= 0) {
                this.completedWaves++;
                this._startNextWave();
            }
        }
    }
    _startNextWave() {
        while (this.currentWaveIndex < WAVE_DATA.length) {
            const wave = WAVE_DATA[this.currentWaveIndex];
            if (wave.scout) { this.currentWaveIndex++; continue; }
            break;
        }
        if (this.currentWaveIndex >= WAVE_DATA.length) {
            this.allWavesCleared = true;
            this.phase = 'victory';
            return;
        }
        const wave = WAVE_DATA[this.currentWaveIndex];
        this.currentWaveIndex++;
        for (let i = 0; i < wave.count; i++) {
            this.spawnQueue.push({ type: wave.type, interval: wave.interval });
        }
        this.spawnTimer = 0;
        this.waveTimer = 3;
        if (wave.type === 'boss') this.bossAlive = true;
    }
    getPhaseLabel() {
        if (this.phase === 'preparation') {
            const m = Math.floor(this.countdown / 60);
            const s = Math.floor(this.countdown % 60);
            return '准备阶段 ' + m + ':' + s.toString().padStart(2, '0');
        }
        if (this.phase === 'combat') {
            return '第 ' + Math.min(this.completedWaves + 1, this.totalWaves) + ' / ' + this.totalWaves + ' 波';
        }
        return this.phase === 'victory' ? '胜利！' : '失败';
    }
    reset() {
        this.countdown = this.prepTime;
        this.phase = 'preparation';
        this.currentWaveIndex = 0;
        this.waveTimer = 0;
        this.spawnQueue = [];
        this.spawnTimer = 0;
        this.allWavesCleared = false;
        this.scoutsSpawned = {};
        this.completedWaves = 0;
        this.bossAlive = false;
    }
}
'@

# ================================================
# 14. src/core/SkillSystem.js
# ================================================
Write-File "src\core\SkillSystem.js" @'
import { GAME_CONFIG } from '../data/waveConfig.js';

export class SkillSystem {
    constructor() {
        this.cooldown = 0;
        this.maxCooldown = GAME_CONFIG.heroSkillCooldown;
        this.aiming = false;
        this.aimX = 0;
        this.aimY = 0;
        this.effects = [];
        this.onCast = null;
    }
    canCast() { return this.cooldown <= 0; }
    startAiming() {
        if (!this.canCast()) return false;
        this.aiming = true;
        return true;
    }
    updateAim(x, y) { this.aimX = x; this.aimY = y; }
    cast(targetX, targetY) {
        if (!this.canCast()) return null;
        this.aiming = false;
        this.cooldown = this.maxCooldown;
        const result = {
            x: targetX, y: targetY,
            radius: GAME_CONFIG.heroSkillRadius,
            damage: GAME_CONFIG.heroSkillDamage
        };
        this.effects.push({
            type:'arrowRain', x:targetX, y:targetY,
            radius: GAME_CONFIG.heroSkillRadius, timer:0.8, maxTimer:0.8
        });
        if (this.onCast) this.onCast(result);
        return result;
    }
    cancelAiming() { this.aiming = false; }
    update(dt) {
        if (this.cooldown > 0) this.cooldown -= dt;
        for (let i = this.effects.length - 1; i >= 0; i--) {
            this.effects[i].timer -= dt;
            if (this.effects[i].timer <= 0) this.effects.splice(i, 1);
        }
    }
    getProgress() {
        if (this.cooldown <= 0) return 1;
        return 1 - (this.cooldown / this.maxCooldown);
    }
    reset() {
        this.cooldown = 0;
        this.aiming = false;
        this.effects = [];
    }
}
'@

# ================================================
# 15. src/core/StateMachine.js
# ================================================
Write-File "src\core\StateMachine.js" @'
export const STATES = {
    LOADING: 'loading',
    MENU: 'menu',
    PLAYING: 'playing',
    PAUSED: 'paused',
    VICTORY: 'victory',
    DEFEAT: 'defeat'
};

export class StateMachine {
    constructor() {
        this.current = STATES.LOADING;
        this.previous = null;
        this.listeners = new Map();
    }
    on(state, callback) {
        if (!this.listeners.has(state)) this.listeners.set(state, []);
        this.listeners.get(state).push(callback);
    }
    transition(newState) {
        if (this.current === newState) return;
        this.previous = this.current;
        this.current = newState;
        const callbacks = this.listeners.get(newState) || [];
        for (const cb of callbacks) cb(this.previous, newState);
    }
    is(state) { return this.current === state; }
}
'@

# ================================================
# 16. src/core/Game.js
# ================================================
Write-File "src\core\Game.js" @'
import { GameLoop } from './GameLoop.js';
import { GameMap } from './GameMap.js';
import { Enemy, resetEnemyIdCounter } from './Enemy.js';
import { Tower, resetTowerIdCounter } from './Tower.js';
import { Projectile } from './Projectile.js';
import { Hero } from './Hero.js';
import { Economy } from './Economy.js';
import { MergeSystem } from './MergeSystem.js';
import { WaveManager } from './WaveManager.js';
import { SkillSystem } from './SkillSystem.js';
import { StateMachine, STATES } from './StateMachine.js';
import { GAME_CONFIG } from '../data/waveConfig.js';

export class Game {
    constructor(platform) {
        this.platform = platform;
        this.stateMachine = new StateMachine();
        this.map = new GameMap();
        this.economy = new Economy(GAME_CONFIG.initialGold);
        this.waveManager = new WaveManager();
        this.mergeSystem = new MergeSystem();
        this.skillSystem = new SkillSystem();
        this.enemies = [];
        this.towers = [];
        this.projectiles = [];
        const heroPos = this.map.getPositionAtDistance(this.map.pathLength * 0.85);
        this.hero = new Hero(heroPos.x, heroPos.y - 30);
        this.castleHp = GAME_CONFIG.castleMaxHp;
        this.castleMaxHp = GAME_CONFIG.castleMaxHp;
        this.killCount = 0;
        this.elapsedTime = 0;
        this.onGameOver = null;
        this.waveManager.onSpawnEnemy = (type) => this._spawnEnemy(type);
        this.loop = new GameLoop((dt) => this.update(dt), (alpha) => this.render(alpha));
        this.loop.setPlatform(platform);
        this.renderCallback = null;
    }
    setRenderer(cb) { this.renderCallback = cb; }
    startGame() {
        this.reset();
        this.stateMachine.transition(STATES.PLAYING);
        this.loop.start();
    }
    reset() {
        this.map.reset();
        this.economy.reset(GAME_CONFIG.initialGold);
        this.waveManager.reset();
        this.mergeSystem.reset();
        this.skillSystem.reset();
        this.enemies = [];
        this.towers = [];
        this.projectiles = [];
        const heroPos = this.map.getPositionAtDistance(this.map.pathLength * 0.85);
        this.hero = new Hero(heroPos.x, heroPos.y - 30);
        this.castleHp = GAME_CONFIG.castleMaxHp;
        this.killCount = 0;
        this.elapsedTime = 0;
        resetEnemyIdCounter();
        resetTowerIdCounter();
    }
    update(dt) {
        if (this.stateMachine.is(STATES.PAUSED) ||
            this.stateMachine.is(STATES.VICTORY) ||
            this.stateMachine.is(STATES.DEFEAT)) return;
        if (!this.stateMachine.is(STATES.PLAYING)) return;
        this.elapsedTime += dt;
        this.economy.update(dt);
        this.waveManager.update(dt, this.enemies);
        for (const e of this.enemies) {
            e.update(dt);
            e.updatePosition(this.map);
        }
        for (const e of this.enemies) {
            if (e.reachedCastle && e.alive && !e.isDying) this._onEnemyReachedCastle(e);
        }
        for (const t of this.towers) {
            if (!t.alive || t._dragging) continue;
            t.update(dt, this.enemies);
            if (t.target && t.cooldown >= (1 / t.attackSpeed) - 0.001) {
                this._fireProjectile(t);
            }
        }
        this.hero.update(dt, this.enemies);
        if (this.hero.target) this._heroFire();
        this.skillSystem.update(dt);
        for (const p of this.projectiles) {
            p.update(dt);
            const hit = p.checkHit(this.enemies);
            if (hit) this._onProjectileHit(p, hit);
        }
        this._cleanup();
        this._checkGameOver();
    }
    render(alpha) { if (this.renderCallback) this.renderCallback(alpha); }
    _spawnEnemy(type) {
        const enemy = new Enemy(type, this.map.pathLength);
        enemy.updatePosition(this.map);
        this.enemies.push(enemy);
    }
    _fireProjectile(tower) {
        const target = tower.target;
        if (!target || !target.alive) return;
        const p = new Projectile(tower.x, tower.y - 10, target.x, target.y,
            tower.projectileSpeed, tower.damage, tower.isMagic);
        this.projectiles.push(p);
    }
    _heroFire() {
        const target = this.hero.target;
        if (!target || !target.alive) return;
        const killed = target.takeDamage(this.hero.damage);
        if (killed) this._onEnemyKilled(target);
        this.hero.target = null;
    }
    _onProjectileHit(projectile, enemy) {
        const killed = enemy.takeDamage(projectile.damage);
        if (killed) this._onEnemyKilled(enemy);
    }
    _onEnemyKilled(enemy) {
        this.killCount++;
        this.economy.earn(enemy.goldReward, enemy.x, enemy.y);
    }
    _onEnemyReachedCastle(enemy) {
        this.castleHp -= enemy.damage;
        enemy.alive = false;
        enemy.isDying = false;
        if (this.castleHp <= 0) this.castleHp = 0;
    }
    _cleanup() {
        this.enemies = this.enemies.filter(e => e.alive);
        this.towers = this.towers.filter(t => t.alive);
        this.projectiles = this.projectiles.filter(p => p.alive);
    }
    _checkGameOver() {
        if (this.stateMachine.is(STATES.PLAYING)) {
            if (this.castleHp <= 0) {
                this.stateMachine.transition(STATES.DEFEAT);
                this.loop.stop();
                if (this.onGameOver) this.onGameOver('defeat');
            } else if (this.waveManager.phase === 'victory') {
                this.stateMachine.transition(STATES.VICTORY);
                this.loop.stop();
                if (this.onGameOver) this.onGameOver('victory');
            }
        }
    }
    buildTower(spot) {
        if (spot.occupied) return false;
        if (!this.economy.canAfford(25)) return false;
        if (this.map.isOnPath(spot.x, spot.y, 35)) return false;
        this.economy.spend(25);
        const tower = new Tower(1, spot.x, spot.y);
        this.towers.push(tower);
        spot.occupied = true;
        return true;
    }
    startTowerDrag(tower, worldX, worldY) {
        this.mergeSystem.startDrag(tower, worldX, worldY);
    }
    updateTowerDrag(worldX, worldY) {
        this.mergeSystem.updateDrag(worldX, worldY);
    }
    endTowerDrag(worldX, worldY) {
        const result = this.mergeSystem.endDrag(worldX, worldY, this.towers);
        if (result && result.success && result.newTower) {
            this.towers.push(result.newTower);
            this.map.freeBuildSpot(result.newTower.x, result.newTower.y);
        }
        return result;
    }
    useHeroSkill(x, y) {
        if (!this.skillSystem.canCast()) return false;
        const result = this.skillSystem.cast(x, y);
        if (!result) return false;
        for (const e of this.enemies) {
            if (!e.alive || e.isDying) continue;
            const dx = e.x - result.x, dy = e.y - result.y;
            if (Math.sqrt(dx * dx + dy * dy) <= result.radius) {
                const killed = e.takeDamage(result.damage);
                if (killed) this._onEnemyKilled(e);
            }
        }
        return true;
    }
    pause() {
        if (this.stateMachine.is(STATES.PLAYING)) {
            this.stateMachine.transition(STATES.PAUSED);
            this.loop.stop();
        }
    }
    resume() {
        if (this.stateMachine.is(STATES.PAUSED)) {
            this.stateMachine.transition(STATES.PLAYING);
            this.loop.start();
        }
    }
    restart() {
        this.loop.stop();
        this.reset();
        this.stateMachine.transition(STATES.PLAYING);
        this.loop.start();
    }
    getStats() {
        return {
            killCount: this.killCount,
            totalGoldEarned: this.economy.totalEarned,
            elapsedTime: this.elapsedTime,
            castleHp: this.castleHp,
            completedWaves: this.waveManager.completedWaves,
            totalWaves: this.waveManager.totalWaves
        };
    }
}
'@

# ================================================
# 17. src/render/Camera.js
# ================================================
Write-File "src\render\Camera.js" @'
export class Camera {
    constructor(logicalWidth, logicalHeight) {
        this.logicalWidth = logicalWidth;
        this.logicalHeight = logicalHeight;
        this.viewportWidth = logicalWidth;
        this.viewportHeight = logicalHeight;
        this.scale = 1;
        this.offsetX = 0;
        this.offsetY = 0;
    }
    resize(screenWidth, screenHeight) {
        this.viewportWidth = screenWidth;
        this.viewportHeight = screenHeight;
        const scaleX = screenWidth / this.logicalWidth;
        const scaleY = screenHeight / this.logicalHeight;
        this.scale = Math.min(scaleX, scaleY);
        this.offsetX = (screenWidth - this.logicalWidth * this.scale) / 2;
        this.offsetY = (screenHeight - this.logicalHeight * this.scale) / 2;
    }
    toScreen(lx, ly) {
        return { x: lx * this.scale + this.offsetX, y: ly * this.scale + this.offsetY };
    }
    toLogical(sx, sy) {
        return { x: (sx - this.offsetX) / this.scale, y: (sy - this.offsetY) / this.scale };
    }
}
'@

# ================================================
# 18. src/render/ParticleSystem.js
# ================================================
Write-File "src\render\ParticleSystem.js" @'
export class ParticleSystem {
    constructor() { this.particles = []; }
    burst(x, y, count, color, speedRange = [50, 150], lifeRange = [0.3, 0.8]) {
        for (let i = 0; i < count; i++) {
            const angle = Math.random() * Math.PI * 2;
            const speed = speedRange[0] + Math.random() * (speedRange[1] - speedRange[0]);
            const life = lifeRange[0] + Math.random() * (lifeRange[1] - lifeRange[0]);
            this.particles.push({
                x, y,
                vx: Math.cos(angle) * speed,
                vy: Math.sin(angle) * speed,
                life, maxLife: life,
                size: 2 + Math.random() * 4,
                color
            });
        }
    }
    update(dt) {
        for (let i = this.particles.length - 1; i >= 0; i--) {
            const p = this.particles[i];
            p.x += p.vx * dt;
            p.y += p.vy * dt;
            p.vy += 150 * dt;
            p.vx *= 0.98;
            p.life -= dt;
            if (p.life <= 0) this.particles.splice(i, 1);
        }
    }
    reset() { this.particles = []; }
}
'@

# ================================================
# 19. src/render/Renderer.js
# ================================================
Write-File "src\render\Renderer.js" @'
import { MAP_WIDTH, MAP_HEIGHT } from '../core/GameMap.js';

export class Renderer {
    constructor(ctx, camera) {
        this.ctx = ctx;
        this.camera = camera;
        this.time = 0;
    }
    render(game, alpha) {
        const ctx = this.ctx;
        const cam = this.camera;
        this.time += 0.016;
        ctx.save();
        ctx.fillStyle = '#1a1a2e';
        ctx.fillRect(0, 0, cam.viewportWidth, cam.viewportHeight);
        ctx.translate(cam.offsetX, cam.offsetY);
        ctx.scale(cam.scale, cam.scale);
        this._drawMap();
        this._drawBuildSpots(game);
        this._drawPath(game.map);
        this._drawCastle(game);
        for (const e of game.enemies) this._drawEnemy(e);
        this._drawHero(game.hero);
        for (const t of game.towers) this._drawTower(t);
        if (game.mergeSystem.dragState) {
            const dt = game.mergeSystem.dragState.tower;
            this._drawTower(dt, true);
            this._drawDragHint(dt, game);
        }
        for (const p of game.projectiles) this._drawProjectile(p);
        this._drawParticles(game.mergeSystem.particles);
        this._drawSkillEffects(game.skillSystem.effects);
        this._drawGoldPopups(game.economy.earnPopups);
        ctx.restore();
    }
    _drawMap() {
        const ctx = this.ctx;
        const grad = ctx.createLinearGradient(0, 0, 0, MAP_HEIGHT);
        grad.addColorStop(0, '#4a7c3f');
        grad.addColorStop(1, '#3d6b34');
        ctx.fillStyle = grad;
        ctx.fillRect(0, 0, MAP_WIDTH, MAP_HEIGHT);
        ctx.strokeStyle = 'rgba(255,255,255,0.03)';
        ctx.lineWidth = 1;
        for (let x = 0; x < MAP_WIDTH; x += 40) {
            ctx.beginPath(); ctx.moveTo(x, 0); ctx.lineTo(x, MAP_HEIGHT); ctx.stroke();
        }
        for (let y = 0; y < MAP_HEIGHT; y += 40) {
            ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(MAP_WIDTH, y); ctx.stroke();
        }
        const trees = [
            { x:60, y:300 }, { x:100, y:500 }, { x:850, y:200 },
            { x:900, y:400 }, { x:200, y:550 }, { x:500, y:580 },
            { x:820, y:100 }, { x:700, y:100 }
        ];
        for (const t of trees) this._drawTree(t.x, t.y);
    }
    _drawTree(x, y) {
        const ctx = this.ctx;
        ctx.fillStyle = '#5C3A1E';
        ctx.fillRect(x - 4, y - 10, 8, 20);
        ctx.fillStyle = '#2E7D32';
        ctx.beginPath(); ctx.arc(x, y - 20, 18, 0, Math.PI * 2); ctx.fill();
        ctx.fillStyle = '#388E3C';
        ctx.beginPath(); ctx.arc(x - 5, y - 25, 12, 0, Math.PI * 2); ctx.fill();
    }
    _drawPath(map) {
        const ctx = this.ctx;
        ctx.save();
        ctx.strokeStyle = 'rgba(0,0,0,0.3)';
        ctx.lineWidth = 52;
        ctx.lineCap = 'round';
        ctx.lineJoin = 'round';
        ctx.beginPath();
        ctx.moveTo(map.path[0].x, map.path[0].y);
        for (let i = 1; i < map.path.length; i++) ctx.lineTo(map.path[i].x, map.path[i].y);
        ctx.stroke();
        ctx.strokeStyle = '#8B7355';
        ctx.lineWidth = 44;
        ctx.beginPath();
        ctx.moveTo(map.path[0].x, map.path[0].y);
        for (let i = 1; i < map.path.length; i++) ctx.lineTo(map.path[i].x, map.path[i].y);
        ctx.stroke();
        ctx.strokeStyle = '#A0896B';
        ctx.lineWidth = 36;
        ctx.beginPath();
        ctx.moveTo(map.path[0].x, map.path[0].y);
        for (let i = 1; i < map.path.length; i++) ctx.lineTo(map.path[i].x, map.path[i].y);
        ctx.stroke();
        ctx.restore();
    }
    _drawBuildSpots(game) {
        const ctx = this.ctx;
        for (const spot of game.map.buildSpots) {
            if (spot.occupied) continue;
            ctx.save();
            ctx.globalAlpha = 0.3 + Math.sin(this.time * 3) * 0.1;
            ctx.strokeStyle = '#FFD700';
            ctx.lineWidth = 2;
            ctx.setLineDash([4, 4]);
            ctx.beginPath();
            ctx.arc(spot.x, spot.y, 18, 0, Math.PI * 2);
            ctx.stroke();
            ctx.restore();
        }
    }
    _drawCastle(game) {
        const ctx = this.ctx;
        const pos = game.map.castlePos;
        ctx.save();
        ctx.fillStyle = '#7B7B7B';
        ctx.fillRect(pos.x - 30, pos.y - 40, 60, 50);
        ctx.fillStyle = '#9B9B9B';
        ctx.fillRect(pos.x - 25, pos.y - 35, 50, 40);
        for (let i = 0; i < 3; i++) {
            ctx.fillStyle = '#8B8B8B';
            ctx.fillRect(pos.x - 30 + i * 22, pos.y - 52, 16, 14);
        }
        ctx.fillStyle = '#4A3520';
        ctx.beginPath();
        ctx.arc(pos.x, pos.y - 5, 12, Math.PI, 0);
        ctx.fillRect(pos.x - 12, pos.y - 5, 24, 15);
        ctx.fillStyle = '#E74C3C';
        ctx.beginPath();
        ctx.moveTo(pos.x, pos.y - 52);
        ctx.lineTo(pos.x + 15, pos.y - 60);
        ctx.lineTo(pos.x, pos.y - 68);
        ctx.fill();
        const barW = 60, barH = 6;
        const hpRatio = game.castleHp / game.castleMaxHp;
        ctx.fillStyle = 'rgba(0,0,0,0.5)';
        ctx.fillRect(pos.x - barW / 2, pos.y - 78, barW, barH);
        ctx.fillStyle = hpRatio > 0.5 ? '#4ade80' : (hpRatio > 0.25 ? '#fbbf24' : '#ef4444');
        ctx.fillRect(pos.x - barW / 2, pos.y - 78, barW * hpRatio, barH);
        ctx.restore();
    }
    _drawEnemy(enemy) {
        const ctx = this.ctx;
        if (!enemy.alive) return;
        ctx.save();
        if (enemy.isDying) {
            const scale = Math.max(0, enemy.deathTimer / 0.3);
            ctx.globalAlpha = scale;
            ctx.translate(enemy.x, enemy.y);
            ctx.scale(scale, scale);
            ctx.translate(-enemy.x, -enemy.y);
        }
        const bob = Math.sin(enemy.animTime * 8) * 2;
        ctx.fillStyle = 'rgba(0,0,0,0.3)';
        ctx.beginPath();
        ctx.ellipse(enemy.x, enemy.y + enemy.size + 2, enemy.size * 0.8, enemy.size * 0.3, 0, 0, Math.PI * 2);
        ctx.fill();
        const bodyColor = enemy.hitFlashTimer > 0 ? '#FFFFFF' : enemy.color;
        ctx.fillStyle = bodyColor;
        ctx.beginPath();
        ctx.arc(enemy.x, enemy.y + bob, enemy.size, 0, Math.PI * 2);
        ctx.fill();
        const eyeOff = enemy.size * 0.3;
        ctx.fillStyle = '#FF0000';
        ctx.beginPath();
        ctx.arc(enemy.x - eyeOff, enemy.y + bob - 2, enemy.size * 0.18, 0, Math.PI * 2);
        ctx.arc(enemy.x + eyeOff, enemy.y + bob - 2, enemy.size * 0.18, 0, Math.PI * 2);
        ctx.fill();
        if (enemy.hp < enemy.maxHp && !enemy.isDying) {
            const barW = enemy.size * 2.5;
            const hpRatio = enemy.hp / enemy.maxHp;
            ctx.fillStyle = 'rgba(0,0,0,0.6)';
            ctx.fillRect(enemy.x - barW / 2, enemy.y - enemy.size - 10, barW, 4);
            ctx.fillStyle = enemy.isBoss ? '#FF4500' : '#FF6B6B';
            ctx.fillRect(enemy.x - barW / 2, enemy.y - enemy.size - 10, barW * hpRatio, 4);
        }
        if (enemy.isBoss) {
            ctx.fillStyle = '#FFD700';
            ctx.beginPath();
            ctx.moveTo(enemy.x - 12, enemy.y - enemy.size - 14);
            ctx.lineTo(enemy.x - 8, enemy.y - enemy.size - 24);
            ctx.lineTo(enemy.x, enemy.y - enemy.size - 16);
            ctx.lineTo(enemy.x + 8, enemy.y - enemy.size - 24);
            ctx.lineTo(enemy.x + 12, enemy.y - enemy.size - 14);
            ctx.fill();
        }
        if (enemy.slowTimer > 0) {
            ctx.strokeStyle = 'rgba(100,200,255,0.6)';
            ctx.lineWidth = 2;
            ctx.beginPath();
            ctx.arc(enemy.x, enemy.y + bob, enemy.size + 4, 0, Math.PI * 2);
            ctx.stroke();
        }
        ctx.restore();
    }
    _drawTower(tower, isDragging) {
        const ctx = this.ctx;
        if (!tower.alive) return;
        ctx.save();
        const x = tower.x, y = tower.y;
        if (isDragging) ctx.globalAlpha = 0.8;
        ctx.fillStyle = 'rgba(0,0,0,0.25)';
        ctx.beginPath();
        ctx.ellipse(x, y + tower.size + 2, tower.size * 0.8, tower.size * 0.3, 0, 0, Math.PI * 2);
        ctx.fill();
        ctx.fillStyle = tower.baseColor;
        ctx.beginPath();
        ctx.moveTo(x - tower.size, y + tower.size * 0.5);
        ctx.lineTo(x + tower.size, y + tower.size * 0.5);
        ctx.lineTo(x + tower.size * 0.7, y - tower.size * 0.2);
        ctx.lineTo(x - tower.size * 0.7, y - tower.size * 0.2);
        ctx.closePath();
        ctx.fill();
        ctx.fillStyle = tower.color;
        ctx.fillRect(x - tower.size * 0.6, y - tower.size * 0.2 - tower.size * 1.2,
                     tower.size * 1.2, tower.size * 1.2);
        ctx.fillStyle = tower.roofColor;
        ctx.beginPath();
        ctx.moveTo(x - tower.size * 0.8, y - tower.size * 0.2 - tower.size * 1.2);
        ctx.lineTo(x, y - tower.size * 0.2 - tower.size * 2.0);
        ctx.lineTo(x + tower.size * 0.8, y - tower.size * 0.2 - tower.size * 1.2);
        ctx.closePath();
        ctx.fill();
        if (tower.target && tower.alive && !tower._dragging) {
            const recoil = tower.recoilTimer > 0 ? tower.recoilTimer * 8 : 0;
            ctx.save();
            ctx.translate(x, y - tower.size);
            ctx.rotate(tower.angle);
            ctx.fillStyle = tower.isMagic ? '#E74C3C' : '#FFD700';
            ctx.beginPath();
            ctx.arc(0, 0, 4 + recoil, 0, Math.PI * 2);
            ctx.fill();
            ctx.restore();
        }
        if (tower.level > 1) {
            ctx.fillStyle = '#FFD700';
            ctx.font = 'bold 11px sans-serif';
            ctx.textAlign = 'center';
            ctx.fillText('Lv' + tower.level, x, y + tower.size + 14);
        }
        if (tower.isMagic) {
            ctx.strokeStyle = 'rgba(155,89,182,' + (0.3 + Math.sin(this.time * 4) * 0.15) + ')';
            ctx.lineWidth = 2;
            ctx.beginPath();
            ctx.arc(x, y - tower.size, tower.size * 1.2, 0, Math.PI * 2);
            ctx.stroke();
        }
        ctx.restore();
    }
    _drawDragHint(dragTower, game) {
        const ctx = this.ctx;
        const x = dragTower.x, y = dragTower.y;
        for (const t of game.towers) {
            if (t === dragTower) continue;
            if (!t.alive) continue;
            if (t.level !== dragTower.level) continue;
            if (t.level >= 6) continue;
            const d = Math.sqrt((t.x - x) ** 2 + (t.y - y) ** 2);
            if (d < 60) {
                ctx.save();
                ctx.strokeStyle = '#4ade80';
                ctx.lineWidth = 3;
                ctx.setLineDash([6, 4]);
                ctx.beginPath();
                ctx.arc(t.x, t.y, 28, 0, Math.PI * 2);
                ctx.stroke();
                ctx.fillStyle = '#4ade80';
                ctx.font = 'bold 14px sans-serif';
                ctx.textAlign = 'center';
                ctx.fillText('合 成', t.x, t.y - 35);
                ctx.restore();
            }
        }
    }
    _drawHero(hero) {
        const ctx = this.ctx;
        const x = hero.x, y = hero.y;
        const bob = Math.sin(hero.animTime * 3) * 2;
        ctx.save();
        ctx.fillStyle = 'rgba(0,0,0,0.3)';
        ctx.beginPath();
        ctx.ellipse(x, y + 14, 12, 5, 0, 0, Math.PI * 2);
        ctx.fill();
        ctx.fillStyle = '#4169E1';
        ctx.beginPath();
        ctx.arc(x, y + bob, 10, 0, Math.PI * 2);
        ctx.fill();
        ctx.fillStyle = '#1E3A8A';
        ctx.beginPath();
        ctx.moveTo(x - 6, y + bob - 5);
        ctx.lineTo(x - 14, y + bob + 12);
        ctx.lineTo(x + 4, y + bob + 8);
        ctx.fill();
        ctx.fillStyle = '#FFD700';
        ctx.beginPath();
        ctx.arc(x, y + bob - 8, 7, Math.PI, 0);
        ctx.fill();
        ctx.fillRect(x - 7, y + bob - 8, 14, 3);
        if (hero.target) {
            ctx.save();
            ctx.translate(x, y + bob);
            ctx.rotate(hero.angle);
            const recoil = hero.recoilTimer > 0 ? hero.recoilTimer * 10 : 0;
            ctx.strokeStyle = '#8B4513';
            ctx.lineWidth = 2.5;
            ctx.beginPath();
            ctx.arc(10 + recoil, 0, 10, -Math.PI * 0.4, Math.PI * 0.4);
            ctx.stroke();
            ctx.restore();
        }
        ctx.restore();
    }
    _drawProjectile(p) {
        const ctx = this.ctx;
        if (p.trail.length > 1) {
            ctx.save();
            ctx.strokeStyle = p.isMagic ? 'rgba(231,76,60,0.4)' : 'rgba(255,215,0,0.4)';
            ctx.lineWidth = 2;
            ctx.beginPath();
            ctx.moveTo(p.trail[0].x, p.trail[0].y);
            for (let i = 1; i < p.trail.length; i++) ctx.lineTo(p.trail[i].x, p.trail[i].y);
            ctx.stroke();
            ctx.restore();
        }
        ctx.save();
        ctx.fillStyle = p.isMagic ? '#E74C3C' : '#FFD700';
        ctx.beginPath();
        ctx.arc(p.x, p.y, 3, 0, Math.PI * 2);
        ctx.fill();
        ctx.restore();
    }
    _drawParticles(particles) {
        const ctx = this.ctx;
        for (const p of particles) {
            const alpha = p.life / p.maxLife;
            ctx.save();
            ctx.globalAlpha = alpha;
            ctx.fillStyle = p.color;
            ctx.beginPath();
            ctx.arc(p.x, p.y, p.size * alpha, 0, Math.PI * 2);
            ctx.fill();
            ctx.restore();
        }
    }
    _drawSkillEffects(effects) {
        const ctx = this.ctx;
        for (const e of effects) {
            const progress = 1 - e.timer / e.maxTimer;
            const alpha = e.timer / e.maxTimer;
            ctx.save();
            ctx.globalAlpha = alpha;
            ctx.strokeStyle = '#FFD700';
            ctx.lineWidth = 3;
            ctx.beginPath();
            ctx.arc(e.x, e.y, e.radius * Math.min(1, progress * 2), 0, Math.PI * 2);
            ctx.stroke();
            ctx.fillStyle = 'rgba(255,215,0,0.15)';
            ctx.beginPath();
            ctx.arc(e.x, e.y, e.radius * Math.min(1, progress * 2), 0, Math.PI * 2);
            ctx.fill();
            const arrowCount = 8;
            for (let i = 0; i < arrowCount; i++) {
                const angle = (i / arrowCount) * Math.PI * 2 + progress * 2;
                const dist = e.radius * progress;
                const ax = e.x + Math.cos(angle) * dist;
                const ay = e.y + Math.sin(angle) * dist;
                ctx.fillStyle = '#FFFACD';
                ctx.beginPath();
                ctx.moveTo(ax, ay - 8);
                ctx.lineTo(ax - 3, ay);
                ctx.lineTo(ax + 3, ay);
                ctx.closePath();
                ctx.fill();
            }
            ctx.restore();
        }
    }
    _drawGoldPopups(popups) {
        const ctx = this.ctx;
        for (const p of popups) {
            const progress = 1 - p.timer / p.maxTimer;
            const y = p.y - progress * 30;
            const alpha = p.timer / p.maxTimer;
            ctx.save();
            ctx.globalAlpha = alpha;
            ctx.fillStyle = '#FFD700';
            ctx.font = 'bold 14px sans-serif';
            ctx.textAlign = 'center';
            ctx.fillText('+' + p.amount, p.x, y);
            ctx.restore();
        }
    }
}
'@

# ================================================
# 20. src/platform/PlatformAPI.js
# ================================================
Write-File "src\platform\PlatformAPI.js" @'
export class PlatformAPI {
    get name() { throw new Error('Not implemented'); }
    async initialize() { throw new Error('Not implemented'); }
    getCanvasSize() { throw new Error('Not implemented'); }
    getContext() { throw new Error('Not implemented'); }
    requestAnimationFrame(callback) { throw new Error('Not implemented'); }
    cancelAnimationFrame(id) { throw new Error('Not implemented'); }
    now() { throw new Error('Not implemented'); }
    onPointerDown(handler) { throw new Error('Not implemented'); }
    onPointerMove(handler) { throw new Error('Not implemented'); }
    onPointerUp(handler) { throw new Error('Not implemented'); }
    async loadData(key) { throw new Error('Not implemented'); }
    async saveData(key, value) { throw new Error('Not implemented'); }
    playSound(name) { throw new Error('Not implemented'); }
    vibrate(pattern) { throw new Error('Not implemented'); }
    getScreenSize() { throw new Error('Not implemented'); }
    destroy() { throw new Error('Not implemented'); }
}
'@

# ================================================
# 21. src/platform/WebPlatform.js
# ================================================
Write-File "src\platform\WebPlatform.js" @'
import { PlatformAPI } from './PlatformAPI.js';

export class WebPlatform extends PlatformAPI {
    constructor() {
        super();
        this.canvas = null;
        this.ctx = null;
        this._handlers = { down: [], move: [], up: [] };
        this._boundEvents = [];
    }
    get name() { return 'web'; }
    async initialize() {
        this.canvas = document.getElementById('game-canvas');
        if (!this.canvas) {
            this.canvas = document.createElement('canvas');
            document.getElementById('game-container').appendChild(this.canvas);
        }
        this.ctx = this.canvas.getContext('2d');
        this._setupEvents();
        return { canvas: this.canvas, ctx: this.ctx };
    }
    _setupEvents() {
        const getPos = (e) => {
            const rect = this.canvas.getBoundingClientRect();
            const clientX = e.touches ? e.touches[0].clientX : e.clientX;
            const clientY = e.touches ? e.touches[0].clientY : e.clientY;
            return {
                x: (clientX - rect.left) * (this.canvas.width / rect.width),
                y: (clientY - rect.top) * (this.canvas.height / rect.height)
            };
        };
        const onDown = (e) => { e.preventDefault(); const p = getPos(e); this._handlers.down.forEach(h => h(p.x, p.y)); };
        const onMove = (e) => { e.preventDefault(); const p = getPos(e); this._handlers.move.forEach(h => h(p.x, p.y)); };
        const onUp = (e) => { e.preventDefault(); const p = getPos(e); this._handlers.up.forEach(h => h(p.x, p.y)); };
        this.canvas.addEventListener('mousedown', onDown);
        this.canvas.addEventListener('mousemove', onMove);
        this.canvas.addEventListener('mouseup', onUp);
        this.canvas.addEventListener('mouseleave', onUp);
        this.canvas.addEventListener('touchstart', onDown, { passive: false });
        this.canvas.addEventListener('touchmove', onMove, { passive: false });
        this.canvas.addEventListener('touchend', onUp, { passive: false });
        this._boundEvents = [
            ['mousedown', onDown], ['mousemove', onMove], ['mouseup', onUp], ['mouseleave', onUp],
            ['touchstart', onDown], ['touchmove', onMove], ['touchend', onUp]
        ];
    }
    getCanvasSize() { return { width: this.canvas.width, height: this.canvas.height }; }
    getContext() { return this.ctx; }
    requestAnimationFrame(cb) { return requestAnimationFrame(cb); }
    cancelAnimationFrame(id) { cancelAnimationFrame(id); }
    now() { return performance.now(); }
    onPointerDown(handler) { this._handlers.down.push(handler); }
    onPointerMove(handler) { this._handlers.move.push(handler); }
    onPointerUp(handler) { this._handlers.up.push(handler); }
    async loadData(key) {
        try {
            const raw = localStorage.getItem(key);
            return raw ? JSON.parse(raw) : null;
        } catch { return null; }
    }
    async saveData(key, value) {
        try { localStorage.setItem(key, JSON.stringify(value)); return true; }
        catch { return false; }
    }
    playSound(name) { /* V0.2 */ }
    vibrate(pattern) { if (navigator.vibrate) navigator.vibrate(pattern); }
    getScreenSize() { return { width: window.innerWidth, height: window.innerHeight }; }
    destroy() {
        for (const [type, handler] of this._boundEvents) {
            this.canvas.removeEventListener(type, handler);
        }
        this._handlers = { down: [], move: [], up: [] };
    }
}
'@

# ================================================
# 22. src/platform/AndroidPlatform.js
# ================================================
Write-File "src\platform\AndroidPlatform.js" @'
import { WebPlatform } from './WebPlatform.js';

export class AndroidPlatform extends WebPlatform {
    constructor() {
        super();
        this._capacitor = null;
    }
    get name() { return 'android'; }
    async initialize() {
        const result = await super.initialize();
        try {
            const mod = await import('@capacitor/core');
            this._capacitor = mod.Capacitor;
            if (this._capacitor.isNativePlatform && this._capacitor.isNativePlatform()) {
                await this._setupNativeFeatures();
            }
        } catch (e) {
            console.warn('[AndroidPlatform] Capacitor 未安装，回退到 Web 模式');
        }
        return result;
    }
    async _setupNativeFeatures() {
        try {
            const { ScreenOrientation } = await import('@capacitor/screen-orientation');
            await ScreenOrientation.lock({ orientation: 'portrait' });
        } catch (e) { /* 可选 */ }
        try {
            const { App } = await import('@capacitor/app');
            App.addListener('backButton', () => {
                if (this._onBackButton) this._onBackButton();
            });
        } catch (e) { /* 可选 */ }
    }
    onBackButton(handler) { this._onBackButton = handler; }
    async vibrate(pattern) {
        try {
            const mod = await import('@capacitor/haptics');
            await mod.Haptics.impact({ style: mod.ImpactStyle.Medium });
        } catch (e) {
            super.vibrate(pattern);
        }
    }
}
'@

# ================================================
# 23. src/platform/TapTapPlatform.js
# ================================================
Write-File "src\platform\TapTapPlatform.js" @'
import { PlatformAPI } from './PlatformAPI.js';

export class TapTapPlatform extends PlatformAPI {
    constructor() {
        super();
        this.canvas = null;
        this.ctx = null;
        this._handlers = { down: [], move: [], up: [] };
    }
    get name() { return 'taptap'; }
    async initialize() {
        if (typeof tap === 'undefined') {
            throw new Error('[TapTapPlatform] tap 全局对象未定义');
        }
        this.canvas = tap.createCanvas();
        this.ctx = this.canvas.getContext('2d');
        const info = tap.getSystemInfoSync();
        this.canvas.width = info.screenWidth;
        this.canvas.height = info.screenHeight;
        this._setupTouchEvents();
        return { canvas: this.canvas, ctx: this.ctx };
    }
    _setupTouchEvents() {
        tap.onTouchStart((e) => {
            const t = e.touches[0];
            this._handlers.down.forEach(h => h(t.clientX, t.clientY));
        });
        tap.onTouchMove((e) => {
            const t = e.touches[0];
            this._handlers.move.forEach(h => h(t.clientX, t.clientY));
        });
        tap.onTouchEnd((e) => {
            const t = e.changedTouches[0];
            this._handlers.up.forEach(h => h(t.clientX, t.clientY));
        });
    }
    getCanvasSize() { return { width: this.canvas.width, height: this.canvas.height }; }
    getContext() { return this.ctx; }
    requestAnimationFrame(cb) { return requestAnimationFrame(cb); }
    cancelAnimationFrame(id) { cancelAnimationFrame(id); }
    now() { return typeof performance !== 'undefined' ? performance.now() : Date.now(); }
    onPointerDown(handler) { this._handlers.down.push(handler); }
    onPointerMove(handler) { this._handlers.move.push(handler); }
    onPointerUp(handler) { this._handlers.up.push(handler); }
    async loadData(key) {
        try {
            const raw = tap.getStorageSync(key);
            return raw ? JSON.parse(raw) : null;
        } catch { return null; }
    }
    async saveData(key, value) {
        try { tap.setStorageSync(key, JSON.stringify(value)); return true; }
        catch { return false; }
    }
    playSound(name) { /* V0.2 */ }
    vibrate(pattern) {
        try { tap.vibrateShort({ type: 'medium' }); } catch (e) { /* ignore */ }
    }
    getScreenSize() {
        const info = tap.getSystemInfoSync();
        return { width: info.screenWidth, height: info.screenHeight };
    }
    destroy() { this._handlers = { down: [], move: [], up: [] }; }
}
'@

# ================================================
# 24. src/input/InputManager.js
# ================================================
Write-File "src\input\InputManager.js" @'
export class InputManager {
    constructor(platform, camera) {
        this.platform = platform;
        this.camera = camera;
        this.game = null;
        this.isDragging = false;
        this.dragTower = null;
        this.dragThreshold = 8;
        this.pointerDownX = 0;
        this.pointerDownY = 0;
        this.onBuildAttempt = null;
        this._setup();
    }
    setGame(game) { this.game = game; }
    _setup() {
        this.platform.onPointerDown((sx, sy) => this._onDown(sx, sy));
        this.platform.onPointerMove((sx, sy) => this._onMove(sx, sy));
        this.platform.onPointerUp((sx, sy) => this._onUp(sx, sy));
    }
    _toLogical(sx, sy) { return this.camera.toLogical(sx, sy); }
    _onDown(screenX, screenY) {
        const p = this._toLogical(screenX, screenY);
        this.pointerDownX = p.x;
        this.pointerDownY = p.y;
        if (!this.game) return;
        const tower = this._findTowerAt(p.x, p.y);
        if (tower) {
            this.isDragging = false;
            this.dragTower = tower;
            return;
        }
        const spot = this.game.map.findNearestBuildSpot(p.x, p.y, 30);
        if (spot) {
            if (this.onBuildAttempt) this.onBuildAttempt(spot);
            return;
        }
        if (this.game.skillSystem.aiming) {
            this.game.skillSystem.updateAim(p.x, p.y);
        }
    }
    _onMove(screenX, screenY) {
        const p = this._toLogical(screenX, screenY);
        if (!this.game) return;
        if (this.game.skillSystem.aiming) {
            this.game.skillSystem.updateAim(p.x, p.y);
            return;
        }
        if (this.dragTower) {
            const dx = p.x - this.pointerDownX;
            const dy = p.y - this.pointerDownY;
            const dist = Math.sqrt(dx * dx + dy * dy);
            if (!this.isDragging && dist > this.dragThreshold) {
                this.isDragging = true;
                this.game.startTowerDrag(this.dragTower, this.pointerDownX, this.pointerDownY);
            }
            if (this.isDragging) this.game.updateTowerDrag(p.x, p.y);
        }
    }
    _onUp(screenX, screenY) {
        const p = this._toLogical(screenX, screenY);
        if (!this.game) return;
        if (this.game.skillSystem.aiming) {
            this.game.useHeroSkill(p.x, p.y);
            this.game.skillSystem.cancelAiming();
            return;
        }
        if (this.isDragging && this.dragTower) {
            this.game.endTowerDrag(p.x, p.y);
        }
        this.isDragging = false;
        this.dragTower = null;
    }
    _findTowerAt(x, y) {
        if (!this.game) return null;
        for (const t of this.game.towers) {
            if (!t.alive) continue;
            const dx = t.x - x, dy = t.y - y;
            if (Math.abs(dx) < t.size + 5 && Math.abs(dy) < t.size + 10) return t;
        }
        return null;
    }
    reset() { this.isDragging = false; this.dragTower = null; }
}
'@

# ================================================
# 25. src/storage/StorageManager.js
# ================================================
Write-File "src\storage\StorageManager.js" @'
const STORAGE_KEY = 'kingdom_arrow_defense_save';
const CURRENT_VERSION = 1;

export class StorageManager {
    constructor(platform) { this.platform = platform; }
    async save(data) {
        const payload = { version: CURRENT_VERSION, timestamp: Date.now(), data };
        return await this.platform.saveData(STORAGE_KEY, payload);
    }
    async load() {
        const payload = await this.platform.loadData(STORAGE_KEY);
        if (!payload) return null;
        const migrated = migrate(payload);
        return migrated ? migrated.data : null;
    }
    async clear() { return await this.platform.saveData(STORAGE_KEY, null); }
    async saveHighScore(score) {
        const existing = await this.load() || {};
        if (!existing.highScore || score > existing.highScore) {
            existing.highScore = score;
            await this.save(existing);
        }
    }
    async getHighScore() {
        const data = await this.load();
        return data ? (data.highScore || 0) : 0;
    }
}

function migrate(payload) {
    if (!payload || !payload.version) return null;
    let version = payload.version;
    let data = payload.data;
    if (version < 1) {
        data = {
            highScore: data.score || 0,
            highWave: data.wave || 0,
            settings: { sound: true, vibration: true }
        };
        version = 1;
    }
    if (version === CURRENT_VERSION) return { version, data };
    return { version: CURRENT_VERSION, data };
}
'@

# ================================================
# 26. src/storage/migrations.js
# ================================================
Write-File "src\storage\migrations.js" @'
export const MIGRATIONS = {
    1: (data) => data
};

export function applyMigrations(payload) {
    if (!payload || typeof payload.version !== 'number') return null;
    let current = payload;
    while (current.version < Object.keys(MIGRATIONS).length) {
        const nextVersion = current.version + 1;
        const migrateFn = MIGRATIONS[nextVersion];
        if (!migrateFn) break;
        current = {
            version: nextVersion,
            data: migrateFn(current.data),
            timestamp: current.timestamp
        };
    }
    return current;
}
'@

# ================================================
# 27. src/ui/UIManager.js
# ================================================
Write-File "src\ui\UIManager.js" @'
import { STATES } from '../core/StateMachine.js';

export class UIManager {
    constructor(game, platform) {
        this.game = game;
        this.platform = platform;
        this.hudContainer = document.getElementById('hud-container');
        this.screens = {
            loading: document.getElementById('loading-screen'),
            start: document.getElementById('start-menu'),
            pause: document.getElementById('pause-menu'),
            victory: document.getElementById('victory-screen'),
            defeat: document.getElementById('defeat-screen')
        };
        this.hudElements = {};
        this._bindButtons();
        this._createHUD();
        game.stateMachine.on(STATES.MENU, () => this._showScreen('start'));
        game.stateMachine.on(STATES.PLAYING, () => this._hideAllScreens());
        game.stateMachine.on(STATES.PAUSED, () => this._showScreen('pause'));
        game.stateMachine.on(STATES.VICTORY, () => this._showVictory());
        game.stateMachine.on(STATES.DEFEAT, () => this._showDefeat());
        game.onGameOver = (result) => {
            if (result === 'victory') game.stateMachine.transition(STATES.VICTORY);
            else game.stateMachine.transition(STATES.DEFEAT);
        };
    }
    _bindButtons() {
        document.getElementById('btn-start').addEventListener('click', () => this.game.startGame());
        document.getElementById('btn-resume').addEventListener('click', () => this.game.resume());
        document.getElementById('btn-restart-from-pause').addEventListener('click', () => this.game.restart());
        document.getElementById('btn-restart-victory').addEventListener('click', () => this.game.restart());
        document.getElementById('btn-restart-defeat').addEventListener('click', () => this.game.restart());
    }
    _createHUD() {
        const hud = this.hudContainer;
        const topBar = document.createElement('div');
        topBar.id = 'hud-top';
        topBar.style.cssText = 'position:absolute;top:0;left:0;right:0;height:48px;display:flex;align-items:center;justify-content:space-between;padding:0 12px;background:rgba(0,0,0,0.5);backdrop-filter:blur(4px);font-size:14px;color:#fff;pointer-events:none;z-index:20;';
        topBar.innerHTML =
            '<div style="display:flex;gap:16px;align-items:center;">' +
            '<span id="hud-gold" style="color:#FFD700;font-weight:700;">?? 100</span>' +
            '<span id="hud-castle" style="color:#4ade80;">?? 100</span>' +
            '</div>' +
            '<div id="hud-wave" style="color:#FFD700;font-weight:700;">准备阶段 3:00</div>';
        hud.appendChild(topBar);

        const bottomBar = document.createElement('div');
        bottomBar.id = 'hud-bottom';
        bottomBar.style.cssText = 'position:absolute;bottom:0;left:0;right:0;height:64px;display:flex;align-items:center;justify-content:center;gap:16px;padding:0 12px;z-index:20;pointer-events:none;';
        bottomBar.innerHTML =
            '<button id="hud-skill-btn" style="pointer-events:auto;width:56px;height:56px;border-radius:50%;border:3px solid #FFD700;background:rgba(0,0,0,0.6);color:#FFD700;font-size:20px;cursor:pointer;display:flex;align-items:center;justify-content:center;position:relative;overflow:hidden;">??</button>' +
            '<button id="hud-pause-btn" style="pointer-events:auto;width:44px;height:44px;border-radius:50%;border:2px solid rgba(255,255,255,0.4);background:rgba(0,0,0,0.5);color:#fff;font-size:16px;cursor:pointer;display:flex;align-items:center;justify-content:center;">?</button>';
        hud.appendChild(bottomBar);

        this.hudElements = {
            gold: document.getElementById('hud-gold'),
            castle: document.getElementById('hud-castle'),
            wave: document.getElementById('hud-wave'),
            skillBtn: document.getElementById('hud-skill-btn'),
            pauseBtn: document.getElementById('hud-pause-btn')
        };
        this.hudElements.pauseBtn.addEventListener('click', () => {
            if (this.game.stateMachine.is(STATES.PLAYING)) this.game.pause();
        });
        this.hudElements.skillBtn.addEventListener('click', () => {
            if (this.game.skillSystem.canCast()) this.game.skillSystem.startAiming();
        });
    }
    _showScreen(name) {
        this._hideAllScreens();
        if (this.screens[name]) this.screens[name].classList.remove('hidden');
    }
    _hideAllScreens() {
        for (const key in this.screens) {
            if (this.screens[key]) this.screens[key].classList.add('hidden');
        }
    }
    _showVictory() {
        const stats = this.game.getStats();
        document.getElementById('victory-stats').innerHTML =
            '击杀敌人：<strong>' + stats.killCount + '</strong><br>' +
            '获得金币：<strong>' + stats.totalGoldEarned + '</strong><br>' +
            '用时：<strong>' + Math.floor(stats.elapsedTime) + '秒</strong><br>' +
            '城堡剩余生命：<strong>' + stats.castleHp + '</strong>';
        this._showScreen('victory');
    }
    _showDefeat() {
        const stats = this.game.getStats();
        document.getElementById('defeat-stats').innerHTML =
            '击杀敌人：<strong>' + stats.killCount + '</strong><br>' +
            '获得金币：<strong>' + stats.totalGoldEarned + '</strong><br>' +
            '存活时间：<strong>' + Math.floor(stats.elapsedTime) + '秒</strong><br>' +
            '抵挡波次：<strong>' + stats.completedWaves + ' / ' + stats.totalWaves + '</strong>';
        this._showScreen('defeat');
    }
    update() {
        if (!this.game) return;
        this.hudElements.gold.textContent = '?? ' + this.game.economy.gold;
        const hp = Math.max(0, this.game.castleHp);
        this.hudElements.castle.textContent = '?? ' + hp;
        this.hudElements.castle.style.color = hp > 50 ? '#4ade80' : (hp > 20 ? '#fbbf24' : '#ef4444');
        this.hudElements.wave.textContent = this.game.waveManager.getPhaseLabel();
        const skillProgress = this.game.skillSystem.getProgress();
        this.hudElements.skillBtn.style.background = skillProgress >= 1
            ? 'rgba(255,215,0,0.3)'
            : 'conic-gradient(rgba(255,215,0,0.3) ' + (skillProgress * 360) + 'deg, rgba(0,0,0,0.6) 0deg)';
    }
    showLoading(visible) {
        if (visible) this._showScreen('loading');
        else this.screens.loading.classList.add('hidden');
    }
}
'@

# ================================================
# 28. src/ui/HUD.js
# ================================================
Write-File "src\ui\HUD.js" @'
export class HUD {
    constructor() { this.visible = false; }
    show() { this.visible = true; }
    hide() { this.visible = false; }
}
'@

# ================================================
# 29. src/ui/MenuScreen.js
# ================================================
Write-File "src\ui\MenuScreen.js" @'
export class MenuScreen {
    constructor(name) { this.name = name; }
}
'@

# ================================================
# 30. src/ui/BuildMenu.js
# ================================================
Write-File "src\ui\BuildMenu.js" @'
export class BuildMenu {
    constructor() {
        this.visible = false;
        this.position = { x: 0, y: 0 };
        this.selectedSpot = null;
    }
    open(spot) { this.visible = true; this.selectedSpot = spot; }
    close() { this.visible = false; this.selectedSpot = null; }
}
'@

# ================================================
# 31. src/main.js
# ================================================
Write-File "src\main.js" @'
import { WebPlatform } from './platform/WebPlatform.js';
import { AndroidPlatform } from './platform/AndroidPlatform.js';
import { TapTapPlatform } from './platform/TapTapPlatform.js';
import { Game } from './core/Game.js';
import { Renderer } from './render/Renderer.js';
import { Camera } from './render/Camera.js';
import { InputManager } from './input/InputManager.js';
import { UIManager } from './ui/UIManager.js';
import { StorageManager } from './storage/StorageManager.js';
import { MAP_WIDTH, MAP_HEIGHT } from './core/GameMap.js';
import { STATES } from './core/StateMachine.js';

async function detectPlatform() {
    if (typeof tap !== 'undefined' && typeof tap.createCanvas === 'function') {
        return new TapTapPlatform();
    }
    try {
        const mod = await import('@capacitor/core');
        if (mod.Capacitor && mod.Capacitor.isNativePlatform && mod.Capacitor.isNativePlatform()) {
            return new AndroidPlatform();
        }
    } catch (e) { /* Capacitor 未安装 */ }
    return new WebPlatform();
}

async function bootstrap() {
    const platform = await detectPlatform();
    const { canvas, ctx } = await platform.initialize();

    const screenSize = platform.getScreenSize();
    const dpr = Math.min(window.devicePixelRatio || 1, 2);

    canvas.width = screenSize.width * dpr;
    canvas.height = screenSize.height * dpr;
    canvas.style.width = screenSize.width + 'px';
    canvas.style.height = screenSize.height + 'px';
    ctx.scale(dpr, dpr);

    const camera = new Camera(MAP_WIDTH, MAP_HEIGHT);
    camera.resize(screenSize.width, screenSize.height);

    const renderer = new Renderer(ctx, camera);
    const game = new Game(platform);
    game.setRenderer((alpha) => renderer.render(game, alpha));

    const input = new InputManager(platform, camera);
    input.setGame(game);
    input.onBuildAttempt = (spot) => {
        const success = game.buildTower(spot);
        if (!success) platform.vibrate(30);
    };

    const ui = new UIManager(game, platform);
    const storage = new StorageManager(platform);

    const handleResize = () => {
        const s = platform.getScreenSize();
        canvas.width = s.width * dpr;
        canvas.height = s.height * dpr;
        canvas.style.width = s.width + 'px';
        canvas.style.height = s.height + 'px';
        ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
        camera.resize(s.width, s.height);
    };

    if (typeof window !== 'undefined') {
        window.addEventListener('resize', handleResize);
        window.addEventListener('orientationchange', () => setTimeout(handleResize, 300));
    }

    let uiUpdateTimer = 0;
    const menuLoop = (now) => {
        uiUpdateTimer++;
        if (uiUpdateTimer % 10 === 0) ui.update();
        renderer.render(game, 0);
        platform.requestAnimationFrame(menuLoop);
    };

    game.stateMachine.transition(STATES.MENU);
    platform.requestAnimationFrame(menuLoop);

    const highScore = await storage.getHighScore();
    console.log('[王国箭塔防线] 已加载，最高分:', highScore);
    ui.showLoading(false);
    console.log('[王国箭塔防线] 平台:', platform.name, '初始化完成');
}

bootstrap().catch(err => {
    console.error('[启动失败]', err);
    const loading = document.getElementById('loading-screen');
    if (loading) {
        loading.innerHTML = '<div style="color:#ef4444;padding:20px;text-align:center;">?? 游戏启动失败<br><small style="color:#888;">' + err.message + '</small></div>';
    }
});
'@

# ================================================
# 32. capacitor.config.json
# ================================================
Write-File "capacitor.config.json" @'
{
  "appId": "com.kingdom.arrowdefense",
  "appName": "王国箭塔防线",
  "webDir": ".",
  "bundledWebRuntime": false,
  "server": { "androidScheme": "https" },
  "android": { "allowMixedContent": true, "backgroundColor": "#1a1a2e" },
  "plugins": {
    "SplashScreen": {
      "launchShowDuration": 2000,
      "backgroundColor": "#1a1a2e",
      "showSpinner": false
    },
    "ScreenOrientation": { "orientation": "portrait" }
  }
}
'@

# ================================================
# 33. package.json
# ================================================
Write-File "package.json" @'
{
  "name": "kingdom-arrow-defense",
  "version": "0.1.0",
  "description": "王国箭塔防线 - 塔防合成生存游戏",
  "type": "module",
  "scripts": {
    "dev": "npx serve . -l 3000",
    "build:android": "npx cap copy android && npx cap sync android",
    "open:android": "npx cap open android"
  }
}
'@

# ================================================
# 34. .gitignore
# ================================================
Write-File ".gitignore" @'
node_modules/
dist/
.DS_Store
*.log
android/
ios/
.vscode/
.idea/
'@

# ================================================
# 完成
# ================================================
Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  ? 全部文件生成完成！" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "下一步：" -ForegroundColor Yellow
Write-Host "  1. 双击 index.html 用浏览器打开验证" -ForegroundColor White
Write-Host "  2. 若显示'加载中...'不动，按 F12 查看控制台错误" -ForegroundColor White
Write-Host "  3. 验证通过后，参考下面的命令推送到 GitHub" -ForegroundColor White
Write-Host ""
Write-Host "推送命令：" -ForegroundColor Yellow
Write-Host "  git init" -ForegroundColor Gray
Write-Host "  git add ." -ForegroundColor Gray
Write-Host "  git commit -m ""init: 王国箭塔防线 V0.1""" -ForegroundColor Gray
Write-Host "  git branch -M main" -ForegroundColor Gray
Write-Host "  git remote add origin https://github.com/你的用户名/kingdom-arrow-defense.git" -ForegroundColor Gray
Write-Host "  git push -u origin main" -ForegroundColor Gray
Write-Host ""