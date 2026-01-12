## =============================================================================
## CyclableContainer 类
## 可循环列表容器组件
## 
## 功能说明：
##   1. 管理可循环切换的项目列表，支持循环选择功能
##   2. 提供两种显示模式：正常显示(NORMAL)和居中显示(CENTERED)
##   3. 基于max_items_per_row和max_items_per_column属性创建固定数量的item scene，实现高效的数据滚动更新
##   4. 支持大量数据的高效渲染和滚动操作
##   5. 提供完整的事件通知机制，便于与其他组件交互
##   6. 支持行列布局，可设置每行每列最大显示项目数
##
## 使用场景：
##   - 轮播图组件
##   - 无限滚动列表
##   - 分页数据展示
##   - 选择器组件
## =============================================================================
@tool
extends Container
class_name CyclableContainer

## =============================================================================
## 枚举定义
## =============================================================================
## 显示类型枚举
enum DisplayType {
	NORMAL,   ## 正常显示 - 所有项目都显示
	CENTERED, ## 居中显示 - 只显示当前项及前后项
}

## =============================================================================
## 信号定义
## =============================================================================
signal selected_item_changed(index, data, item)       ## 当选中项改变时发出
										 ## @param index: 新选中的项目索引
										 ## @param data: 新选中的项目数据
										 ## @param item: 新选中的项目节点对象
signal data_list_updated(items)          ## 当数据列表更新时发出
										 ## @param items: 更新后的数据列表
signal item_created(item, index)         ## 当项目创建时发出
										 ## @param item: 创建的项目节点
										 ## @param index: 项目索引
signal item_deleted(item, index)         ## 当项目删除时发出
										 ## @param item: 被删除的项目节点
										 ## @param index: 项目索引
signal item_updated(item, index, data)   ## 当项目数据更新时发出
										 ## @param item: 更新的项目节点
										 ## @param index: 项目索引
										 ## @param data: 新的项目数据
signal item_scene_changed()              ## 当项目场景变更时发出

## =============================================================================
## 导出属性
## =============================================================================
@export var is_cyclable: bool = true ## 是否启用循环功能，启用后可以无限循环切换项目
@export var display_type: DisplayType = DisplayType.NORMAL ## 显示类型：NORMAL(全部显示)或CENTERED(居中显示)
@export var selected_index: int = -1 ## 当前选中的项目索引，-1表示未选中任何项目
@export var data_list: Array = [] ## 数据列表，存储所有项目的数据，每项可以是任何类型
@export var item_scene: Variant = null ## 用于创建列表项的资源或节点，可以是PackedScene或Node类型
## 最大显示项目数（已弃用）
## @deprecated: 使用max_items_per_row和max_items_per_column代替
var _max_item_deprecated: int = 0
@export var max_items_per_row: int = 1 ## 每行最大显示的项目数量，0表示不限制，默认1表示垂直单列显示
@export var max_items_per_column: int = 5 ## 每列最大显示的项目数量，0表示不限制，默认5表示垂直最多显示5个项目
@export var is_auto_calculate_max_item_per_row: bool = false ## 是否自动计算每行的最大项目数
@export var is_auto_calculate_max_item_per_column: bool = false ## 是否自动计算每列的最大项目数，基于container的item_size和max_items_per_row
@export var item_size: Vector2 = Vector2(100, 100) ## 项目宽高尺寸，如果设置为(0,0)则根据子节点自动计算
@export var item_spacing := 10.0  ## 项目间距
@export var display_start_index: int = 0

## =============================================================================
## 私有属性
## =============================================================================
var _items: Array = [] ## 存储创建的列表项节点(内部使用)
var _item_cache_key: String = "cyclable_container_item" ## 用于缓存池的默认缓存键，由_set_item_cache_key方法动态生成唯一值
## 导入缓存池管理器（通过Engine.has_singleton在_ready方法中检查）

## =============================================================================
## 拖拽相关属性
## =============================================================================
var _is_dragging: bool = false ## 当前是否正在拖拽

## =============================================================================
## 生命周期方法
## =============================================================================
## 节点进入场景树时调用
## 功能：检查item_scene是否为空，如果为空则尝试从自身节点中查找名称为ItemScene的节点
func _ready() -> void:
	"""
	节点就绪时的初始化逻辑
	- 设置最小尺寸
	- 如果未设置item_scene，优先从子节点中查找名称为"ItemScene"的节点
	- 只支持Node类型的模板，不自动使用第一个子节点
	- 初始化拖拽相关状态
	- 连接ScrollContainer滚动信号，实现循环滚动
	- 初始化缓存池管理器引用
	- 设置item缓存键（参考WindowManager的ID创建方式）
	"""
	##self.custom_minimum_size = Vector2(200, 200)
	connect("sort_children", _on_sort_children)
	
	var parent = _get_scroll_container()
	if parent:
		parent.connect("resized", _on_scroll_container_resized)
	
	
	calculate_max_item()
	
	## =============================================================================
	## 尺寸计算方法
	## =============================================================================
	## 重新计算容器大小以适应所有子节点
	resize_container()
	
	## 如果item_scene未设置，尝试从子节点中获取
	if item_scene == null:
		## 优先查找名称完全匹配"ItemScene"的节点
		for child in get_children():
			if child.name == "ItemScene" and child is Node:
				## 直接使用名称为ItemScene的子节点作为item_scene模板
				item_scene = child
				print("CyclableContainer: 已从子节点获取名为ItemScene的节点作为模板")
				## 移除原始子节点，因为我们会在set_data_list中创建副本
				#remove_child(child)
				## 不用移除原始子节点，隐藏原始节点即可
				child.visible = false  ## 修复拼写错误
				break
	
	## 初始化缓存池管理器引用
	if Engine.has_singleton("CachePoolManager"):
		print("CyclableContainer: 已初始化缓存池管理器")
	else:
		print("警告: 未找到CachePoolManager单例")
	
	## 设置item缓存键，参考WindowManager的ID创建方式
	_set_item_cache_key()
	
	queue_sort()

