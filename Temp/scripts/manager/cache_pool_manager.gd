# 缓存池管理器 - CachePoolManager
# 通用缓存管理系统，支持根据资源路径或对象类型进行缓存管理
# 实现了缓存超时机制，可自动清理过期缓存
# @version v.0.0.1
#
# @class CachePoolManager
# @extends Node
# @description 提供通用的对象缓存管理功能，支持资源路径和对象类型两种缓存方式
#
# ## 设计理念
# - **通用缓存**：支持任意类型对象的缓存，不仅限于窗口
# - **双维度管理**：同时支持按资源路径和对象类型进行缓存管理
# - **超时机制**：实现缓存超时自动清理，避免资源泄漏
# - **灵活配置**：支持设置缓存超时时间、最大缓存数量等参数
# - **性能优化**：通过缓存减少对象创建和销毁的开销
#
# ## 主要功能
# 1. **缓存管理**：添加、获取、清理缓存对象
# 2. **超时控制**：自动清理过期缓存
# 3. **数量限制**：限制每个分类的最大缓存数量
# 4. **双维度查询**：支持按资源路径或对象类型查询缓存
# 5. **统计信息**：提供缓存使用情况的统计信息
#
# ## 使用示例
# ```gdscript
# # 获取缓存池管理器实例
# var cache_manager = CachePoolManager.get_instance()
#
# # 缓存一个对象（按资源路径）
# cache_manager.cache_object("res://scenes/ui/Button.tscn", button_instance)
#
# # 缓存一个对象（按类型）
# cache_manager.cache_object_by_type("Button", button_instance)
#
# # 获取缓存对象（按资源路径）
# var cached_button = cache_manager.get_cached_object("res://scenes/ui/Button.tscn")
#
# # 获取缓存对象（按类型）
# var cached_button2 = cache_manager.get_cached_object_by_type("Button")
#
# # 清理指定资源路径的缓存
# cache_manager.clear_cache("res://scenes/ui/Button.tscn")
#
# # 清理指定类型的缓存
# cache_manager.clear_cache_by_type("Button")
#
# # 清理所有缓存
# cache_manager.clear_all_cache()
#
# # 获取缓存统计信息
# var stats = cache_manager.get_cache_stats()
# print("总缓存数量：", stats.total_count)
# ```
extends Node

# 信号定义
signal cache_added(key: Variant, object: Object, cache_type: String)
	# 当对象被添加到缓存时触发
	# @param key 缓存键（资源路径或类型名）
	# @param object 被缓存的对象
	# @param cache_type 缓存类型（"path"或"type"）
signal cache_removed(key: Variant, object: Object, cache_type: String, reason: String)
	# 当对象从缓存中移除时触发
	# @param key 缓存键（资源路径或类型名）
	# @param object 被移除的对象
	# @param cache_type 缓存类型（"path"或"type"）
	# @param reason 移除原因（"expired"或"size_limit"）
signal cache_cleared(key: Variant, cache_type: String)
	# 当缓存被清理时触发
	# @param key 缓存键（资源路径或类型名，null表示清理所有）
	# @param cache_type 缓存类型（"path"、"type"或"all"）

# 常量定义
const DEFAULT_CACHE_TIMEOUT = 300.0  # 默认缓存超时时间（秒），5分钟
const DEFAULT_MAX_CACHE_SIZE = 10    # 默认每个分类的最大缓存数量

# 内部变量
var _cached_objects: Dictionary = {}
	# 存储所有缓存对象
	# 格式: {
	#   "path": {资源路径: [缓存对象列表]},  # 按资源路径缓存
	#   "type": {类型名: [缓存对象列表]}      # 按对象类型缓存
	# }
var _cache_config: Dictionary = {}
	# 缓存配置
	# 格式: {
	#   "timeout": 超时时间（秒）,
	#   "max_size": 最大缓存数量
	# }

