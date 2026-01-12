# 窗口基类 - BaseWindow
# 厨房管理系统中所有窗口的基类，提供统一的窗口功能和行为规范
# 与WindowManager协同工作，实现完整的窗口系统
#
# @class BaseWindow
# @extends Control
# @description 提供窗口的基本功能实现，包括窗口状态管理、事件处理和UI操作
# @version v.0.0.1
#
# ## 设计理念
# - **统一接口**：为所有窗口提供一致的接口和行为
# - **状态管理**：内置窗口状态（正常、最小化、最大化）的管理
# - **事件驱动**：通过信号系统通知窗口状态变化
# - **可扩展性**：设计为易于继承和扩展，支持自定义窗口行为
# - **与WindowManager协同**：与WindowManager配合使用，实现完整的窗口管理系统

class_name BaseWindow
extends Control

## 信号定义 - 窗口状态通知
# 用于通知外部窗口状态变化的信号
signal window_closed()        # 窗口关闭时触发
signal window_minimized()     # 窗口最小化时触发
signal window_maximized()     # 窗口最大化时触发
signal window_restored()      # 窗口恢复普通大小时触发
signal window_moved()         # 窗口移动时触发
signal window_resized()       # 窗口调整大小时触发
signal window_opened()        # 窗口打开时触发

## 公有属性 - 窗口配置
# 窗口的基本配置属性
@export var window_title: String = "窗口"  # 窗口标题
@export var can_minimize: bool = true      # 是否允许最小化
@export var can_maximize: bool = true      # 是否允许最大化
@export var can_resize: bool = true        # 是否允许调整大小
@export var window_layer: String = "normal"  # 窗口所在层级，默认使用normal层级（对应MiddleWindowLayer）

## 私有属性 - 功能节点引用
# 窗口UI组件的引用
@onready var WindowContent: Control = $WindowContent
@onready var MainContent: Control = $WindowContent/VBoxContainer/MainContent

## 私有属性 - 窗口状态
# 窗口内部状态变量
var _is_minimized: bool = false  # 窗口是否处于最小化状态
var _is_maximized: bool = false  # 窗口是否处于最大化状态
var _is_opened: bool = false     # 窗口是否已经打开
var _normal_rect: Rect2 = Rect2()  # 窗口普通状态的位置和大小

## 生命周期方法
# Godot节点生命周期相关方法

# 节点进入场景树时的初始化函数
# Godot节点生命周期方法，窗口创建时自动调用
# @description 初始化窗口组件和状态，设置基本属性
# @private
func _ready() -> void:
	# 初始化窗口UI组件和状态
	init_window()
	# 打开窗口
	open()
	pass

# 每帧更新函数
# Godot节点生命周期方法，每帧自动调用
# @param delta 帧间隔时间（秒）
# @description 处理窗口状态更新、拖拽逻辑和输入事件
# @private
func _process(delta: float) -> void:
	# 处理窗口状态更新
	# 处理拖拽逻辑
	# 处理输入事件
	pass

## 初始化相关方法
# 窗口初始化和配置相关的方法

# 初始化窗口UI组件
# 配置窗口的初始UI状态和组件位置
# @description 设置窗口名称和初始UI布局
# @private
func init_window() -> void:
	set_name("[ %s ] %s" % [get_script().get_global_name(), get_instance_id()])
	# 调整关闭触摸面板的位置
	resize_window()
	move_close_touch_panel()
	# 更新窗口的渲染顺序
	update_z_index()

# 初始化窗口设置
# 供继承BaseWindow的类自行实现，用于窗口打开前的属性初始化
# @param settings 包含初始化设置的字典，具体内容由继承类定义
# @description 在窗口打开前执行自定义初始化逻辑
# @public
func init_window_settings(settings: Dictionary = {}) -> void:
	# 基类中实现为空，交给继承类自行实现
	# 子类可以重写此方法来处理特定的初始化设置
	pass

