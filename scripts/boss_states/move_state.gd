extends "res://scripts/boss_states/boss_state.gd"

## Move 状态 - BOSS 移动

var direction: int = 1
var move_timer: float = 0.0

func _on_enter():
	print("[BOSS State] >>> Move 状态 - 开始移动 pattern=", boss.attack_type if boss else "unknown")
	move_timer = 0.0

func _on_exit():
	print("[BOSS State] <<< Exit Move 状态")

func _on_state_physics_processing(delta):
	if not boss:
		return

	var attack_type = boss.attack_type if boss else "single"
	var speed = boss.move_speed if boss else 50.0

	match attack_type:
		"single":
			_move_pattern_single(delta, speed)
		"double":
			_move_pattern_double(delta)
		"scatter":
			_move_pattern_scatter(delta)
		"circle":
			_move_pattern_circle(delta)
		"multi":
			_move_pattern_multi(delta)

func _move_pattern_single(delta, speed):
	boss.position.x += speed * direction * delta
	if boss.position.x > 400 or boss.position.x < 80:
		direction *= -1

func _move_pattern_double(delta):
	var time = Time.get_ticks_msec() / 1000.0
	boss.position.x = 240 + sin(time * 2) * 150
	boss.position.y = 100 + cos(time * 4) * 30

func _move_pattern_scatter(delta):
	boss.position.y = 100 + sin(Time.get_ticks_msec() / 500.0) * 50

func _move_pattern_circle(delta):
	var time = Time.get_ticks_msec() / 1000.0
	boss.position.x = 240 + cos(time * 3) * 180
	boss.position.y = 150 + sin(time * 3) * 100

func _move_pattern_multi(delta):
	var time = Time.get_ticks_msec() / 1000.0
	boss.position.x = 240 + sin(time * 2.5) * 160 + cos(time * 1.5) * 40
	boss.position.y = 120 + cos(time * 2) * 60
