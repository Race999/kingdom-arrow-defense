import { PlatformAPI } from './PlatformAPI.js';

export class TapTapPlatform extends PlatformAPI {
    constructor() {
        super();
        this.canvas = null;
        this.ctx = null;
        this._handlers = { down: [], move: [], up: [] };
    }
    get name() { return 'taptap'; }
    async initialize() {
        if (typeof tap === 'undefined') {
            throw new Error('[TapTapPlatform] tap 全局对象未定义');
        }
        this.canvas = tap.createCanvas();
        this.ctx = this.canvas.getContext('2d');
        const info = tap.getSystemInfoSync();
        this.canvas.width = info.screenWidth;
        this.canvas.height = info.screenHeight;
        this._setupTouchEvents();
        return { canvas: this.canvas, ctx: this.ctx };
    }
    _setupTouchEvents() {
        tap.onTouchStart((e) => {
            const t = e.touches[0];
            this._handlers.down.forEach(h => h(t.clientX, t.clientY));
        });
        tap.onTouchMove((e) => {
            const t = e.touches[0];
            this._handlers.move.forEach(h => h(t.clientX, t.clientY));
        });
        tap.onTouchEnd((e) => {
            const t = e.changedTouches[0];
            this._handlers.up.forEach(h => h(t.clientX, t.clientY));
        });
    }
    getCanvasSize() { return { width: this.canvas.width, height: this.canvas.height }; }
    getContext() { return this.ctx; }
    requestAnimationFrame(cb) { return requestAnimationFrame(cb); }
    cancelAnimationFrame(id) { cancelAnimationFrame(id); }
    now() { return typeof performance !== 'undefined' ? performance.now() : Date.now(); }
    onPointerDown(handler) { this._handlers.down.push(handler); }
    onPointerMove(handler) { this._handlers.move.push(handler); }
    onPointerUp(handler) { this._handlers.up.push(handler); }
    async loadData(key) {
        try {
            const raw = tap.getStorageSync(key);
            return raw ? JSON.parse(raw) : null;
        } catch { return null; }
    }
    async saveData(key, value) {
        try { tap.setStorageSync(key, JSON.stringify(value)); return true; }
        catch { return false; }
    }
    playSound(name) { /* V0.2 */ }
    vibrate(pattern) {
        try { tap.vibrateShort({ type: 'medium' }); } catch (e) { /* ignore */ }
    }
    getScreenSize() {
        const info = tap.getSystemInfoSync();
        return { width: info.screenWidth, height: info.screenHeight };
    }
    destroy() { this._handlers = { down: [], move: [], up: [] }; }
}