## 布局和渲染方法
# 处理窗口布局和渲染相关的方法

# 根据窗口大小调整关闭触摸面板的位置
# 将CloseTouchPanel定位到窗口中央
# @description 计算并设置关闭触摸面板的居中位置
# @private
func move_close_touch_panel() -> void:
	# 计算关闭触摸面板的居中位置
	var center_position = Vector2(
		size.x/2 - $CloseTouchPanel.size.x/2,
		size.y/2 - $CloseTouchPanel.size.y/2
	)
	# 设置关闭触摸面板的位置
	$CloseTouchPanel.set_position(center_position)

# 调整窗口大小
# 将窗口大小设置为WindowContent的大小
# @description 根据内容容器调整窗口大小
# @private
func resize_window() -> void:
	set_size(WindowContent.size)

# 更新窗口的渲染顺序
# 根据窗口状态和层级调整Z-index，确保正确的显示顺序
# @description 实现窗口渲染顺序的更新逻辑
# @private
func update_z_index() -> void:
	# 实现窗口渲染顺序的更新逻辑
	# 可以根据窗口层级和活动状态调整Z-index
	pass

## 窗口属性设置方法
# 设置和获取窗口属性的方法

# 设置窗口标题
# 更新窗口的标题文本
# @param title 新的窗口标题文本
# @description 更新窗口标题属性和UI显示
# @public
func set_title(title: String) -> void:
	# 更新窗口标题属性
	self.window_title = title
	# 可以在这里添加更新UI显示的逻辑
	pass

## 窗口状态控制方法
# 控制窗口打开、关闭、最小化、最大化等状态的方法

# 打开窗口
# @description 初始化窗口状态，设置可见性并通知窗口管理器
# @public
func open() -> void:
	# 如果窗口已经打开，不需要再次打开
	if _is_opened:
		return
	
	# 保存当前窗口的初始状态
	if _normal_rect == Rect2():
		_normal_rect = Rect2(global_position, size)
	
	# 设置窗口打开状态
	_is_opened = true
	on_opened()
	
	# 发送窗口打开信号
	emit_signal("window_opened")
	
	# 直接使用WindowManager单例通知窗口已打开
	if Engine.get_singleton("WindowManager"):
		WindowManager.on_window_opened(self)
	
	# 发送窗口移动和调整大小信号（确保初始状态已通知）
	emit_signal("window_moved")
	emit_signal("window_resized")

# 窗口打开后的回调
# @description 设置窗口可见性并连接信号
# @private
func on_opened() -> void:
	visible = true
	connect_all_private_signals()
	connect_all_signals()

# 关闭窗口
# @description 发送关闭信号，清理资源并通知窗口管理器
# @public
func close() -> void:
	# 发送关闭信号
	emit_signal("window_closed")
	
	# 设置窗口关闭状态
	_is_opened = false
	on_closed()
	
	# 直接使用WindowManager单例通知窗口已关闭
	WindowManager.close_window(self)

# 窗口关闭后的回调
# @description 设置窗口不可见并断开所有信号连接
# @private
func on_closed() -> void:
	visible = false
	disconnect_all_signals()

## 信号管理方法
# 处理窗口信号连接和断开的方法

# 连接所有公共信号（保留方法，供子类重写）
# @description 连接窗口公共信号的模板方法
# @private
func connect_all_signals() -> void:
	pass

# 连接所有私有信号（保留方法，供子类重写）
# @description 连接窗口内部使用的私有信号的模板方法
# @private
func connect_all_private_signals() -> void:
	pass

# 断开所有信号连接
# @description 清理窗口所有的信号连接，避免内存泄漏
# @private
func disconnect_all_signals() -> void:
	for _signal in get_signal_list():
		for signal_connection in get_signal_connection_list(_signal.name):
			disconnect(_signal.name, signal_connection.callable)

## 窗口状态控制方法（续）
# 窗口最小化、最大化和恢复相关的方法

