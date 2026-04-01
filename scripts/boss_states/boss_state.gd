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

	# 向上查找 BOSS 节点
	var parent = get_parent()
	while parent:
		if parent.has_method("set_boss_config") or parent.has_method("_perform_attack"):
			boss = parent
			break
		parent = parent.get_parent()

## 重写 _state_init - 在状态初始化时刷新过渡缓存
## 这是关键！因为 _state_enter 在 _ready 之前被调用
func _state_init() -> void:
	# 调用父类方法，填充 _transitions 数组
	super._state_init()

	# 立即刷新所有过渡的缓存
	for child in get_children():
		if child is Transition:
			# 打印过渡的详细信息
			print("[BOSS State] 过渡详情: ", child.name)
			print("  - event='", child.event, "' (type=", typeof(child.event), ")")
			print("  - event.is_empty()=", child.event.is_empty() if child.event is String or child.event is StringName else "N/A")
			print("  - event.length()=", child.event.length() if child.event is String or child.event is StringName else "N/A")
			print("  - _dirty=", child._dirty)

			if child.has_method("_refresh_caches"):
				child._refresh_caches()
				print("  - 刷新后 _supported_trigger_types=", child._supported_trigger_types)
				print("  - 刷新后 _dirty=", child._dirty)
				print("  - is_triggered_by(STATE_ENTER)=", child.is_triggered_by(StateChart.TriggerType.STATE_ENTER))

func get_boss() -> Area2D:
	return boss

## 重写状态进入方法
func _state_enter(transition_target: StateChartState) -> void:
	print("[BOSS State] _state_enter：", name)
	super._state_enter(transition_target)
	_on_enter()
	# 连接 physics processing 信号（如果需要）
	if has_method("_on_state_physics_processing"):
		state_physics_processing.connect(_on_state_physics_processing)

## 重写 _process_transitions 添加详细调试
func _process_transitions(trigger_type: int, event: StringName = "") -> bool:
	print("[BOSS State] _process_transitions: ", name, " trigger_type=", trigger_type, " event='", event, "'")
	print("[BOSS State]   active=", active, " _transitions.size()=", _transitions.size())

	if not active:
		print("[BOSS State]   返回 false: 状态未激活")
		return false

	for transition in _transitions:
		var is_triggered = transition.is_triggered_by(trigger_type)
		var event_match = (event == "" or transition.event == event)
		var guard_ok = transition.evaluate_guard()
		print("[BOSS State]   过渡 '", transition.name, "': is_triggered=", is_triggered, " event_match=", event_match, " guard=", guard_ok)

		if is_triggered and event_match and guard_ok:
			print("[BOSS State]   匹配成功！准备执行过渡: ", transition.name)
			if transition != _pending_transition:
				# 检查延迟
				var delay = transition.evaluate_delay()
				print("[BOSS State]   延迟=", delay, " 秒")
				if delay > 0:
					print("[BOSS State]   过渡将被延迟 ", delay, " 秒后执行")

	var result = super._process_transitions(trigger_type, event)
	print("[BOSS State]   super 返回: ", result)
	return result

## 重写状态退出方法
func _state_exit() -> void:
	print("[BOSS State] _state_exit: ", name)
	_on_exit()
	# 断开信号连接
	if has_method("_on_state_physics_processing"):
		state_physics_processing.disconnect(_on_state_physics_processing)
	super._state_exit()

## 虚方法 - 子类可以重写
func _on_enter():
	pass

func _on_exit():
	pass

func _on_state_physics_processing(_delta: float):
	pass