## =============================================================================
## 项目管理方法
## =============================================================================

## =============================================================================
## Godot通知处理
## =============================================================================
## 处理Godot内部通知，将NOTIFICATION_SORT_CHILDREN连接到我们的排序方法
func _notification(what: int) -> void:
	"""
	处理Godot的内部通知
	当queue_sort()被调用时，会触发NOTIFICATION_SORT_CHILDREN通知
	"""
	if what == NOTIFICATION_SORT_CHILDREN:
		## 调用我们实现的排序方法
		_on_sort_children()

## =============================================================================
## 布局与滚动相关方法
## =============================================================================
## 检查项目是否在ScrollContainer的可见范围内
func _is_item_visible_in_scroll_container(item: Control) -> bool:
	"""
	检查指定的项目是否在父ScrollContainer的可见范围内
	
	@param item: 要检查的项目控件
	@return: 如果项目与可见范围有交集返回true，否则返回false
	"""
	var scroll_container = _get_scroll_container()
	if not scroll_container:
		return true  ## 如果没有ScrollContainer，默认所有项目都可见
	
	## 计算项目的全局边界矩形
	var item_global_rect = Rect2(
		item.get_global_position(),
		item.size
	)
	
	## 计算ScrollContainer的全局可见区域
	var container_global_pos = scroll_container.get_global_position()
	var viewport_rect = Rect2(
		container_global_pos,
		scroll_container.size
	)
	
	## 检查项目是否与视图范围相交
	return viewport_rect.intersects(item_global_rect)

## 获取ScrollContainer的可见区域边界
func _get_scroll_container_viewport_rect() -> Rect2:
	"""
	获取父ScrollContainer的可见区域矩形
	
	@return: ScrollContainer的可见区域矩形，如果没有ScrollContainer则返回空矩形
	"""
	var scroll_container = _get_scroll_container()
	if not scroll_container:
		return Rect2()
	
	## 计算ScrollContainer的全局可见区域
	var container_global_pos = scroll_container.get_global_position()
	return Rect2(
		container_global_pos,
		scroll_container.size
	)

func _on_scroll_container_resized() -> void:
	set_data_list(data_list)

## 处理ScrollContainer的滚动事件
func _on_scroll_container_scrolled() -> void:
	"""
	当ScrollContainer滚动时被调用，更新循环滚动布局
	
	这个方法作为信号处理器，用于在用户滚动时触发循环滚动逻辑
	仅在is_cyclable为true时执行循环滚动计算
	使用call_deferred确保滚动操作完成后再更新布局
	"""
	## 延迟一点执行，确保滚动完成后再更新布局
	call_deferred("_update_cyclic_scrolling")

