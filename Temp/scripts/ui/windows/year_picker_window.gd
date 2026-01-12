# 日期选择器组件 - 年份选择器窗口
# 用于选择年份的UI组件，支持年份跳转和显示
class_name YearPickerWindow
extends BaseWindow

@export var base_year = 2010
@export var selected_year = 2010

signal on_year_pick(year)

# 年份按钮数量
const YEAR_BUTTON_COUNT = 10

func _ready() -> void:
	super._ready()
	base_year = 2010
	selected_year = base_year
	# 初始化年份显示
	_update_year_buttons()
	# 所有信号已在场景文件中静态连接，不需要动态连接

func select_year(year) -> void:
	selected_year = year
	base_year = year - year%10
	_update_year_buttons()

# 更新年份按钮显示
func _update_year_buttons() -> void:
	for i in range(YEAR_BUTTON_COUNT):
		var button_name = "Year_%d" % i
		var container_path = $WindowContent/VBoxContainer/MainContent/VBoxContainer/YearButtons/CenterContainer/Container
		if container_path.has_node(button_name):
			var button = container_path.get_node(button_name)
			var year = base_year + i
			button.text = str(year)
			# 重置所有按钮的Selected节点为隐藏
			if button.has_node("Selected"):
				button.get_node("Selected").visible = false
			# 为选中的年份显示Selected节点
			if year == selected_year:
				if button.has_node("Selected"):
					button.get_node("Selected").visible = true
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

# 年份按钮点击处理 - 接收索引参数
func _on_year_button_pressed(index: int) -> void:
	selected_year = base_year + index
	# 发送年份选择信号
	on_year_pick.emit(selected_year)
	# 更新按钮状态
	#_update_year_buttons()
	close()


# ##############################################################################
# funcs
# ##############################################################################

# 年份按钮点击处理 - 接收索引参数（从场景信号连接中绑定）
func _on_year_0_pressed() -> void:
	_on_year_button_pressed(0)

func _on_year_1_pressed() -> void:
	_on_year_button_pressed(1)

func _on_year_2_pressed() -> void:
	_on_year_button_pressed(2)

func _on_year_3_pressed() -> void:
	_on_year_button_pressed(3)

func _on_year_4_pressed() -> void:
	_on_year_button_pressed(4)

func _on_year_5_pressed() -> void:
	_on_year_button_pressed(5)

func _on_year_6_pressed() -> void:
	_on_year_button_pressed(6)

func _on_year_7_pressed() -> void:
	_on_year_button_pressed(7)

func _on_year_8_pressed() -> void:
	_on_year_button_pressed(8)

func _on_year_9_pressed() -> void:
	_on_year_button_pressed(9)

# 年份跳转按钮处理
func _on_pre_year_50_pressed() -> void:
	jump_years(-50)

func _on_pre_year_10_pressed() -> void:
	jump_years(-10)

func _on_next_year_10_pressed() -> void:
	jump_years(10)

func _on_next_year_50_pressed() -> void:
	jump_years(50)


# ##############################################################################
# END
# ##############################################################################
