## =============================================================================
## TouchScreenContainer 类
## 触摸屏幕容器组件
## 
## 功能说明：
##   1. 负责子节点ScrollContainer的滚动处理
##   2. 通过TouchPanel对触摸或者鼠标的处理，对ScrollContainer进行滚动操作
##   3. 支持触摸滑动、惯性滚动和滚动边界检测
##   4. 提供平滑的滚动体验和触摸反馈
##
## 使用场景：
##   - 移动设备触摸滚动界面
##   - 需要精确控制滚动行为的列表
##   - 自定义触摸交互的容器组件
## =============================================================================
extends TouchScreenContainer
class_name TouchScreenContainerWithCyclableContainer


@onready var itemContainer = $ScrollContainer/ItemContainer

func update_scrolling():
	if not _is_scrolling: return
	if itemContainer:
		itemContainer._on_scroll_container_scrolled()

func set_data_list(data_list):
	itemContainer.set_data_list(data_list)
	
func _process_touch_click(touch_position: Vector2) -> void:
	super._process_touch_click(touch_position)
	if itemContainer and "_process_touch_click" in itemContainer:
		itemContainer._process_touch_click(touch_position)
