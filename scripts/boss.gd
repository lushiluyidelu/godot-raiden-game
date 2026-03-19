extends Area2D

signal boss_defeated(score_val: int)
signal boss_health_changed(current_hp: int, max_hp: int)

# BOSS 属性
var max_health: int = 20
var health: int = 20
var move_speed: float = 50.0
var attack_type: String = "single"
var score_value: int = 1000
var is_invincible: bool = false

# 阶段（最终 BOSS 用）
var phase: int = 1
var has_phase_2: bool = false

# StateChart
@onready var state_chart: Node = $BossStateMachine

# 子弹场景
var bullet_scene = preload("res://scenes/bullet.tscn")

func _ready():
	add_to_group("boss")
	add_to_group("enemies")

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

	# 初始化 StateChart 表达式属性
	if state_chart:
		state_chart.set_expression_property("health", health)
		state_chart.set_expression_property("max_health", max_health)
		state_chart.set_expression_property("phase", phase)
		state_chart.set_expression_property("move_speed", move_speed)
		state_chart.set_expression_property("attack_interval", _get_attack_interval())

	# 延迟启动状态机
	_setup_state_chart.call_deferred()

func _setup_state_chart():
	if state_chart:
		state_chart.send_event.call_deferred("initialized")

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

func _get_attack_interval() -> float:
	match attack_type:
		"single": return 1.5
		"double": return 1.2
		"scatter": return 2.0
		"circle": return 2.5
		"multi": return 1.0
	return 1.5

# 攻击方法 - 由 AttackState 调用
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

# 受伤处理
func take_damage(amount):
	if is_invincible:
		return

	health -= amount
	print("[BOSS] 受到伤害！剩余血量：", health, "/", max_health)

	# 更新 StateChart 属性
	if state_chart:
		state_chart.set_expression_property("health", health)

	# 发射血量变化信号
	boss_health_changed.emit(health, max_health)

	# 发送受伤事件给状态机
	if state_chart:
		state_chart.send_event("take_damage")

	# 检查阶段变化（最终 BOSS）
	if has_phase_2 and health <= max_health / 2 and phase == 1:
		_phase_2_transform()

	if health <= 0:
		_die()

func _phase_2_transform():
	phase = 2
	print("[BOSS] 第二阶段变身！攻击加强！")

	# 发送 Phase2 事件给状态机
	if state_chart:
		state_chart.send_event("phase2_transform")
		state_chart.set_expression_property("phase", phase)

func _die():
	# 发送死亡事件给状态机
	if state_chart:
		state_chart.send_event("death")
	# 注意：DeathState 会处理实际的死亡逻辑和 queue_free()

func _on_area_entered(area):
	# 被子弹击中
	if area.is_in_group("bullets"):
		var bullet = area as Area2D
		if bullet and not bullet.is_enemy_bullet:
			take_damage(bullet.damage if bullet.has_method("get_damage") else 1)

	# 撞到玩家
	if area.is_in_group("player"):
		if area.has_method("take_damage"):
			area.take_damage(1)

func get_health_percent() -> float:
	return float(health) / float(max_health)
