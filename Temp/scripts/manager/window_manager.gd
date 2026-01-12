# 窗口管理器 - WindowManager
# 厨房管理系统的核心UI组件，负责窗口的创建、管理、缓存和状态控制
# 提供完整的窗口生命周期管理和层级系统
#
# @class WindowManager
# @extends Node
# @description 统一管理应用程序中所有窗口的创建、显示、隐藏、销毁和缓存
#
# ## 设计理念
# - **集中管理**：所有窗口操作通过统一接口进行，确保窗口状态一致性
# - **层级系统**：支持多窗口层级，实现弹窗、对话框等不同类型窗口的管理
# - **窗口缓存**：提供窗口实例缓存机制，提高常用窗口的打开速度
# - **事件驱动**：通过信号系统通知窗口状态变化，便于其他组件响应
# - **与BaseWindow协同**：设计为与BaseWindow基类配合使用，提供完整窗口功能
#
# ## 类用法说明
# 1. **初始化**：在场景中添加WindowManager节点，通常作为根节点的子节点
# 2. **注册窗口层级**：使用`set_window_layer`方法设置不同层级的窗口容器
# 3. **打开窗口**：调用`open_window`方法打开新窗口
# 4. **管理窗口**：使用`close_window`、`minimize_window`等方法管理窗口状态
# 5. **响应事件**：连接`window_opened`、`window_closed`等信号以响应窗口事件
# 6. **与BaseWindow配合**：通常与BaseWindow类一起使用，实现完整的窗口系统
#
# ## 主要功能和方法
# - **open_window(window_scene_path, window_id, properties)**：打开指定场景的窗口
# - **close_window(window_or_id)**：关闭指定窗口
# - **close_all_windows()**：关闭所有打开的窗口
# - **activate_window(window_or_id)**：激活指定窗口
# - **minimize_window(window_or_id)**：最小化指定窗口
# - **restore_window(window_or_id)**：恢复指定窗口
# - **set_window_layer(layer_name, container)**：设置窗口层级容器
#
# ## 状态查询方法
# - **get_active_window()**：获取当前活动窗口
# - **get_all_windows()**：获取所有打开的窗口
# - **get_windows_in_layer(layer_name)**：获取指定层级的所有窗口
# - **is_window_open(window_or_id)**：检查窗口是否已打开
# - **clear_cache(scene_path)**：清理窗口缓存
#
# ## 信号说明
# - **window_opened(window)**：窗口打开时触发
# - **window_closed(window)**：窗口关闭时触发
# - **active_window_changed(active_window, previous_window)**：当前活动窗口改变时触发
#
# ## 使用示例
# ```gdscript
# # 获取窗口管理器实例
# var window_manager = get_node("/root/WindowManager")
# 
# # 设置窗口层级
# window_manager.set_window_layer("normal", $NormalWindows)
# window_manager.set_window_layer("dialog", $DialogWindows)
# 
# # 打开窗口
# var window = window_manager.open_window(
#     "res://scenes/windows/ExampleWindow.tscn",
#     "example_window",
#     {"title": "示例窗口", "size": Vector2(800, 600)}
# )
# 
# # 连接窗口信号
# window_manager.connect("window_opened", self, "_on_window_opened")
# window_manager.connect("window_closed", self, "_on_window_closed")
# 
# # 关闭窗口
# window_manager.close_window(window)
# 
# # 检查窗口状态
# if window_manager.is_window_open("example_window"):
#     print("窗口已打开")
# ```
extends Node

# 信号定义
signal window_opened(window: Object)
	# 窗口打开并添加到场景树后触发
	# @param window 打开的窗口实例
signal window_closed(window: Object)
	# 窗口从场景树移除前触发
	# @param window 关闭的窗口实例
signal active_window_changed(active_window: Object, previous_window: Object)
	# 当前活动窗口改变时触发
	# @param active_window 新的活动窗口
	# @param previous_window 之前的活动窗口（如果有）

