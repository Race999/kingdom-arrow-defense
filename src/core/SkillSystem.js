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