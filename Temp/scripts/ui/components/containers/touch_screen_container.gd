## =============================================================================
## TouchScreenContainer 类
## 触摸屏幕容器组件
## 
## 功能说明：
##   1. 负责子节点ScrollContainer的滚动处理
##   2. 通过TouchPanel对触摸或者鼠标的处理，对ScrollContainer进行滚动操作
##   3. 支持触摸滑动、惯性滚动和滚动边界检测
##   4. 提供平滑的滚动体验和触摸反馈
##
## 使用场景：
##   - 移动设备触摸滚动界面
##   - 需要精确控制滚动行为的列表
##   - 自定义触摸交互的容器组件
## =============================================================================
extends MarginContainer
class_name TouchScreenContainer

@onready var scrollContainer = $ScrollContainer
@onready var touchPanel = $TouchPanel

## 滚动相关配置
var scroll_speed_factor: float = 1
var scroll_inertia: float = 0.9
var min_scroll_speed: float = 10.0

## 触摸状态跟踪
var is_touching: bool = false
var last_touch_position: Vector2 = Vector2.ZERO
var start_touch_position: Vector2 = Vector2.ZERO
var current_velocity: Vector2 = Vector2.ZERO
var last_delta_time: float = 0.0

## 初始化函数
func _ready() -> void:
	## 设置最小尺寸
	set_custom_minimum_size(Vector2(0, 200))
	
	## 连接触摸信号
	if touchPanel:
		touchPanel.connect("gui_input", _on_touch_panel_input)
		if "selected_item_changed" in touchPanel:
			touchPanel.connect("selected_item_changed", _on_selected_item_changed)
	
	#if scrollContainer:
		#scrollContainer.connect("scroll_started", _on_scroll_started)
		#scrollContainer.connect("scroll_ended", _on_scroll_ended)

@export_category("UITouchStatus")
@export var _is_scrolling = false
@export var _is_touch_click = false
@export var _is_touch_drag = false

func _clean_touch_status():
	is_touching = false
	_is_touch_click = false
	_is_touch_drag = false

func _on_scroll_started():
	print("_on_scroll_started")
	_is_scrolling = true
	_is_touch_drag = true

func _on_scroll_ended():
	print("_on_scroll_ended")
	_is_scrolling = false

func update_scrolling():
	if not _is_scrolling: return

##override
func set_data_list(data_list):
	pass
	

## 触摸面板输入处理
## @param event: 输入事件对象，可能是触摸事件、鼠标事件或拖动事件
## @description 统一处理触摸面板的各种输入事件，分发到对应的处理方法
## @note 根据事件类型调用不同的处理方法，实现触摸和鼠标输入的统一处理
func _on_touch_panel_input(event: InputEvent) -> void:
	# 处理触摸事件
	if event is InputEventScreenTouch:
		_process_touch(event)
	# 处理鼠标事件（当前已注释）
	#elif event is InputEventMouseButton:
		#_process_mouse(event)
	# 处理触摸移动事件
	elif event is InputEventScreenDrag:
		_process_touch_drag(event)
	# 处理鼠标移动事件
	elif event is InputEventMouseMotion:
		if is_touching:
			_process_mouse_motion(event)

## 处理触摸事件
## @param event: 触摸屏幕事件对象
## @description 处理触摸开始和结束事件，更新触摸状态和相关参数
## @note 区分触摸按下、触摸释放（点击）和触摸释放（拖动结束）三种情况
func _process_touch(event: InputEventScreenTouch) -> void:
	#print("_process_touch", event)  # 调试信息
	
	if event.pressed:
		# 触摸开始：初始化触摸状态和参数
		is_touching = true
		start_touch_position = event.position
		last_touch_position = event.position
		current_velocity = Vector2.ZERO
		scroll_inertia = 0.9  # 重置滚动惯性系数
		
		# 如果正在滚动，停止滚动并更新状态
		if _is_scrolling:
			_on_scroll_ended()
			if scrollContainer.has_signal("scroll_ended"):
				scrollContainer.emit_signal("scroll_ended")
				
	elif not _is_touch_drag:
		# 触摸释放且未拖动：视为点击事件
		_is_touch_click = true
		_process_touch_click(event.position)
		_after_process_touch_click(event.position)
		
	elif is_touching:
		# 触摸释放且已拖动：结束触摸并清理状态
		_clean_touch_status()
		_process_inertia()