# 内部变量
var _resource_manager: ResourceManager = null
	# 资源管理器实例
	# 用于通过资源名称获取场景路径
var _cache_pool_manager: CachePoolManager = null
	# 缓存池管理器实例
	# 用于管理窗口缓存
var _windows: Dictionary = {}
	# 存储所有打开的窗口信息字典
	# 格式: {窗口ID: {"window": 窗口实例, "cacheable": 是否可缓存, "scene_path": 场景路径}}
var _window_layers: Dictionary = {}
	# 窗口层级容器映射字典
	# 格式: {层级名称: 容器节点}
	# 支持不同类型窗口在不同层级显示（如普通窗口、对话框、提示框等）
var _active_window: Object = null
	# 当前活动窗口引用
	# 指向用户当前正在交互的窗口
var _window_stack: Array = []
	# 窗口栈，管理窗口的显示顺序
	# 栈顶元素为最上层窗口，栈底为最底层窗口

# 初始化窗口管理器
# 当管理器进入场景树时调用
# @description 完成窗口管理器的基础初始化工作，包括获取必要的管理器引用、初始化窗口层级
# @private
func _ready() -> void:
	# 获取资源管理器实例
	_resource_manager = get_node("/root/ResourceManager")
	
	# 获取缓存池管理器实例
	_cache_pool_manager = get_node("/root/CachePoolManager")
	
	# 初始化窗口层级容器
	# 根据Main场景结构注册窗口层级
	_setup_window_layers()
	
	# 连接必要的信号
	pass
	
# 每帧更新
# @param delta 帧间隔时间（秒）
# @description 在物理帧更新中执行必要的操作，目前缓存清理由CachePoolManager自动处理
# @private
func _physics_process(delta: float) -> void:
	# 缓存清理由CachePoolManager自动处理
	pass

# 设置窗口层级容器
# @description 根据Main场景的层级结构自动注册窗口层级，支持多种窗口层级类型
# @private
func _setup_window_layers() -> void:
	# 尝试获取Main场景中的窗口层级容器
	if has_node("/root/Main/CanvasLayer/Control"):
		var control = get_node("/root/Main/CanvasLayer/Control")
		
		# 注册BottomWindowLayer - 用于底部窗口
		if control.has_node("BottomWindowLayer"):
			set_window_layer("bottom", control.get_node("BottomWindowLayer"))
		
		# 注册MiddleWindowLayer - 用于普通窗口
		if control.has_node("MiddleWindowLayer"):
			set_window_layer("normal", control.get_node("MiddleWindowLayer"))
		
		# 注册TopWindowLayer - 用于顶层窗口
		if control.has_node("TopWindowLayer"):
			set_window_layer("top", control.get_node("TopWindowLayer"))
		
		# 注册TipsWindowLayer - 用于提示窗口
		if control.has_node("TipsWindowLayer"):
			set_window_layer("tips", control.get_node("TipsWindowLayer"))
		
		print("WindowManager: 已注册窗口层级")
	else:
		print("WindowManager: 未找到Control容器，无法注册窗口层级")

