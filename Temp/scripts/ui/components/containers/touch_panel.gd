## =============================================================================
## TouchPanel 类
## 触摸面板组件
## 
## 功能说明：
##   1. 接收和处理触摸输入事件
##   2. 作为TouchScreenContainer的子节点，用于捕获触摸和鼠标事件
##   3. 传递输入事件给父容器进行处理
## =============================================================================
extends Control
class_name TouchPanel

## 初始化函数
func _ready() -> void:
	# 设置鼠标过滤模式，确保能接收鼠标事件
	set_mouse_filter(MOUSE_FILTER_STOP)
	# 设置捕获输入，确保能接收所有触摸事件
	set_process_input(true)

## 输入事件处理
func _input(event: InputEvent) -> void:
	# 直接传递事件给gui_input信号
	# 这个方法会自动将事件传递给通过connect("gui_input")连接的处理函数
	pass

## 设置面板大小
func set_panel_size(size: Vector2) -> void:
	self.size = size

## 启用/禁用触摸捕获
func set_touch_enabled(enabled: bool) -> void:
	set_process_input(enabled)
	set_mouse_filter(enabled ? MOUSE_FILTER_STOP : MOUSE_FILTER_IGNORE)
