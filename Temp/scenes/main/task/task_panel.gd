# 任务面板脚本
# 负责管理任务列表的显示、搜索、筛选和交互
# 实现从DataManager获取任务数据并复制ItemCloner设置相关数据

class_name TaskPanel extends Control

# ==============================================================================
# 常量和变量定义
# ==============================================================================

# 引用路径常量
const TASK_EDIT_PANEL_SCENE = "res://scenes/main/task/task_edit_panel.tscn"
const TASK_ITEM_SCENE = "res://scenes/main/task/task_item.tscn"

# 节点引用
var jump_to_task_edit_button: Button
var item_cloner: Control
var task_list_container: VBoxContainer
var search_input: LineEdit
var filter_button: Button

# 数据相关
var current_tasks: Array = []
var current_filter_type: String = "全部"
var current_filter_status: String = "全部"

# 缓存的任务编辑面板实例
var cached_task_edit_panel: Control = null

# 信号定义
signal task_completed_changed(task_id, completed)
signal task_edit_requested(task_data)
signal task_delete_requested(task_id)

# ==============================================================================
# 生命周期方法
# ==============================================================================

func _ready() -> void:
	"""
	场景就绪时初始化
	初始化UI、连接信号并刷新任务列表
	"""
	initialize_ui()
	connect_signals()
	# 刷新任务列表
	refresh_task_list()

func _process(_delta: float) -> void:
	"""
	每帧更新处理
	暂时简化为pass
	"""
	# TODO: 实现每帧更新处理逻辑
	pass

# ==============================================================================
# 初始化方法
# ==============================================================================

func initialize_ui() -> void:
	"""
	初始化UI元素引用
	获取所有必要的节点引用
	"""
	# 获取主要UI元素引用
	jump_to_task_edit_button = $VBoxContainer/ToolsBar/MarginContainer/HBoxContainer/JumpToTaskEditScene
	item_cloner = $VBoxContainer/MainContent/VBoxContainer/ItemCloner
	task_list_container = $VBoxContainer/MainContent/VBoxContainer
	search_input = $VBoxContainer/ToolsBar/MarginContainer/HBoxContainer/SearchLineEdit
	filter_button = $VBoxContainer/ToolsBar/MarginContainer/HBoxContainer/FilterButton
	
	# 隐藏ItemCloner原型
	item_cloner.visible = false

func connect_signals() -> void:
	"""
	连接UI元素的信号
	连接所有必要的信号处理器
	"""
	# 跳转到任务编辑界面按钮信号
	jump_to_task_edit_button.connect("pressed", _on_jump_to_task_edit_pressed)
	
	# 搜索输入框信号
	search_input.connect("text_changed", _on_search_text_changed)
	
	# 筛选按钮信号
	filter_button.connect("pressed", _on_filter_button_pressed)

# ==============================================================================
# 数据管理方法
# ==============================================================================

func refresh_task_list() -> void:
	"""
	刷新任务列表，从DataManager获取任务并复制ItemCloner设置相关数据
	"""
	# 清空现有任务项
	_clear_task_list()
	
	# 从DataManager获取任务
	print("从DataManager获取任务数据")
	current_tasks = DataManager.get_tasks(current_filter_type, current_filter_status)
	print("获取到任务数量: ", current_tasks.size())
	
	# 复制ItemCloner并添加任务项
	for i in range(current_tasks.size()):
		var task = current_tasks[i]
		# 为任务添加ID（如果不存在）
		if not task.has("id"):
			task.id = i

		# 复制ItemCloner并设置数据
		var task_item = _create_task_item(task)
		if task_item:
			task_list_container.add_child(task_item)

