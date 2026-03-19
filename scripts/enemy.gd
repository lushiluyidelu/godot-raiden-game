extends Area2D

# 敌人类型（字符串）
var enemy_type: String = "normal"
var direction = 1
var health = 1
var max_health = 1
var score_value = 100
var move_speed = 60.0
var enemy_color = Color.RED

# 射击怪专用
var can_shoot = false
var shoot_timer: Timer
var bullet_scene = preload("res://scenes/bullet.tscn")

# 自爆怪专用
var is_kamikaze = false

signal enemy_defeated(score_val: int)
signal enemy_destroyed(position: Vector2, score_val: int)
signal player_hit

# 初始化敌人类型（支持字符串）
func set_enemy_type(type_name: String, type_config: Dictionary):
	if type_config.is_empty():
		return

	enemy_type = type_name
	move_speed = type_config.get("speed", 60)
	health = type_config.get("health", 1)
	max_health = health
	score_value = type_config.get("score", 100)
	enemy_color = type_config.get("color", Color.RED)

	# 特殊类型设置
	if type_name == "shooter":
		can_shoot = true
		_setup_shoot_timer()
	elif type_name == "kamikaze":
		is_kamikaze = true

	_create_sprite(enemy_color, _get_size_for_type(type_name))

func _ready():
	add_to_group("enemies")
	direction = 1 if randf() > 0.5 else -1

	# 手动连接信号
	connect("area_entered", _on_area_entered)
	connect("body_entered", _on_body_entered)

	print("[Enemy] 初始化完成，类型：", enemy_type)

func _get_size_for_type(type_name: String) -> float:
	match type_name:
		"normal": return 48
		"fast": return 40
		"heavy": return 56
		"shooter": return 50
		"kamikaze": return 36
	return 48

func _create_sprite(color: Color, size: float):
	var sprite = get_node_or_null("Sprite")
	if not sprite:
		return

	var img = Image.create(int(size), int(size), false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))  # 透明背景

	var half = size / 2

	# 根据敌人类型绘制不同形状
	match enemy_type:
		"normal":
			_draw_triangle(img, color, size)
		"fast":
			_draw_thin_triangle(img, color, size)
		"heavy":
			_draw_heavy_triangle(img, color, size)
		"shooter":
			_draw_shooter_sprite(img, color, size)
		"kamikaze":
			_draw_kamikaze_sprite(img, color, size)

	var texture = ImageTexture.create_from_image(img)
	sprite.texture = texture

func _draw_triangle(img: Image, base_color: Color, size: float):
	var half = size / 2
	for y in range(int(size * 0.15), int(size * 0.8)):
		var t = float(y - int(size * 0.15)) / (int(size * 0.65))
		var width = int(lerp(size * 0.15, size * 0.45, t))
		var c = base_color.lerp(_color_dark(base_color, 0.4), t)
		for x in range(int(half - width), int(half + width)):
			if x >= 0 and x < size:
				img.set_pixel(x, y, c)
	# 机翼
	for y in range(int(size * 0.4), int(size * 0.7)):
		for x in range(int(half - size * 0.45 - size * 0.1), int(half - size * 0.45)):
			if x >= 0 and x < size:
				img.set_pixel(x, y, _color_dark(base_color, 0.2))
		for x in range(int(half + size * 0.45), int(half + size * 0.45 + size * 0.1)):
			if x >= 0 and x < size:
				img.set_pixel(x, y, _color_dark(base_color, 0.2))

func _draw_thin_triangle(img: Image, base_color: Color, size: float):
	var half = size / 2
	for y in range(int(size * 0.1), int(size * 0.85)):
		var t = float(y - int(size * 0.1)) / (int(size * 0.75))
		var width = int(lerp(size * 0.08, size * 0.35, t))
		var c = base_color.lerp(_color_dark(base_color, 0.3), t)
		for x in range(int(half - width), int(half + width)):
			if x >= 0 and x < size:
				img.set_pixel(x, y, c)
	# 细长机翼
	for y in range(int(size * 0.3), int(size * 0.6)):
		for x in range(int(half - size * 0.35 - size * 0.15), int(half - size * 0.35)):
			if x >= 0 and x < size:
				img.set_pixel(x, y, _color_dark(base_color, 0.2))
		for x in range(int(half + size * 0.35), int(half + size * 0.35 + size * 0.15)):
			if x >= 0 and x < size:
				img.set_pixel(x, y, _color_dark(base_color, 0.2))

func _draw_heavy_triangle(img: Image, base_color: Color, size: float):
	var half = size / 2
	# 主体三角形
	for y in range(int(size * 0.1), int(size * 0.85)):
		var t = float(y - int(size * 0.1)) / (int(size * 0.75))
		var width = int(lerp(size * 0.2, size * 0.5, t))
		var c = base_color.lerp(_color_dark(base_color, 0.4), t)
		for x in range(int(half - width), int(half + width)):
			if x >= 0 and x < size:
				img.set_pixel(x, y, c)
	# 厚重机翼
	for y in range(int(size * 0.35), int(size * 0.75)):
		for x in range(int(half - size * 0.5 - size * 0.15), int(half - size * 0.5)):
			if x >= 0 and x < size:
				img.set_pixel(x, y, _color_dark(base_color, 0.2))
		for x in range(int(half + size * 0.5), int(half + size * 0.5 + size * 0.15)):
			if x >= 0 and x < size:
				img.set_pixel(x, y, _color_dark(base_color, 0.2))
	# 驾驶舱（亮色）
	for y in range(int(size * 0.25), int(size * 0.45)):
		for x in range(int(half - size * 0.1), int(half + size * 0.1)):
			if x >= 0 and x < size:
				img.set_pixel(x, y, _color_light(base_color, 0.3))

