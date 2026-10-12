import { PlatformAPI } from './PlatformAPI.js';

export class WebPlatform extends PlatformAPI {
    constructor() {
        super();
        this.canvas = null;
        this.ctx = null;
        this._handlers = { down: [], move: [], up: [] };
        this._boundEvents = [];
    }
    get name() { return 'web'; }
    async initialize() {
        this.canvas = document.getElementById('game-canvas');
        if (!this.canvas) {
            this.canvas = document.createElement('canvas');
            document.getElementById('game-container').appendChild(this.canvas);
        }
        this.ctx = this.canvas.getContext('2d');
        this._setupEvents();
        return { canvas: this.canvas, ctx: this.ctx };
    }
    _setupEvents() {
        const getPos = (e) => {
            const rect = this.canvas.getBoundingClientRect();
            const clientX = e.touches ? e.touches[0].clientX : e.clientX;
            const clientY = e.touches ? e.touches[0].clientY : e.clientY;
            return {
                x: (clientX - rect.left) * (this.canvas.width / rect.width),
                y: (clientY - rect.top) * (this.canvas.height / rect.height)
            };
        };
        const onDown = (e) => { e.preventDefault(); const p = getPos(e); this._handlers.down.forEach(h => h(p.x, p.y)); };
        const onMove = (e) => { e.preventDefault(); const p = getPos(e); this._handlers.move.forEach(h => h(p.x, p.y)); };
        const onUp = (e) => { e.preventDefault(); const p = getPos(e); this._handlers.up.forEach(h => h(p.x, p.y)); };
        this.canvas.addEventListener('mousedown', onDown);
        this.canvas.addEventListener('mousemove', onMove);
        this.canvas.addEventListener('mouseup', onUp);
        this.canvas.addEventListener('mouseleave', onUp);
        this.canvas.addEventListener('touchstart', onDown, { passive: false });
        this.canvas.addEventListener('touchmove', onMove, { passive: false });
        this.canvas.addEventListener('touchend', onUp, { passive: false });
        this._boundEvents = [
            ['mousedown', onDown], ['mousemove', onMove], ['mouseup', onUp], ['mouseleave', onUp],
            ['touchstart', onDown], ['touchmove', onMove], ['touchend', onUp]
        ];
    }
    getCanvasSize() { return { width: this.canvas.width, height: this.canvas.height }; }
    getContext() { return this.ctx; }
    requestAnimationFrame(cb) { return requestAnimationFrame(cb); }
    cancelAnimationFrame(id) { cancelAnimationFrame(id); }
    now() { return performance.now(); }
    onPointerDown(handler) { this._handlers.down.push(handler); }
    onPointerMove(handler) { this._handlers.move.push(handler); }
    onPointerUp(handler) { this._handlers.up.push(handler); }
    async loadData(key) {
        try {
            const raw = localStorage.getItem(key);
            return raw ? JSON.parse(raw) : null;
        } catch { return null; }
    }
    async saveData(key, value) {
        try { localStorage.setItem(key, JSON.stringify(value)); return true; }
        catch { return false; }
    }
    playSound(name) { /* V0.2 */ }
    vibrate(pattern) { if (navigator.vibrate) navigator.vibrate(pattern); }
    getScreenSize() { return { width: window.innerWidth, height: window.innerHeight }; }
    destroy() {
        for (const [type, handler] of this._boundEvents) {
            this.canvas.removeEventListener(type, handler);
        }
        this._handlers = { down: [], move: [], up: [] };
    }
}