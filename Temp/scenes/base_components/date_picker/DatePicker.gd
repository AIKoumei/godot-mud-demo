# 日期选择器组件
# 用于选择年月日的UI组件
class_name DatePicker
extends Control

signal on_date_pick(datetime: Dictionary)

# 导出变量
@export var year: int = 2025       # 年份
@export var month: int = 11        # 月份
@export var day: int = 1           # 日期
@export var hour: int = 1          # 小时
@export var minute: int = 1        # 分钟
@export var second: int = 0        # 秒
@export var time_string: String = "" # 格式化后的时间字符串

#var year_picker: YearPicker
#var month_picker: MonthPicker

# 内部变量
var _datetime: Dictionary
var grid_container: GridContainer = null  # 日期网格容器引用
var day_buttons: Array[Button] = []  # 存储日期按钮 (Day_1 到 Day_31)
var empty_buttons: Array[Button] = []  # 存储占位按钮 (Day_Empty_1 到 Day_Empty_11)

# 日期选择器初始化完成时调用
# 当节点进入场景树时执行一次
func _ready() -> void:
	# 获取日期网格容器引用
	grid_container = $VBoxContainer/Days/GridContainer
	
	# 初始化按钮数组
	_init_buttons()
	
	# 初始化时更新时间字符串
	_update_time_string()
	
	# 更新年月标签显示
	_update_year_month_labels()
	
	# 连接导航按钮信号
	$VBoxContainer/YearMonthBar/YearMonthBar/LastYearButton.pressed.connect(_on_last_year_button_pressed)
	$VBoxContainer/YearMonthBar/YearMonthBar/LastMonthButton.pressed.connect(_on_last_month_button_pressed)
	$VBoxContainer/YearMonthBar/YearMonthBar/NextMonthButton.pressed.connect(_on_next_month_button_pressed)
	$VBoxContainer/YearMonthBar/YearMonthBar/NextYearButton.pressed.connect(_on_next_year_button_pressed)
	
	# 初始化时更新数据显示
	update_data()

# 每帧调用一次，用于处理时间更新
# 参数 delta: 从上一帧到当前帧的时间间隔（秒）
func _process(delta: float) -> void:
	# 不再每帧更新数据，只在用户交互时更新
	pass

# 更新时间数据，只在需要时调用
# 不再根据游戏时间流逝自动更新时、分、秒
func update_data() -> void:
	# 更新时间字符串
	_update_time_string()
	
	# 更新日期显示
	_update_date_display()
				
	emit_signal("on_date_pick", {
		"year":year
		,"month":month
		,"day":day
		,"hour":hour
		,"minute":minute
		,"second":second
		,"time_string":time_string
	})

func get_date_dict():
	return {
		"year":year
		,"month":month
		,"day":day
		,"hour":hour
		,"minute":minute
		,"second":second
		,"time_string":time_string
	}

# 更新日期显示
func _update_date_display() -> void:
	# 获取当月天数
	var days_in_month = _get_days_in_month(month, year)
	# 计算当月第一天是星期几（0=周日，1=周一，...，6=周六）
	var first_day_of_week = _get_first_day_of_week(year, month)
	
	# 添加调试信息
	print("当前年月: " + str(year) + "年" + str(month) + "月, 天数: " + str(days_in_month) + ", " + time_string)
	
	# 重置所有日期按钮和占位按钮的可见性
	for button in day_buttons:
		button.visible = false
		# 重置选中状态显示
		if button.has_node("Selected"):
			button.get_node("Selected").visible = false
	for button in empty_buttons:
		button.visible = false
	
	# 显示占位按钮，使第一天出现在正确的星期位置
	for i in range(first_day_of_week):
		if i < empty_buttons.size():
			empty_buttons[i].visible = true
			grid_container.move_child(empty_buttons[i], 0)
	
	# 显示日期按钮，确保它们出现在正确的位置
	for button in day_buttons:
		var node_name = button.name
		if node_name.begins_with("Day_") and node_name.length() > 4:
			var day_number = int(node_name.substr(4))
			# 明确设置按钮可见性，确保超出月份天数的按钮被隐藏
			if day_number <= days_in_month:
				button.visible = true
				button.disabled = false
				if day_number == day:
					# 设置选中状态，显示Selected节点
					if button.has_node("Selected"):
						button.get_node("Selected").visible = true
					button.call_deferred("grab_focus")
			else:
				button.visible = false
				button.disabled = true
	
	# 确保日期按钮的标签正确显示
	_update_day_labels()