# 打开窗口
# @param window_identifier 窗口场景路径或场景名称（对应ResourceManager.SCENES中的键）
# @param properties 窗口属性字典，将应用到窗口实例
#                   可包含window_id字段指定窗口ID，如不提供则自动生成
#                   可包含window_layer字段指定窗口层级，如不指定则使用默认层级
#                   可包含cacheable字段控制窗口是否可缓存，默认为true
#                   可包含always_cache字段控制窗口是否永久缓存，默认为false
#                   可包含init_settings字段用于窗口初始化设置，将在窗口打开前传递给init_window_settings方法
# @return 打开的窗口实例，如果打开失败则返回null
# @description 创建并显示新窗口，或复用已存在的窗口实例
func open_window(window_identifier: String, properties: Dictionary = {}) -> Object:
	# 获取实际的场景路径
	var window_scene_path: String
	if window_identifier.begins_with("res://"):
		# 如果是完整路径，直接使用
		window_scene_path = window_identifier
	else:
		# 如果是场景名称，通过资源管理器获取路径
		if _resource_manager:
			var scene = _resource_manager.load_scene(window_identifier)
			if scene:
				window_scene_path = _resource_manager.SCENES[window_identifier]
			else:
				push_error("WindowManager: Scene '" + window_identifier + "' not found in ResourceManager")
				return null
		else:
			push_error("WindowManager: ResourceManager not initialized")
			return null
	
	# 从properties中获取window_id，如果未提供则生成唯一ID
	var window_id: String = properties.get("window_id", "")
	if window_id.is_empty():
		window_id = _generate_window_id(window_scene_path)
	
	# 检查是否已有相同ID的窗口打开，如果有则激活它
	if window_id in _windows:
		activate_window(window_id)
		return _windows[window_id]["window"]
	
	# 从properties中获取cacheable和always_cache参数，默认值分别为true和false
	var cacheable: bool = properties.get("cacheable", true)
	var always_cache: bool = properties.get("always_cache", false)
	
	# 检查缓存中是否有可用的窗口实例（只有当窗口可缓存时才从缓存获取）
	var window = null
	if cacheable:
		window = _get_cached_window(window_scene_path)
	
	# 如果没有缓存的实例，使用资源管理器实例化新窗口
	if window == null:
		if _resource_manager:
			window = _resource_manager.instantiate_scene(window_identifier)
			if window:
				# 设置窗口属性
				for key in properties:
					# 跳过window_layer，因为它是用于窗口管理器内部的
					if key == "window_layer":
						continue
					if window.has_method("set_" + key):
						window.call("set_" + key, properties[key])
					elif window.has(key):
						window[key] = properties[key]
	
	# 记录窗口信息（实际实现中需要存储cacheable标志）
	if window != null:
		# 获取窗口层级，默认为normal（对应MiddleWindowLayer）
		var window_layer: String = properties.get("window_layer", "normal")
		
		# 存储窗口ID与实例的映射，以及是否可缓存和是否永久缓存的标志
		_windows[window_id] = {
			"window": window,
			"cacheable": cacheable,
			"always_cache": always_cache,  # 是否永久缓存，不受超时影响
			"scene_path": window_scene_path,
			"layer": window_layer  # 保存窗口所在层级
		}
		
		# 将窗口添加到指定层级的容器中
		var target_container: Node = null
		
		# 检查指定的层级是否存在
		if window_layer in _window_layers:
			target_container = _window_layers[window_layer]
		else:
			# 如果指定层级不存在，使用默认层级
			print("WindowManager: 指定层级'" + window_layer + "'不存在，使用默认层级'normal'")
			window_layer = "normal"
			if "normal" in _window_layers:
				target_container = _window_layers["normal"]
		
		# 将窗口添加到目标容器
		if target_container:
			target_container.add_child(window)
		
		# 添加到窗口栈并激活
			_window_stack.append(window)
			activate_window(window)
			
			# 在窗口打开前调用init_window_settings进行初始化
			if window.has_method("init_window_settings"):
				var init_settings = properties.get("init_settings", {})
				window.init_window_settings(init_settings)
			
			# 发送窗口打开信号
			window.open()
			self.emit_signal("window_opened", window)
	
	return window

