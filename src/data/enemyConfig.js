export const ENEMY_TYPES = {
    goblin:     { name:'哥布林', hp:30, speed:40, damage:5, goldReward:8, size:10,
                  color:'#5D8A3C', accentColor:'#3A5C24', armor:0 },
    fastGoblin: { name:'迅捷哥布林', hp:20, speed:75, damage:4, goldReward:10, size:9,
                  color:'#7DBF4A', accentColor:'#4A8C2A', armor:0 },
    orc:        { name:'重甲兽人', hp:120, speed:25, damage:15, goldReward:20, size:14,
                  color:'#8B4513', accentColor:'#5C2E0A', armor:3 },
    boss:       { name:'魔王', hp:600, speed:18, damage:50, goldReward:100, size:22,
                  color:'#8B0000', accentColor:'#4A0000', armor:8, isBoss:true }
};
export function getEnemyConfig(type) {
    return ENEMY_TYPES[type] || ENEMY_TYPES.goblin;
}