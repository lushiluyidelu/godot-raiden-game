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

## 重写状态进入方法 - 在信号之前调用
func _state_enter(transition_target: StateChartState) -> void:
	super._state_enter(transition_target)
	_on_enter()
	# 连接 physics processing 信号（如果需要）
	if has_method("_on_state_physics_processing"):
		state_physics_processing.connect(_on_state_physics_processing)

## 重写状态退出方法
func _state_exit() -> void:
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
