extends GPUParticles2D

func _ready():
	# 播放爆炸音效
	var sound_manager = get_tree().root.get_node_or_null("Main/SoundManager")
	if sound_manager and sound_manager.has_method("play_explosion_sound"):
		sound_manager.play_explosion_sound()

	# 自动删除节点
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _on_finished():
	queue_free()
