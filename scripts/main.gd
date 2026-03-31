extends Node2D

const ENEMY_SCENE = preload("res://scenes/enemy.tscn")
const EXPLOSION_SCENE = preload("res://scenes/explosion.tscn")
const POWERUP_SCENE = preload("res://scenes/powerup.tscn")
const PowerUpType = preload("res://scripts/powerup.gd").PowerUpType
const LEVEL_CONFIG = preload("res://config/levels.gd")

# UI 节点引用
@onready var score_label = $UI/TopBar/ScoreContainer/ScoreLabel
@onready var health_icons = [
	$UI/TopBar/HealthContainer/HealthIcon1,
	$UI/TopBar/HealthContainer/HealthIcon2,
	$UI/TopBar/HealthContainer/HealthIcon3
]
@onready var wave_label = $UI/WaveLabel
@onready var weapon_label = $UI/BottomBar/WeaponLabel
@onready var bomb_count_label = $UI/BottomBar/BombContainer/BombCount
@onready var combo_label = $UI/ComboLabel
@onready var boss_health_bar = $UI/BossHealthBar
@onready var boss_name_label = $UI/BossHealthBar/BossNameLabel
@onready var game_over_overlay = $UI/GameOverOverlay
@onready var game_over_label = $UI/GameOverOverlay/GameOverVBox/GameOverLabel
@onready var final_score_label = $UI/GameOverOverlay/GameOverVBox/FinalScoreLabel
@onready var pause_overlay = $UI/PauseOverlay
@onready var wave_message = $UI/WaveMessage
@onready var warning_message = $UI/WarningMessage

var score = 0
var game_over = false
var level_complete = false
var is_paused = false

# 生命值系统
var player_health = 3
var max_health = 3

# 背景星空
var stars = []
var bg_scroll_speed = 50.0

# 玩家无敌时间
var player_invincible = false
var invincible_timer = 0.0
var invincible_duration = 1.5

# 关卡系统
var current_level: int = 1
var wave_manager: Node

# 连击系统
var combo_count: int = 0
var combo_timer: float = 0.0
var combo_multiplier: float = 1.0

# 道具掉落
var powerup_drop_rate: float = 0.15  # 15% 掉落率

func _ready():
	print("[Main] 游戏开始！")

	# 初始化星空背景
	var screen_size = get_viewport_rect().size
	for i in range(100):
		stars.append({
			"pos": Vector2(randf() * screen_size.x, randf() * screen_size.y),
			"speed": randf_range(20.0, 60.0),
			"size": randf_range(1.0, 2.5),
			"brightness": randf_range(0.5, 1.0)
		})

	# 播放背景音乐
	var sound_manager = get_node_or_null("SoundManager")
	if sound_manager:
		sound_manager.start_bgm()

	# 初始化 UI
	update_health_display()
	update_wave_display()
	update_weapon_level_display()
	update_combo_display()

	# 隐藏 BOSS 血条
	if boss_health_bar:
		boss_health_bar.visible = false

	# 创建并初始化 WaveManager
	wave_manager = preload("res://scripts/wave_manager.gd").new()
	wave_manager.name = "WaveManager"
	add_child(wave_manager)

	# 连接 WaveManager 信号
	wave_manager.wave_started.connect(_on_wave_started)
	wave_manager.wave_completed.connect(_on_wave_completed)
	wave_manager.boss_spawned.connect(_on_boss_spawned)
	wave_manager.level_completed.connect(_on_level_completed)

	# 连接 BOSS 信号（当 BOSS 生成时）
	wave_manager.boss_spawned.connect(_connect_boss_signal)

	# 开始第一关
	wave_manager.start_level(current_level)

func _connect_boss_signal():
	# 延迟连接 BOSS 信号
	await get_tree().create_timer(0.1).timeout
	var boss = get_node_or_null("Boss")
	if boss and boss.has_signal("boss_health_changed"):
		boss.boss_health_changed.connect(_on_boss_health_changed)

