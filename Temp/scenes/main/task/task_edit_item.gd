extends Control

class_name TaskEditItem

# 任务编辑项脚本
# 管理task edit面板中的单个任务项，支持选中状态

# 任务数据对象
var task_data = {}

# 信号定义
signal task_selected_changed(source: TaskEditItem, uid, selected)
signal task_title_changed(uid, title)
signal task_delete_requested(source: TaskEditItem, uid)
signal task_time_clicked(uid)

func _ready() -> void:
	"""
	场景就绪时初始化
	连接UI元素信号
	"""
	# 连接选择复选框信号
	$MarginContainer/HBoxContainer/TaskSekectCheckBox/CheckBox.toggled.connect(_on_task_selected_toggled)
	
	# 连接删除按钮信号
	$MarginContainer/HBoxContainer/DeleteButton.pressed.connect(_on_delete_button_pressed)
	
	# 连接任务标题变化信号
	$MarginContainer/HBoxContainer/TaskTitle.text_changed.connect(_on_task_title_changed)
	
	# 连接任务时间按钮信号
	$MarginContainer/HBoxContainer/TaskTime/Button.pressed.connect(_on_deadline_button_pressed)

func set_data(data):
	"""
	设置任务项数据
	
	参数:
		data: 包含任务信息的字典，必须包含uid、title、completed、type、task_time等字段
	"""
	task_data = data
	print("set_data ", data)
	
	# 更新显示
	$MarginContainer/HBoxContainer/TaskTitle.text = data.get("title", "任务")
	# 注意：这里不再使用completed状态来设置复选框，而是作为独立的选中状态
	$MarginContainer/HBoxContainer/TaskTag/TaskTag.text = data.get("type", "家务")
	$MarginContainer/HBoxContainer/TaskTime.text = data.get("task_time", "")
	
	# 根据任务类型设置重要性颜色
	_update_importance_color(data.get("type", "家务"))

func get_data() -> Dictionary:
	"""
	获取当前任务项的数据
	
	返回:
		Dictionary - 包含任务信息的字典
	"""
	return task_data

func set_selected(value: bool) -> void:
	"""
	设置任务选中状态
	
	参数:
		value: 布尔值，表示任务是否被选中
	"""
	$MarginContainer/HBoxContainer/TaskSekectCheckBox/CheckBox.button_pressed = value

func is_selected() -> bool:
	"""
	获取任务选中状态
	
	返回:
		bool - 任务是否被选中
	"""
	return $MarginContainer/HBoxContainer/TaskSekectCheckBox/CheckBox.button_pressed

func get_completed() -> bool:
	"""
	获取任务完成状态
	
	返回:
		bool - 任务是否已完成
	"""
	return task_data.get("completed", false)

func set_title(title: String) -> void:
	"""
	设置任务标题
	
	参数:
		title: 任务标题字符串
	"""
	task_data.title = title
	$MarginContainer/HBoxContainer/TaskTitle.text = title

func get_title() -> String:
	"""
	获取任务标题
	
	返回:
		String - 任务标题
	"""
	return task_data.get("title", "")

func set_deadline(deadline: String) -> void:
	"""
	设置任务截止日期
	
	参数:
		deadline: 截止日期字符串
	"""
	task_data.deadline = deadline
	$MarginContainer/HBoxContainer/Deadline.text = deadline

func get_deadline() -> String:
	"""
	获取任务截止日期
	
	返回:
		String - 截止日期
	"""
	return task_data.get("deadline", "")

func set_task_type(task_type: String) -> void:
	"""
	设置任务类型
	
	参数:
		task_type: 任务类型字符串
	"""
	task_data.type = task_type
	$MarginContainer/HBoxContainer/TaskTag/TaskTag.text = task_type
	_update_importance_color(task_type)

func get_task_type() -> String:
	"""
	获取任务类型
	
	返回:
		String - 任务类型
	"""
	return task_data.get("type", "家务")

func _update_importance_color(task_type: String) -> void:
	"""
	根据任务类型更新重要性颜色
	
	参数:
		task_type: 任务类型字符串
	"""
	var importance_color = $MarginContainer/HBoxContainer/ImportanceColor/ImportanceColor
	var tag_background = $MarginContainer/HBoxContainer/TaskTag/Background/Background
	
	match task_type:
		"家务":
			importance_color.color = Color(0.2, 0.8, 0.2, 1)  # 绿色
			tag_background.color = Color(0.2, 0.8, 0.2, 0.3)  # 半透明绿色
		"外出":
			importance_color.color = Color(0.2, 0.6, 0.8, 1)  # 蓝色
			tag_background.color = Color(0.2, 0.6, 0.8, 0.3)  # 半透明蓝色
		"采购":
			importance_color.color = Color(0.8, 0.6, 0.2, 1)  # 橙色
			tag_background.color = Color(0.8, 0.6, 0.2, 0.3)  # 半透明橙色
		"其他":
			importance_color.color = Color(0.6, 0.6, 0.6, 1)  # 灰色
			tag_background.color = Color(0.6, 0.6, 0.6, 0.3)  # 半透明灰色
		_:
			importance_color.color = Color(1, 0, 0, 1)  # 默认红色
			tag_background.color = Color(1, 0, 0, 0.3)  # 默认半透明红色

func _update_selected_style(selected: bool) -> void:
	"""
	根据选中状态更新样式
	
	参数:
		selected: 任务是否被选中
	"""
	var background = $Background
	
	if selected:
		# 设置选中样式
		background.color = Color(0.2, 0.6, 0.8, 0.2)  # 淡蓝色背景
	else:
		# 设置未选中样式
		background.color = Color(1, 0, 0, 0.1)  # 淡红色背景

func _on_task_selected_toggled(toggled: bool) -> void:
	"""
	任务选择复选框切换处理
	
	参数:
		toggled: 复选框状态
	"""
	_update_selected_style(toggled)
	# 发射选中状态变化信号
	task_selected_changed.emit(self, task_data.get("uid", -1), toggled)

func _on_delete_button_pressed() -> void:
	"""
	删除按钮点击处理
	"""
	print("_on_delete_button_pressed", task_data)
	# 发射删除请求信号
	task_delete_requested.emit(self, task_data.get("uid", -1))

func _on_task_title_changed(new_text: String) -> void:
	"""
	任务标题变化处理
	
	参数:
		new_text: 新的任务标题
	"""
	task_data.title = new_text
	# 发射标题变化信号
	task_title_changed.emit(task_data.get("uid", -1), new_text)

func _on_deadline_button_pressed():
	"""
	任务时间按钮点击处理
	"""
	# 发射任务时间点击信号
	task_time_clicked.emit(task_data.get("uid", -1))


func _on_button_pressed() -> void:
	var window = WindowManager.open_window(ResourceManager.SCENE_CATEGORIES.window_components.date_picker_simple_window)
	#var window = WindowManager.open_window(ResourceManager.SCENE_CATEGORIES.window_components.date_picker_window)
	#window.connect("on_confirm", _on_date_pick)

func _on_date_pick(date_dict) -> void:
	$MarginContainer/HBoxContainer/TaskTime.set_text(date_dict.time_string)