## =============================================================================
## 数据管理方法
## =============================================================================
## 实现循环滚动逻辑
func _update_cyclic_scrolling() -> void:
	"""
	更新循环滚动状态
	- 重新排列子节点的位置，实现无限循环滚动
	- 根据当前滚动位置调整项目位置
	- 实现无限滚动的视觉效果
	"""
	## 调试信息
	#print("_update_cyclic_scrolling")
	
	var scroll_container = _get_scroll_container()
	if not scroll_container:
		return
	
	## 获取ScrollContainer的可见区域
	var viewport_rect = _get_scroll_container_viewport_rect()
	if viewport_rect == Rect2():
		return
	
	calculate_display_start_direction()
	
	#
	## 边界检查：如果没有可见项目，直接返回
	if _items.size() < 3:
		return
	
	## TODO
	match item_dispaly_direction:
		DisplayDirection.RightBottom:
			var item_list = []
			while _items.size()>max(1,max_items_per_row):
				if _items[max(1,max_items_per_row)].data_index >= display_start_index or _items.back().data_index + 1 >= data_list.size():
					break
				var item = _items.pop_front()
				var old_item_index = item.data_index
				if item.has_method("set_data"):
					var last_item = _items.back()
					#item.set_data(last_item.data_index + 1, data_list[last_item.data_index + 1])
					#self.item_updated.emit(item, item.data_index, data_list[item.data_index])
					print(old_item_index, " -> ", last_item.data_index + 1)
				item_list.append(item)
				queue_sort()
			_items.append_array(item_list)
			if item_list.size() == 0:
				var _item_list_size = _items.size()
				while _items.size()>max(1,max_items_per_row):
					if _items.back().data_index <= display_start_index + _item_list_size - 2 or _items.front().data_index - 1 < 0:
						break
					var item = _items.pop_back()
					var old_item_index = item.data_index
					if item.has_method("set_data"):
						var last_item = _items.front()
						#item.set_data(last_item.data_index - 1, data_list[last_item.data_index - 1])
						#self.item_updated.emit(item, item.data_index, data_list[item.data_index])
						print(old_item_index, " -> ", last_item.data_index - 1)
					item_list.push_front(item)
					queue_sort()
				_items.append_array(item_list)
		DisplayDirection.RightTop:
			pass
		DisplayDirection.LeftBottom:
			pass
		DisplayDirection.LeftTop:
			pass
		DisplayDirection.StartToEnd:
			pass
		DisplayDirection.EndToStart:
			pass
	queue_sort()
	
	## TODO 暂时没有多行多列的布局，只有单行或者单列
	#if not viewport_rect.intersects(Rect2(_items[0].global_position, _items[0].size)) and not viewport_rect.intersects(Rect2(_items[1].global_position, _items[1].size)):
		#if max_items_per_column > 0 and _items.back().data_index + 1 < data_list.size():
			##var item = _items.pop_front()
			##var last_item = _items.c()
			##item.global_position = last_item.global_position
			##item.global_position.y = last_item.global_position.y + item_spacing + item_size.y
			##_items.push_back(item)
			#var item = _items.pop_front()
			#var last_item = _items.back()
			#_items.push_back(item)
			#if item.has_method("set_data"):
				#item.set_data(last_item.data_index + 1, data_list[last_item.data_index + 1])
				### 发出item_updated信号，传递item、index和data参数
				#self.item_updated.emit(item, item.data_index, data_list[item.data_index])
			#queue_sort()
		##else:
			##var item = _items.pop_front()
			##var last_item = _items.back()
			##item.global_position = last_item.global_position
			##item.global_position = last_item.global_position + item_spacing + last_item.size.x
			##_items.push_back(item)
	##elif not viewport_rect.intersects(Rect2(_items[_items.size()-1].global_position, _items[_items.size()-1].size)) and not viewport_rect.intersects(Rect2(_items[_items.size()-2].global_position, _items[_items.size()-2].size)):
		##if max_items_per_column > 0 and _items.front().data_index - 1 > 0:
			###var item = _items.pop_back()
			###var last_item = _items.front()
			###item.global_position = last_item.global_position
			###item.global_position.y = last_item.global_position.y - item_spacing - item_size.y
			###_items.push_front(item)
			##var item = _items.pop_back()
			##var last_item = _items.front()
			##_items.push_front(item)
			##if item.has_method("set_data"):
				##item.set_data(last_item.data_index - 1, data_list[last_item.data_index - 1])
				#### 发出item_updated信号，传递item、index和data参数
				##self.item_updated.emit(item, item.data_index, data_list[item.data_index])
			##queue_sort()
		##else:
			##var item = _items.pop_back()
			##var last_item = _items.front()
			##item.global_position = last_item.global_position
			##item.global_position.x = last_item.global_position.x - item_spacing - last_item.size.x
			##_items.push_front(item)
	##
	#### 找出需要移动的项目
	##var items_to_move_down = []  ## 需要向下移动的项目（上方超出）
	##var items_to_move_up = []    ## 需要向上移动的项目（下方超出）
	##
	#### 确定哪些项目需要移动
	##for item in visible_items:
		##var item_global_rect = Rect2(item.get_global_position(), item.size)
		##
		#### 检查项目是否完全在视口上方
		##if item_global_rect.position.y + item_global_rect.size.y < viewport_rect.position.y:
			##items_to_move_down.append(item)
		#### 检查项目是否完全在视口下方
		##elif item_global_rect.position.y > viewport_rect.position.y + viewport_rect.size.y:
			##items_to_move_up.append(item)
	##
	#### 调试信息：记录需要移动的项目数量
	##print("Cyclic scrolling - Items to move down: ", items_to_move_down.size(), ", Items to move up: ", items_to_move_up.size())
	##
	#### 将上方超出的项目移动到最底部
	##for item in items_to_move_down:
		##var current_pos = item.position
		#### 计算新位置，移动到底部项目下方
		##var new_y = bottommost_y - self.get_global_position().y + vertical_offset
		##item.position = Vector2(current_pos.x, new_y)
		#### 更新底部位置
		##bottommost_y = max(bottommost_y, new_y + item.size.y)
	##
	#### 将下方超出的项目移动到最顶部
	##for item in items_to_move_up:
		##var current_pos = item.position
		#### 计算新位置，移动到顶部项目上方
		##var new_y = topmost_y - self.get_global_position().y - item.size.y - vertical_offset
		##item.position = Vector2(current_pos.x, new_y)
		#### 更新顶部位置
		##topmost_y = min(topmost_y, new_y)
	##
	#### 调试信息：记录移动后的位置
	##for i in range(items_to_move_down.size()):
		##print("Moved down item new pos:", items_to_move_down[i].position)
	##for i in range(items_to_move_up.size()):
		##print("Moved up item new pos:", items_to_move_up[i].position)
	#
	#### 如果有项目被移动，重新检查并更新视图
	##if items_to_move_down.size() > 0 or items_to_move_up.size() > 0:
		#### 避免无限循环，只执行一次调整
		#### 触发视图重绘以确保更新立即生效
	#
	#queue_redraw()

