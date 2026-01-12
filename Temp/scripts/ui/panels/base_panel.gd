## =============================================================================
## BasePanel - 所有面板的基类
## 提供面板通用功能：显示/隐藏控制、信号管理、子节点操作
## =============================================================================
class_name BasePanel
extends BaseWindow

## =============================================================================
## 信号定义
## =============================================================================



## =============================================================================
## 私有属性
## =============================================================================

## 信号连接状态标志
@export var _is_all_signals_connected = false

## =============================================================================
## 公共属性
## =============================================================================


## =============================================================================
## 生命周期方法
## =============================================================================

func _init() -> void:
	MainContent = $MainContent

## 节点进入场景树时的初始化函数
func _ready() -> void:
	## 初始化UI组件和状态
	init_panel()
	## 打开窗口
	open()

## 每帧更新函数
func _process(delta: float) -> void:
	## 子类可以重写此方法处理窗口状态更新、拖拽逻辑和输入事件
	pass

## =============================================================================
## 面板生命周期控制
## =============================================================================

## 初始化面板UI组件
func init_panel() -> void:
	## 设置面板名称，包含类名和实例ID便于调试
	set_name("[ %s ] %s" % [get_script().get_global_name(), get_instance_id()])
	## 更新面板的渲染顺序
	update_z_index()

## 更新面板的渲染顺序
func update_z_index() -> void:
	## 子类可以重写此方法，根据面板层级和活动状态调整Z-index
	pass

## 打开面板
func open() -> void:
	## 如果面板已经打开，不需要再次打开
	if _is_opened:
		return
	
	## 设置面板打开状态
	_is_opened = true
	## 调用打开回调
	on_opened()
	## 发出窗口显示信号
	self.window_show.emit()

## 面板打开时的回调函数
func on_opened() -> void:
	## 设置面板可见
	visible = true

## 关闭面板
func close() -> void:
	## 设置面板关闭状态
	_is_opened = false
	## 调用关闭回调
	on_closed()
	## 发出窗口隐藏信号
	self.window_hide.emit()

## 面板关闭时的回调函数
func on_closed() -> void:
	## 设置面板不可见
	visible = false
	## 断开所有信号连接
	disconnect_all_signals()

## 检查面板是否已经打开
func is_opened() -> bool:
	## 返回面板打开状态标志
	return _is_opened

## =============================================================================
## 信号管理
## =============================================================================

## 检查是否所有信号都已连接
func is_all_signals_connected() -> bool:
	return _is_all_signals_connected

## 连接所有信号
func connect_all_signals() -> void:
	## 避免重复连接
	if _is_all_signals_connected:
		return
	_is_all_signals_connected = true

## 断开所有信号连接
func disconnect_all_signals() -> void:
	_is_all_signals_connected = false
	## 遍历所有信号并断开连接
	for _signal in get_signal_list():
		for signal_connection in get_signal_connection_list(_signal.name):
			disconnect(_signal.name, signal_connection.callable)

## =============================================================================
## 内容管理
## =============================================================================

## 向主内容容器添加子节点
func add_child_node(node: Node2D) -> void:
	MainContent.add_child(node)

## 从主内容容器移除子节点
func remove_child_node(node: Node2D) -> void:
	MainContent.remove_child(node)
