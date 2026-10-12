export class GameLoop {
    constructor(updateCallback, renderCallback) {
        this.updateCallback = updateCallback;
        this.renderCallback = renderCallback;
        this.step = 1 / 60;
        this.accumulator = 0;
        this.lastTime = 0;
        this.isRunning = false;
        this.requestId = null;
        this.boundLoop = this.loop.bind(this);
        this._platform = null;
    }
    setPlatform(platform) { this._platform = platform; }
    start() {
        if (this.isRunning) return;
        this.isRunning = true;
        this.lastTime = this._now();
        this.requestId = this._raf(this.boundLoop);
    }
    stop() {
        this.isRunning = false;
        if (this.requestId && this._platform) {
            this._platform.cancelAnimationFrame(this.requestId);
        }
        this.requestId = null;
    }
    _now() {
        if (this._platform) return this._platform.now();
        return typeof performance !== 'undefined' ? performance.now() : Date.now();
    }
    _raf(cb) {
        if (this._platform) return this._platform.requestAnimationFrame(cb);
        return requestAnimationFrame(cb);
    }
    loop(currentTime) {
        if (!this.isRunning) return;
        let deltaTime = (currentTime - this.lastTime) / 1000;
        this.lastTime = currentTime;
        if (deltaTime > 0.25) deltaTime = 0.25;
        this.accumulator += deltaTime;
        while (this.accumulator >= this.step) {
            this.updateCallback(this.step);
            this.accumulator -= this.step;
        }
        const alpha = this.accumulator / this.step;
        this.renderCallback(alpha);
        this.requestId = this._raf(this.boundLoop);
    }
}