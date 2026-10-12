export class Economy {
    constructor(initialGold) {
        this.gold = initialGold;
        this.totalEarned = 0;
        this.totalSpent = 0;
        this.earnPopups = [];
    }
    canAfford(amount) { return this.gold >= amount; }
    spend(amount) {
        if (!this.canAfford(amount)) return false;
        this.gold -= amount;
        this.totalSpent += amount;
        return true;
    }
    earn(amount, x, y) {
        this.gold += amount;
        this.totalEarned += amount;
        if (x !== undefined && y !== undefined) {
            this.earnPopups.push({ x, y, amount, timer:0.8, maxTimer:0.8 });
        }
    }
    update(dt) {
        for (let i = this.earnPopups.length - 1; i >= 0; i--) {
            const p = this.earnPopups[i];
            p.timer -= dt;
            if (p.timer <= 0) this.earnPopups.splice(i, 1);
        }
    }
    reset(initialGold) {
        this.gold = initialGold;
        this.totalEarned = 0;
        this.totalSpent = 0;
        this.earnPopups = [];
    }
}