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