# 关闭窗口
# @param window_or_id 窗口实例或窗口ID
# @description 关闭指定窗口，处理窗口状态变更和资源管理
# @details 根据窗口的可缓存属性决定是缓存窗口实例还是直接销毁它
# @public
func close_window(window_or_id: Variant) -> void:
	# 获取窗口ID和信息
	var window_id = ""
	var window_info = null
	
	# 通过ID或实例查找窗口
	if typeof(window_or_id) == TYPE_STRING:
		window_id = window_or_id
		if window_id in _windows:
			window_info = _windows[window_id]
	elif window_or_id is Object:
		for id in _windows:
			if _windows[id]["window"] == window_or_id:
				window_id = id
				window_info = _windows[id]
				break
	
	# 如果找不到窗口，直接返回
	if window_info == null:
		return
	
	var window = window_info["window"]
	var cacheable = window_info["cacheable"]
	var scene_path = window_info["scene_path"]
	
	# 发送窗口关闭信号
	self.emit_signal("window_closed", window)
	
	# 从窗口栈移除
	_window_stack.erase(window)
	
	# 如果是当前活动窗口，激活栈顶的下一个窗口
	if _active_window == window:
		if _window_stack.size() > 0:
			_active_window = _window_stack[_window_stack.size() - 1]
			# 调整活动窗口的层级
		else:
			_active_window = null
	
	# 从打开窗口列表中移除
	_windows.erase(window_id)
	
	# 根据可缓存标志决定是缓存还是销毁窗口
	if cacheable:
		# 缓存窗口以便重用
		_cache_window(window, scene_path)
		print("WindowManager: 窗口已缓存 - " + scene_path)
	else:
		# 直接销毁窗口，释放资源
		if window.is_inside_tree():
			window.queue_free()
		print("WindowManager: 窗口已释放 - " + scene_path)

# 关闭所有窗口
# @description 关闭所有当前打开的窗口
# @details 遍历所有窗口并调用close_window方法关闭，清空窗口栈和活动窗口引用
func close_all_windows() -> void:
	# TODO: 实现关闭所有窗口的功能
	pass





# 激活指定窗口
# @param window_or_id 窗口实例或窗口ID
# @description 激活指定窗口，将其设为当前活动窗口
# @details 将窗口移到窗口栈顶部，更新活动窗口引用，并发送相关信号
# @public
func activate_window(window_or_id: Variant) -> void:
	# 获取窗口实例
	var window = null
	
	if typeof(window_or_id) == TYPE_STRING:
		if window_or_id in _windows:
			window = _windows[window_or_id]["window"]
	elif window_or_id is Object:
		window = window_or_id
	
	# 如果找不到窗口或已经是活动窗口，直接返回
	if window == null or window == _active_window:
		return
	
	# 记录之前的活动窗口
	var previous_window = _active_window
	
	# 更新活动窗口引用
	_active_window = window
	
	# 将窗口移到窗口栈顶部
	_window_stack.erase(window)
	_window_stack.append(window)
	
	# 调整窗口在层级容器中的顺序（通常是移到最前）
	_reorder_windows() # TODO: 调用未实现的方法
	
	# 发送活动窗口改变信号
	self.emit_signal("active_window_changed", window, previous_window)
	pass

# 最小化指定窗口
# @param window_or_id 窗口实例或窗口ID
# @description 最小化指定窗口，隐藏其内容但保留在内存中
# @details 调用窗口实例的minimize方法，并更新活动窗口状态
func minimize_window(window_or_id: Variant) -> void:
	# 获取窗口实例
	var window = null
	
	if typeof(window_or_id) == TYPE_STRING:
		if window_or_id in _windows:
			window = _windows[window_or_id]["window"]
	elif window_or_id is Object:
		window = window_or_id
	
	if window != null:
		# 调用窗口的minimize方法
		window.minimize()
		# 从活动窗口位置移除
		if _active_window == window:
			_active_window = null
	pass

# 恢复指定窗口
# @param window_or_id 窗口实例或窗口ID
# @description 恢复已最小化的窗口，使其重新可见
# @details 调用窗口实例的restore方法，并将其设为活动窗口
func restore_window(window_or_id: Variant) -> void:
	# 获取窗口实例
	var window = null
	
	if typeof(window_or_id) == TYPE_STRING:
		if window_or_id in _windows:
			window = _windows[window_or_id]["window"]
	elif window_or_id is Object:
		window = window_or_id
	
	if window != null:
		# 调用窗口的restore方法
		window.restore()
		# 将其设为活动窗口
		activate_window(window)
	pass

