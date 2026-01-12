# 日期选择器组件 - 月份选择器
# 用于选择月份的UI组件，支持月份选择和显示
class_name MonthPicker
extends Control

@export var selected_month = 1

signal on_month_pick(month)

func _ready() -> void:
	# 更新月份按钮显示，高亮选中的月份
	_update_month_buttons()

func _process(delta: float) -> void:
	pass

func update_data(delta: float) -> void:
	pass

# 月份按钮点击处理 - 接收索引参数（从场景信号连接中绑定）
func _on_month_button_pressed(index: int) -> void:
	selected_month = index
	_update_month_buttons()
	on_month_pick.emit(selected_month)
	close_window()

# 更新月份按钮显示，设置选中月份的焦点
func _update_month_buttons() -> void:
	var button_container = $MonthButtons/Container
	for i in range(1, 13):
		var button = button_container.get_node("Month_" + str(i))
		var month = i
		if month == selected_month:
			button.call_deferred("grab_focus")


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
