extends ColorRect

## 暂停界面脚本

func _ready():
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED

func _unhandled_input(event):
	if not visible:
		return

	if event.is_action_pressed("ui_cancel"):
		# ESC 继续游戏
		var main = get_node_or_null("../../..")
		if main and main.has_method("toggle_pause"):
			main.toggle_pause()
		get_viewport().set_input_as_handled()

	if event is InputEventKey and event.pressed and event.keycode == KEY_Q:
		# Q 返回主菜单
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
		get_viewport().set_input_as_handled()