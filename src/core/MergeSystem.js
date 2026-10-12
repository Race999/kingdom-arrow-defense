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