# 初始化日期按钮和占位按钮数组
func _init_buttons() -> void:
	# 遍历网格容器中的所有子节点
	for child in grid_container.get_children():
		if child is Button:
			# 根据节点名称判断是日期按钮还是占位按钮
			var node_name = child.name
			# 检查是否为占位按钮 (Day_Empty_1 到 Day_Empty_11)
			if node_name.begins_with("Day_Empty_"):
				# 占位按钮
				empty_buttons.append(child)
				# 占位按钮通常不需要响应点击
				child.disabled = true
			elif node_name.begins_with("Day_"):
				var day_number = int(node_name.substr(4))
				if day_number >= 1 and day_number <= 31:
					# 日期按钮
					day_buttons.append(child)
					# 连接信号
					child.disabled = false
					child.pressed.connect(func(day_num = day_number): _on_day_button_pressed(day_num))
	
	print("初始化完成，日期按钮数量：", day_buttons.size())
	print("占位按钮数量：", empty_buttons.size())

# 日期按钮点击事件处理
# 参数 day_number: 被点击的日期
func _on_day_button_pressed(day_number: int) -> void:
	# 设置选中的日期
	day = day_number
	# 调用更新数据函数
	update_data()
	# 这里可以添加更多的日期选择处理逻辑

# 计算指定月份的天数
# 参数 month: 月份
# 参数 year: 年份
# 返回: 该月的天数
func _get_days_in_month(month: int, year: int) -> int:
	match month:
		1, 3, 5, 7, 8, 10, 12:
			return 31
		4, 6, 9, 11:
			return 30
		2:
			# 闰年判断
			if (year % 4 == 0 and year % 100 != 0) or (year % 400 == 0):
				return 29
			else:
				return 28
	return 30

# 计算指定月份第一天是星期几
# 使用基姆拉尔森计算公式的变种
# 参数 year: 年份
# 参数 month: 月份
# 返回: 星期几（0=周日，1=周一，...，6=周六）
func _get_first_day_of_week(year: int, month: int) -> int:
	# 基姆拉尔森计算公式需要将1月和2月视为上一年的13、14月
	var m = month
	var y = year
	if m < 3:
		m += 12
		y -= 1
	
	# 基姆拉尔森计算公式：h = ( q + [ (13(m+1))/5 ] + K + [K/4] + [J/4] + 5J ) mod 7
	# 这里q=1（第一天），K是年份的后两位，J是年份的前两位
	var k = y % 100
	var j = int(y / 100)
	var h = (1 + int((13 * (m + 1)) / 5) + k + int(k / 4) + int(j / 4) + 5 * j) % 7
	
	# 调整结果，使其符合0=周日，1=周一的标准
	# 基姆拉尔森公式结果：0=周六，1=周日，...，6=周五
	return (h + 5) % 7

# 更新年月标签显示
func _update_year_month_labels() -> void:
	# 更新年份标签
	var year_label = $VBoxContainer/YearMonthBar/YearMonthBar/Year
	if year_label is Label:
		year_label.text = str(year) + "年"
	
	# 更新月份标签
	var month_label = $VBoxContainer/YearMonthBar/YearMonthBar/Month
	if month_label is Label:
		month_label.text = str(month) + "月"

# 更新日期按钮的标签显示
func _update_day_labels() -> void:
	for button in day_buttons:
		var node_name = button.name
		if node_name.begins_with("Day_") and node_name.length() > 4:
			var day_number = int(node_name.substr(4))
			# 查找按钮内的标签节点
			for child in button.get_children():
				if child is Label:
					child.text = str(day_number)

# 更新时间字符串格式
func _update_time_string() -> void:
	# 格式化时间字符串为: YYYY-MM-DD HH:MM:SS
	time_string = "%04d-%02d-%02d %02d:%02d:%02d" % [
		year,
		month,
		day,
		int(hour),
		int(minute),
		int(second)
	]

# 获取当前日期的短格式字符串 (YYYY-MM-DD)
func get_date_short() -> String:
	return "%04d-%02d-%02d" % [year, month, day]

