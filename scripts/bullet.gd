extends Area2D

const SPEED = 600.0

@onready var sprite = $Sprite
@onready var collision = $CollisionShape2D

# 子弹类型
var is_enemy_bullet: bool = false
var damage: int = 1
var velocity: Vector2 = Vector2.ZERO  # 可用于非垂直方向的子弹

func _ready():
	add_to_group("bullets")

	# 根据子弹类型创建不同纹理
	if is_enemy_bullet:
		_create_enemy_bullet_texture()
	else:
		_create_player_bullet_texture()

	# 手动连接信号
	connect("area_entered", _on_area_entered)

func set_is_enemy_bullet(is_enemy: bool):
	is_enemy_bullet = is_enemy

func _create_player_bullet_texture():
	var img = Image.create(16, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	# 画子弹主体（黄色到橙色渐变）
	for y in range(0, 32):
		var t = float(y) / 32
		var width = int(lerp(2, 6, 1 - t))
		var color = Color(1, 1, 0, 1).lerp(Color(1, 0.5, 0, 1), t)

		for x in range(8 - width, 8 + width):
			if x >= 0 and x < 16:
				img.set_pixel(x, y, color)

	# 画子弹核心（亮白色）
	for y in range(4, 28):
		for x in range(6, 10):
			if x >= 0 and x < 16:
				img.set_pixel(x, y, Color(1, 1, 0.8, 1))

	var texture = ImageTexture.create_from_image(img)
	sprite.texture = texture

func _create_enemy_bullet_texture():
	var img = Image.create(12, 12, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	# 红色圆形子弹
	var center = Vector2(6, 6)
	var radius = 5
	for y in range(12):
		for x in range(12):
			var dist = Vector2(x, y).distance_to(center)
			if dist <= radius:
				var t = dist / radius
				var color = Color(1, 0.3, 0.3, 1).lerp(Color(1, 0.8, 0.8, 0.5), t)
				img.set_pixel(x, y, color)

	var texture = ImageTexture.create_from_image(img)
	sprite.texture = texture

func _process(delta):
	if is_enemy_bullet:
		# 敌人子弹使用 velocity
		if velocity != Vector2.ZERO:
			position += velocity * delta
		else:
			position.y += SPEED * delta
	else:
		# 玩家子弹向上飞行
		position.y -= SPEED * delta

	# 超出屏幕后删除子弹
	if position.y < -50 or position.y > 800:
		queue_free()

func _on_area_entered(area):
	if is_enemy_bullet:
		# 敌人子弹击中玩家
		if area.is_in_group("player"):
			if area.has_method("take_damage"):
				area.take_damage(1)
			queue_free()
	else:
		# 玩家子弹击中敌人
		if area.is_in_group("enemies"):
			if area.has_method("take_damage"):
				area.take_damage(damage)
			queue_free()