func _process(delta):
	# 暂停处理（ESC键）
	if Input.is_action_just_pressed("ui_cancel"):
		if not game_over:
			toggle_pause()
		return

	if game_over:
		game_over_overlay.visible = true
		final_score_label.text = "最终分数：" + str(score)
		# 回车键重新开始
		if Input.is_action_just_pressed("ui_accept"):
			get_tree().reload_current_scene()
		return

	if is_paused:
		return

	if level_complete:
		return

	score_label.text = str(score)

	# 测试命令：按 B 键直接生成 BOSS
	if Input.is_action_just_pressed("spawn_test_boss"):
		_spawn_test_boss()

	# 更新连击计时器
	if combo_count > 1:
		combo_timer -= delta
		if combo_timer <= 0:
			combo_count = 0
			combo_multiplier = 1.0
			update_combo_display()

	# 更新无敌状态
	if player_invincible:
		invincible_timer -= delta
		if invincible_timer <= 0:
			player_invincible = false
			var player = get_node_or_null("Player")
			if player:
				player.modulate.a = 1.0

	# 玩家闪烁效果（无敌时）
	if player_invincible and int(invincible_timer * 10) % 2 == 0:
		var player = get_node_or_null("Player")
		if player:
			player.modulate.a = 0.3
		else:
			player_invincible = false

	# 更新星空背景（向下滚动）
	for i in range(stars.size()):
		stars[i].pos.y += stars[i].speed * delta
		if stars[i].pos.y > 720:
			stars[i].pos.y = -10
			stars[i].pos.x = randf() * 480

func _draw():
	# 绘制星空背景
	for star in stars:
		var color = Color(star.brightness, star.brightness, star.brightness + 0.2, 0.8)
		draw_circle(star.pos, star.size, color)

# WaveManager 信号处理
func _on_wave_started(wave_number: int):
	print("[Main] 第 ", wave_number, " 波开始")
	update_wave_display()

	# 显示 WAVE 提示
	show_wave_message(str(current_level) + "-" + str(wave_number))

# 测试用：生成 BOSS
func _spawn_test_boss():
	print("[Main] 测试：生成 BOSS！")
	var boss_config = LEVEL_CONFIG.get_boss_config(1)
	var boss_scene = preload("res://scenes/boss.tscn")

	if boss_scene:
		# 删除已有的 BOSS
		var old_boss = get_node_or_null("Boss")
		if old_boss:
			old_boss.queue_free()

		var boss = boss_scene.instantiate()
		boss.set_boss_config(boss_config)
		boss.name = "Boss"
		boss.position = Vector2(240, 100)  # 屏幕中央上方
		add_child(boss)

		# 连接 BOSS 信号
		await get_tree().create_timer(0.1).timeout
		if boss and boss.has_signal("boss_health_changed"):
			boss.boss_health_changed.connect(_on_boss_health_changed)

		print("[Main] BOSS 已生成！血量：", boss.health, " 攻击类型：", boss.attack_type)

func _on_wave_completed(wave_number: int):
	print("[Main] 第 ", wave_number, " 波完成")

func _on_boss_spawned():
	print("[Main] BOSS 战开始!")

	# 显示警告动画
	show_warning_message("BOSS")

	# 等待警告动画完成
	await get_tree().create_timer(1.5).timeout

	if boss_health_bar:
		boss_health_bar.visible = true
		boss_health_bar.value = 100.0

	# 连接 BOSS 血条信号
	_connect_boss_signal()

func _on_boss_health_changed(current_hp: int, max_hp: int):
	if boss_health_bar:
		boss_health_bar.max_value = max_hp
		boss_health_bar.value = current_hp

func _on_level_completed(level: int):
	print("[Main] 关卡 ", level, " 完成!")
	level_complete = true

	# 关卡结算奖励
	var level_bonus = 10000 * level
	score += level_bonus
	print("[Main] 关卡完成奖励：", level_bonus)

	# 进入下一关或游戏通关
	if level < LEVEL_CONFIG.get_total_levels():
		await get_tree().create_timer(3.0).timeout
		current_level = level + 1
		level_complete = false
		wave_manager.start_level(current_level)
	else:
		# 游戏通关
		game_over = true
		game_over_label.text = "游戏通关!"
		final_score_label.text = "最终分数：" + str(score)

# 敌人被击毁
func _on_enemy_destroyed(enemy_position: Vector2, score_value: int):
	# 连击系统
	combo_count += 1
	combo_timer = 3.0
	_update_combo_multiplier()

	var multiplier_score = int(score_value * combo_multiplier)
	score += multiplier_score

	print("[Main] 敌人被击毁！获得分数：", multiplier_score, " (x", combo_multiplier, ")")

	# 生成爆炸效果
	var explosion = EXPLOSION_SCENE.instantiate()
	explosion.position = enemy_position
	add_child(explosion)

	# 道具掉落
	_try_drop_powerup(enemy_position)

	# 更新 UI
	update_combo_display()