## =============================================================================
## 子节点排序回调方法
## =============================================================================
func _on_sort_children() -> void:
	"""
	处理子节点排序和布局逻辑
	
	主要职责：
	- 重新计算并调整容器大小
	- 根据display_type应用不同的布局策略
	- 在CENTERED模式下实现选中项居中布局
	- 在NORMAL模式下实现行列网格布局
	- 确保所有可见项正确排列
	- 与data_list大小保持同步的布局计算
	- 实现循环滚动功能，将超出显示范围的子节点移动到相应位置
	- 使用item_size变量作为item宽高的计算依据
	"""
	calculate_display_start_direction()
	
	## 为所有子节点设置正确的位置和大小
	var current_position := Vector2()
	
	## 根据display_type调整布局策略
	if display_type == DisplayType.NORMAL:
		## 正常显示模式 - 实现行列网格布局
		## 这是列表或网格视图的标准布局模式
		current_position = Vector2()  ## 复用之前定义的变量
		var item_width := item_size.x
		var item_height := item_size.y
		## 重要：使用data_list.size()而非_items.size()计算行列布局，与resize_container保持一致
		## 这确保了布局计算与实际数据量匹配，而不是与创建的item数量匹配
		var items_per_row: int = max_items_per_row if max_items_per_row > 0 else data_list.size()  ## 0表示不限制，使用所有数据项数
		var current_row := 0
		var current_col := 0
		
		## TODO
		match item_dispaly_direction:
			DisplayDirection.RightBottom:
				if max_items_per_row == 0:
					current_col = display_start_index - 1
				else:
					current_row = display_start_index/max_items_per_row - 1
			DisplayDirection.RightTop:
				pass
			DisplayDirection.LeftBottom:
				pass
			DisplayDirection.LeftTop:
				pass
			DisplayDirection.StartToEnd:
				pass
			DisplayDirection.EndToStart:
				pass
		
		## 安全检查：如果没有可见项目或尺寸无效，直接返回
		if item_width <= 0 or item_height <= 0:
			return
		
		### 计算实际可用空间，减去间距
		#var available_width = size.x - item_spacing * (items_per_row - 1)
		## 计算实际项目宽度，确保不会溢出
		var actual_item_width = item_width 
		var actual_item_height = item_height
		
		## 按行列布局排列项目，实现网格效果
		for i in range(_items.size()):
			var child = _items[i]
			## TODO 计算当前项目在网格中的位置，考虑间距
			current_position.x = current_col * (item_width + item_spacing if current_col > 0 else 0.0)
			current_position.y = current_row * (item_height + item_spacing if current_row > 0 else 0.0)
			
			## 设置项目位置和大小，使其填充单元格
			child.position = current_position
			
			var _is_item_need_reset_data := false
			var _new_data_index := -1
			match item_dispaly_direction:
				DisplayDirection.RightBottom:
					if max_items_per_row == 0:
						if child.data_index != current_col:
							_is_item_need_reset_data = true
							_new_data_index = current_col
					else:
						if child.data_index != current_row * max_items_per_row + current_col:
							_is_item_need_reset_data = true
							_new_data_index = current_row * max_items_per_row + current_col
				DisplayDirection.RightTop:
					pass
				DisplayDirection.LeftBottom:
					pass
				DisplayDirection.LeftTop:
					pass
				DisplayDirection.StartToEnd:
					pass
				DisplayDirection.EndToStart:
					pass
			## TODO
			if _is_item_need_reset_data and _new_data_index >= 0 and _new_data_index < data_list.size():
				child.set_data(_new_data_index, data_list[_new_data_index])
				self.item_updated.emit(child, _new_data_index, data_list[_new_data_index])
			child.visible = child.data_index >= 0 and child.data_index < data_list.size() and current_row >= 0 and current_col >= 0
			
			## TODO 确保项目大小不会小于其custom_minimum_size
			#var final_width = max(actual_item_width, child.custom_minimum_size.x)
			#var final_height = max(actual_item_height, child.custom_minimum_size.y)
			#child.size = Vector2(final_width, final_height)
			child.size = Vector2(item_width, item_height)
			#fit_child_in_rect(child, Rect2(current_position, Vector2(final_width, final_height)))
			
			## 更新行列索引，准备放置下一个项目
			current_col += 1
			if current_col >= items_per_row:
				current_col = 0
				current_row += 1
	elif display_type == DisplayType.CENTERED:
		pass
	else:
		pass
	

var _last_max_items_per_column: int = max_items_per_column
func calculate_max_item():
	## 自动计算max_items_per_column（如果启用）
	if is_auto_calculate_max_item_per_column and item_size.y > 0 and max_items_per_row > 0:
		## 根据容器高度、项目高度和行数计算每列的最大项目数
		var container_height = _get_scroll_container().size.y
		var calculated_columns = ceil((container_height + item_spacing) / (item_size.y + item_spacing))
		## 确保至少有1列
		calculated_columns = max(0, calculated_columns)
		## 考虑max_items_per_row的影响，根据实际需求调整计算逻辑
		## 这里的逻辑是：容器高度除以项目高度得到可容纳的行数
		## 根据设计需求可能需要进一步调整
		max_items_per_column = calculated_columns
	if not _last_max_items_per_column == max_items_per_column:
		_last_max_items_per_column = max_items_per_column
		resize_container()

## item 的排序方向
enum DisplayDirection {
	RightBottom
	,RightTop
	,LeftBottom
	,LeftTop
	,StartToEnd
	,EndToStart
}
@export var item_dispaly_direction = DisplayDirection.RightBottom				## TODO 排序方向
func calculate_display_start_direction():
	var offset = -position
	match item_dispaly_direction:
		DisplayDirection.RightBottom:
			if max_items_per_row == 0:
				display_start_index = (offset.x + item_spacing)/(item_size.x + item_spacing)
			else:
				display_start_index = (offset.y + item_spacing)/(item_size.y + item_spacing)
		DisplayDirection.RightTop:
			pass
		DisplayDirection.LeftBottom:
			pass
		DisplayDirection.LeftTop:
			pass
		DisplayDirection.StartToEnd:
			pass
		DisplayDirection.EndToStart:
			pass
	pass

## =============================================================================
## 调整容器大小
## =============================================================================
## 
## 功能：
##   - 根据子节点的大小和布局模式重新计算容器的最小尺寸
##   - 支持不同显示模式下的尺寸计算策略
##   - 考虑行列布局下的网格排列需求
func resize_container() -> void:
	"""
	重新计算并设置容器的最小尺寸
	
	计算策略：
	- CENTERED模式：预留足够空间显示当前项及其两侧项
	- NORMAL模式：根据数据列表大小和行列布局计算网格所需的最小空间
	- 基于data_list大小计算容器尺寸，确保容器能够完全容纳所有数据项
	- 优先使用item_size变量作为计算依据
	"""
	var min_width := 0.0
	var min_height := 0.0
	
	## 快速路径：如果没有数据项，直接返回
	if data_list.size() == 0:
		return
	
	## 正常模式 - 根据data_list大小和行列布局计算网格所需尺寸
	var max_item_width := 0.0  ## 所有项目的最大宽度
	var max_item_height := 0.0 ## 所有项目的最大高度
	
	## 优先使用item_size变量，如果为(0,0)则根据子节点自动计算
	if item_size.x > 0:
		max_item_width = item_size.x
	else:
		## 计算项目的最大尺寸（从现有item中获取参考尺寸）
		for item in _items:
			if item and item.visible:
				## 同时考虑当前size和custom_minimum_size，取较大值
				max_item_width = max(max_item_width, max(item.size.x, item.custom_minimum_size.x))
	
	if item_size.y > 0:
		max_item_height = item_size.y
	else:
		## 计算项目的最大尺寸（从现有item中获取参考尺寸）
		for item in _items:
			if item and item.visible:
				## 同时考虑当前size和custom_minimum_size，取较大值
				max_item_height = max(max_item_height, max(item.size.y, item.custom_minimum_size.y))
	
	## 至少需要有一个参考尺寸
	if max_item_width > 0 and max_item_height > 0:
		## 计算实际使用的行列数
		## 重要：基于data_list.size()而不是可见项数量计算容器大小
		var items_per_row = max_items_per_row if max_items_per_row > 0 else data_list.size()  ## 0表示不限制，使用所有数据项数
		var rows = ceil(float(data_list.size()) / items_per_row)  ## 所需的行数，基于数据列表大小
		
		## 计算容器最小尺寸，考虑间距
		min_width = max_item_width * items_per_row + item_spacing * (items_per_row - 1)  ## 宽度 = 项目宽度×列数 + 间距×(列数-1)
		min_height = max_item_height * rows + item_spacing * (rows - 1)  ## 高度 = 项目高度×行数 + 间距×(行数-1)
	
	## 设置容器的最小尺寸
	self.custom_minimum_size = Vector2(min_width, min_height)
	
	## 同时设置容器的实际尺寸，确保有足够空间容纳所有项目
	if size.x < min_width or size.y < min_height:
		size = Vector2(max(size.x, min_width), max(size.y, min_height))
	custom_minimum_size = size