# 获取当前时间的短格式字符串 (HH:MM)
func get_time_short() -> String:
	return "%02d:%02d" % [int(hour), int(minute)]

# ##############################################################################
# ui
# ##############################################################################

# 处理面板的输入事件
# 参数 event: 输入事件
func _on_panel_gui_input(event: InputEvent) -> void:
	if not visible: return
	
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == MouseButton.MOUSE_BUTTON_LEFT:
				# 点击面板空白区域时关闭日期选择器
				# 实际应用中可能需要根据项目需求进行调整
				visible = false
				
				emit_signal("on_date_pick", {
					"year":year
					,"month":month
					,"day":day
					,"hour":hour
					,"minute":minute
					,"second":second
					,"time_string":time_string
				})

# ##############################################################################
# funcs
# ##############################################################################

# 获取年份
# 返回: 当前年份
func get_year() -> int:
	return year

# 设置年份
# 参数 _year: 要设置的年份
func set_year(_year: int):
	year = _year
	update_data()

# 获取月份
# 返回: 当前月份
func get_month() -> int:
	return month

# 设置月份
# 参数 _month: 要设置的月份（1-12）
func set_month(_month: int):
	# 确保月份在有效范围内
	month = clamp(_month, 1, 12)
	# 调整日期，确保不超过当月天数
	day = min(day, _get_days_in_month(month, year))
	update_data()

# 获取日期
# 返回: 当前日期
func get_day() -> int:
	return day

# 设置日期
# 参数 _day: 要设置的日期
func set_day(_day: int):
	# 确保日期在有效范围内
	day = clamp(_day, 1, _get_days_in_month(month, year))
	update_data()

# 获取小时
# 返回: 当前小时
func get_hour() -> int:
	return int(hour)

# 设置小时
# 参数 _hour: 要设置的小时（0-23）
func set_hour(_hour: int):
	hour = clamp(_hour, 0, 23)
	update_data()

# 获取分钟
# 返回: 当前分钟
func get_minute() -> int:
	return int(minute)

# 设置分钟
# 参数 _minute: 要设置的分钟（0-59）
func set_minute(_minute: int):
	minute = clamp(_minute, 0, 59)
	update_data()

# 获取秒
# 返回: 当前秒
func get_second() -> float:
	return second

# 设置秒
# 参数 _second: 要设置的秒
func set_second(_second: float):
	second = clamp(_second, 0, 59)
	update_data()

# 设置完整的日期时间
# 参数 _year: 年份
# 参数 _month: 月份
# 参数 _day: 日期
# 参数 _hour: 小时
# 参数 _minute: 分钟
# 参数 _second: 秒
func set_datetime(_year: int, _month: int, _day: int, _hour: int, _minute: int, _second: float = 0.0) -> void:
	year = _year
	month = clamp(_month, 1, 12)
	day = clamp(_day, 1, _get_days_in_month(month, year))
	hour = clamp(_hour, 0, 23)
	minute = clamp(_minute, 0, 59)
	second = clamp(_second, 0, 59)
	update_data()

# 比较两个日期对象
# 参数 other_date: 要比较的另一个日期对象
# 返回: 0表示相等，1表示当前日期晚于other_date，-1表示当前日期早于other_date
func compare_datetime(other_date) -> int:
	if year != other_date.year:
		return 1 if year > other_date.year else -1
	if month != other_date.month:
		return 1 if month > other_date.month else -1
	if day != other_date.day:
		return 1 if day > other_date.day else -1
	if hour != other_date.hour:
		return 1 if hour > other_date.hour else -1
	if minute != other_date.minute:
		return 1 if minute > other_date.minute else -1
	if second != other_date.second:
		return 1 if second > other_date.second else -1
	return 0

# 从字符串解析日期时间
# 参数 datetime_str: 格式为"YYYY-MM-DD HH:MM:SS"的字符串
# 返回: 是否解析成功
func parse_datetime_string(datetime_str: String) -> bool:
	# 解析格式为 "YYYY-MM-DD HH:MM:SS" 的字符串
	var regex = RegEx.new()
	regex.compile("^(\\d{4})-(\\d{2})-(\\d{2}) (\\d{2}):(\\d{2}):(\\d{2})$")
	var result = regex.search(datetime_str)
	
	if result:
		var y = result.get_string(1).to_int()
		var m = result.get_string(2).to_int()
		var d = result.get_string(3).to_int()
		var h = result.get_string(4).to_int()
		var mi = result.get_string(5).to_int()
		var s = result.get_string(6).to_int()
		
		# 设置解析后的日期时间
		set_datetime(y, m, d, h, mi, s)
		return true
	else:
		print("日期时间字符串格式不正确，应为: YYYY-MM-DD HH:MM:SS")
		return false

