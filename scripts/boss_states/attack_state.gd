extends "res://scripts/boss_states/boss_state.gd"

## Attack 状态 - BOSS 攻击

var bullet_scene = preload("res://scenes/bullet.tscn")

func _on_enter():
	print("[BOSS State] >>> Attack 状态 - 发动攻击 pattern=", boss.attack_type if boss else "unknown")
	if boss:
		boss._perform_attack()

func _on_exit():
	print("[BOSS State] <<< Exit Attack 状态")
