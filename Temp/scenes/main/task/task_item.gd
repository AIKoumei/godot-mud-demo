extends Control

class_name TaskItem

# 任务列表项脚本
# 管理单个任务项的显示和交互

# 任务数据对象
var task_data = {}

# 信号定义
signal task_completed_changed(uid, completed)
signal task_title_changed(uid, title)
signal task_delete_requested(source: TaskItem, uid)
signal task_time_clicked(uid)

func _ready() -> void:
	"""
	场景就绪时初始化
	连接UI元素信号
	"""
	# 连接复选框信号
	$MarginContainer/HBoxContainer/TaskDoneCheckBox/CheckBox.toggled.connect(_on_task_done_toggled)
	
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
		data: 包含任务信息的字典，必须包含uid、title、completed、type、deadline等字段
	"""
	task_data = data
	print("set_data ", data)
	
	# 更新显示
	$MarginContainer/HBoxContainer/TaskTitle.text = data.get("title", "任务")
	$MarginContainer/HBoxContainer/TaskDoneCheckBox/CheckBox.button_pressed = data.get("completed", false)
	$MarginContainer/HBoxContainer/TaskTag/TaskTag.text = data.get("type", "家务")
	$MarginContainer/HBoxContainer/TaskTime.text = data.get("task_time", "")
	
	# 根据任务类型设置重要性颜色
	_update_importance_color(data.get("type", "家务"))
	
	# 根据完成状态更新样式
	_update_completed_style(data.get("completed", false))

func get_data() -> Dictionary:
	"""
	获取当前任务项的数据
	
	返回:
		Dictionary - 包含任务信息的字典
	"""
	return task_data

func set_completed(value: bool) -> void:
	"""
	设置任务完成状态
	
	参数:
		value: 布尔值，表示任务是否完成
	"""
	task_data.completed = value
	$MarginContainer/HBoxContainer/TaskDoneCheckBox/CheckBox.button_pressed = value
	_update_completed_style(value)

func is_completed() -> bool:
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

func _update_completed_style(completed: bool) -> void:
	"""
	根据完成状态更新样式
	
	参数:
		completed: 任务是否已完成
	"""
	var task_title = $MarginContainer/HBoxContainer/TaskTitle
	var background = $Background
	
	if completed:
		# 设置已完成样式
		background.color = Color(0.2, 0.8, 0.2, 0.1)  # 淡绿色背景
		task_title.add_theme_font_override("font", null)
		task_title.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))  # 灰色文字
	else:
		# 设置未完成样式
		background.color = Color(1, 0, 0, 0.1)  # 淡红色背景
		task_title.add_theme_font_override("font", null)
		task_title.add_theme_color_override("font_color", Color(1, 1, 1, 1))  # 白色文字

func _on_task_done_toggled(toggled: bool) -> void:
	"""
	任务完成复选框切换处理
	
	参数:
		toggled: 复选框状态
	"""
	task_data.completed = toggled
	_update_completed_style(toggled)
	# 发射完成状态变化信号
	task_completed_changed.emit(task_data.get("uid", -1), toggled)

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