# ##############################################################################
# END
# ##############################################################################


func _on__pressed(source: BaseButton, extra_arg_0: int) -> void:
	pass # Replace with function body.


func _on_year_button_pressed() -> void:
	#if not year_picker:
		#var year_picker_scene = load("res://scenes/base_components/YearPicker.tscn")
		#if year_picker_scene:
			## 实例化任务项
			#year_picker = year_picker_scene.instantiate()
			#year_picker.connect("on_year_pick", _on_year_pick)
			#add_child(year_picker)
	#year_picker.visible = true
	#year_picker.global_position = $VBoxContainer/YearMonthBar/YearMonthBar/Year/YearButton.global_position
	#year_picker.base_year = year/10*10
	#year_picker.selected_year = year
	#year_picker._update_year_buttons()
	var year_picker = WindowManager.open_window(ResourceManager.SCENE_CATEGORIES.window_components.year_picker_window)
	year_picker.connect("on_year_pick", _on_year_pick)
	year_picker.select_year(year)

func _on_year_pick(selected_year):
	# 设置年份
	year = selected_year
	# 调整日期，确保不超过当月天数
	day = min(day, _get_days_in_month(month, year))
	# 更新数据
	update_data()
	# 更新年月标签
	_update_year_month_labels()

func _on_month_button_pressed() -> void:
	#if not month_picker:
		#var month_picker_scene = load("res://scenes/base_components/MonthPicker.tscn")
		#if month_picker_scene:
			## 实例化任务项
			#month_picker = month_picker_scene.instantiate()
			#month_picker.connect("on_month_pick", _on_month_pick)
			#add_child(month_picker)
	#month_picker.visible = true
	#month_picker.global_position = $VBoxContainer/YearMonthBar/YearMonthBar/Month/MonthButton.global_position
	#month_picker.selected_month = month
	#month_picker._update_month_buttons()
	var month_picker = WindowManager.open_window(ResourceManager.SCENE_CATEGORIES.window_components.month_picker_window)
	month_picker.connect("on_month_pick", _on_month_pick)
	month_picker.select_month(month)


func _on_month_pick(selected_month):
	# 设置月份
	month = selected_month
	# 调整日期，确保不超过当月天数
	day = min(day, _get_days_in_month(month, year))
	# 更新数据
	update_data()
	# 更新年月标签
	_update_year_month_labels()

# 上一年按钮点击事件处理
func _on_last_year_button_pressed() -> void:
	# 年份减1
	year -= 1
	# 调整日期，确保不超过当月天数（考虑闰年）
	day = min(day, _get_days_in_month(month, year))
	# 更新数据
	update_data()
	# 更新年月标签
	_update_year_month_labels()

# 上一月按钮点击事件处理
func _on_last_month_button_pressed() -> void:
	# 月份减1
	month -= 1
	# 处理月份边界情况
	if month < 1:
		month = 12
		year -= 1
	# 调整日期，确保不超过当月天数
	day = min(day, _get_days_in_month(month, year))
	# 更新数据
	update_data()
	# 更新年月标签
	_update_year_month_labels()

# 下一月按钮点击事件处理
func _on_next_month_button_pressed() -> void:
	# 月份加1
	month += 1
	# 处理月份边界情况
	if month > 12:
		month = 1
		year += 1
	# 调整日期，确保不超过当月天数
	day = min(day, _get_days_in_month(month, year))
	# 更新数据
	update_data()
	# 更新年月标签
	_update_year_month_labels()

# 下一年按钮点击事件处理
func _on_next_year_button_pressed() -> void:
	# 年份加1
	year += 1
	# 调整日期，确保不超过当月天数（考虑闰年）
	day = min(day, _get_days_in_month(month, year))
	# 更新数据
	update_data()
	# 更新年月标签
	_update_year_month_labels()
