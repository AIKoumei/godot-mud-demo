# =========================================================================
# 日期时间选择窗口类
# 
# 功能: 提供简单的日期时间选择界面，允许用户选择年、月、日、时、分、秒
# 继承: 继承自BaseWindow类，拥有基础窗口功能
# =========================================================================
class_name DatePickerSimpleWindow
extends BaseWindow

# =========================================================================
# 日期时间选择器的各个容器节点
# 所有容器节点均为可循环选择的容器组件
# =========================================================================

# 年份选择容器
@onready var yearContainer = $WindowContent/VBoxContainer/MainContent/HBoxContainer/YearContainer

# 月份选择容器
@onready var monthContainer = $WindowContent/VBoxContainer/MainContent/HBoxContainer/MonthContainer

# 日期选择容器
@onready var dayContainer = $WindowContent/VBoxContainer/MainContent/HBoxContainer/DayContainer

# 小时选择容器
@onready var hourContainer = $WindowContent/VBoxContainer/MainContent/HBoxContainer/HourContainer

# 分钟选择容器
@onready var minuteContainer = $WindowContent/VBoxContainer/MainContent/HBoxContainer/MinuteContainer

# 秒钟选择容器
@onready var secondContainer = $WindowContent/VBoxContainer/MainContent/HBoxContainer/SecondContainer


# =========================================================================
# 节点就绪时的回调方法
# 初始化窗口组件和设置默认状态
# =========================================================================
func _ready() -> void:
	super._ready()

# =========================================================================
# 窗口打开时的回调方法
# 处理窗口打开时的逻辑，如初始化日期时间值
# =========================================================================
func on_opened() -> void:
	super.on_opened()

# =========================================================================
# 窗口关闭时的回调方法
# 处理窗口关闭时的逻辑，如清理资源或保存状态
# =========================================================================
func on_closed() -> void:
	super.on_closed()


func _on_ready() -> void:
	hourContainer.set_data_list([{"value":0},{"value":1},{"value":2},{"value":3},{"value":4},{"value":5},{"value":6},{"value":7},{"value":8},{"value":9},{"value":10},{"value":11},{"value":12},{"value":13},{"value":14},{"value":15},{"value":16},{"value":17},{"value":18},{"value":19},{"value":20},{"value":21},{"value":22},{"value":23},{"value":24}])
