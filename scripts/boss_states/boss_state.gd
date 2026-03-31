extends "res://addons/godot_state_charts/state_chart_state.gd"

## BOSS 状态机基类
## 所有 BOSS 状态都继承自这个类

var boss: Area2D = null

# 使用父类提供的 _chart 引用
func get_state_chart() -> StateChart:
	return _chart as StateChart

func _ready():
	# 重要：调用父类 _ready() 以初始化 _chart 变量
	super._ready()

	# 连接 process 信号用于调试
	if not Engine.is_editor_hint():
		set_process(true)

	# 向上查找 BOSS 节点
	var parent = get_parent()
	while parent:
		if parent.has_method("set_boss_config") or parent.has_method("_perform_attack"):
			boss = parent
			break
		parent = parent.get_parent()

	# 重要：手动刷新所有过渡的缓存，因为插件在某些情况下不会自动刷新
	# 这必须在 _ready 中完成，确保过渡的 _supported_trigger_types 正确设置
	for child in get_children():
		if child is Transition:
			if child.has_method("_refresh_caches"):
				child._refresh_caches()
				print("[BOSS State] 初始化刷新过渡缓存：", child.name, " _supported_trigger_types=", child._supported_trigger_types)

func get_boss() -> Area2D:
	return boss

## 重写 _process 方法用于调试延迟过渡
func _process(delta: float) -> void:
	print("[BOSS State] _process: ", name, " active=", active, " pending=", _pending_transition.name if _pending_transition else "null", " remaining=", _pending_transition_remaining_delay)
	if _pending_transition != null:
		if _pending_transition_remaining_delay <= 0:
			print("[BOSS State] _process: 过渡就绪！", name, " -> ", _pending_transition.to)
	super._process(delta)

## 重写状态进入方法 - 在信号之前调用
func _state_enter(transition_target: StateChartState) -> void:
	print("[BOSS State] _state_enter 开始：", name, " target=", transition_target.name if transition_target else "null")
	# 先调用父类方法，它会调用 _process_transitions(STATE_ENTER)
	super._state_enter(transition_target)
	print("[BOSS State] _state_enter 结束后：", name)
	_on_enter()
	# 连接 physics processing 信号（如果需要）
	if has_method("_on_state_physics_processing"):
		state_physics_processing.connect(_on_state_physics_processing)

## 重写状态退出方法
func _state_exit() -> void:
	print("[BOSS State] _state_exit: ", name)
	_on_exit()
	# 断开信号连接
	if has_method("_on_state_physics_processing"):
		state_physics_processing.disconnect(_on_state_physics_processing)
	super._state_exit()

## 重写 _process_transitions 用于调试
func _process_transitions(trigger_type: int, event:StringName = "") -> bool:
	print("[BOSS State] _process_transitions 开始：", name, " trigger_type=", trigger_type, " event=", event)
	print("[BOSS State]   过渡列表：", _transitions.size())
	for transition in _transitions:
		var is_triggered = transition.is_triggered_by(trigger_type)
		var guard_result = transition.evaluate_guard()
		var event_match = (event == "" or transition.event == event)
		# 检查过渡的_dirty 标志和_supported_trigger_types
		print("[BOSS State]   过渡：", transition.name, " event='", transition.event, "' is_triggered=", is_triggered, " guard=", guard_result, " event_match=", event_match)
		# 打印过渡的内部状态
		if transition.has_method("_refresh_caches"):
			transition._refresh_caches()
			print("[BOSS State]     刷新后：_supported_trigger_types=", transition._supported_trigger_types, " is_triggered_by(STATE_ENTER)=", transition.is_triggered_by(2))
	var result = super._process_transitions(trigger_type, event)
	print("[BOSS State] _process_transitions 结果：", name, " event=", event, " result=", result)
	return result

## 虚方法 - 子类可以重写
func _on_enter():
	pass

func _on_exit():
	pass

func _on_state_physics_processing(_delta: float):
	pass