# 最小化窗口
# @description 将窗口状态设置为最小化，保存当前状态
# @public
func minimize() -> void:
	# 如果已经处于最小化状态，不需要再次最小化
	if _is_minimized:
		return
	
	# 如果当前是最大化状态，先保存状态
	if _is_maximized:
		# 这里不需要额外保存，因为restore会使用_normal_rect
		pass
	else:
		# 保存当前窗口状态（位置和大小）
		_normal_rect = Rect2(global_position, size)
	
	# 最小化逻辑：可以选择隐藏窗口或缩小到标题栏大小
	# 这里选择保存当前大小，然后将高度缩小（只显示标题栏）
	var original_size = size
	
	# 设置最小化状态
	_is_minimized = true
	_is_maximized = false
	
	# 发送最小化信号
	emit_signal("window_minimized")

# 最大化窗口
# @description 将窗口调整为视口大小，保存当前状态
# @public
func maximize() -> void:
	# 如果已经处于最大化状态，不需要再次最大化
	if _is_maximized:
		return
	
	# 保存当前窗口状态（位置和大小）
	_normal_rect = Rect2(global_position, size)
	
	# 获取视口大小（减去一些边距，避免完全填满）
	var viewport_size = get_viewport_rect().size
	var margin = Vector2(10, 10)  # 边距
	var max_size = viewport_size - margin * 2
	
	# 调整窗口大小以填充可用空间
	size = max_size
	
	# 设置窗口位置为视口左上角（考虑边距）
	global_position = margin
	
	# 设置最大化状态
	_is_maximized = true
	
	# 重置最小化状态
	_is_minimized = false
	
	# 发送最大化信号
	emit_signal("window_maximized")
	
	# 发送窗口调整大小和移动信号
	emit_signal("window_resized")
	emit_signal("window_moved")

# 恢复窗口到普通状态
# @description 从保存的状态恢复窗口位置和大小
# @public
func restore() -> void:
	# 从保存的状态恢复窗口位置和大小
	if _normal_rect != Rect2():
		global_position = _normal_rect.position
		size = _normal_rect.size
		
		# 发送窗口调整大小和移动信号
		emit_signal("window_resized")
		emit_signal("window_moved")
	
	# 重置最大化和最小化标志
	_is_minimized = false
	_is_maximized = false
	
	# 发送恢复信号
	emit_signal("window_restored")

## 窗口位置和大小控制方法
# 控制窗口位置和大小调整的方法

# 移动窗口到指定位置
# @param position 目标位置向量
# @description 将窗口移动到指定位置，并确保不超出视口边界
# @public
func move_to(position: Vector2) -> void:
	# 如果窗口处于最大化或最小化状态，不允许移动
	if _is_maximized or _is_minimized:
		return
	
	# 更新窗口位置
	global_position = position
	
	# 确保窗口不会移出屏幕（简单实现）
	var viewport_size = get_viewport_rect().size
	global_position.x = clamp(global_position.x, 0, viewport_size.x - size.x)
	global_position.y = clamp(global_position.y, 0, viewport_size.y - size.y)
	
	# 发送移动信号
	emit_signal("window_moved")

# 调整窗口大小
# @param new_size 目标大小向量
# @description 调整窗口大小，确保不小于最小尺寸要求
# @public
func resize(new_size: Vector2) -> void:
	# 如果窗口处于最大化或最小化状态，不允许调整大小
	if _is_maximized or _is_minimized:
		return
	
	# 确保窗口不小于最小尺寸要求
	var min_size = Vector2(200, 100)  # 最小宽度和高度
	var final_size = Vector2(
		max(new_size.x, min_size.x),
		max(new_size.y, min_size.y)
	)
	
	# 更新窗口大小
	size = final_size
	
	# 发送调整大小信号
	emit_signal("window_resized")

## 状态查询方法
# 查询窗口当前状态的方法

