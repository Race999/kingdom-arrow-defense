import { WebPlatform } from './WebPlatform.js';

export class AndroidPlatform extends WebPlatform {
    constructor() {
        super();
        this._capacitor = null;
    }
    get name() { return 'android'; }
    async initialize() {
        const result = await super.initialize();
        try {
            const mod = await import('@capacitor/core');
            this._capacitor = mod.Capacitor;
            if (this._capacitor.isNativePlatform && this._capacitor.isNativePlatform()) {
                await this._setupNativeFeatures();
            }
        } catch (e) {
            console.warn('[AndroidPlatform] Capacitor 未安装，回退到 Web 模式');
        }
        return result;
    }
    async _setupNativeFeatures() {
        try {
            const { ScreenOrientation } = await import('@capacitor/screen-orientation');
            await ScreenOrientation.lock({ orientation: 'portrait' });
        } catch (e) { /* 可选 */ }
        try {
            const { App } = await import('@capacitor/app');
            App.addListener('backButton', () => {
                if (this._onBackButton) this._onBackButton();
            });
        } catch (e) { /* 可选 */ }
    }
    onBackButton(handler) { this._onBackButton = handler; }
    async vibrate(pattern) {
        try {
            const mod = await import('@capacitor/haptics');
            await mod.Haptics.impact({ style: mod.ImpactStyle.Medium });
        } catch (e) {
            super.vibrate(pattern);
        }
    }
}