# 初始化缓存管理器
# @description 完成缓存管理器的基础初始化工作，包括初始化缓存结构和设置默认配置
# @private
func _ready() -> void:
	# 初始化缓存结构
	_cached_objects = {
		"path": {},
		"type": {}
	}
	
	# 设置默认缓存配置
	_cache_config = {
		"timeout": DEFAULT_CACHE_TIMEOUT,
		"max_size": DEFAULT_MAX_CACHE_SIZE
	}

# 设置缓存配置
# @param timeout 缓存超时时间（秒），默认300秒（5分钟）
# @param max_size 每个分类的最大缓存数量，默认10个
# @description 设置全局缓存配置
# @public
func set_cache_config(timeout: float = DEFAULT_CACHE_TIMEOUT, max_size: int = DEFAULT_MAX_CACHE_SIZE) -> void:
	_cache_config["timeout"] = timeout
	_cache_config["max_size"] = max_size

# 缓存对象（按资源路径）
# @param path 资源路径
# @param object 要缓存的对象（可以是任意Object类型）
# @param always_cache 是否永久缓存（默认false）
# @return void
# @description 将对象缓存到指定资源路径下
# @details 支持设置永久缓存，超出数量限制时会自动移除最旧的缓存
# @public
func cache_object(path: String, object: Object, always_cache: bool = false) -> void:
	# 确保路径缓存字典存在
	if path not in _cached_objects["path"]:
		_cached_objects["path"][path] = []
	
	# 计算过期时间戳
	var expiry_time = 0
	if not always_cache:
		expiry_time = Time.get_unix_time_from_system() + _cache_config["timeout"]
	
	# 创建缓存信息
	var cache_info = {
		"object": object,
		"expiry_time": expiry_time,
		"always_cache": always_cache,
		"cached_time": Time.get_unix_time_from_system()
	}
	
	# 添加到缓存
	_cached_objects["path"][path].append(cache_info)
	
	# 检查缓存数量限制
	_check_cache_size_limit("path", path)
	
	# 发出信号
	cache_added.emit(path, object, "path")

# 缓存对象（按对象类型）
# @param type_name 对象类型名
# @param object 要缓存的对象（可以是任意Object类型）
# @param always_cache 是否永久缓存（默认false）
# @return void
# @description 将对象缓存到指定类型名下
# @details 支持设置永久缓存，超出数量限制时会自动移除最旧的缓存
# @public
func cache_object_by_type(type_name: String, object: Object, always_cache: bool = false) -> void:
	# 确保类型缓存字典存在
	if type_name not in _cached_objects["type"]:
		_cached_objects["type"][type_name] = []
	
	# 计算过期时间戳
	var expiry_time = 0
	if not always_cache:
		expiry_time = Time.get_unix_time_from_system() + _cache_config["timeout"]
	
	# 创建缓存信息
	var cache_info = {
		"object": object,
		"expiry_time": expiry_time,
		"always_cache": always_cache,
		"cached_time": Time.get_unix_time_from_system()
	}
	
	# 添加到缓存
	_cached_objects["type"][type_name].append(cache_info)
	
	# 检查缓存数量限制
	_check_cache_size_limit("type", type_name)
	
	# 发出信号
	cache_added.emit(type_name, object, "type")

# 获取缓存对象（按资源路径）
# @param path 资源路径
# @return Object 缓存的对象实例，如果没有则返回null
# @description 从指定资源路径获取缓存对象，获取后从缓存中移除
# @details 使用FIFO（先进先出）策略获取缓存对象
# @public
func get_cached_object(path: String) -> Object:
	if path not in _cached_objects["path"] or _cached_objects["path"][path].size() == 0:
		return null
	
	# 获取最旧的缓存对象（FIFO）
	var cache_info = _cached_objects["path"][path].pop_front()
	return cache_info["object"]

# 获取缓存对象（按对象类型）
# @param type_name 对象类型名
# @return Object 缓存的对象实例，如果没有则返回null
# @description 从指定类型名获取缓存对象，获取后从缓存中移除
# @details 使用FIFO（先进先出）策略获取缓存对象
# @public
func get_cached_object_by_type(type_name: String) -> Object:
	if type_name not in _cached_objects["type"] or _cached_objects["type"][type_name].size() == 0:
		return null
	
	# 获取最旧的缓存对象（FIFO）
	var cache_info = _cached_objects["type"][type_name].pop_front()
	return cache_info["object"]

