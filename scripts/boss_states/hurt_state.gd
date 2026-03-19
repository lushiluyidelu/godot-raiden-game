extends "res://scripts/boss_states/boss_state.gd"

## Hurt 状态 - BOSS 受击无敌

func _on_enter():
	print("[BOSS State] >>> Hurt 状态 - 受击无敌 hp=", boss.health if boss else "?", "/", boss.max_health if boss else "?")
	if boss:
		boss.is_invincible = true
		var sprite = boss.get_node_or_null("Sprite")
		if sprite:
			sprite.modulate = Color(1, 1, 1, 0.5)

func _on_exit():
	print("[BOSS State] <<< Exit Hurt 状态")
	if boss:
		boss.is_invincible = false
		var sprite = boss.get_node_or_null("Sprite")
		if sprite:
			sprite.modulate = Color(1, 1, 1, 1)
