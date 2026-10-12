import { WebPlatform } from './platform/WebPlatform.js';
import { AndroidPlatform } from './platform/AndroidPlatform.js';
import { TapTapPlatform } from './platform/TapTapPlatform.js';
import { Game } from './core/Game.js';
import { Renderer } from './render/Renderer.js';
import { Camera } from './render/Camera.js';
import { InputManager } from './input/InputManager.js';
import { UIManager } from './ui/UIManager.js';
import { StorageManager } from './storage/StorageManager.js';
import { MAP_WIDTH, MAP_HEIGHT } from './core/GameMap.js';
import { STATES } from './core/StateMachine.js';

async function detectPlatform() {
    if (typeof tap !== 'undefined' && typeof tap.createCanvas === 'function') {
        return new TapTapPlatform();
    }
    try {
        const mod = await import('@capacitor/core');
        if (mod.Capacitor && mod.Capacitor.isNativePlatform && mod.Capacitor.isNativePlatform()) {
            return new AndroidPlatform();
        }
    } catch (e) { /* Capacitor 未安装 */ }
    return new WebPlatform();
}

async function bootstrap() {
    const platform = await detectPlatform();
    const { canvas, ctx } = await platform.initialize();

    const screenSize = platform.getScreenSize();
    const dpr = Math.min(window.devicePixelRatio || 1, 2);

    canvas.width = screenSize.width * dpr;
    canvas.height = screenSize.height * dpr;
    canvas.style.width = screenSize.width + 'px';
    canvas.style.height = screenSize.height + 'px';
    ctx.scale(dpr, dpr);

    const camera = new Camera(MAP_WIDTH, MAP_HEIGHT);
    camera.resize(screenSize.width, screenSize.height);

    const renderer = new Renderer(ctx, camera);
    const game = new Game(platform);
    game.setRenderer((alpha) => renderer.render(game, alpha));

    const input = new InputManager(platform, camera);
    input.setGame(game);
    input.onBuildAttempt = (spot) => {
        const success = game.buildTower(spot);
        if (!success) platform.vibrate(30);
    };

    const ui = new UIManager(game, platform);
    const storage = new StorageManager(platform);

    const handleResize = () => {
        const s = platform.getScreenSize();
        canvas.width = s.width * dpr;
        canvas.height = s.height * dpr;
        canvas.style.width = s.width + 'px';
        canvas.style.height = s.height + 'px';
        ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
        camera.resize(s.width, s.height);
    };

    if (typeof window !== 'undefined') {
        window.addEventListener('resize', handleResize);
        window.addEventListener('orientationchange', () => setTimeout(handleResize, 300));
    }

    let uiUpdateTimer = 0;
    const menuLoop = (now) => {
        uiUpdateTimer++;
        if (uiUpdateTimer % 10 === 0) ui.update();
        renderer.render(game, 0);
        platform.requestAnimationFrame(menuLoop);
    };

    game.stateMachine.transition(STATES.MENU);
    platform.requestAnimationFrame(menuLoop);

    const highScore = await storage.getHighScore();
    console.log('[王国箭塔防线] 已加载，最高分:', highScore);
    ui.showLoading(false);
    console.log('[王国箭塔防线] 平台:', platform.name, '初始化完成');
}

bootstrap().catch(err => {
    console.error('[启动失败]', err);
    const loading = document.getElementById('loading-screen');
    if (loading) {
        loading.innerHTML = '<div style="color:#ef4444;padding:20px;text-align:center;">?? 游戏启动失败<br><small style="color:#888;">' + err.message + '</small></div>';
    }
});