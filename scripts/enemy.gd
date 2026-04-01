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

# 精灵资源映射
const ENEMY_SPRITES = {
	"normal": "res://assets/sprites/kenney_space-shooter-redux/PNG/Enemies/enemyRed1.png",
	"fast": "res://assets/sprites/kenney_space-shooter-redux/PNG/Enemies/enemyBlue1.png",
	"heavy": "res://assets/sprites/kenney_space-shooter-redux/PNG/Enemies/enemyBlack3.png",
	"shooter": "res://assets/sprites/kenney_space-shooter-redux/PNG/Enemies/enemyGreen2.png",
	"kamikaze": "res://assets/sprites/kenney_space-shooter-redux/PNG/Enemies/enemyRed5.png"
}

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

	_create_sprite()

func _ready():
	add_to_group("enemies")
	direction = 1 if randf() > 0.5 else -1

	# 手动连接信号
	connect("area_entered", _on_area_entered)
	connect("body_entered", _on_body_entered)

	print("[Enemy] 初始化完成，类型：", enemy_type)

func _create_sprite():
	var sprite = get_node_or_null("Sprite")
	if not sprite:
		return

	# 使用 kenney 精灵资源
	var sprite_path = ENEMY_SPRITES.get(enemy_type, ENEMY_SPRITES["normal"])
	var texture = load(sprite_path)
	if texture:
		sprite.texture = texture
		sprite.scale = Vector2(0.8, 0.8)  # 适当缩放
	else:
		push_warning("[Enemy] 无法加载精灵: " + sprite_path)

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