# 更新连击倍率
func _update_combo_multiplier():
	if combo_count >= 20:
		combo_multiplier = 3.0
	elif combo_count >= 10:
		combo_multiplier = 2.0
	elif combo_count >= 5:
		combo_multiplier = 1.5
	elif combo_count >= 2:
		combo_multiplier = 1.2
	else:
		combo_multiplier = 1.0

# 道具掉落
func _try_drop_powerup(position: Vector2):
	if randf() > powerup_drop_rate:
		return

	var powerup = POWERUP_SCENE.instantiate()

	# 随机道具类型
	var rand = randf()
	var powerup_type = PowerUpType.WEAPON_P
	if rand < 0.35:
		powerup_type = PowerUpType.WEAPON_P  # 35% 武器升级
	elif rand < 0.55:
		powerup_type = PowerUpType.MISSILE_M  # 20% 导弹
	elif rand < 0.70:
		powerup_type = PowerUpType.SHIELD_S   # 15% 护盾
	elif rand < 0.82:
		powerup_type = PowerUpType.HEART      # 12% 生命
	elif rand < 0.92:
		powerup_type = PowerUpType.BOMB_B     # 10% 炸弹
	else:
		powerup_type = PowerUpType.SPEED_V    # 8% 速度提升

	powerup.set_powerup_type(powerup_type)
	powerup.position = position
	add_child(powerup)

	print("[Main] 道具掉落：", powerup._get_type_name())

func _on_player_hit():
	if game_over or player_invincible:
		return

	player_health -= 1
	print("[Main] 玩家受伤！剩余生命：", player_health)
	update_health_display()

	# 播放受伤音效
	var sound_manager = get_node_or_null("SoundManager")
	if sound_manager and sound_manager.has_method("play_explosion_sound"):
		sound_manager.play_explosion_sound()

	if player_health <= 0:
		game_over = true
		print("[Main] 游戏结束！最终分数：", score)
	else:
		player_invincible = true
		invincible_timer = invincible_duration

# 添加生命
func add_life(amount: int):
	player_health = min(player_health + amount, max_health)
	update_health_display()
	print("[Main] 生命 +", amount, "，当前生命：", player_health)

# 玩家受伤（供 player.gd 调用）
func player_hit():
	_on_player_hit()

# UI 更新函数
func update_health_display():
	"""更新生命值图标显示"""
	for i in range(health_icons.size()):
		if i < player_health:
			health_icons[i].modulate = Color(1, 1, 1, 1)  # 正常显示
		else:
			health_icons[i].modulate = Color(0.3, 0.3, 0.3, 0.5)  # 灰色半透明

func update_wave_display():
	if wave_label:
		wave_label.text = "WAVE " + str(current_level) + "-" + str(wave_manager.get_current_wave() if wave_manager else 0)

func update_weapon_level_display():
	if weapon_label:
		var player = get_node_or_null("Player")
		var level = player.weapon_level if player and "weapon_level" in player else 1
		weapon_label.text = "武器 Lv." + str(level)

func update_bomb_display():
	"""更新炸弹数量显示"""
	if bomb_count_label:
		var player = get_node_or_null("Player")
		var bombs = player.bombs if player and "bombs" in player else 0
		bomb_count_label.text = "x" + str(bombs)

func update_combo_display():
	if combo_label:
		if combo_count >= 2:
			combo_label.text = "COMBO x" + str(combo_count)
			combo_label.visible = true
		else:
			combo_label.visible = false

# === 暂停功能 ===
func toggle_pause():
	"""切换暂停状态"""
	is_paused = not is_paused
	pause_overlay.visible = is_paused
	get_tree().paused = is_paused
	print("[Main] 游戏暂停：", is_paused)

# === 过渡动画 ===
func show_wave_message(wave: String):
	"""显示关卡波次提示"""
	wave_message.text = "WAVE " + wave
	wave_message.modulate.a = 0
	wave_message.visible = true

	var tween = create_tween()
	tween.tween_property(wave_message, "modulate:a", 1.0, 0.3)
	tween.tween_interval(1.0)
	tween.tween_property(wave_message, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): wave_message.visible = false)

func show_warning_message(boss_name: String = ""):
	"""显示BOSS警告"""
	warning_message.text = "WARNING!"
	warning_message.modulate.a = 0
	warning_message.visible = true

	var tween = create_tween()
	tween.set_loops(3)  # 闪烁3次
	tween.tween_property(warning_message, "modulate:a", 1.0, 0.2)
	tween.tween_property(warning_message, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func():
		warning_message.visible = false
		if boss_name != "" and boss_name_label:
			boss_name_label.text = boss_name
			boss_name_label.visible = true
	)