## =============================================================================
## 辅助方法
## =============================================================================
## 当设置发生变化时，请求重新排序子节点
func set_some_setting():
	## 某些设置已更改，请求重新排序子节点
	queue_sort()

## =============================================================================
## 公共方法
## =============================================================================
## 设置item_scene
## 设置项目场景
## @param scene 要设置的项目场景资源或节点
## @description: 允许从外部设置用于创建列表项的场景资源或节点
## @注意：支持PackedScene或Node类型，设置后会立即生效，下次创建item时将使用新的scene
func set_item_scene(scene: Variant) -> void:
	"""
	设置项目场景
	- 支持PackedScene和Node类型
	- 提供类型检查和错误处理
	"""
	## 进行类型检查
	if typeof(scene) == TYPE_OBJECT and (scene is PackedScene or scene is Node):
		item_scene = scene
		## 发出场景变更信号
		if has_signal("item_scene_changed"):
			self.item_scene_changed.emit()
	else:
		print("警告: set_item_scene接收到无效类型，期望PackedScene或Node")

## =============================================================================
## 缓存管理相关方法
## =============================================================================
## 设置缓存键
## @param key 用于缓存item的键名
func set_item_cache_key(key: String) -> void:
	"""
	设置缓存键
	- 用于从缓存池获取和存储item的标识
	- 允许不同的CyclableContainer实例使用不同的缓存池分区
	- 自定义键名需要确保唯一性，避免缓存冲突
	
	@param key: 自定义的缓存键名，必须非空且有效
	"""
	if key and key.length() > 0:
		_item_cache_key = key

## 生成并设置item缓存键（内部方法）
func _set_item_cache_key() -> void:
	"""
	生成并设置item缓存键
	- 参考WindowManager的_generate_window_id方法实现
	- 基于组件名称、场景路径和时间戳生成唯一键
	- 确保不同实例使用不同的缓存键，避免缓存冲突
	"""
	## 获取组件名称（默认名称或自定义名称）
	var component_name = name
	if component_name == "":
		component_name = "CyclableContainer"
	
	## 获取时间戳和随机后缀
	var timestamp = Time.get_unix_time_from_system()
	var random_suffix = randi() % 10000
	
	## 生成基础缓存键
	var base_key = "%s_item_%d_%04d" % [component_name, timestamp, random_suffix]
	
	## 设置缓存键
	_item_cache_key = base_key
	print("CyclableContainer: 已生成缓存键: ", _item_cache_key)

## =============================================================================
## 数据管理相关方法
## =============================================================================
## 设置数据列表
## =============================================================================
## 数据列表管理
## =============================================================================
func set_data_list(new_data: Array) -> void:
	"""
	设置数据列表并创建/复用列表项
	
	功能说明：
	- 清空现有列表项并设置新的数据列表
	- 优先从缓存池获取item以优化性能，减少内存分配和GC压力
	- 基于max_items_per_row和max_items_per_column计算需要创建的item数量
	- 支持从PackedScene或Node类型的模板创建item
	- 处理item创建后的初始化和位置设置
	- 发出data_list_updated信号通知数据更新
	- 自动处理空数据列表情况
	
	参数：
	@param new_data: 新的数据列表数组，支持任何数据类型
	
	返回值：
	@return: 无
	
	信号：
	- 执行过程中会发出item_created信号
	- 执行完成后会发出data_list_updated信号
	"""
	
	calculate_max_item()
	
	## 清空现有列表项
	_clear_items()
	
	## 保存新的数据列表
	data_list = new_data
	
	
	## 创建新的列表项 - 根据数据列表创建item
	_items = []
	
	#if _get_scroll_container().size.x == 0 or _get_scroll_container().size.y == 0:
		#call_deferred("set_data_list", data_list)
		#return
		
	## 检查item_scene是否已设置
	if item_scene:
		## 计算需要创建的item数量
		var create_count = 0
		if data_list.size() > 0:
			## 使用数据列表的实际大小 + 2
			create_count = (max(1,max_items_per_row) * max(1,max_items_per_column)) + 2
		
		## 创建固定数量的item scene
		for i in range(create_count):
			var item = null
			
			## 首先尝试从缓存池获取item
			if CachePoolManager and CachePoolManager.has_method("get_cached_object_by_type"):
				item = CachePoolManager.get_cached_object_by_type(_item_cache_key)
				print("CyclableContainer: 尝试从缓存池获取item: ", item)
					
				## 如果缓存池中没有可用item，则创建新item
				if item == null:
					## 根据item_scene的类型进行不同的处理
					match typeof(item_scene):
						TYPE_OBJECT:
							if item_scene is PackedScene:
								## 如果是PackedScene类型，使用instantiate方法创建
								item = item_scene.instantiate()
							elif item_scene is Node:
								## 如果是Node类型，使用duplicate方法创建副本
								## 无论节点是否在场景树中，我们都复制它以避免多次使用同一个节点
								item = item_scene.duplicate()
							else:
								print("警告: item_scene不是有效的PackedScene或Node对象")
						_:
							print("警告: item_scene类型无效: ", typeof(item_scene))
				
				## 检查是否成功获取/创建了item
				if item is Node:
					## 添加到容器
					add_child(item)
					_items.append(item)
					
					## 如果是Control类型，连接点击信号
					if item is Control and item.has_signal("pressed"):
						## 确保信号只连接一次
						if not item.is_connected("pressed", _on_item_pressed.bind(item)):
							item.connect("pressed", _on_item_pressed.bind(item))
					
					## 发出项目创建信号
					self.item_created.emit(item, i)
				else:
					print("警告: 获取/创建item失败，无法继续")
					break  ## 如果失败，停止继续
	
	## 自动选中第一个项
	if data_list.size() > 0:
		selected_index = 0
		set_selected_index(0)
	else:
		selected_index = -1
	
	calculate_display_start_direction()
	
	## 更新可见的item数据 - 实现滚动更新机制的核心
	_update_visible_items()
	
	## 更新显示
	_update_display()
	
	queue_sort()
	
	## 发出数据列表更新信号
	self.data_list_updated.emit(data_list)

