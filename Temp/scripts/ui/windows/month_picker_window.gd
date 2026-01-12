# 日期选择器组件 - 月份选择器
# 用于选择月份的UI组件，支持月份选择和显示
class_name MonthPickerWindow
extends BaseWindow

@export var selected_month = 1

signal on_month_pick(month)

func _ready() -> void:
	super._ready()
	# 更新月份按钮显示，高亮选中的月份
	_update_month_buttons()

func select_month(month) -> void:
	selected_month = month
	_update_month_buttons()

# 月份按钮点击处理 - 接收索引参数（从场景信号连接中绑定）
func _on_month_button_pressed(index: int) -> void:
	selected_month = index
	_update_month_buttons()
	on_month_pick.emit(selected_month)
	close()

# 更新月份按钮显示，控制选中月份的Selected节点显示
func _update_month_buttons() -> void:
	# 修改：直接使用MonthButtons/Container路径
	var button_container = $WindowContent/VBoxContainer/MainContent/MonthButtons/Container
	for i in range(1, 13):
		var button = button_container.get_node("Month_" + str(i))
		var month = i
		# 重置所有按钮的Selected节点为隐藏
		if button.has_node("Selected"):
			button.get_node("Selected").visible = false
		# 为选中的月份显示Selected节点
		if month == selected_month:
			if button.has_node("Selected"):
				button.get_node("Selected").visible = true
			button.call_deferred("grab_focus")


# ##############################################################################
# END
# ##############################################################################