# 设置窗口层级容器
# @param layer_name 层级名称（如"bottom"、"normal"、"top"、"tips"）
# @param container 层级对应的容器节点
# @description 注册窗口层级及其对应的容器节点
# @details 建立层级名称与场景容器节点的映射关系，用于后续窗口定位
# @public
func set_window_layer(layer_name: String, container: Node) -> void:
	# 存储层级名称与容器的映射
	_window_layers[layer_name] = container
	print("WindowManager: 已注册窗口层级 '" + layer_name + "'")
	pass

# 获取指定层级的所有窗口
# @param layer_name 层级名称
# @return 该层级的窗口实例数组
# @description 获取在指定层级中打开的所有窗口
# @details 遍历所有窗口，检查其层级并收集符合条件的窗口实例
func get_windows_in_layer(layer_name: String) -> Array:
	# 遍历所有窗口，收集指定层级的窗口
	var result: Array = []
	for window_id in _windows:
		var window_info = _windows[window_id]
		if window_info["layer"] == layer_name:
			result.append(window_info["window"])
	return result

# 获取当前活动窗口
# @return Object 当前活动窗口实例，如果没有活动窗口则返回null
# @description 获取用户当前正在交互的窗口
# @public
func get_active_window() -> Object:
	# 返回当前活动窗口实例
	return _active_window

# 获取所有打开的窗口
# @return Dictionary 所有打开的窗口实例字典，格式为{窗口ID: 窗口实例}
# @description 获取所有当前打开的窗口信息
# @details 返回一个字典，包含所有打开窗口的ID和对应的窗口实例
# @public
func get_all_windows() -> Dictionary:
	# 返回所有打开的窗口实例字典
	var result: Dictionary = {}
	for window_id in _windows:
		result[window_id] = _windows[window_id]["window"]
	return result

# 检查窗口是否已打开
# @param window_or_id 窗口实例或窗口ID
# @return bool 布尔值，表示窗口是否已打开
# @description 检查指定的窗口是否处于打开状态
# @details 支持通过窗口ID或窗口实例进行检查
# @public
func is_window_open(window_or_id: Variant) -> bool:
	# 通过窗口ID或实例检查窗口是否在打开窗口列表中
	if typeof(window_or_id) == TYPE_STRING:
		return window_or_id in _windows
	elif window_or_id is Object:
		for id in _windows:
			if _windows[id]["window"] == window_or_id:
				return true
	return false

# 缓存窗口实例
# @param window 要缓存的窗口实例
# @param scene_path 窗口场景路径
# @description 将窗口实例添加到缓存中以便后续重用
# @details 从场景树中移除窗口但保留实例，添加到对应场景路径的缓存列表中
# @private
func _cache_window(window: Node, scene_path: String) -> void:
	# 确保窗口从场景树中移除但不释放
	if window.is_inside_tree():
		window.get_parent().remove_child(window)
	
	# 查找窗口对应的always_cache标志
	var always_cache = false
	for window_id in _windows:
		var window_info = _windows[window_id]
		if window_info["window"] == window:
			always_cache = window_info.get("always_cache", false)
			break
	
	# 使用CachePoolManager缓存窗口实例
	_cache_pool_manager.cache_object(scene_path, window, always_cache)

# 从缓存获取窗口实例
# @param scene_path 窗口场景路径
# @return 缓存的窗口实例，如果没有则返回null
# @description 从缓存中获取指定场景路径的窗口实例
# @details 返回最旧的缓存实例，并从缓存列表中移除它
# @private
func _get_cached_window(scene_path: String) -> Node:
	# 使用CachePoolManager从缓存获取窗口实例
	return _cache_pool_manager.get_cached_object(scene_path) as Node

# 清理窗口缓存
# @param scene_path 可选，指定要清理的场景路径，不提供则清理所有缓存
# @description 清理指定场景或所有场景的窗口缓存
# @details 释放缓存窗口资源，避免内存泄漏
func clear_cache(scene_path: String = "") -> void:
	if scene_path != "":
		# 清理指定场景的缓存
		_cache_pool_manager.clear_cache(scene_path)
		print("WindowManager: 已清理场景'" + scene_path + "'的所有缓存窗口")
	else:
		# 清理所有缓存
		var stats = _cache_pool_manager.get_cache_stats()
		_cache_pool_manager.clear_all_cache()
		print("WindowManager: 已清理所有缓存窗口，共" + str(stats.total_count) + "个实例")
	pass