## 处理鼠标事件
func _process_mouse(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# 鼠标按下
			is_touching = true
			start_touch_position = event.position
			last_touch_position = event.position
			current_velocity = Vector2.ZERO
			scroll_inertia = 0.9
			# 如果正在滚动，停止滚动并更新状态
			if _is_scrolling:
				_on_scroll_ended()
				if scrollContainer.has_signal("scroll_ended"):
					scrollContainer.emit_signal("scroll_ended")
		elif not _is_touch_drag:
			_is_touch_click = true
			_process_touch_click(event.position)
			_after_process_touch_click(event.position)
		else:
			# 鼠标释放，触发滚动结束信号
			_clean_touch_status()
			_process_inertia()

## 处理触摸
func _process_touch_click(touch_position: Vector2) -> void:
	print("touch_position", touch_position)

func _after_process_touch_click(touch_position: Vector2) -> void:
	_clean_touch_status()

## 处理触摸拖动
## @param event: 触摸拖动事件对象
## @description 处理触摸拖动事件，实现滚动操作和速度计算
## @note 负责触发滚动开始信号、执行滚动操作、更新触摸位置和速度
func _process_touch_drag(event: InputEventScreenDrag) -> void:
	if is_touching and scrollContainer:
		# 计算滚动增量，应用滚动速度因子
		var delta = event.relative * scroll_speed_factor
		
		# 拖动开始：如果之前未滚动且有实际拖动距离，触发滚动开始信号
		if not _is_scrolling and (delta.x != 0 or delta.y != 0):
			_on_scroll_started()
			if scrollContainer.has_signal("scroll_started"):
				scrollContainer.emit_signal("scroll_started")
		
		# 执行实际滚动操作
		_perform_scroll(delta)
		
		# 更新触摸位置和当前速度
		last_touch_position = event.position
		current_velocity = delta  # 记录当前拖动速度，用于惯性滚动

## 处理鼠标移动
func _process_mouse_motion(event: InputEventMouseMotion) -> void:
	if is_touching and scrollContainer:
		var delta = event.relative * scroll_speed_factor
		
		# 当开始拖动时，触发滚动开始信号
		if not _is_scrolling and (delta.x != 0 or delta.y != 0):
			_on_scroll_started()
			if scrollContainer.has_signal("scroll_started"):
				scrollContainer.emit_signal("scroll_started")
		
		_perform_scroll(delta)
		last_touch_position = event.position
		# 计算当前速度
		current_velocity = delta

## 执行滚动操作
## @param delta: 滚动增量向量，x和y分别代表水平和垂直滚动距离
## @description 根据滚动增量计算新的滚动位置，并应用到ScrollContainer
## @note 包含边界检查，确保滚动位置在有效范围内
func _perform_scroll(delta: Vector2) -> void:
	# 安全检查：确保ScrollContainer存在
	if not scrollContainer:
		return
	
	# 计算新的滚动位置
	# 注意：delta为负表示向下/向右滚动，所以使用减法计算新位置
	var new_scroll_x = scrollContainer.scroll_horizontal - delta.x
	var new_scroll_y = scrollContainer.scroll_vertical - delta.y
	
	# 应用边界检查，确保滚动位置在有效范围内
	# 水平滚动范围：0到水平滚动条的最大值
	new_scroll_x = clamp(new_scroll_x, 0, scrollContainer.get_h_scroll_bar().max_value)
	# 垂直滚动范围：0到垂直滚动条的最大值
	new_scroll_y = clamp(new_scroll_y, 0, scrollContainer.get_v_scroll_bar().max_value)
	
	# 应用计算好的滚动位置到ScrollContainer
	scrollContainer.scroll_horizontal = new_scroll_x
	scrollContainer.scroll_vertical = new_scroll_y

## 处理惯性滚动
## 处理惯性滚动入口
## @description 惯性滚动的入口方法，检查滚动条件并启动惯性滚动处理
## @note 作为触摸拖动结束后的惯性滚动触发点
func _process_inertia() -> void:
	# 停止条件：没有ScrollContainer或速度低于最小滚动速度
	if not scrollContainer or current_velocity.length() < min_scroll_speed:
		# 惯性滚动结束：更新滚动状态并发出信号
		if _is_scrolling:
			_on_scroll_ended()
			if scrollContainer.has_signal("scroll_ended"):
				scrollContainer.emit_signal("scroll_ended")
		return
	
	# 开始惯性滚动：调用实际处理惯性滚动的方法
	_process_inertia_scroll()

## 惯性滚动处理
## @description 实现惯性滚动的核心逻辑，包括速度衰减和持续滚动
## @note 使用异步等待实现平滑的惯性滚动效果
## @process 1. 检查滚动条件 2. 衰减速度 3. 执行滚动 4. 异步等待后递归调用自身
func _process_inertia_scroll() -> void:
	# 安全检查：确保ScrollContainer存在
	if not scrollContainer:
		return
	
	# 滚动条件：速度大于最小值且未触摸
	if current_velocity.length() > min_scroll_speed and not is_touching:
		# 应用速度衰减：逐渐减小滚动速度
		current_velocity *= scroll_inertia
		
		# 执行滚动操作：使用衰减后的速度
		_perform_scroll(current_velocity)
		
		# 异步等待约16ms（60fps）后继续惯性滚动
		await get_tree().create_timer(0.016).timeout
		_process_inertia_scroll()
		#print("? next")  # 调试信息
	else:
		print("? end")
		# 惯性滚动结束
		if _is_scrolling:
			_on_scroll_ended()
			if scrollContainer.has_signal("scroll_ended"):
				scrollContainer.emit_signal("scroll_ended")

## 更新函数
func _process(delta: float) -> void:
	last_delta_time = delta
	
	# 可以在这里添加额外的处理逻辑
	pass
	
func _physics_process(delta: float) -> void:
	update_scrolling()

## 获取当前滚动位置
func get_scroll_position() -> Vector2:
	if not scrollContainer:
		return Vector2.ZERO
	return Vector2(scrollContainer.scroll_horizontal, scrollContainer.scroll_vertical)

## 设置滚动位置
func set_scroll_position(position: Vector2) -> void:
	if not scrollContainer:
		return
	scrollContainer.scroll_horizontal = position.x
	scrollContainer.scroll_vertical = position.y

## 滚动到指定位置（带动画）
func scroll_to(position: Vector2, duration: float = 0.3) -> void:
	if not scrollContainer:
		return
	
	var start_position = get_scroll_position()
	var elapsed_time: float = 0.0
	
	while elapsed_time < duration:
		elapsed_time += get_process_delta_time()
		var t = _ease(elapsed_time / duration)
		
		scrollContainer.scroll_horizontal = start_position.x + (position.x - start_position.x) * t
		scrollContainer.scroll_vertical = start_position.y + (position.y - start_position.y) * t
		
		await get_tree().process_frame

## 缓动函数
func _ease(t: float) -> float:
	# 使用平滑的缓动曲线
	return t * t * (3.0 - 2.0 * t)


func _on_selected_item_changed(index, data, item) -> void:
	print("select item, index: %s, data: %s, item: %s" % [str(index), str(data), str(item)])
