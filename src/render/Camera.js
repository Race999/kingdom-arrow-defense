export class Camera {
    constructor(logicalWidth, logicalHeight) {
        this.logicalWidth = logicalWidth;
        this.logicalHeight = logicalHeight;
        this.viewportWidth = logicalWidth;
        this.viewportHeight = logicalHeight;
        this.scale = 1;
        this.offsetX = 0;
        this.offsetY = 0;
    }
    resize(screenWidth, screenHeight) {
        this.viewportWidth = screenWidth;
        this.viewportHeight = screenHeight;
        const scaleX = screenWidth / this.logicalWidth;
        const scaleY = screenHeight / this.logicalHeight;
        this.scale = Math.min(scaleX, scaleY);
        this.offsetX = (screenWidth - this.logicalWidth * this.scale) / 2;
        this.offsetY = (screenHeight - this.logicalHeight * this.scale) / 2;
    }
    toScreen(lx, ly) {
        return { x: lx * this.scale + this.offsetX, y: ly * this.scale + this.offsetY };
    }
    toLogical(sx, sy) {
        return { x: (sx - this.offsetX) / this.scale, y: (sy - this.offsetY) / this.scale };
    }
}