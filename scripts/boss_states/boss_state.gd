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

func get_boss() -> Area2D:
	return boss

## 重写 _process 方法用于调试延迟过渡
func _process(delta: float) -> void:
	if _pending_transition != null:
		print("[BOSS State] _process: ", name, " pending=", _pending_transition.name, " remaining=", _pending_transition_remaining_delay)
		if _pending_transition_remaining_delay <= 0:
			print("[BOSS State] _process: 过渡就绪！", name, " -> ", _pending_transition.to)
	super._process(delta)

## 重写状态进入方法 - 在信号之前调用
func _state_enter(transition_target: StateChartState) -> void:
	print("[BOSS State] _state_enter: ", name, " target=", transition_target.name if transition_target else "null")
	super._state_enter(transition_target)
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
