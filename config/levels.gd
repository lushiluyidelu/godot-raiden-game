extends Node

# 关卡配置数据结构
const LEVEL_CONFIG = {
	1: {
		"waves": 5,
		"enemies": [
			{"type": "normal", "count": 3, "wave": 1},
			{"type": "normal", "count": 4, "wave": 2},
			{"type": "fast", "count": 3, "wave": 3},
			{"type": "normal", "count": 5, "wave": 4},
			{"type": "shooter", "count": 3, "wave": 5}
		],
		"boss": {"hp": 20, "speed": 50, "attack": "single", "score": 1000}
	},
	2: {
		"waves": 7,
		"enemies": [
			{"type": "normal", "count": 4, "wave": 1},
			{"type": "fast", "count": 4, "wave": 2},
			{"type": "normal", "count": 5, "wave": 3},
			{"type": "shooter", "count": 4, "wave": 4},
			{"type": "fast", "count": 5, "wave": 5},
			{"type": "normal", "count": 6, "wave": 6},
			{"type": "shooter", "count": 4, "wave": 7}
		],
		"boss": {"hp": 40, "speed": 70, "attack": "double", "score": 2000}
	},
	3: {
		"waves": 8,
		"enemies": [
			{"type": "normal", "count": 5, "wave": 1},
			{"type": "fast", "count": 5, "wave": 2},
			{"type": "heavy", "count": 3, "wave": 3},
			{"type": "shooter", "count": 5, "wave": 4},
			{"type": "normal", "count": 6, "wave": 5},
			{"type": "fast", "count": 6, "wave": 6},
			{"type": "heavy", "count": 4, "wave": 7},
			{"type": "shooter", "count": 5, "wave": 8}
		],
		"boss": {"hp": 60, "speed": 40, "attack": "scatter", "score": 3000}
	},
	4: {
		"waves": 10,
		"enemies": [
			{"type": "normal", "count": 5, "wave": 1},
			{"type": "fast", "count": 6, "wave": 2},
			{"type": "heavy", "count": 3, "wave": 3},
			{"type": "shooter", "count": 5, "wave": 4},
			{"type": "kamikaze", "count": 4, "wave": 5},
			{"type": "normal", "count": 6, "wave": 6},
			{"type": "fast", "count": 7, "wave": 7},
			{"type": "heavy", "count": 4, "wave": 8},
			{"type": "shooter", "count": 6, "wave": 9},
			{"type": "kamikaze", "count": 5, "wave": 10}
		],
		"boss": {"hp": 80, "speed": 90, "attack": "circle", "score": 4000}
	},
	5: {
		"waves": 12,
		"enemies": [
			{"type": "normal", "count": 6, "wave": 1},
			{"type": "fast", "count": 7, "wave": 2},
			{"type": "heavy", "count": 4, "wave": 3},
			{"type": "shooter", "count": 6, "wave": 4},
			{"type": "kamikaze", "count": 5, "wave": 5},
			{"type": "normal", "count": 7, "wave": 6},
			{"type": "fast", "count": 8, "wave": 7},
			{"type": "heavy", "count": 5, "wave": 8},
			{"type": "shooter", "count": 7, "wave": 9},
			{"type": "kamikaze", "count": 6, "wave": 10},
			{"type": "heavy", "count": 6, "wave": 11},
			{"type": "shooter", "count": 8, "wave": 12}
		],
		"boss": {"hp": 150, "speed": 60, "attack": "multi", "score": 5000}
	}
}

# 敌人类型基础属性
const ENEMY_TYPES = {
	"normal": {"speed": 60, "health": 1, "score": 100, "color": Color.RED},
	"fast": {"speed": 120, "health": 1, "score": 200, "color": Color.YELLOW},
	"heavy": {"speed": 40, "health": 3, "score": 300, "color": Color.PURPLE},
	"shooter": {"speed": 50, "health": 2, "score": 250, "color": Color.GREEN},
	"kamikaze": {"speed": 150, "health": 1, "score": 150, "color": Color.ORANGE}
}

# 获取关卡配置
static func get_level_config(level: int) -> Dictionary:
	if LEVEL_CONFIG.has(level):
		return LEVEL_CONFIG[level]
	return {}

# 获取某波敌人的配置
static func get_wave_enemies(level: int, wave: int) -> Array:
	var config = get_level_config(level)
	if config.is_empty():
		return []

	var wave_enemies = []
	for enemy in config["enemies"]:
		if enemy["wave"] == wave:
			wave_enemies.append(enemy)
	return wave_enemies

# 获取 BOSS 配置
static func get_boss_config(level: int) -> Dictionary:
	var config = get_level_config(level)
	if config.is_empty():
		return {}
	return config["boss"]

# 获取总关卡数
static func get_total_levels() -> int:
	return LEVEL_CONFIG.size()

# 获取敌人类型属性
static func get_enemy_type_config(type_name: String) -> Dictionary:
	if ENEMY_TYPES.has(type_name):
		return ENEMY_TYPES[type_name]
	return {}
