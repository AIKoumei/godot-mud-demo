# 日期选择器组件 - 年份选择器
# 用于选择年份的UI组件，支持年份跳转和显示
class_name YearPicker
extends Control

@export var base_year = 2010
@export var selected_year = 2010

signal on_year_pick(year)

# 年份按钮数量
const YEAR_BUTTON_COUNT = 10

func _ready() -> void:
	base_year = 2010
	selected_year = base_year
	# 初始化年份显示
	_update_year_buttons()
	# 所有信号已在场景文件中静态连接，不需要动态连接

func _process(delta: float) -> void:
	pass

func update_data(delta: float) -> void:
	pass

# 更新年份按钮显示
func _update_year_buttons() -> void:
	for i in range(YEAR_BUTTON_COUNT):
		var button_name = "Year_%d" % i
		if $YearButtons/Container.has_node(button_name):
			var button = $YearButtons/Container.get_node(button_name)
			var year = base_year + i
			button.text = str(year)
			# 使用grab_focus而不是pressed属性来显示选中状态
			if year == selected_year:
				button.call_deferred("grab_focus")

# 年份跳转函数
# 根据传入的年数变化值调整base_year，并确保不小于0
func jump_years(years_delta: int) -> void:
	# 计算新的base_year
	var new_base_year = base_year + years_delta
	# 确保base_year不小于0
	if new_base_year < 0:
		new_base_year = 0
	# 更新base_year
	base_year = new_base_year
	# 同步更新年份按钮的显示内容
	_update_year_buttons()

# 年份按钮点击处理 - 接收索引参数（从场景信号连接中绑定）
func _on_year_button_pressed(index: int) -> void:
	selected_year = base_year + index
	# 发送年份选择信号
	on_year_pick.emit(selected_year)
	# 更新按钮状态
	#_update_year_buttons()
	close_window()


# ##############################################################################
# funcs
# ##############################################################################


func _on_panel_gui_input(event: InputEvent) -> void:
	if not visible: return
	
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == MouseButton.MOUSE_BUTTON_LEFT:
				# 点击面板空白区域时关闭日期选择器
				# 实际应用中可能需要根据项目需求进行调整
				visible = false

func close_window():
	visible = false


# ##############################################################################
# END
# ##############################################################################
