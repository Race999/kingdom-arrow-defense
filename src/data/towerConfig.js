export const TOWER_LEVELS = [
    { level:1, name:'木制箭塔', cost:25, damage:8, range:80, attackSpeed:1.0, projectileSpeed:300,
      color:'#8B6914', roofColor:'#A0522D', baseColor:'#6B4226', size:14 },
    { level:2, name:'强化木塔', cost:0, damage:16, range:95, attackSpeed:1.2, projectileSpeed:350,
      color:'#A0782C', roofColor:'#CD853F', baseColor:'#7B5B3A', size:16 },
    { level:3, name:'石制箭塔', cost:0, damage:30, range:110, attackSpeed:1.4, projectileSpeed:400,
      color:'#808080', roofColor:'#A9A9A9', baseColor:'#696969', size:18 },
    { level:4, name:'钢铁箭塔', cost:0, damage:55, range:125, attackSpeed:1.7, projectileSpeed:450,
      color:'#4A6FA5', roofColor:'#6B8CC7', baseColor:'#2E4A6E', size:20 },
    { level:5, name:'黄金箭塔', cost:0, damage:100, range:140, attackSpeed:2.0, projectileSpeed:500,
      color:'#DAA520', roofColor:'#FFD700', baseColor:'#B8860B', size:22 },
    { level:6, name:'魔法箭塔', cost:0, damage:200, range:160, attackSpeed:2.5, projectileSpeed:600,
      color:'#9B59B6', roofColor:'#E74C3C', baseColor:'#6C3483', size:24, magic:true }
];
export const TOWER_COST_LV1 = 25;
export function getTowerConfig(level) {
    return TOWER_LEVELS[level - 1] || TOWER_LEVELS[0];
}
export const MAX_TOWER_LEVEL = 6;