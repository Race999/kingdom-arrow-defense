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