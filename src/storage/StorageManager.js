const STORAGE_KEY = 'kingdom_arrow_defense_save';
const CURRENT_VERSION = 1;

export class StorageManager {
    constructor(platform) { this.platform = platform; }
    async save(data) {
        const payload = { version: CURRENT_VERSION, timestamp: Date.now(), data };
        return await this.platform.saveData(STORAGE_KEY, payload);
    }
    async load() {
        const payload = await this.platform.loadData(STORAGE_KEY);
        if (!payload) return null;
        const migrated = migrate(payload);
        return migrated ? migrated.data : null;
    }
    async clear() { return await this.platform.saveData(STORAGE_KEY, null); }
    async saveHighScore(score) {
        const existing = await this.load() || {};
        if (!existing.highScore || score > existing.highScore) {
            existing.highScore = score;
            await this.save(existing);
        }
    }
    async getHighScore() {
        const data = await this.load();
        return data ? (data.highScore || 0) : 0;
    }
}

function migrate(payload) {
    if (!payload || !payload.version) return null;
    let version = payload.version;
    let data = payload.data;
    if (version < 1) {
        data = {
            highScore: data.score || 0,
            highWave: data.wave || 0,
            settings: { sound: true, vibration: true }
        };
        version = 1;
    }
    if (version === CURRENT_VERSION) return { version, data };
    return { version: CURRENT_VERSION, data };
}