export const MIGRATIONS = {
    1: (data) => data
};

export function applyMigrations(payload) {
    if (!payload || typeof payload.version !== 'number') return null;
    let current = payload;
    while (current.version < Object.keys(MIGRATIONS).length) {
        const nextVersion = current.version + 1;
        const migrateFn = MIGRATIONS[nextVersion];
        if (!migrateFn) break;
        current = {
            version: nextVersion,
            data: migrateFn(current.data),
            timestamp: current.timestamp
        };
    }
    return current;
}