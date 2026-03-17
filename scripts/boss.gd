extends Area2D

signal boss_defeated(score_val: int)
signal boss_health_changed(current_hp: int, max_hp: int)

# BOSS 属性
var max_health: int = 20
var health: int = 20
var move_speed: float = 50.0
var attack_type: String = "single"
var score_value: int = 1000

# 状态
var direction: int = 1
var state: String = "move"  # move, attack, hurt
var attack_timer: Timer
var is_invincible: bool = false

# 子弹场景
var bullet_scene = preload("res://scenes/bullet.tscn")

# 阶段（最终 BOSS 用）
var phase: int = 1
var has_phase_2: bool = false

func _ready():
	add_to_group("boss")
	add_to_group("enemies")

	# 创建 BOSS 纹理
	_create_boss_sprite()

	# 连接信号
	connect("area_entered", _on_area_entered)

	print("[BOSS] 初始化完成！血量：", health, " 攻击类型：", attack_type)

func set_boss_config(config: Dictionary):
	if config.is_empty():
		return

	max_health = config.get("hp", 20)
	health = max_health
	move_speed = config.get("speed", 50)
	attack_type = config.get("attack", "single")
	score_value = config.get("score", 1000)

	# 检查是否有第二阶段（血量>100 的 BOSS 有变身）
	has_phase_2 = max_health >= 100
	phase = 1

	# 重新创建纹理
	_create_boss_sprite()

	# 设置攻击定时器
	_setup_attack_timer()

func _create_boss_sprite():
	var sprite = get_node_or_null("Sprite")
	if not sprite:
		return

	var size = 80
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var color = _get_color_for_attack_type()
	var half = size / 2

	# 根据攻击类型绘制不同 BOSS 外形
	match attack_type:
		"single":
			_draw_boss_green(img, color, size)
		"double":
			_draw_boss_red(img, color, size)
		"scatter":
			_draw_boss_purple(img, color, size)
		"circle":
			_draw_boss_yellow(img, color, size)
		"multi":
			_draw_boss_final(img, color, size)

	var texture = ImageTexture.create_from_image(img)
	sprite.texture = texture

func _get_color_for_attack_type() -> Color:
	match attack_type:
		"single": return Color(0.2, 0.8, 0.2, 1)   # 绿色
		"double": return Color(0.8, 0.2, 0.2, 1)   # 红色
		"scatter": return Color(0.6, 0.2, 0.8, 1)  # 紫色
		"circle": return Color(0.8, 0.8, 0.2, 1)   # 黄色
		"multi": return Color(0.9, 0.1, 0.9, 1)    # 紫色
	return Color(1, 1, 1, 1)

func _draw_boss_green(img: Image, color: Color, size: int):
	var half = size / 2
	# 主体 - 绿色战舰
	for y in range(10, 70):
		var width = int(lerp(20, 35, float(y) / size))
		for x in range(half - width, half + width):
			img.set_pixel(x, y, color.lerp(Color(0, 0.5, 0, 1), float(y) / size))
	# 机翼
	for y in range(20, 60):
		for x in range(half - 45, half - 35):
			img.set_pixel(x, y, color.darkened(0.2))
		for x in range(half + 35, half + 45):
			img.set_pixel(x, y, color.darkened(0.2))

func _draw_boss_red(img: Image, color: Color, size: int):
	var half = size / 2
	# 红色双翼舰 - W 形状
	for y in range(15, 65):
		var width = int(lerp(15, 30, float(y) / size))
		for x in range(half - width, half + width):
			img.set_pixel(x, y, color)
	# 双翼展开
	for y in range(25, 55):
		for x in range(half - 38, half - 28):
			img.set_pixel(x, y, color.lightened(0.2))
		for x in range(half + 28, half + 38):
			img.set_pixel(x, y, color.lightened(0.2))

func _draw_boss_purple(img: Image, color: Color, size: int):
	var half = size / 2
	# 紫色堡垒 - 方形主体
	for y in range(10, 70):
		for x in range(half - 35, half + 35):
			img.set_pixel(x, y, color)
	# 厚重装甲
	for y in range(15, 65):
		for x in range(half - 40, half - 35):
			img.set_pixel(x, y, color.darkened(0.3))
		for x in range(half + 35, half + 40):
			img.set_pixel(x, y, color.darkened(0.3))
	# 核心
	for y in range(25, 45):
		for x in range(half - 15, half + 15):
			img.set_pixel(x, y, color.lightened(0.3))

func _draw_boss_yellow(img: Image, color: Color, size: int):
	var half = size / 2
	# 黄色蜂群 - 圆形主体
	var center = Vector2(half, half)
	for y in range(10, 70):
		for x in range(10, 70):
			var dist = Vector2(x, y).distance_to(center)
			if dist <= 30:
				var t = dist / 30
				img.set_pixel(x, y, color.lerp(Color(1, 1, 0.5, 1), t))
	# 快速移动翼
	for y in range(20, 60):
		for x in range(half - 38, half - 30):
			img.set_pixel(x, y, color)
		for x in range(half + 30, half + 38):
			img.set_pixel(x, y, color)

func _draw_boss_final(img: Image, color: Color, size: int):
	var half = size / 2
	# 最终 BOSS - 复杂形状
	# 主体
	for y in range(5, 75):
		var width = int(lerp(25, 40, float(y) / size))
		for x in range(half - width, half + width):
			img.set_pixel(x, y, color)
	# 多重翼
	for y in range(15, 65):
		for x in range(half - 50, half - 40):
			img.set_pixel(x, y, color.darkened(0.2))
		for x in range(half + 40, half + 50):
			img.set_pixel(x, y, color.darkened(0.2))
	# 核心发光
	for y in range(20, 50):
		for x in range(half - 20, half + 20):
			var dist = Vector2(x, y).distance_to(Vector2(half, 35))
			if dist <= 15:
				img.set_pixel(x, y, color.lightened(0.4))