# 获取所有缓存对象（按资源路径）
# @param path 资源路径
# @return 缓存对象列表
# @description 获取指定资源路径下的所有缓存对象
func get_all_cached_objects(path: String) -> Array:
	if path not in _cached_objects["path"]:
		return []
	
	var objects = []
	for cache_info in _cached_objects["path"][path]:
		objects.append(cache_info["object"])
	return objects

# 获取所有缓存对象（按对象类型）
# @param type_name 对象类型名
# @return 缓存对象列表
# @description 获取指定类型名下的所有缓存对象
func get_all_cached_objects_by_type(type_name: String) -> Array:
	if type_name not in _cached_objects["type"]:
		return []
	
	var objects = []
	for cache_info in _cached_objects["type"][type_name]:
		objects.append(cache_info["object"])
	return objects

# 清理指定资源路径的缓存
# @param path 资源路径
# @description 清理指定资源路径下的所有缓存对象
func clear_cache(path: String) -> void:
	if path in _cached_objects["path"]:
		# 释放所有缓存对象
		for cache_info in _cached_objects["path"][path]:
			var object = cache_info["object"]
			if object is Node and object.is_inside_tree():
				object.queue_free()
		
		# 移除缓存列表
		_cached_objects["path"].erase(path)
		
		# 发出信号
		cache_cleared.emit(path, "path")

# 清理指定类型的缓存
# @param type_name 对象类型名
# @description 清理指定类型名下的所有缓存对象
func clear_cache_by_type(type_name: String) -> void:
	if type_name in _cached_objects["type"]:
		# 释放所有缓存对象
		for cache_info in _cached_objects["type"][type_name]:
			var object = cache_info["object"]
			if object is Node and object.is_inside_tree():
				object.queue_free()
		
		# 移除缓存列表
		_cached_objects["type"].erase(type_name)
		
		# 发出信号
		cache_cleared.emit(type_name, "type")

# 清理所有缓存
# @description 清理所有类型和路径的缓存对象
func clear_all_cache() -> void:
	# 清理按路径缓存的对象
	for path in _cached_objects["path"].keys():
		clear_cache(path)
	
	# 清理按类型缓存的对象
	for type_name in _cached_objects["type"].keys():
		clear_cache_by_type(type_name)
	
	# 发出信号
	cache_cleared.emit(null, "all")

# 获取缓存大小（按资源路径）
# @param path 资源路径（可选）
# @return 缓存对象数量
# @description 获取指定资源路径或所有路径的缓存数量
func get_cache_size(path: String = "") -> int:
	if path != "":
		if path in _cached_objects["path"]:
			return _cached_objects["path"][path].size()
		return 0
	else:
		var total = 0
		for path_key in _cached_objects["path"].keys():
			total += _cached_objects["path"][path_key].size()
		return total

# 获取缓存大小（按对象类型）
# @param type_name 对象类型名（可选）
# @return 缓存对象数量
# @description 获取指定类型名或所有类型的缓存数量
func get_cache_size_by_type(type_name: String = "") -> int:
	if type_name != "":
		if type_name in _cached_objects["type"]:
			return _cached_objects["type"][type_name].size()
		return 0
	else:
		var total = 0
		for type_key in _cached_objects["type"].keys():
			total += _cached_objects["type"][type_key].size()
		return total

# 检查对象是否在缓存中（按资源路径）
# @param path 资源路径
# @param object 要检查的对象
# @return 是否在缓存中
# @description 检查指定对象是否在指定资源路径的缓存中
func is_object_cached(path: String, object: Object) -> bool:
	if path not in _cached_objects["path"]:
		return false
	
	for cache_info in _cached_objects["path"][path]:
		if cache_info["object"] == object:
			return true
	return false

# 检查对象是否在缓存中（按对象类型）
# @param type_name 对象类型名
# @param object 要检查的对象
# @return 是否在缓存中
# @description 检查指定对象是否在指定类型名的缓存中
func is_object_cached_by_type(type_name: String, object: Object) -> bool:
	if type_name not in _cached_objects["type"]:
		return false
	
	for cache_info in _cached_objects["type"][type_name]:
		if cache_info["object"] == object:
			return true
	return false

