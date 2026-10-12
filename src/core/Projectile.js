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