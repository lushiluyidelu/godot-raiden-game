extends Area2D

# 道具类型
enum PowerUpType {
	WEAPON_P,      # 红色 P 字 - 武器升级
	MISSILE_M,     # 绿色 M 字 - 追踪导弹
	SHIELD_S,      # 蓝色 S 字 - 护盾
	HEART,         # 粉色心形 - +1 生命
	BOMB_B,        # 黄色 B 字 - 全屏炸弹
	SPEED_V        # 紫色 V 字 - 速度提升
}

var powerup_type: PowerUpType = PowerUpType.WEAPON_P
var move_speed: float = 80.0
var effect_duration: float = 0.0  # 0 表示永久

signal powerup_collected(type: PowerUpType)

func _ready():
	add_to_group("powerups")

	# 创建道具纹理
	_create_powerup_texture()

	# 连接信号
	connect("body_entered", _on_body_entered)

	print("[PowerUp] 生成！类型：", _get_type_name())

func _get_type_name() -> String:
	match powerup_type:
		PowerUpType.WEAPON_P: return "武器升级"
		PowerUpType.MISSILE_M: return "追踪导弹"
		PowerUpType.SHIELD_S: return "护盾"
		PowerUpType.HEART: return "生命"
		PowerUpType.BOMB_B: return "炸弹"
		PowerUpType.SPEED_V: return "速度提升"
	return "未知"

func set_powerup_type(type: PowerUpType):
	powerup_type = type
	_create_powerup_texture()

func _create_powerup_texture():
	var sprite = get_node_or_null("Sprite")
	if not sprite:
		return

	var size = 32
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var center = Vector2(size / 2, size / 2)
	var color = _get_color_for_type()

	match powerup_type:
		PowerUpType.WEAPON_P:
			_draw_letter_P(img, color, size)
		PowerUpType.MISSILE_M:
			_draw_letter_M(img, color, size)
		PowerUpType.SHIELD_S:
			_draw_letter_S(img, color, size)
		PowerUpType.HEART:
			_draw_heart(img, color, size)
		PowerUpType.BOMB_B:
			_draw_letter_B(img, color, size)
		PowerUpType.SPEED_V:
			_draw_letter_V(img, color, size)

	var texture = ImageTexture.create_from_image(img)
	sprite.texture = texture

func _get_color_for_type() -> Color:
	match powerup_type:
		PowerUpType.WEAPON_P: return Color(1, 0.2, 0.2, 1)  # 红色
		PowerUpType.MISSILE_M: return Color(0.2, 1, 0.2, 1)  # 绿色
		PowerUpType.SHIELD_S: return Color(0.2, 0.6, 1, 1)   # 蓝色
		PowerUpType.HEART: return Color(1, 0.4, 0.8, 1)      # 粉色
		PowerUpType.BOMB_B: return Color(1, 1, 0.2, 1)       # 黄色
		PowerUpType.SPEED_V: return Color(0.8, 0.2, 1, 1)    # 紫色
	return Color(1, 1, 1, 1)

func _draw_letter_P(img: Image, color: Color, size: int):
	var center = size / 2
	# 圆形部分
	for y in range(4, 18):
		for x in range(8, 24):
			var dist = Vector2(x, y).distance_to(Vector2(16, 12))
			if dist <= 8 and x >= 12:
				if x <= 18 or y <= 12:
					img.set_pixel(x, y, color)
	# 竖线
	for y in range(4, 28):
		for x in range(10, 14):
			img.set_pixel(x, y, color)

func _draw_letter_M(img: Image, color: Color, size: int):
	var center = size / 2
	# M 形状
	for y in range(6, 26):
		var t = float(y - 6) / 20
		var left_x = int(lerp(8, 14, t))
		var right_x = int(lerp(24, 18, t))
		for x in range(left_x, left_x + 3):
			if x < size:
				img.set_pixel(x, y, color)
		for x in range(right_x - 2, right_x + 1):
			if x >= 0:
				img.set_pixel(x, y, color)
	# 中间 V
	for y in range(12, 20):
		var t = float(y - 12) / 8
		var mid_x = int(lerp(16, 14, t))
		img.set_pixel(mid_x, y, color)
		img.set_pixel(32 - mid_x, y, color)

func _draw_letter_S(img: Image, color: Color, size: int):
	# S 形状
	for x in range(10, 22):
		img.set_pixel(x, 8, color)
		img.set_pixel(x, 24, color)
	for y in range(8, 16):
		img.set_pixel(10, y, color)
	for y in range(16, 24):
		img.set_pixel(22, y, color)
	for x in range(10, 22):
		img.set_pixel(x, 16, color)

func _draw_heart(img: Image, color: Color, size: int):
	var center = Vector2(size / 2, size / 2 + 2)
	for y in range(6, 28):
		for x in range(6, 26):
			var pos = Vector2(x, y)
			# 心形公式
			var dx = (x - 16) / 8.0
			var dy = (y - 14) / 8.0
			var heart = pow(dx * dx + dy * dy - 1, 3) - dx * dx * dy * dy * dy
			if heart <= 0:
				img.set_pixel(x, y, color)

func _draw_letter_B(img: Image, color: Color, size: int):
	# 竖线
	for y in range(6, 26):
		for x in range(10, 14):
			img.set_pixel(x, y, color)
	# 上半圆
	for y in range(6, 16):
		for x in range(14, 22):
			var dist = Vector2(x, y).distance_to(Vector2(14, 11))
			if dist <= 7:
				img.set_pixel(x, y, color)
	# 下半圆
	for y in range(16, 26):
		for x in range(14, 24):
			var dist = Vector2(x, y).distance_to(Vector2(14, 21))
			if dist <= 8:
				img.set_pixel(x, y, color)

func _draw_letter_V(img: Image, color: Color, size: int):
	# V 形状
	for y in range(6, 24):
		var t = float(y - 6) / 18
		var offset = int(lerp(0, 6, t))
		img.set_pixel(10 + offset, y, color)
		img.set_pixel(11 + offset, y, color)
		img.set_pixel(22 - offset, y, color)
		img.set_pixel(23 - offset, y, color)

func _process(delta):
	position.y += move_speed * delta

	# 超出屏幕后删除
	if position.y > 750:
		queue_free()

func _on_body_entered(body):
	if body.is_in_group("player"):
		if body.has_method("collect_powerup"):
			body.collect_powerup(powerup_type)
		emit_signal("powerup_collected", powerup_type)
		queue_free()