# 获取缓存统计信息
# @return 缓存统计信息字典
# @description 获取缓存使用情况的统计信息
func get_cache_stats() -> Dictionary:
	var stats = {
		"total_count": 0,
		"path_count": 0,
		"type_count": 0,
		"path_details": {},
		"type_details": {}
	}
	
	# 统计按路径缓存的信息
	stats["path_count"] = _cached_objects["path"].size()
	for path in _cached_objects["path"].keys():
		var count = _cached_objects["path"][path].size()
		stats["path_details"][path] = count
		stats["total_count"] += count
	
	# 统计按类型缓存的信息
	stats["type_count"] = _cached_objects["type"].size()
	for type_name in _cached_objects["type"].keys():
		var count = _cached_objects["type"][type_name].size()
		stats["type_details"][type_name] = count
		stats["total_count"] += count
	
	return stats

# 每帧检查缓存是否过期
func _physics_process(_delta: float) -> void:
	_cleanup_expired_cache()

# 清理过期缓存（内部方法）
# @private
func _cleanup_expired_cache() -> void:
	var current_time = Time.get_unix_time_from_system()
	var expired_count = 0
	
	# 清理按路径缓存的过期对象
	for path in _cached_objects["path"].keys():
		var valid_caches = []
		
		for cache_info in _cached_objects["path"][path]:
			var object = cache_info["object"]
			var expiry_time = cache_info["expiry_time"]
			var always_cache = cache_info["always_cache"]
			
			if always_cache or current_time < expiry_time:
				# 有效缓存，保留
				valid_caches.append(cache_info)
			else:
				# 过期缓存，释放资源
				if object is Node and object.is_inside_tree():
					object.queue_free()
				expired_count += 1
				
				# 发出信号
				cache_removed.emit(path, object, "path", "expired")
		
		# 更新缓存列表
		_cached_objects["path"][path] = valid_caches
		
		# 如果没有有效缓存，移除该路径的缓存
		if valid_caches.size() == 0:
			_cached_objects["path"].erase(path)
	
	# 清理按类型缓存的过期对象
	for type_name in _cached_objects["type"].keys():
		var valid_caches = []
		
		for cache_info in _cached_objects["type"][type_name]:
			var object = cache_info["object"]
			var expiry_time = cache_info["expiry_time"]
			var always_cache = cache_info["always_cache"]
			
			if always_cache or current_time < expiry_time:
				# 有效缓存，保留
				valid_caches.append(cache_info)
			else:
				# 过期缓存，释放资源
				if object is Node and object.is_inside_tree():
					object.queue_free()
				expired_count += 1
				
				# 发出信号
				cache_removed.emit(type_name, object, "type", "expired")
		
		# 更新缓存列表
		_cached_objects["type"][type_name] = valid_caches
		
		# 如果没有有效缓存，移除该类型的缓存
		if valid_caches.size() == 0:
			_cached_objects["type"].erase(type_name)
	
	if expired_count > 0:
		print("CachePoolManager: 已清理" + str(expired_count) + "个过期缓存对象")

# 检查并限制缓存数量（内部方法）
# @param cache_type 缓存类型（"path"或"type"）
# @param key 缓存键
# @private
func _check_cache_size_limit(cache_type: String, key: Variant) -> void:
	if cache_type not in ["path", "type"] or key not in _cached_objects[cache_type]:
		return
	
	var cache_list = _cached_objects[cache_type][key]
	if cache_list.size() > _cache_config["max_size"]:
		# 移除超出数量的最旧缓存（FIFO）
		var overflow = cache_list.size() - _cache_config["max_size"]
		
		for i in range(overflow):
			var old_cache = cache_list.pop_front()
			var object = old_cache["object"]
			
			# 释放资源
			if object is Node and object.is_inside_tree():
				object.queue_free()
			
			# 发出信号
			cache_removed.emit(key, object, cache_type, "size_limit")