# 获取缓存窗口数量
# @param scene_path 可选，指定要查询的场景路径，不提供则查询所有缓存
# @return 缓存窗口的数量
# @description 获取指定场景或所有场景的缓存窗口数量
func get_cache_size(scene_path: String = "") -> int:
	# 使用CachePoolManager获取缓存数量
	return _cache_pool_manager.get_cache_size(scene_path)

# 检查窗口是否在缓存中
# @param window 要检查的窗口实例
# @return 布尔值，表示窗口是否在缓存中
# @description 检查指定窗口实例是否在缓存中
func is_window_cached(window: Node) -> bool:
	# 遍历所有打开的窗口信息，找到对应的场景路径
	for window_id in _windows.keys():
		var window_info = _windows[window_id]
		if window_info["window"] == window:
			# 找到了窗口对应的场景路径，使用CachePoolManager检查
			return _cache_pool_manager.is_object_cached(window_info["scene_path"], window)
	
	# 如果窗口不在打开列表中，检查是否在所有缓存中
	var stats = _cache_pool_manager.get_cache_stats()
	for scene_path in stats["path_details"].keys():
		if _cache_pool_manager.is_object_cached(scene_path, window):
			return true
	
	return false

# 获取缓存信息
# @return 缓存的详细信息字典
# @description 获取缓存的详细信息，包括每个场景的缓存数量和总缓存数量
func get_cache_info() -> Dictionary:
	# 使用CachePoolManager获取缓存统计信息
	var stats = _cache_pool_manager.get_cache_stats()
	
	# 转换为与原方法相同的格式
	var info = {
		"total_count": stats["total_count"],
		"scenes": stats["path_details"]
	}
	
	return info

# 处理窗口关闭信号
# @param window 关闭的窗口实例
# @description 响应窗口实例发出的关闭信号
# @details 当窗口自身发出关闭信号时，调用close_window方法进行处理
# @private
func _on_window_closed(window: Object) -> void:
	# 调用close_window方法关闭窗口
	close_window(window)
	pass

# 处理窗口打开信号
# @param window 打开的窗口实例
# @description 响应窗口实例发出的打开信号
# @details 当窗口自身发出打开信号时，进行相应处理
# @private
# TODO: 未实现的方法，在BaseWindow中被调用
func _on_window_opened(window: Object) -> void:
	# 处理窗口打开的逻辑
	pass

# 窗口排序函数
# @description 根据窗口栈顺序调整窗口在层级容器中的显示顺序
# @details 按照窗口栈的顺序调整窗口的Z顺序，确保窗口的显示层级与交互顺序一致
# @private
func _reorder_windows() -> void:
	# TODO: 实现窗口排序逻辑
	# 遍历窗口栈
	# 按照从下到上的顺序调整窗口Z顺序
	for window in _window_stack:
		# 调整窗口层级顺序
		pass

# 生成唯一窗口ID
# @param scene_path 窗口场景路径
# @return 唯一的窗口ID字符串
# @description 生成一个唯一的窗口ID，确保不与已存在的窗口ID冲突
# @details 基于场景路径、时间戳和随机数生成ID，并确保ID唯一性
# @private
func _generate_window_id(scene_path: String) -> String:
	# 基于场景路径和时间戳或随机数生成唯一ID
	# 确保ID在当前打开的窗口中不重复
	var timestamp = Time.get_unix_time_from_system()
	var random_suffix = randi() % 10000
	var base_id = "%s_%d_%04d" % [scene_path.replace("/", "_"), timestamp, random_suffix]
	
	# 确保ID不重复
	var counter = 1
	var final_id = base_id
	while final_id in _windows:
		final_id = "%s_%d" % [base_id, counter]
		counter += 1
		
	return final_id