## =============================================================================
## 缓存管理方法
## =============================================================================
## 清空列表项（私有方法）
func _clear_items() -> void:
	"""
	清空列表项并将item放入缓存池而非销毁
	
	功能说明：
	- 遍历所有已创建的列表项，执行清理操作
	- 对每个item发出item_deleted信号通知删除事件
	- 从场景树中移除item节点
	- 根据是否存在缓存池管理器决定item的处理方式
	- 调用_reset_item_for_cache方法重置item状态，确保可复用
	
	参数：
	@param: 无
	
	返回值：
	@return: 无
	
	信号：
	- 对每个被删除的item发出item_deleted信号
	
	处理逻辑：
	1. 发出删除信号
	2. 从场景树移除item
	3. 重置item状态
	4. 根据缓存池可用性决定item的最终处理
	"""
	for i in range(_items.size()):
		var item = _items[i]
		if item:
			## 发出项目删除信号
			self.item_deleted.emit(item, i)
			
			if item.is_inside_tree():
				remove_child(item)
			
			## 尝试将item放入缓存池
			if Engine.has_singleton("CachePoolManager"):
				var cache_pool_manager = Engine.get_singleton("CachePoolManager")
				if cache_pool_manager and cache_pool_manager.has_method("cache_object_by_type"):
					## 确保item在放入缓存池前重置到初始状态
					_reset_item_for_cache(item)
					## 将item存储到缓存池，使用_item_cache_key作为类型名
					cache_pool_manager.cache_object_by_type(_item_cache_key, item)
					print("CyclableContainer: 已将item放入缓存池: ", _item_cache_key)
	
	## 清空_items数组
	_items.clear()

## 重置item到缓存状态
## =============================================================================
## 缓存准备方法
## =============================================================================
func _reset_item_for_cache(item: Node) -> void:
	"""
	重置item状态以便缓存和复用
	
	功能说明：
	- 在将item放入缓存池前，重置其状态以便下次复用
	- 清除临时数据和状态，确保item处于干净的初始状态
	- 重置视觉属性，避免残留的UI状态
	- 处理不同类型节点的特定重置需求
	- 支持自定义reset方法的调用，实现扩展功能
	
	参数：
	@param item: 要重置的item节点，通常是Control类型或其子类
	
	返回值：
	@return: 无
	
	处理逻辑：
	1. 检查item是否为Control类型
	2. 重置位置到原点(0,0)
	3. 确保可见性为true
	4. 清除data_index元数据
	5. 特殊处理Button类型，重置pressed状态
	6. 如果item实现了reset方法，则调用它（支持自定义重置逻辑）
	"""
	if item is Control:
		## 重置位置和可见性
		item.position = Vector2()
		item.visible = true
		## 清除自定义元数据
		item.remove_meta("data_index")
		## 如果是Button，重置选中状态
		if item is Button:
			item.pressed = false
		## 如果item实现了reset方法，调用它
		if item.has_method("reset"):
			item.reset()

## 设置选中索引
## @param index 要选中的项目索引
## @description: 设置当前选中的项目索引，并处理循环逻辑和边界情况
## @注意：调用此方法会触发_update_visible_items更新item数据，实现滚动效果
func set_selected_index(index: int) -> void:
	if data_list.size() == 0:
		return
	
	## 处理循环逻辑
	if is_cyclable:
		## 循环模式：索引小于0时选择最后一个，大于等于列表长度时选择第一个
		if index < 0:
			index = data_list.size() - 1
		elif index >= data_list.size():
			index = 0
	else:
		## 非循环模式下，限制索引范围在有效范围内
		index = clamp(index, 0, data_list.size() - 1)
	
	## 检查索引是否真的发生变化
	if selected_index != index:
		## 保存旧值用于比较
		var old_index = selected_index
		var old_item = null
		if old_index >= 0 and old_index < data_list.size():
			old_item = data_list[old_index]
		
		selected_index = index
		
		## 更新可见的item数据 - 实现滚动更新机制的关键
		_update_visible_items()
		
		## 更新UI状态
		_update_selected_state()


