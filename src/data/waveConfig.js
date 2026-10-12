export const GAME_CONFIG = {
    prepTime: 180,
    castleMaxHp: 100,
    initialGold: 100,
    heroDamage: 12,
    heroRange: 100,
    heroAttackSpeed: 1.0,
    heroSkillCooldown: 20,
    heroSkillDamage: 80,
    heroSkillRadius: 100
};
export const WAVE_DATA = [
    { scout:true, count:2, type:'goblin', interval:2.0, delay:30 },
    { scout:true, count:3, type:'goblin', interval:1.5, delay:75 },
    { scout:true, count:2, type:'fastGoblin', interval:1.2, delay:120 },
    { count:5, type:'goblin', interval:1.0, delay:0 },
    { count:8, type:'goblin', interval:0.8, delay:3 },
    { count:6, type:'fastGoblin', interval:0.6, delay:3 },
    { count:10, type:'goblin', interval:0.7, delay:3 },
    { count:4, type:'orc', interval:1.5, delay:3 },
    { count:12, type:'goblin', interval:0.5, delay:3 },
    { count:8, type:'fastGoblin', interval:0.4, delay:3 },
    { count:6, type:'orc', interval:1.2, delay:3 },
    { count:1, type:'boss', interval:1.0, delay:5 },
    { count:15, type:'goblin', interval:0.4, delay:3 },
    { count:10, type:'fastGoblin', interval:0.35, delay:3 },
    { count:8, type:'orc', interval:1.0, delay:3 },
    { count:1, type:'boss', interval:1.0, delay:5 },
    { count:20, type:'goblin', interval:0.3, delay:2 },
    { count:12, type:'fastGoblin', interval:0.3, delay:2 },
    { count:10, type:'orc', interval:0.8, delay:2 }
];