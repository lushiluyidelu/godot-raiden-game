extends "res://scripts/boss_states/boss_state.gd"

## Phase2 状态 - BOSS 第二阶段（强化）

func _on_enter():
	print("[BOSS State] >>> Phase2 状态 - 第二阶段变身！hp=", boss.health if boss else "?", "/", boss.max_health if boss else "?")
	if boss:
		boss.phase = 2
		# 加快攻击速度
		var chart = get_state_chart()
		if chart:
			chart.set_expression_property("attack_interval", 0.9)  # 原速度 * 0.6

func _on_exit():
	print("[BOSS State] <<< Exit Phase2 状态")