## 更新选中状态（私有方法）
## @description: 根据当前选中索引更新所有可见item的选中状态和样式
## @注意：此方法会根据可见范围计算每个item对应的实际数据索引，确保正确的选中状态
func _update_selected_state() -> void:
	## 检查是否有项目和数据
	if _items.size() == 0 or data_list.size() == 0:
		return
	
	## 获取当前可见范围
	var visible_range = _get_visible_range()
	
	## 遍历所有创建的item，更新选中状态
	for i in range(_items.size()):
		var item = _items[i]
		if item is Control and item.visible:
			## 计算这个item对应的实际数据索引
			var data_index = visible_range.start + i
			
			if item is Button:
				## 设置按钮的选中状态
				item.pressed = (data_index == selected_index)
				## 根据选中状态设置不同的样式
				if data_index == selected_index:
					item.add_theme_color_override("font_color", Color(1, 1, 1, 1))  ## 白色文字
					item.add_theme_color_override("bg_color", Color(0.2, 0.6, 1, 1))  ## 蓝色背景
				else:
					item.add_theme_color_override("font_color", Color(0, 0, 0, 1))  ## 黑色文字
					item.add_theme_color_override("bg_color", Color(0.9, 0.9, 0.9, 1))  ## 灰色背景
			elif item is Control:
				## 对于非Button类型的Control，使用自定义的set_selected方法（如果有）
				if item.has_method("set_selected"):
					item.set_selected(data_index == selected_index)
				else:
					## 为没有set_selected方法的Control提供默认处理
## 可以在这里添加默认的样式处理
					pass
				## 设置焦点到选中项
				if data_index == selected_index:
					item.grab_focus()
	
	## 发出选中状态变化信号
	## 获取选中的数据和项目节点
	var selected_data = get_selected_item()
	var selected_node = null
	
	# TODO
	## 查找对应的项目节点
	if selected_index >= 0 and selected_index < _items.size():
		selected_node = _items[selected_index]
	
	## 发出整合后的选中项变化信号
	self.selected_item_changed.emit(selected_index, selected_data, selected_node)
	
	## 请求重新排序子节点以更新布局
	queue_sort()
	
	## 滚动到选中项
	_scroll_to_selected()

## 更新可见的item数据（私有方法）
## @description: 根据当前显示起始索引和可见范围，动态更新现有item的数据和状态
## @核心功能：实现滚动更新机制，只更新可见范围内的item数据，提高性能
## @注意：
##   1. 信号绑定已移至item创建时，不再在此处重复绑定
##   2. 会为每个item设置meta数据"data_index"，用于点击事件处理
##   3. 根据display_type采用不同的数据索引计算方式
##   4. 自动处理数据索引越界情况，隐藏超出范围的item
func _update_visible_items() -> void:
	## 检查是否有项目和数据
	if _items.size() == 0 or data_list.size() == 0:
		return
	
	## 遍历创建的item，更新它们的数据
	for i in range(_items.size()):
		var item = _items[i]
		if item is Control:
			## 计算实际的数据索引
			## 基础计算：起始索引 + 当前item在列表中的索引
			var data_index = display_start_index + i
			
			## CENTERED模式下的特殊处理：计算居中显示的数据索引
			## 公式：(_items.size() + display_start_index + i - 中间偏移量) % _items.size()
			## 确保选中项始终居中显示，其他项围绕其排列
			if display_type == DisplayType.CENTERED:
				## 计算中间偏移量，基于最大行列数
				var center_offset = int(max(max_items_per_row, max_items_per_column) / 2)
				data_index = (_items.size() + display_start_index + i - center_offset) % _items.size()
			
			## 存储数据索引到item的自定义数据属性，供_on_item_pressed使用
			item.set_meta("data_index", data_index)
			
			## 检查数据索引是否有效
			if data_index >= 0 and data_index < data_list.size():
				## 设置数据到item - 要求item实现set_data方法
				if item.has_method("set_data"):
					item.set_data(data_index, data_list[data_index])
					## 发出item_updated信号，传递item、index和data参数
					self.item_updated.emit(item, data_index, data_list[data_index])
				## 设置item可见
				item.visible = true
			else:
				## 超出数据范围的item隐藏
				item.visible = false
	
	## 数据更新后，请求重新排序子节点以更新布局
	queue_sort()

## 当item被点击时的回调
## @param item 被点击的项目节点自身
## @description: 处理item的点击事件，获取item的data_index并将其设置为选中状态
func _on_item_pressed(item: Control) -> void:
	## 从item的meta数据中获取data_index
	var data_index = item.get_meta("data_index", -1)
	## 检查data_index是否有效
	if data_index >= 0 and data_index < data_list.size():
		## 设置选中项
		set_selected_index(data_index)


## =============================================================================
## 辅助方法：获取父ScrollContainer
## =============================================================================
func _get_scroll_container() -> ScrollContainer:
	## 遍历父节点，查找ScrollContainer
	var parent = get_parent()
	while parent != null:
		if parent is ScrollContainer:
			return parent
		parent = parent.get_parent()
	return null

## 获取当前选中的项
## @return 当前选中项的数据，如果没有选中项则返回null
func get_selected_item() -> Variant:
	if selected_index >= 0 and selected_index < data_list.size():
		return data_list[selected_index]
	return null

## 更新显示（私有方法）
func _update_display() -> void:
	if data_list.size() == 0:
		return
	
	## 根据display_type调整显示逻辑
	if display_type == DisplayType.CENTERED:
		_update_centered_display()
	else:
		_update_normal_display()

## 更新居中显示模式（私有方法）
func _update_centered_display() -> void:
	## 使用_get_visible_range计算可见范围，保持与NORMAL模式一致的逻辑
	var visible_range = _get_visible_range()
	
	## 更新每个项目的位置和可见性
	for i in range(_items.size()):
		var item = _items[i]
		if item is Control:
			## 根据项目是否在可见范围内设置可见性
			item.visible = (i >= visible_range.start && i <= visible_range.end)
			#if item.visible:
				## 对于可见的项目，设置适当的大小标志
				#if i == selected_index:
					### 选中项居中并完全填充
					#item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
					#item.size_flags_vertical = Control.SIZE_EXPAND_FILL
				#else:
					### 其他可见项也填充，但可能会根据布局调整
					#item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
					#item.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	## 滚动到选中项
	_scroll_to_selected()

