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