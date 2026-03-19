extends "res://scripts/boss_states/boss_state.gd"

## Enter 状态 - BOSS 入场动画

func _on_enter():
	print("[BOSS State] >>> Enter 状态 - BOSS 入场")
	if boss:
		boss._create_boss_sprite()

func _on_exit():
	print("[BOSS State] <<< Exit Enter 状态")
