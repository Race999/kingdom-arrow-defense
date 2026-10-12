import { WAVE_DATA, GAME_CONFIG } from '../data/waveConfig.js';

export class WaveManager {
    constructor() {
        this.prepTime = GAME_CONFIG.prepTime;
        this.countdown = this.prepTime;
        this.phase = 'preparation';
        this.currentWaveIndex = 0;
        this.waveTimer = 0;
        this.spawnQueue = [];
        this.spawnTimer = 0;
        this.allWavesCleared = false;
        this.scoutsSpawned = {};
        this.totalWaves = WAVE_DATA.filter(w => !w.scout).length;
        this.completedWaves = 0;
        this.bossAlive = false;
        this.onSpawnEnemy = null;
    }
    update(dt, enemies) {
        if (this.phase === 'preparation') {
            this.countdown -= dt;
            if (this.countdown <= 0) {
                this.countdown = 0;
                this.phase = 'combat';
                this.currentWaveIndex = 0;
                this._startNextWave();
            }
            this._updateScouts(dt);
        } else if (this.phase === 'combat') {
            this._updateCombat(dt, enemies);
        }
    }
    _updateScouts(dt) {
        for (let i = 0; i < WAVE_DATA.length; i++) {
            const wave = WAVE_DATA[i];
            if (!wave.scout) continue;
            if (this.scoutsSpawned[i]) continue;
            if (this.prepTime - this.countdown >= (wave.delay || 0)) {
                this.scoutsSpawned[i] = true;
                for (let j = 0; j < wave.count; j++) {
                    this.spawnQueue.push({ type: wave.type, interval: wave.interval });
                }
            }
        }
    }
    _updateCombat(dt, enemies) {
        if (this.spawnQueue.length > 0) {
            this.spawnTimer -= dt;
            if (this.spawnTimer <= 0) {
                const next = this.spawnQueue.shift();
                if (this.onSpawnEnemy) this.onSpawnEnemy(next.type);
                this.spawnTimer = next.interval || 0.5;
            }
            return;
        }
        const aliveEnemies = enemies.filter(e => e.alive && !e.isDying);
        if (aliveEnemies.length === 0) {
            this.waveTimer -= dt;
            if (this.waveTimer <= 0) {
                this.completedWaves++;
                this._startNextWave();
            }
        }
    }
    _startNextWave() {
        while (this.currentWaveIndex < WAVE_DATA.length) {
            const wave = WAVE_DATA[this.currentWaveIndex];
            if (wave.scout) { this.currentWaveIndex++; continue; }
            break;
        }
        if (this.currentWaveIndex >= WAVE_DATA.length) {
            this.allWavesCleared = true;
            this.phase = 'victory';
            return;
        }
        const wave = WAVE_DATA[this.currentWaveIndex];
        this.currentWaveIndex++;
        for (let i = 0; i < wave.count; i++) {
            this.spawnQueue.push({ type: wave.type, interval: wave.interval });
        }
        this.spawnTimer = 0;
        this.waveTimer = 3;
        if (wave.type === 'boss') this.bossAlive = true;
    }
    getPhaseLabel() {
        if (this.phase === 'preparation') {
            const m = Math.floor(this.countdown / 60);
            const s = Math.floor(this.countdown % 60);
            return '准备阶段 ' + m + ':' + s.toString().padStart(2, '0');
        }
        if (this.phase === 'combat') {
            return '第 ' + Math.min(this.completedWaves + 1, this.totalWaves) + ' / ' + this.totalWaves + ' 波';
        }
        return this.phase === 'victory' ? '胜利！' : '失败';
    }
    reset() {
        this.countdown = this.prepTime;
        this.phase = 'preparation';
        this.currentWaveIndex = 0;
        this.waveTimer = 0;
        this.spawnQueue = [];
        this.spawnTimer = 0;
        this.allWavesCleared = false;
        this.scoutsSpawned = {};
        this.completedWaves = 0;
        this.bossAlive = false;
    }
}