# 获取窗口层级
# @return String 窗口所在的层级名称（如"normal"、"dialog"）
# @description 返回窗口当前所在的层级名称
# @public
func get_window_layer() -> String:
	# 返回窗口所在层级
	return window_layer

# 检查窗口是否处于最小化状态
# @return bool 窗口是否处于最小化状态
# @description 返回窗口的最小化状态标志
# @public
func is_minimized() -> bool:
	# 返回最小化状态标志
	return _is_minimized

# 检查窗口是否处于最大化状态
# @return bool 窗口是否处于最大化状态
# @description 返回窗口的最大化状态标志
# @public
func is_maximized() -> bool:
	# 返回最大化状态标志
	return _is_maximized

# 检查窗口是否已经打开
# @return bool 窗口是否已经打开
# @description 返回窗口的打开状态标志
# @public
func is_opened() -> bool:
	# 返回窗口打开状态标志
	return _is_opened

## 事件处理方法
# 处理用户输入和UI事件的方法

# 处理窗口标题栏点击事件
# 用于实现拖拽、最小化、最大化等操作
# @param event 输入事件对象
# @description 处理鼠标点击和拖拽逻辑
# @private
func _on_title_bar_gui_input(event: InputEvent) -> void:
	# 处理鼠标点击和拖拽
	# 区分点击标题栏和点击控制按钮的情况
	pass

# 处理最小化按钮点击
# @description 检查权限并执行最小化操作
# @private
func _on_minimize_button_pressed() -> void:
	# 检查是否允许最小化
	if can_minimize:
		minimize()

# 处理最大化按钮点击
# @description 检查权限并在最大化和恢复之间切换
# @private
func _on_maximize_button_pressed() -> void:
	# 检查是否允许最大化
	if can_maximize:
		if _is_maximized:
			restore()
		else:
			maximize()

# 处理关闭按钮点击
# @description 调用close方法关闭窗口
# @private
func _on_close_button_pressed() -> void:
	# 调用close方法
	close()

# 处理窗口边界拖拽调整大小
# @param event 输入事件对象
# @description 检查权限并处理拖拽调整大小的逻辑
# @private
func _on_resize_handle_gui_input(event: InputEvent) -> void:
	# 检查是否允许调整大小
	# 处理拖拽调整大小的逻辑
	pass

# 处理关闭触摸面板的输入事件
# @param event 输入事件对象
# @description 检测点击并关闭窗口
# @private
func _on_close_touch_panel_gui_input(event: InputEvent) -> void:
	if not visible: return
	
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == MouseButton.MOUSE_BUTTON_LEFT:
				# 点击面板空白区域时关闭日期选择器
				# 实际应用中可能需要根据项目需求进行调整
				close()

## 测试代码（注释掉）
# 以下是测试代码，目前已注释掉
# @export var test_ButtonList:Array[Button] = []
# @export var test_button_index = 0
#
#func _on_test_add_button_pressed() -> void:
	#var button = Button.new()
	#button.set_custom_minimum_size(Vector2(32, 32))
	#test_button_index += 1
	#button.set_name("Test_Button_" + str(test_button_index))
	#button.set_text("测试_" + str(test_button_index))
	#test_ButtonList.append(button)
	#Test_HFlowContainer.add_child(button)
#
#func _on_test_del_button_pressed() -> void:
	#if test_ButtonList.size() <= 0: return
	#var button: Button = test_ButtonList.pop_front()
	#button.queue_free()
	#print("删除组件 " + button.get_text())

## 内容管理方法
# 管理窗口内容区域子节点的方法

# 添加子节点到主内容区域
# @param node 要添加的节点
# @description 将节点添加到窗口的主内容容器中
# @public
func add_child_node(node:Node2D) -> void:
	MainContent.add_child(node)

# 从主内容区域移除子节点
# @param node 要移除的节点
# @description 从窗口的主内容容器中移除指定节点
# @public
func remove_child_node(node:Node2D) -> void:
	MainContent.remove_child(node)