func _setup_attack_timer():
	attack_timer = Timer.new()
	var attack_interval = _get_attack_interval()
	attack_timer.wait_time = attack_interval
	attack_timer.autostart = true
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	add_child(attack_timer)

func _get_attack_interval() -> float:
	match attack_type:
		"single": return 1.5
		"double": return 1.2
		"scatter": return 2.0
		"circle": return 2.5
		"multi": return 1.0
	return 1.5

func _process(delta):
	# BOSS 移动逻辑
	if state == "move":
		_move_pattern(delta)

func _move_pattern(delta):
	match attack_type:
		"single":
			# 左右平移
			position.x += move_speed * direction * delta
			if position.x > 400 or position.x < 80:
				direction *= -1
		"double":
			# 8 字飞行
			var time = Time.get_ticks_msec() / 1000.0
			position.x = 240 + sin(time * 2) * 150
			position.y = 100 + cos(time * 4) * 30
		"scatter":
			# 缓慢上下移动
			position.y = 100 + sin(Time.get_ticks_msec() / 500.0) * 50
		"circle":
			# 快速环绕
			var time = Time.get_ticks_msec() / 1000.0
			position.x = 240 + cos(time * 3) * 180
			position.y = 150 + sin(time * 3) * 100
		"multi":
			# 复杂走位
			var time = Time.get_ticks_msec() / 1000.0
			position.x = 240 + sin(time * 2.5) * 160 + cos(time * 1.5) * 40
			position.y = 120 + cos(time * 2) * 60

func _on_attack_timer_timeout():
	if is_invincible:
		return

	_perform_attack()

func _perform_attack():
	match attack_type:
		"single":
			_attack_single()
		"double":
			_attack_double()
		"scatter":
			_attack_scatter()
		"circle":
			_attack_circle()
		"multi":
			_attack_multi()

func _attack_single():
	# 单发子弹
	var bullet = bullet_scene.instantiate()
	bullet.position = position + Vector2(0, 40)
	bullet.velocity = Vector2(0, 250)
	bullet.is_enemy_bullet = true
	get_parent().add_child(bullet)

func _attack_double():
	# 双发子弹
	for dir in [-1, 1]:
		var bullet = bullet_scene.instantiate()
		bullet.position = position + Vector2(dir * 20, 40)
		bullet.velocity = Vector2(dir * 50, 250)
		bullet.is_enemy_bullet = true
		get_parent().add_child(bullet)

func _attack_scatter():
	# 散射（3 向）
	for i in range(-1, 2):
		var bullet = bullet_scene.instantiate()
		bullet.position = position + Vector2(0, 40)
		bullet.velocity = Vector2(i * 100, 200)
		bullet.is_enemy_bullet = true
		get_parent().add_child(bullet)

func _attack_circle():
	# 环形子弹（8 向）
	for i in range(8):
		var angle = (PI * 2 / 8) * i
		var bullet = bullet_scene.instantiate()
		bullet.position = position
		bullet.velocity = Vector2(sin(angle) * 150, cos(angle) * 150)
		bullet.is_enemy_bullet = true
		get_parent().add_child(bullet)

func _attack_multi():
	# 多重弹幕 + 追踪弹
	# 环形
	for i in range(12):
		var angle = (PI * 2 / 12) * i
		var bullet = bullet_scene.instantiate()
		bullet.position = position
		bullet.velocity = Vector2(sin(angle) * 120, cos(angle) * 120)
		bullet.is_enemy_bullet = true
		get_parent().add_child(bullet)

	# 追踪弹（简化版 - 直接向下）
	await get_tree().create_timer(0.5).timeout
	var tracking_bullet = bullet_scene.instantiate()
	tracking_bullet.position = position + Vector2(0, 40)
	tracking_bullet.velocity = Vector2(0, 300)
	tracking_bullet.is_enemy_bullet = true
	get_parent().add_child(tracking_bullet)

func take_damage(amount):
	if is_invincible:
		return

	health -= amount
	print("[BOSS] 受到伤害！剩余血量：", health, "/", max_health)

	# 发射血量变化信号
	boss_health_changed.emit(health, max_health)

	# 受伤闪烁
	is_invincible = true
	var sprite = get_node_or_null("Sprite")
	if sprite:
		sprite.modulate = Color(1, 1, 1, 0.5)

	await get_tree().create_timer(0.2).timeout
	is_invincible = false
	if sprite:
		sprite.modulate = Color(1, 1, 1, 1)

	# 检查阶段变化（最终 BOSS）
	if has_phase_2 and health <= max_health / 2 and phase == 1:
		_phase_2_transform()

	if health <= 0:
		_die()

func _phase_2_transform():
	phase = 2
	print("[BOSS] 第二阶段变身！攻击加强！")
	# 加快攻击速度
	if attack_timer:
		attack_timer.wait_time = attack_timer.wait_time * 0.6

func _die():
	print("[BOSS] 被击败！分数：", score_value)

	# 播放爆炸音效
	var sound_manager = get_tree().root.get_node_or_null("Main/SoundManager")
	if sound_manager and sound_manager.has_method("play_explosion_sound"):
		sound_manager.play_explosion_sound()

	# 发射信号
	emit_signal("boss_defeated", score_value)
	queue_free()

func _on_area_entered(area):
	# 被子弹击中
	if area.is_in_group("bullets"):
		var bullet = area as Area2D
		if bullet and not bullet.is_enemy_bullet:
			take_damage(bullet.damage if bullet.has_method("get_damage") else 1)

func get_health_percent() -> float:
	return float(health) / float(max_health)
