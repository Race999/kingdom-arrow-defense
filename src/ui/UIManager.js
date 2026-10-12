import { STATES } from '../core/StateMachine.js';

export class UIManager {
    constructor(game, platform) {
        this.game = game;
        this.platform = platform;
        this.hudContainer = document.getElementById('hud-container');
        this.screens = {
            loading: document.getElementById('loading-screen'),
            start: document.getElementById('start-menu'),
            pause: document.getElementById('pause-menu'),
            victory: document.getElementById('victory-screen'),
            defeat: document.getElementById('defeat-screen')
        };
        this.hudElements = {};
        this._bindButtons();
        this._createHUD();
        game.stateMachine.on(STATES.MENU, () => this._showScreen('start'));
        game.stateMachine.on(STATES.PLAYING, () => this._hideAllScreens());
        game.stateMachine.on(STATES.PAUSED, () => this._showScreen('pause'));
        game.stateMachine.on(STATES.VICTORY, () => this._showVictory());
        game.stateMachine.on(STATES.DEFEAT, () => this._showDefeat());
        game.onGameOver = (result) => {
            if (result === 'victory') game.stateMachine.transition(STATES.VICTORY);
            else game.stateMachine.transition(STATES.DEFEAT);
        };
    }
    _bindButtons() {
        document.getElementById('btn-start').addEventListener('click', () => this.game.startGame());
        document.getElementById('btn-resume').addEventListener('click', () => this.game.resume());
        document.getElementById('btn-restart-from-pause').addEventListener('click', () => this.game.restart());
        document.getElementById('btn-restart-victory').addEventListener('click', () => this.game.restart());
        document.getElementById('btn-restart-defeat').addEventListener('click', () => this.game.restart());
    }
    _createHUD() {
        const hud = this.hudContainer;
        const topBar = document.createElement('div');
        topBar.id = 'hud-top';
        topBar.style.cssText = 'position:absolute;top:0;left:0;right:0;height:48px;display:flex;align-items:center;justify-content:space-between;padding:0 12px;background:rgba(0,0,0,0.5);backdrop-filter:blur(4px);font-size:14px;color:#fff;pointer-events:none;z-index:20;';
        topBar.innerHTML =
            '<div style="display:flex;gap:16px;align-items:center;">' +
            '<span id="hud-gold" style="color:#FFD700;font-weight:700;">?? 100</span>' +
            '<span id="hud-castle" style="color:#4ade80;">?? 100</span>' +
            '</div>' +
            '<div id="hud-wave" style="color:#FFD700;font-weight:700;">准备阶段 3:00</div>';
        hud.appendChild(topBar);

        const bottomBar = document.createElement('div');
        bottomBar.id = 'hud-bottom';
        bottomBar.style.cssText = 'position:absolute;bottom:0;left:0;right:0;height:64px;display:flex;align-items:center;justify-content:center;gap:16px;padding:0 12px;z-index:20;pointer-events:none;';
        bottomBar.innerHTML =
            '<button id="hud-skill-btn" style="pointer-events:auto;width:56px;height:56px;border-radius:50%;border:3px solid #FFD700;background:rgba(0,0,0,0.6);color:#FFD700;font-size:20px;cursor:pointer;display:flex;align-items:center;justify-content:center;position:relative;overflow:hidden;">??</button>' +
            '<button id="hud-pause-btn" style="pointer-events:auto;width:44px;height:44px;border-radius:50%;border:2px solid rgba(255,255,255,0.4);background:rgba(0,0,0,0.5);color:#fff;font-size:16px;cursor:pointer;display:flex;align-items:center;justify-content:center;">?</button>';
        hud.appendChild(bottomBar);

        this.hudElements = {
            gold: document.getElementById('hud-gold'),
            castle: document.getElementById('hud-castle'),
            wave: document.getElementById('hud-wave'),
            skillBtn: document.getElementById('hud-skill-btn'),
            pauseBtn: document.getElementById('hud-pause-btn')
        };
        this.hudElements.pauseBtn.addEventListener('click', () => {
            if (this.game.stateMachine.is(STATES.PLAYING)) this.game.pause();
        });
        this.hudElements.skillBtn.addEventListener('click', () => {
            if (this.game.skillSystem.canCast()) this.game.skillSystem.startAiming();
        });
    }
    _showScreen(name) {
        this._hideAllScreens();
        if (this.screens[name]) this.screens[name].classList.remove('hidden');
    }
    _hideAllScreens() {
        for (const key in this.screens) {
            if (this.screens[key]) this.screens[key].classList.add('hidden');
        }
    }
    _showVictory() {
        const stats = this.game.getStats();
        document.getElementById('victory-stats').innerHTML =
            '击杀敌人：<strong>' + stats.killCount + '</strong><br>' +
            '获得金币：<strong>' + stats.totalGoldEarned + '</strong><br>' +
            '用时：<strong>' + Math.floor(stats.elapsedTime) + '秒</strong><br>' +
            '城堡剩余生命：<strong>' + stats.castleHp + '</strong>';
        this._showScreen('victory');
    }
    _showDefeat() {
        const stats = this.game.getStats();
        document.getElementById('defeat-stats').innerHTML =
            '击杀敌人：<strong>' + stats.killCount + '</strong><br>' +
            '获得金币：<strong>' + stats.totalGoldEarned + '</strong><br>' +
            '存活时间：<strong>' + Math.floor(stats.elapsedTime) + '秒</strong><br>' +
            '抵挡波次：<strong>' + stats.completedWaves + ' / ' + stats.totalWaves + '</strong>';
        this._showScreen('defeat');
    }
    update() {
        if (!this.game) return;
        this.hudElements.gold.textContent = '?? ' + this.game.economy.gold;
        const hp = Math.max(0, this.game.castleHp);
        this.hudElements.castle.textContent = '?? ' + hp;
        this.hudElements.castle.style.color = hp > 50 ? '#4ade80' : (hp > 20 ? '#fbbf24' : '#ef4444');
        this.hudElements.wave.textContent = this.game.waveManager.getPhaseLabel();
        const skillProgress = this.game.skillSystem.getProgress();
        this.hudElements.skillBtn.style.background = skillProgress >= 1
            ? 'rgba(255,215,0,0.3)'
            : 'conic-gradient(rgba(255,215,0,0.3) ' + (skillProgress * 360) + 'deg, rgba(0,0,0,0.6) 0deg)';
    }
    showLoading(visible) {
        if (visible) this._showScreen('loading');
        else this.screens.loading.classList.add('hidden');
    }
}