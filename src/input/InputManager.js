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