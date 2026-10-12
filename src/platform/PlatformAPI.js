export class PlatformAPI {
    get name() { throw new Error('Not implemented'); }
    async initialize() { throw new Error('Not implemented'); }
    getCanvasSize() { throw new Error('Not implemented'); }
    getContext() { throw new Error('Not implemented'); }
    requestAnimationFrame(callback) { throw new Error('Not implemented'); }
    cancelAnimationFrame(id) { throw new Error('Not implemented'); }
    now() { throw new Error('Not implemented'); }
    onPointerDown(handler) { throw new Error('Not implemented'); }
    onPointerMove(handler) { throw new Error('Not implemented'); }
    onPointerUp(handler) { throw new Error('Not implemented'); }
    async loadData(key) { throw new Error('Not implemented'); }
    async saveData(key, value) { throw new Error('Not implemented'); }
    playSound(name) { throw new Error('Not implemented'); }
    vibrate(pattern) { throw new Error('Not implemented'); }
    getScreenSize() { throw new Error('Not implemented'); }
    destroy() { throw new Error('Not implemented'); }
}