## 更新正常显示模式（私有方法）
func _update_normal_display() -> void:
	## 根据max_item控制显示的项目数量
	var visible_range = _get_visible_range()
	#for i in range(_items.size()):
		#var item = _items[i]
		#if item is Control:
			### 只显示在可见范围内的项目
			#item.visible = (i >= visible_range.start && i <= visible_range.end)
			#if item.visible:
				#item.size_flags_horizontal = Control.SIZE_EXPAND_FILL

## 滚动到选中项（私有方法）
## 修改：移除直接移动子节点的代码，通过queue_sort和on_sort_children实现布局管理
func _scroll_to_selected() -> void:
	## 如果正在拖拽中，不执行自动滚动操作
	if _is_dragging:
		return
	
	if selected_index >= 0 and selected_index < _items.size():
		var selected_item = _items[selected_index]
		if is_inside_tree() and selected_item.is_inside_tree():
			## 根据display_type调整滚动行为
			if display_type == DisplayType.CENTERED:
				## 已通过queue_sort和on_sort_children实现布局
				## 这里只处理与ScrollContainer相关的滚动逻辑
				var scroll_container = _get_scroll_container()
				if scroll_container:
					## 确保容器和项目大小已正确设置
					if self.size.x > 0 and selected_item.size.x > 0:
						## 计算滚动位置使选中项居中
						var container_size = self.size.x
						var item_size = selected_item.size.x
						var item_position = selected_item.get_position().x
						var scroll_offset = item_position + (item_size / 2) - (container_size / 2)
						## 限制滚动偏移在有效范围内
						scroll_offset = clamp(scroll_offset, 0, scroll_container.get_h_scrollbar().max_value)
						scroll_container.scroll_horizontal = scroll_offset
			else:
				## NORMAL模式也需要确保选中项可见
				var scroll_container = _get_scroll_container()
				if scroll_container:
					## 计算项目的全局位置
					var item_global_pos = selected_item.get_global_position()
					var container_global_pos = scroll_container.get_global_position()
					var viewport_rect = Rect2(container_global_pos, scroll_container.size)
					
					## 如果项目不在可视区域内，滚动到项目位置
					if not viewport_rect.encloses(selected_item.get_rect()):
						## 计算滚动偏移
						var scroll_offset = scroll_container.scroll_vertical + \
							(item_global_pos.y - container_global_pos.y) - \
							(scroll_container.size.y / 2 - selected_item.size.y / 2)
						## 限制滚动偏移在有效范围内
						scroll_offset = clamp(scroll_offset, 0, scroll_container.get_v_scroll_bar().max_value)
						scroll_container.scroll_vertical = scroll_offset

## 切换到下一个项目
func next_item() -> void:
	if data_list.size() > 0 and selected_index + 1 <= data_list.size():
		var next_index = selected_index + 1
		set_selected_index(next_index)

## 切换到上一个项目
func previous_item() -> void:
	if data_list.size() > 0 and selected_index - 1 >= 0:
		var prev_index = selected_index - 1
		set_selected_index(prev_index)


## =============================================================================
## 私有方法 - 可见范围管理
## =============================================================================
## 获取当前可见的项目索引范围
## 
## @description: 根据显示模式和布局设置计算实际可见的项目范围
## @return: 返回包含start和end索引的字典，代表可见项目的范围
## @note: 行列布局模式下，会根据max_items_per_row和max_items_per_column计算实际可见数量
func _get_visible_range() -> Dictionary:
	var start = 0
	var end = max(0, data_list.size() - 1)  ## 确保end至少为0（当列表为空时）
	
	## 根据display_type调整可见范围
	if display_type == DisplayType.NORMAL:
		## 计算实际显示的项目数量，考虑行列布局
		var items_per_row = max_items_per_row if max_items_per_row > 0 else _items.size()  # 每行项目数，0表示不限制
		var items_per_column = max_items_per_column if max_items_per_column > 0 else _items.size()  # 每列项目数，0表示不限制
		
		## 计算实际最大可见项目数
		var actual_max_items = 0
		if items_per_row > 0 and items_per_column > 0:
			actual_max_items = items_per_row * items_per_column
		elif items_per_row > 0:
			actual_max_items = items_per_row * 3  # 默认显示3行
		elif items_per_column > 0:
			actual_max_items = items_per_column  # 单列情况下，使用每列限制
		else:
			actual_max_items = data_list.size()  # 都为0时，使用数据列表的实际大小
		
		## 在NORMAL模式下，根据实际最大项目数限制可见数量
		if actual_max_items > 0 and data_list.size() > actual_max_items:
			## 确保选中项在可见范围内
			if selected_index >= 0:
				## 计算以选中项为中心的可见范围
				var half_max = floor(actual_max_items / 2)
				start = selected_index - half_max
				end = selected_index + half_max - (1 if actual_max_items % 2 == 0 else 0)  # 调整使总数正确
				
				## 如果范围超出边界，进行调整
				if start < 0:
					start = 0
					end = min(actual_max_items - 1, data_list.size() - 1)
				elif end >= data_list.size():
					end = data_list.size() - 1
					start = max(end - actual_max_items + 1, 0)
			else:
				## 没有选中项时，显示前actual_max_items个项目
				end = min(actual_max_items - 1, data_list.size() - 1)
		
	elif display_type == DisplayType.CENTERED:
		## 在CENTERED模式下，默认只显示当前项及其前后各一项
		if selected_index >= 0:
			start = max(0, selected_index - 1)
			end = min(data_list.size() - 1, selected_index + 1)
		
		## 如果启用了循环，始终显示全部项目
		if is_cyclable:
			start = 0
			end = data_list.size() - 1
	
	## 确保范围有效
	start = max(0, start)
	end = min(end, data_list.size() - 1)
	
	return {
		"start": start,
		"end": end
	}
	
func update_container_position(offset_vector: Vector2):
	if not offset_vector: return
	# TODO
	
func _process_touch_click(touch_position: Vector2) -> void:
	# TODO
	print("item container _process_touch_click")
	pass
