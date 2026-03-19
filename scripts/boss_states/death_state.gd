extends "res://scripts/boss_states/boss_state.gd"

## Death 状态 - BOSS 死亡

func _on_enter():
	print("[BOSS State] >>> Death 状态 - BOSS 死亡！获得分数=", boss.score_value if boss else 1000)
	if boss:
		# 播放爆炸音效
		var sound_manager = get_tree().root.get_node_or_null("Main/SoundManager")
		if sound_manager and sound_manager.has_method("play_explosion_sound"):
			sound_manager.play_explosion_sound()

		# 发射信号
		var score = boss.score_value if boss else 1000
		if boss.has_signal("boss_defeated"):
			boss.emit_signal("boss_defeated", score)

		boss.queue_free()
