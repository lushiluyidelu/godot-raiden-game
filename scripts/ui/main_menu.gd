extends Control

## 主菜单界面

# 场景引用
var game_scene = preload("res://scenes/main.tscn")

# 节点引用
@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var start_button: TextureButton = $VBoxContainer/ButtonContainer/StartButton
@onready var quit_button: TextureButton = $VBoxContainer/ButtonContainer/QuitButton

# 星空背景
var stars = []
var bg_scroll_speed = 50.0

func _ready():
	# 初始化星空背景
	_init_stars()

	# 连接按钮信号
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	# 标题动画
	_animate_title()

func _init_stars():
	"""初始化星空背景"""
	var screen_size = Vector2(480, 720)
	for i in range(100):
		stars.append({
			"pos": Vector2(randf() * screen_size.x, randf() * screen_size.y),
			"speed": randf_range(20.0, 60.0),
			"size": randf_range(1.0, 2.5),
			"brightness": randf_range(0.5, 1.0)
		})

func _draw():
	"""绘制星空背景"""
	for star in stars:
		var color = Color(star.brightness, star.brightness, star.brightness + 0.2, 0.8)
		draw_circle(star.pos, star.size, color)

func _process(delta):
	"""更新星空动画"""
	var screen_size = Vector2(480, 720)
	for star in stars:
		star.pos.y += star.speed * delta
		if star.pos.y > screen_size.y:
			star.pos.y = 0
			star.pos.x = randf() * screen_size.x
	queue_redraw()

func _animate_title():
	"""标题呼吸动画"""
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(title_label, "modulate:v", 1.2, 1.0)
	tween.tween_property(title_label, "modulate:v", 1.0, 1.0)

func _on_start_pressed():
	"""开始游戏"""
	print("[MainMenu] 开始游戏")

	# 按钮点击效果
	_button_click_effect(start_button)

	# 切换到游戏场景
	await get_tree().create_timer(0.2).timeout
	get_tree().change_scene_to_packed(game_scene)

func _on_quit_pressed():
	"""退出游戏"""
	print("[MainMenu] 退出游戏")
	_button_click_effect(quit_button)
	await get_tree().create_timer(0.2).timeout
	get_tree().quit()

func _button_click_effect(button: TextureButton):
	"""按钮点击效果"""
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(0.9, 0.9), 0.1)
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.1)