func _create_task_item(task: Dictionary) -> Control:
	"""
	直接实例化task_item场景并设置任务数据
	参数:
		task: 任务数据字典
	返回:
		设置好数据的任务项控件
	"""
	# 加载并实例化task_item场景
	var task_item_scene = load(TASK_ITEM_SCENE)
	if task_item_scene == null:
		print("错误: 无法加载任务项场景: ", TASK_ITEM_SCENE)
		return null
	
	var new_item = task_item_scene.instantiate()
	if new_item == null:
		print("错误: 任务项场景实例化失败")
		return null
	
	new_item.name = "TaskItem_" + str(task.id)
	
	# 如果task_item有set_data方法，则使用该方法设置数据
	if new_item.has_method("set_data"):
		new_item.set_data(task)
	else:
		# 如果没有set_data方法，则手动设置数据（向后兼容）
		# 设置完成状态
		var check_box = new_item.get_node("HBoxContainer/TaskDoneCheckBox/CheckBox")
		if check_box:
			check_box.button_pressed = task.completed
			check_box.connect("toggled", _on_task_completed_toggled.bind(task.id))
		
		# 设置重要性颜色（根据任务类型设置不同颜色）
		var importance_color = new_item.get_node("HBoxContainer/ImportanceColor/ImportanceColor")
		if importance_color:
			match task.type:
				"家务":
					importance_color.color = Color(0.2, 0.8, 0.2, 1)  # 绿色
				"外出":
					importance_color.color = Color(0.2, 0.2, 0.8, 1)  # 蓝色
				"采购":
					importance_color.color = Color(0.8, 0.4, 0.2, 1)  # 橙色
				_:
					importance_color.color = Color(0.8, 0.2, 0.2, 1)  # 红色
		
		# 设置任务标签
		var task_tag = new_item.get_node("HBoxContainer/TaskTag/TaskTag")
		if task_tag:
			task_tag.text = task.type
		
		# 设置截止日期
		var task_time_label = new_item.get_node("HBoxContainer/TaskTime")
		if task_time_label:
			# 同时支持旧的next_time和新的task_time字段
			var time_value = task.get("task_time", task.get("next_time", ""))
			task_time_label.text = time_value
			
			# 设置任务标题
			var task_title = new_item.get_node("HBoxContainer/TaskTitle")
			if task_title:
				task_title.text = task.name
				# 如果任务已完成，添加删除线样式
				if task.completed:
					task_title.add_theme_font_override("font", task_title.get_theme_font("font"))
					task_title.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0))
					task_title.add_theme_constant_override("font_outline_size", 0)
	
	# 如果new_item是TaskItem类型，连接相关信号
	if new_item is Control:
		# 连接任务完成状态变化信号（如果存在）
		if new_item.has_signal("task_completed_changed"):
			new_item.connect("task_completed_changed", _on_task_completed_toggled.bind(task.id))
		# 连接任务编辑请求信号（如果存在）
		if new_item.has_signal("task_edit_requested"):
			new_item.connect("task_edit_requested", _on_task_edit_requested)
		# 连接任务删除请求信号（如果存在）
		if new_item.has_signal("task_delete_requested"):
			new_item.connect("task_delete_requested", _on_task_delete_requested)
	
	return new_item

func _clear_task_list() -> void:
	"""
	清空任务列表容器中的所有子项
	保留ItemCloner原型，删除其他所有任务项
	"""
	for child in task_list_container.get_children():
		# 保留ItemCloner原型
		if child.name != "ItemCloner":
			child.queue_free()

# ==============================================================================
# 界面交互事件处理
# ==============================================================================

func _on_search_text_changed(text: String) -> void:
	"""
	搜索文本变化处理
	根据搜索文本过滤任务列表
	参数:
		text: 搜索文本
	"""
	# TODO: 实现根据搜索文本过滤任务列表的逻辑
	print("搜索文本变化: ", text)
	refresh_task_list()

func _on_filter_button_pressed() -> void:
	"""
	筛选按钮点击处理
	弹出筛选选项
	"""
	# TODO: 实现筛选对话框，允许用户选择筛选条件
	print("筛选按钮被点击")
	refresh_task_list()

func _on_filter_option_selected(id: int) -> void:
	"""
	筛选选项选择处理
	根据选择的筛选选项更新任务列表
	参数:
		id: 选择的选项ID
	"""
	# TODO: 根据选择的筛选选项（ID）更新任务列表
	print("筛选选项选择: ", id)
	refresh_task_list()

# ==============================================================================
# 任务编辑相关方法
# ==============================================================================

