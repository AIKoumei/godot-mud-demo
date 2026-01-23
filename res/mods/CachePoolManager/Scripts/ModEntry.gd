## ---------------------------------------------------------
## CachePoolManager 模块（ModInterface 版本）
##
## 功能说明：
## - 提供对象缓存池管理功能
## - 支持多种缓存类型（path/type/script/custom）
## - 自动清理过期缓存对象
## - 支持设置缓存超时时间和最大缓存大小
## - 线程安全设计，避免资源冲突
##
## 依赖：
## - ModInterface（基础接口）
##
## 调用方式（其他 Mod）：
## GameCore.mod_manager.call_mod("CachePoolManager", "get_cached_object", {
##     "key": "res://xxx.tscn",
##     "key_type": "path"
## })
##
## ---------------------------------------------------------
extends ModInterface

signal cache_added(key: Variant, object: Object, key_type: String)
signal cache_removed(key: Variant, object: Object, key_type: String, reason: String)
signal cache_cleared(key: Variant, key_type: String)

const DEFAULT_CACHE_TIMEOUT: float = 300.0
const DEFAULT_MAX_CACHE_SIZE: int = 10
const CLEANUP_INTERVAL: float = 1.0

var _cached_objects: Dictionary = {}
var _cache_config: Dictionary = {}

var _cleanup_thread: Thread
var _cleanup_mutex: Mutex = Mutex.new()
var _cleanup_running: bool = false
var _pending_free: Array[Object] = []
var _cleanup_timer: float = 0.0


# ---------------------------------------------------------
# 生命周期：模块加载
# ---------------------------------------------------------
func _on_mod_load() -> bool:
	print("[CachePoolManager] load_mod")

	_cached_objects = {
		"path": {},
		"type": {},
		"script": {},
		"custom": {}
	}

	_cache_config = {
		"timeout": DEFAULT_CACHE_TIMEOUT,
		"max_size": DEFAULT_MAX_CACHE_SIZE
	}

	_cleanup_running = true
	_cleanup_thread = Thread.new()
	_cleanup_thread.start(_thread_cleanup_loop)

	set_process(true)  # 主线程用于 queue_free

	return true


# ---------------------------------------------------------
# 生命周期：模块卸载
# ---------------------------------------------------------
func _on_mod_unload() -> void:
	print("[CachePoolManager] unload")

	_cleanup_running = false
	if _cleanup_thread:
		_cleanup_thread.wait_to_finish()

	clear_all()


# ---------------------------------------------------------
# 主线程：执行 queue_free
# ---------------------------------------------------------
func _process(delta: float) -> void:
	_cleanup_timer += delta
	if _cleanup_timer >= CLEANUP_INTERVAL:
		_cleanup_timer = 0.0

		_cleanup_mutex.lock()
		var to_free: Array[Object] = _pending_free.duplicate()
		_pending_free.clear()
		_cleanup_mutex.unlock()

		for obj: Object in to_free:
			if obj is Node:
				var node := obj as Node
				if node.is_inside_tree():
					node.queue_free()


# ---------------------------------------------------------
# 后台线程：循环清理
# ---------------------------------------------------------
func _thread_cleanup_loop() -> void:
	while _cleanup_running:
		_cleanup_expired_cache_thread()
		OS.delay_msec(int(CLEANUP_INTERVAL * 1000))


# ---------------------------------------------------------
# 后台线程：扫描过期缓存（不 queue_free）
# ---------------------------------------------------------
func _cleanup_expired_cache_thread() -> void:
	var now: float = Time.get_unix_time_from_system()

	_cleanup_mutex.lock()

	for key_type: String in _cached_objects.keys():
		var inner: Dictionary = _cached_objects[key_type]

		for key: Variant in inner.keys():
			var list: Array = inner[key]
			var valid: Array = []

			for cache_info: Dictionary in list:
				var obj: Object = cache_info["object"]
				var expiry: float = cache_info["expiry_time"]
				var always: bool = cache_info["always_cache"]

				if always or now < expiry:
					valid.append(cache_info)
				else:
					_pending_free.append(obj)
					cache_removed.emit(key, obj, key_type, "expired")

			_cached_objects[key_type][key] = valid

	_cleanup_mutex.unlock()


