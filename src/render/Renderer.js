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