func _on_jump_to_task_edit_pressed() -> void:
	"""
	跳转到任务编辑界面按钮点击处理
	使用缓存机制避免重复实例化
	保留完整的跳转逻辑
	"""
	print("_on_jump_to_task_edit_pressed 方法被调用")
	
	# 如果还没有缓存的任务编辑面板实例，则创建它
	if cached_task_edit_panel == null:
		print("开始加载任务编辑面板场景")
		# 加载并实例化任务编辑面板场景
		var task_edit_panel_scene = load(TASK_EDIT_PANEL_SCENE)
		
		# 检查场景加载是否成功
		if task_edit_panel_scene != null:
			print("任务编辑面板场景加载成功: ", task_edit_panel_scene)
			
			# 尝试实例化场景
			var panel_instance = task_edit_panel_scene.instantiate()
			if panel_instance != null:
				cached_task_edit_panel = panel_instance
				print("任务编辑面板实例化成功: ", cached_task_edit_panel)
				
				# 检查任务编辑面板是否有return_to_task_panel信号
				if cached_task_edit_panel.has_signal("return_to_task_panel"):
					print("任务编辑面板有return_to_task_panel信号")
					# 连接返回信号
					cached_task_edit_panel.connect("return_to_task_panel", _on_return_from_edit_panel)
				else:
					print("警告: 任务编辑面板没有return_to_task_panel信号")
				
				# 添加到父节点但暂时不显示
				var parent_node = get_parent()
				if parent_node != null:
					print("获取父节点: ", parent_node)
					parent_node.add_child(cached_task_edit_panel)
					cached_task_edit_panel.visible = false
					print("任务编辑面板添加到父节点成功")
				else:
					print("错误: 无法获取父节点")
			else:
				print("错误: 任务编辑面板实例化失败")
		else:
			print("错误: 任务编辑面板场景加载失败: ", TASK_EDIT_PANEL_SCENE)
	
	# 确保cached_task_edit_panel已正确初始化
	if cached_task_edit_panel != null:
		# 隐藏当前面板
		visible = false
		print("当前面板已隐藏")
		
		# 显示任务编辑面板
		cached_task_edit_panel.visible = true
		print("任务编辑面板已显示")
		
		# 通知任务编辑面板更新数据
		if cached_task_edit_panel.has_method("update_data"):
			print("调用任务编辑面板的update_data方法")
			cached_task_edit_panel.update_data()
		else:
			print("警告: 任务编辑面板没有update_data方法")
	else:
		print("错误: 任务编辑面板未初始化，无法执行操作")

func _on_return_from_edit_panel() -> void:
	"""
	从任务编辑面板返回处理
	当task_edit_panel的ReturnButton被点击时调用
	隐藏编辑面板，显示当前面板并刷新任务列表
	"""
	# 隐藏任务编辑面板
	if cached_task_edit_panel != null:
		cached_task_edit_panel.visible = false
	
	# 刷新任务列表
	refresh_task_list()
	# 显示当前面板
	visible = true

# ==============================================================================
# 任务操作相关方法
# ==============================================================================

func _on_task_completed_toggled(completed: bool, task_id: int) -> void:
	"""
	任务完成状态切换处理
	参数:
		completed: 是否完成
		task_id: 任务ID
	"""
	print("任务完成状态变化: 任务ID=", task_id, " 完成状态=", completed)
	
	# 更新DataManager中的任务状态
	# 找到对应的任务索引
	for i in range(current_tasks.size()):
		if current_tasks[i].id == task_id:
			DataManager.mark_task_completed(i, completed)
			break
	
	# 发射任务完成状态变化信号
	task_completed_changed.emit(task_id, completed)

func _on_task_edit_requested(task_data: Dictionary) -> void:
	"""
	任务编辑请求处理
	参数:
		task_data: 要编辑的任务数据
	"""
	print("任务编辑请求: ", task_data.name)
	# TODO: 实现任务编辑逻辑，打开编辑界面并传入任务数据
	task_edit_requested.emit(task_data)

func _on_task_delete_requested(task_id: int) -> void:
	"""
	任务删除请求处理
	参数:
		task_id: 要删除的任务ID
	"""
	print("任务删除请求: 任务ID=", task_id)
	# TODO: 实现任务删除逻辑，包括确认对话框和数据删除
	task_delete_requested.emit(task_id)

func _on_delete_confirmed(task_id: int) -> void:
	"""
	删除确认处理
	暂时简化为pass
	"""
	# TODO: 实现删除确认后的任务删除逻辑
	pass

func _on_task_link_clicked(link_type: String) -> void:
	"""
	任务关联按钮点击处理
	暂时简化为pass
	"""
	# TODO: 实现任务关联按钮点击的处理逻辑
	pass

# ==============================================================================
# 注释掉的变量（保留供后续开发参考）
# ==============================================================================

# var _was_visible_last_frame = false
