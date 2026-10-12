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