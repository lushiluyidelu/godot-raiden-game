extends Node

signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)
signal boss_spawned()
signal level_completed(level: int)
signal all_enemies_cleared()

@export var current_level: int = 1
@export var current_wave: int = 0

var enemies_to_spawn: Array = []
var active_enemies: Array = []
var is_wave_active: bool = false
var is_boss_active: bool = false
var wave_spawn_timer: Timer
var check_completion_timer: Timer

const LEVEL_CONFIG = preload("res://config/levels.gd")
const ENEMY_SCENE = preload("res://scenes/enemy.tscn")

func _ready():
	setup_timers()
	print("[WaveManager] 初始化完成")

func setup_timers():
	# 波次间隔计时器
	wave_spawn_timer = Timer.new()
	wave_spawn_timer.wait_time = 3.0
	wave_spawn_timer.one_shot = true
	wave_spawn_timer.timeout.connect(_on_wave_spawn_timer_timeout)
	add_child(wave_spawn_timer)

	# 检查完成计时器
	check_completion_timer = Timer.new()
	check_completion_timer.wait_time = 0.5
	check_completion_timer.autostart = false
	check_completion_timer.timeout.connect(_check_wave_completion)
	add_child(check_completion_timer)

# 开始新关卡
func start_level(level: int):
	current_level = level
	current_wave = 0
	is_boss_active = false
	print("[WaveManager] 开始关卡 ", level)

	# 延迟一下开始第一波
	await get_tree().create_timer(1.0).timeout
	spawn_next_wave()

# 生成下一波敌人
func spawn_next_wave():
	current_wave += 1
	var level_config = LEVEL_CONFIG.get_level_config(current_level)

	if level_config.is_empty():
		print("[WaveManager] 关卡配置为空：", current_level)
		return

	# 检查是否所有小波已生成
	if current_wave > level_config["waves"]:
		# 所有小波完成，生成 BOSS
		spawn_boss()
		return

	# 获取当前波的敌人配置
	var wave_enemies = LEVEL_CONFIG.get_wave_enemies(current_level, current_wave)

	if wave_enemies.is_empty():
		print("[WaveManager] 第 ", current_wave, " 波没有敌人配置")
		return

	enemies_to_spawn = []
	for enemy_config in wave_enemies:
		for i in range(enemy_config["count"]):
			enemies_to_spawn.append(enemy_config)

	is_wave_active = true
	wave_started.emit(current_wave)
	print("[WaveManager] 第 ", current_wave, " 波开始，敌人数量：", enemies_to_spawn.size())

	# 开始生成敌人
	spawn_enemies_loop()

# 循环生成敌人
func spawn_enemies_loop():
	if enemies_to_spawn.is_empty():
		is_wave_active = false
		check_completion_timer.start()
		return

	# 每次生成一个敌人
	var enemy_config = enemies_to_spawn.pop_front()
	spawn_enemy(enemy_config)

	# 0.5 秒后生成下一个
	await get_tree().create_timer(0.5).timeout
	spawn_enemies_loop()

# 生成单个敌人
func spawn_enemy(enemy_config: Dictionary):
	if not ENEMY_SCENE:
		print("[WaveManager] 敌人场景未加载")
		return

	var enemy = ENEMY_SCENE.instantiate()
	var type_config = LEVEL_CONFIG.get_enemy_type_config(enemy_config["type"])

	# 设置敌人类型和属性
	enemy.set_enemy_type(enemy_config["type"], type_config)

	# 随机 X 位置（屏幕宽度 480 来自项目设置）
	var screen_width = 480
	enemy.position = Vector2(randf_range(50, screen_width - 50), -50)

	get_parent().add_child(enemy)
	active_enemies.append(enemy)

	# 连接敌人死亡信号
	if enemy.has_signal("enemy_defeated"):
		enemy.enemy_defeated.connect(_on_enemy_defeated.bind(enemy))

# 生成 BOSS
func spawn_boss():
	print("[WaveManager] 生成 BOSS!")
	is_boss_active = true
	boss_spawned.emit()

	var boss_config = LEVEL_CONFIG.get_boss_config(current_level)
	var boss_scene = preload("res://scenes/boss.tscn")

	if boss_scene:
		var boss = boss_scene.instantiate()
		boss.set_boss_config(boss_config)
		# 屏幕宽度 480 来自项目设置
		var screen_width = 480
		boss.position = Vector2(screen_width / 2, -100)
		get_parent().add_child(boss)

		# 连接 BOSS 死亡信号
		if boss.has_signal("boss_defeated"):
			boss.boss_defeated.connect(_on_boss_defeated)

# 敌人被击败
func _on_enemy_defeated(enemy, score: int):
	active_enemies.erase(enemy)

	# 转发敌人摧毁信号给 main.gd
	var main = get_parent()
	if main and main.has_method("_on_enemy_destroyed"):
		main._on_enemy_destroyed(enemy.position, score)

# BOSS 被击败
func _on_boss_defeated(score: int):
	is_boss_active = false
	is_wave_active = false
	check_completion_timer.stop()

	# 转发 BOSS 击杀分数给 main.gd
	var main = get_parent()
	if main and main.has_method("_on_enemy_destroyed"):
		main._on_enemy_destroyed(Vector2.ZERO, score)

	# 触发关卡完成
	level_completed.emit(current_level)
	print("[WaveManager] 关卡 ", current_level, " 完成!")

# 检查波次完成
func _check_wave_completion():
	if active_enemies.is_empty() and enemies_to_spawn.is_empty():
		check_completion_timer.stop()
		wave_completed.emit(current_wave)
		print("[WaveManager] 第 ", current_wave, " 波完成!")

		# 1.5 秒后开始下一波
		await get_tree().create_timer(1.5).timeout
		spawn_next_wave()

# 波次计时器超时
func _on_wave_spawn_timer_timeout():
	spawn_next_wave()

# 获取当前波次
func get_current_wave() -> int:
	return current_wave

# 是否关卡进行中
func is_level_active() -> bool:
	return current_wave > 0 and current_wave <= LEVEL_CONFIG.get_total_levels()

# 重置管理器
func reset():
	current_level = 0
	current_wave = 0
	enemies_to_spawn.clear()
	active_enemies.clear()
	is_wave_active = false
	is_boss_active = false
	wave_spawn_timer.stop()
	check_completion_timer.stop()
