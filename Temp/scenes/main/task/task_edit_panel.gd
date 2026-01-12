# 任务编辑面板脚本
# 负责管理任务编辑界面的功能，支持批量删除

class_name TaskEditPanel extends Control

# 面板标题
var panel_title: Label
# 返回按钮
var return_button: Button
# 删除按钮
var delete_button: Button
# 其他UI元素引用
var task_form_container: VBoxContainer
var task_name_input: LineEdit
var task_type_option: OptionButton
var task_deadline_input: LineEdit
var save_button: Button
var cancel_button: Button
# 任务列表容器引用
var task_list_container: VBoxContainer

# 数据相关
var selected_task_items: Array = []

# 信号定义
signal return_to_task_panel

func _ready() -> void:
	"""初始化任务编辑面板"""
	initialize_ui()
	connect_signals()

func initialize_ui() -> void:
	"""
	初始化任务编辑面板UI元素
	"""
	# 设置面板基础属性
	# 获取UI元素引用
	return_button = $VBoxContainer/ToolsBar/MarginContainer/HSplitContainer/ReturnButton
	delete_button = $VBoxContainer/ToolsBar/MarginContainer/HSplitContainer/HBoxContainer/DeleteButton
	task_form_container = $VBoxContainer/MainContent/VBoxContainer
	
	# 获取任务列表容器引用
	task_list_container = $VBoxContainer/MainContent/ScrollContainer/VBoxContainer
	
	# 初始化选中任务列表
	selected_task_items = []
	
	# 其他UI元素引用将在后续实现
	pass

func connect_signals() -> void:
	"""
	连接UI元素的信号
	"""
	# 连接返回按钮信号
	if return_button:
		return_button.connect("pressed", _on_return_button_pressed)
	
	# 连接删除按钮信号
	if delete_button:
		delete_button.connect("pressed", _on_delete_button_pressed)
	
	# 其他信号连接将在后续实现
	pass

# 以下方法暂时只保留注释和pass占位，具体功能待后续实现
func _on_return_button_pressed() -> void:
	"""返回按钮点击事件处理"""
	# 发射返回信号
	return_to_task_panel.emit()
	# 不要销毁面板，而是隐藏它，以便可以重复使用（与缓存机制配合）
	visible = false

func save_task() -> void:
	"""保存任务数据"""
	# TODO: 实现保存任务数据的逻辑
	# 收集表单数据
	# 验证数据有效性
	# 调用数据管理器保存任务
	# 处理保存结果
	pass

func load_task(task_id: int = -1) -> void:
	"""加载任务数据到表单"""
	# TODO: 实现加载任务数据到表单的逻辑
	# 如果是编辑模式，从数据管理器获取任务数据
	# 将数据填充到表单字段
	# 如果是新增模式，清空表单
	pass

func update_data() -> void:
	"""更新任务编辑面板数据
	这个方法与task_panel.gd中的缓存机制配合使用
	当面板从缓存中显示时调用此方法
	"""
	print("TaskEditPanel: update_data 方法被调用")
	# 默认加载为新增任务模式
	load_task()
	# 加载并显示任务列表
	load_and_display_tasks()

func validate_task_data() -> bool:
	"""验证任务数据"""
	# TODO: 实现任务数据验证逻辑
	# 验证必填字段
	# 验证数据格式
	# 返回验证结果
	return false

func reset_form() -> void:
	"""重置表单"""
	# TODO: 实现表单重置逻辑
	# 清空所有表单字段
	# 恢复默认值
	pass

func load_and_display_tasks() -> void:
	"""
	从DataManager加载任务数据并显示在界面上
	"""
	# 清空现有的任务列表
	clear_task_list()
	
	# 清空选中任务列表
	selected_task_items.clear()
	
	# 从DataManager获取所有任务
	var tasks = DataManager.get_tasks()
	
	# 遍历任务数据，创建并添加任务项
	for task in tasks:
		create_task_item(task)

func create_task_item(task_data: Dictionary) -> void:
	"""
	创建任务编辑项并添加到列表中
	
	参数:
		task_data: 任务数据字典
	"""
	# 加载TaskEditItem场景
	var task_item_scene = load("res://scenes/main/task/task_edit_item.tscn")
	if task_item_scene:
		# 实例化任务项
		var task_item = task_item_scene.instantiate()
		
		# 设置任务数据
		if task_item.has_method("set_data"):
			task_item.set_data(task_data)
		
		# 连接选择状态变化信号
		if task_item.has_signal("task_selected_changed"):
			task_item.connect("task_selected_changed", _on_task_selected_changed)
		
		# 连接删除按钮信号到面板的处理函数
		if task_item.has_signal("task_delete_requested"):
			task_item.connect("task_delete_requested", _on_task_item_delete_button_pressed)
		
		# 添加到任务列表容器
		task_list_container.add_child(task_item)

func clear_task_list() -> void:
	"""清空任务列表"""
	# 移除所有子节点
	for child in task_list_container.get_children():
		child.queue_free()

func _on_task_selected_changed(source: TaskEditItem, uid: int, selected: bool) -> void:
	"""
	处理任务项选中状态变化事件
	
	参数:
		source: 任务项实例
		uid: 任务的唯一ID
		selected: 是否被选中
	"""
	if selected:
		# 添加到选中列表
		if not selected_task_items.has(source):
			selected_task_items.append(source)
		print("任务选中: " + str(uid) + ", 选中数量: " + str(selected_task_items.size()))
	else:
		# 从选中列表移除
		if selected_task_items.has(source):
			selected_task_items.erase(source)
		print("任务取消选中: " + str(uid) + ", 选中数量: " + str(selected_task_items.size()))

func _on_task_item_delete_button_pressed(source: TaskEditItem, uid: int) -> void:
	"""
	处理任务项删除按钮点击事件
	
	参数:
		source: 任务项实例
		uid: 任务的唯一ID
	"""
	print("删除任务: " + str(uid))
	# 从DataManager中删除任务
	DataManager.delete_task(uid)
	# 从选中列表中移除
	if selected_task_items.has(source):
		selected_task_items.erase(source)
	# 从列表中移除
	task_list_container.remove_child(source)

func _on_delete_button_pressed() -> void:
	"""
	处理批量删除按钮点击事件
	执行选中任务的批量删除操作
	"""
	if selected_task_items.size() == 0:
		print("没有选中任何任务")
		return
	
	print("执行批量删除，选中数量: " + str(selected_task_items.size()))
	
	# 遍历选中的任务项并删除
	var tasks_to_delete = selected_task_items.duplicate()
	for task_item in tasks_to_delete:
		# 获取任务ID
		var task_data = task_item.get_data()
		var uid = task_data.get("uid", -1)
		
		if uid != -1:
			# 从DataManager中删除任务
			DataManager.delete_task(uid)
			# 从列表中移除
			task_list_container.remove_child(task_item)
	
	# 清空选中列表
	selected_task_items.clear()
	print("批量删除完成")
