export const MAP_WIDTH = 960;
export const MAP_HEIGHT = 640;
export const ENEMY_PATH = [
    { x:880, y:560 }, { x:780, y:560 }, { x:780, y:420 },
    { x:620, y:420 }, { x:620, y:300 }, { x:460, y:300 },
    { x:460, y:180 }, { x:300, y:180 }, { x:300, y:100 },
    { x:160, y:100 }
];
export const BUILD_SPOTS = [
    { x:700, y:350 }, { x:700, y:490 },
    { x:560, y:350 }, { x:560, y:490 },
    { x:540, y:240 }, { x:680, y:240 },
    { x:400, y:240 }, { x:400, y:360 },
    { x:520, y:120 }, { x:360, y:120 },
    { x:240, y:240 }, { x:240, y:140 }
];
export const CASTLE_POS = { x:140, y:100 };

export class GameMap {
    constructor() {
        this.width = MAP_WIDTH;
        this.height = MAP_HEIGHT;
        this.path = ENEMY_PATH.map(p => ({ ...p }));
        this.buildSpots = BUILD_SPOTS.map(p => ({ ...p, occupied:false }));
        this.castlePos = { ...CASTLE_POS };
        this.pathLength = 0;
        this.pathSegments = [];
        for (let i = 0; i < this.path.length - 1; i++) {
            const a = this.path[i], b = this.path[i + 1];
            const dx = b.x - a.x, dy = b.y - a.y;
            const len = Math.sqrt(dx * dx + dy * dy);
            this.pathSegments.push({ from:a, to:b, length:len });
            this.pathLength += len;
        }
    }
    getPositionAtDistance(dist) {
        let remaining = dist;
        for (const seg of this.pathSegments) {
            if (remaining <= seg.length) {
                const t = remaining / seg.length;
                return {
                    x: seg.from.x + (seg.to.x - seg.from.x) * t,
                    y: seg.from.y + (seg.to.y - seg.from.y) * t
                };
            }
            remaining -= seg.length;
        }
        return { ...this.castlePos };
    }
    isOnPath(x, y, threshold = 40) {
        for (const seg of this.pathSegments) {
            const dist = this._pointToSegmentDist(x, y,
                seg.from.x, seg.from.y, seg.to.x, seg.to.y);
            if (dist < threshold) return true;
        }
        return false;
    }
    _pointToSegmentDist(px, py, x1, y1, x2, y2) {
        const dx = x2 - x1, dy = y2 - y1;
        const lenSq = dx * dx + dy * dy;
        if (lenSq === 0) return Math.sqrt((px - x1) ** 2 + (py - y1) ** 2);
        let t = ((px - x1) * dx + (py - y1) * dy) / lenSq;
        t = Math.max(0, Math.min(1, t));
        return Math.sqrt((px - (x1 + t * dx)) ** 2 + (py - (y1 + t * dy)) ** 2);
    }
    findNearestBuildSpot(x, y, maxDist = 50) {
        let best = null, bestDist = maxDist;
        for (const spot of this.buildSpots) {
            if (spot.occupied) continue;
            const d = Math.sqrt((x - spot.x) ** 2 + (y - spot.y) ** 2);
            if (d < bestDist) { bestDist = d; best = spot; }
        }
        return best;
    }
    freeBuildSpot(x, y) {
        for (const spot of this.buildSpots) {
            if (Math.abs(spot.x - x) < 2 && Math.abs(spot.y - y) < 2) {
                spot.occupied = false;
                return;
            }
        }
    }
    reset() { this.buildSpots.forEach(s => s.occupied = false); }
}