# ---------------------------------------------------------
# 缓存对象（统一入口）
# ---------------------------------------------------------
func cache(key: Variant, object: Object, always_cache: bool = false) -> void:
	var key_type: String = _detect_key_type(key)
	if key_type == "":
		push_warning("[CachePoolManager] Unsupported key type: %s" % key)
		return

	_cleanup_mutex.lock()
	_cache_add(key_type, key, object, always_cache)
	_cleanup_mutex.unlock()


# ---------------------------------------------------------
# 获取缓存对象
# ---------------------------------------------------------
func get_cached(key: Variant) -> Object:
	var key_type: String = _detect_key_type(key)
	if key_type == "":
		return null

	_cleanup_mutex.lock()
	var obj: Object = _cache_pop(key_type, key)
	_cleanup_mutex.unlock()

	return obj


# ---------------------------------------------------------
# Key 类型识别
# ---------------------------------------------------------
func _detect_key_type(key: Variant) -> String:
	if typeof(key) == TYPE_STRING:
		var s := key as String
		if s.begins_with("res://"):
			return "path"
		return "custom"

	if key is Script:
		return "script"

	if key is Node:
		return "type"

	return ""


# ---------------------------------------------------------
# 添加缓存
# ---------------------------------------------------------
func _cache_add(key_type: String, key: Variant, object: Object, always_cache: bool) -> void:
	if not _cached_objects[key_type].has(key):
		_cached_objects[key_type][key] = []

	var expiry: float = 0
	if not always_cache:
		expiry = Time.get_unix_time_from_system() + int(_cache_config["timeout"])

	var cache_info: Dictionary = {
		"object": object,
		"expiry_time": expiry,
		"always_cache": always_cache,
		"cached_time": Time.get_unix_time_from_system()
	}

	var list: Array = _cached_objects[key_type][key]
	list.append(cache_info)
	_cached_objects[key_type][key] = list

	_check_cache_size_limit(key_type, key)

	cache_added.emit(key, object, key_type)


# ---------------------------------------------------------
# 获取缓存对象（FIFO）
# ---------------------------------------------------------
func _cache_pop(key_type: String, key: Variant) -> Object:
	if not _cached_objects[key_type].has(key):
		return null

	var list: Array = _cached_objects[key_type][key]
	if list.is_empty():
		return null

	var cache_info: Dictionary = list.pop_front()
	return cache_info["object"]


# ---------------------------------------------------------
# 缓存数量限制
# ---------------------------------------------------------
func _check_cache_size_limit(key_type: String, key: Variant) -> void:
	var list: Array = _cached_objects[key_type][key]
	var max_size: int = int(_cache_config["max_size"])

	if list.size() > max_size:
		var overflow: int = list.size() - max_size

		for i: int in range(overflow):
			var old_cache: Dictionary = list.pop_front()
			var obj: Object = old_cache["object"]
			_pending_free.append(obj)
			cache_removed.emit(key, obj, key_type, "size_limit")


# ---------------------------------------------------------
# 清理缓存（主线程）
# ---------------------------------------------------------
func clear(key: Variant) -> void:
	var key_type: String = _detect_key_type(key)
	if key_type == "":
		return

	_cleanup_mutex.lock()

	if _cached_objects[key_type].has(key):
		var list: Array = _cached_objects[key_type][key]
		for cache_info: Dictionary in list:
			var obj: Object = cache_info["object"]
			_pending_free.append(obj)

		_cached_objects[key_type].erase(key)

	_cleanup_mutex.unlock()

	cache_cleared.emit(key, key_type)


func clear_all() -> void:
	for key_type: String in _cached_objects.keys():
		for key: Variant in _cached_objects[key_type].keys():
			clear(key)

	cache_cleared.emit(null, "all")
