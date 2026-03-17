extends CharacterBody2D

const SPEED = 300.0
const BULLET_SCENE = preload("res://scenes/bullet.tscn")
const POWERUP_SCENE = preload("res://scenes/powerup.tscn")
const PowerUpType = preload("res://scripts/powerup.gd").PowerUpType

@onready var shoot_timer = $ShootTimer
@onready var sprite = $Sprite
@onready var engine_flame = $EngineFlame

var screen_size

# 武器系统
var weapon_level: int = 1
var weapon_xp: int = 0
var weapon_xp_to_next_level: int = 3

# 道具状态
var has_shield: bool = false
var missile_active: bool = false
var missile_timer: float = 0.0
var speed_boost_active: bool = false
var speed_boost_timer: float = 0.0
var bomb_count: int = 0

# 基础速度
var base_speed: float = SPEED

signal weapon_level_changed(new_level: int)
signal powerup_collected(type: String)

func _ready():
	screen_size = get_viewport_rect().size
	position = Vector2(screen_size.x / 2, screen_size.y - 100)

	add_to_group("player")

	print("[Player] 初始化完成，位置：", position, " 武器等级：", weapon_level)

func _physics_process(delta):
	# 处理道具计时器
	if missile_active:
		missile_timer -= delta
		if missile_timer <= 0:
			missile_active = false
			print("[Player] 追踪导弹效果结束")

	if speed_boost_active:
		speed_boost_timer -= delta
		if speed_boost_timer <= 0:
			speed_boost_active = false
			print("[Player] 速度提升效果结束")

	# 获取输入方向
	var direction = Vector2.ZERO

	if Input.is_action_pressed("move_up"):
		direction.y -= 1
	if Input.is_action_pressed("move_down"):
		direction.y += 1
	if Input.is_action_pressed("move_left"):
		direction.x -= 1
	if Input.is_action_pressed("move_right"):
		direction.x += 1

	# 移动飞机
	var current_speed = base_speed
	if speed_boost_active:
		current_speed = base_speed * 1.3

	velocity = direction * current_speed
	move_and_slide()

	# 保持飞机在屏幕范围内
	position.x = clamp(position.x, 32, screen_size.x - 32)
	position.y = clamp(position.y, 32, screen_size.y - 32)

func _input(event):
	if event.is_action_pressed("shoot"):
		shoot()
	if event.is_action_pressed("use_bomb"):
		use_bomb()

func shoot():
	if not shoot_timer.is_stopped():
		return

	# 根据武器等级发射不同子弹
	match weapon_level:
		1:
			_shoot_level_1()
		2:
			_shoot_level_2()
		3:
			_shoot_level_3()
		4:
			_shoot_level_4()

	# 播放射击音效
	var sound_manager = get_tree().root.get_node_or_null("Main/SoundManager")
	if sound_manager and sound_manager.has_method("play_shoot_sound"):
		sound_manager.play_shoot_sound()

	shoot_timer.start()

func _shoot_level_1():
	# 单发子弹
	var bullet = BULLET_SCENE.instantiate()
	bullet.position = position + Vector2(0, -35)
	get_parent().add_child(bullet)

func _shoot_level_2():
	# 双发子弹（左右各一）
	for dir in [-1, 1]:
		var bullet = BULLET_SCENE.instantiate()
		bullet.position = position + Vector2(dir * 10, -30)
		get_parent().add_child(bullet)

func _shoot_level_3():
	# 散射子弹（5 向扩散）
	for i in range(-2, 3):
		var bullet = BULLET_SCENE.instantiate()
		bullet.position = position + Vector2(0, -35)
		bullet.velocity = Vector2(i * 80, -500)
		get_parent().add_child(bullet)

func _shoot_level_4():
	# 超级散射（7 向 + 导弹）
	# 7 向散射
	for i in range(-3, 4):
		var bullet = BULLET_SCENE.instantiate()
		bullet.position = position + Vector2(0, -35)
		bullet.velocity = Vector2(i * 70, -450)
		get_parent().add_child(bullet)

	# 追踪导弹
	if missile_active:
		var missile = BULLET_SCENE.instantiate()
		missile.position = position + Vector2(0, -35)
		missile.velocity = Vector2(0, -600)
		missile.damage = 3
		get_parent().add_child(missile)

func use_bomb():
	if bomb_count <= 0:
		return

	bomb_count -= 1
	print("[Player] 使用炸弹！剩余：", bomb_count)

	# 全屏爆炸伤害
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy.has_method("take_damage"):
			enemy.take_damage(10)

	# 消除所有敌方子弹
	var bullets = get_tree().get_nodes_in_group("bullets")
	for bullet in bullets:
		if bullet.is_enemy_bullet:
			bullet.queue_free()

	# 播放爆炸音效
	var sound_manager = get_tree().root.get_node_or_null("Main/SoundManager")
	if sound_manager and sound_manager.has_method("play_explosion_sound"):
		sound_manager.play_explosion_sound()

# 收集道具
func collect_powerup(type):
	match type:
		PowerUpType.WEAPON_P:
			_collect_weapon_p()
		PowerUpType.MISSILE_M:
			_collect_missile()
		PowerUpType.SHIELD_S:
			_collect_shield()
		PowerUpType.HEART:
			_collect_heart()
		PowerUpType.BOMB_B:
			_collect_bomb()
		PowerUpType.SPEED_V:
			_collect_speed_boost()

	print("[Player] 收集道具：", _get_powerup_name(type))
	powerup_collected.emit(_get_powerup_name(type))

func _get_powerup_name(type) -> String:
	match type:
		PowerUpType.WEAPON_P: return "武器升级"
		PowerUpType.MISSILE_M: return "追踪导弹"
		PowerUpType.SHIELD_S: return "护盾"
		PowerUpType.HEART: return "生命"
		PowerUpType.BOMB_B: return "炸弹"
		PowerUpType.SPEED_V: return "速度提升"
	return "未知"

func _collect_weapon_p():
	# 武器升级
	if weapon_level < 4:
		weapon_xp += 1
		if weapon_xp >= weapon_xp_to_next_level:
			weapon_level += 1
			weapon_xp = 0
			weapon_xp_to_next_level = weapon_level * 3
			print("[Player] 武器升级！当前等级：", weapon_level)
			weapon_level_changed.emit(weapon_level)
		else:
			print("[Player] 武器经验 +1，进度：", weapon_xp, "/", weapon_xp_to_next_level)

func _collect_missile():
	# 追踪导弹（30 秒）
	missile_active = true
	missile_timer = 30.0
	print("[Player] 追踪导弹激活！持续时间：30 秒")

func _collect_shield():
	# 护盾（抵挡一次伤害）
	has_shield = true
	print("[Player] 护盾激活！可以抵挡一次伤害")

func _collect_heart():
	# +1 生命
	var main = get_tree().root.get_node_or_null("Main")
	if main and main.has_method("add_life"):
		main.add_life(1)
	print("[Player] 生命 +1")

func _collect_bomb():
	# 炸弹 +1
	bomb_count += 1
	print("[Player] 炸弹 +1，当前数量：", bomb_count)

func _collect_speed_boost():
	# 速度提升（20 秒）
	speed_boost_active = true
	speed_boost_timer = 20.0
	print("[Player] 速度提升激活！持续时间：20 秒")

# 玩家受伤
func take_damage(amount):
	if has_shield:
		has_shield = false
		print("[Player] 护盾抵挡伤害！")
		return

	# 调用 main.gd 的受伤处理
	var main = get_tree().root.get_node_or_null("Main")
	if main and main.has_method("player_hit"):
		main.player_hit()
