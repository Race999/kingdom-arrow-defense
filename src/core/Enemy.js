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