func _draw_shooter_sprite(img: Image, base_color: Color, size: float):
	var half = size / 2
	# 主体 - 带炮管的形状
	for y in range(int(size * 0.2), int(size * 0.8)):
		var t = float(y - int(size * 0.2)) / (int(size * 0.6))
		var width = int(lerp(size * 0.25, size * 0.45, t))
		var c = base_color.lerp(_color_dark(base_color, 0.3), t)
		for x in range(int(half - width), int(half + width)):
			if x >= 0 and x < size:
				img.set_pixel(x, y, c)
	# 炮管（深绿色）
	for y in range(int(size * 0.1), int(size * 0.5)):
		for x in range(int(half - size * 0.08), int(half + size * 0.08)):
			if x >= 0 and x < size:
				img.set_pixel(x, y, _color_dark(base_color, 0.5))
	# 机翼
	for y in range(int(size * 0.4), int(size * 0.7)):
		for x in range(int(half - size * 0.45 - size * 0.12), int(half - size * 0.45)):
			if x >= 0 and x < size:
				img.set_pixel(x, y, _color_dark(base_color, 0.2))
		for x in range(int(half + size * 0.45), int(half + size * 0.45 + size * 0.12)):
			if x >= 0 and x < size:
				img.set_pixel(x, y, _color_dark(base_color, 0.2))

func _draw_kamikaze_sprite(img: Image, base_color: Color, size: float):
	var half = size / 2
	# 小型尖刺形状
	for y in range(int(size * 0.15), int(size * 0.85)):
		var t = float(y - int(size * 0.15)) / (int(size * 0.7))
		var width = int(lerp(size * 0.1, size * 0.35, 1 - t * 0.5))
		var c = base_color.lerp(_color_dark(base_color, 0.3), t)
		for x in range(int(half - width), int(half + width)):
			if x >= 0 and x < size:
				img.set_pixel(x, y, c)
	# 尖刺机翼
	for y in range(int(size * 0.3), int(size * 0.6)):
		for x in range(int(half - size * 0.35 - size * 0.15), int(half - size * 0.35 + size * 0.1)):
			if x >= 0 and x < size:
				img.set_pixel(x, y, _color_dark(base_color, 0.3))
		for x in range(int(half + size * 0.35 - size * 0.1), int(half + size * 0.35 + size * 0.15)):
			if x >= 0 and x < size:
				img.set_pixel(x, y, _color_dark(base_color, 0.3))
	# 红色核心
	for y in range(int(size * 0.35), int(size * 0.55)):
		for x in range(int(half - size * 0.12), int(half + size * 0.12)):
			if x >= 0 and x < size:
				img.set_pixel(x, y, Color(1, 0.3, 0.3, 1))

func _setup_shoot_timer():
	shoot_timer = Timer.new()
	shoot_timer.wait_time = 2.0
	shoot_timer.autostart = true
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)
	add_child(shoot_timer)

func _on_shoot_timer_timeout():
	if not can_shoot or not is_instance_valid(self):
		return

	# 发射子弹
	var bullet = bullet_scene.instantiate()
	if bullet:
		bullet.position = position + Vector2(0, 30)
		bullet.velocity = Vector2(0, 200)  # 向下飞行
		bullet.set_is_enemy_bullet(true)
		get_parent().add_child(bullet)

func _color_dark(c: Color, amount: float) -> Color:
	return c.lerp(Color(0, 0, 0, 1), amount)

func _color_light(c: Color, amount: float) -> Color:
	return c.lerp(Color(1, 1, 1, 1), amount)

func _process(delta):
	if is_kamikaze:
		# 自爆怪直接冲向玩家
		_move_towards_player(delta)
	else:
		# 普通敌人水平移动 + 向下移动
		position.x += move_speed * direction * delta
		position.y += move_speed * 0.3 * delta  # 向下移动

		if position.x > 450:
			direction = -1
		elif position.x < 30:
			direction = 1

func _move_towards_player(delta):
	# 获取玩家位置
	var player = get_tree().get_first_node_in_group("player")
	if player and is_instance_valid(player):
		var direction_to_player = (player.position - position).normalized()
		position += direction_to_player * move_speed * delta

func take_damage(amount):
	health -= amount
	if health <= 0:
		# 播放爆炸音效
		var sound_manager = get_tree().root.get_node_or_null("Main/SoundManager")
		if sound_manager and sound_manager.has_method("play_explosion_sound"):
			sound_manager.play_explosion_sound()

		# 发射信号
		emit_signal("enemy_destroyed", position, score_value)
		emit_signal("enemy_defeated", score_value)
		queue_free()
	else:
		# 受伤闪烁效果
		var sprite = get_node_or_null("Sprite")
		if sprite:
			sprite.modulate = Color(1, 1, 1, 0.5)
			await get_tree().create_timer(0.1).timeout
			sprite.modulate = Color(1, 1, 1, 1)

func _on_area_entered(area):
	# 被子弹击中
	if area.is_in_group("bullets"):
		take_damage(1)

func _on_body_entered(body):
	# 撞到玩家
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(1)
		queue_free()
