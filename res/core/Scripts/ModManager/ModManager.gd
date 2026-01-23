## ModManager.gd
## 负责 mod 扫描、依赖解析、加载、卸载、入口场景调度
class_name ModManager
extends RefCounted

var VERSION := "v0.0.1"

## 已加载的 mod 数据
## { mod_name: {config, data, path, scene, enabled, loaded} }
var loaded_mods: Dictionary = {}

## 默认 mod 根目录
const MODS_ROOT := "res://res/mods"


# ---------------------------------------------------------
# 生命周期
# ---------------------------------------------------------
func _init() -> void:
	print("[ModManager] Initialized, version: %s" % VERSION)


# ---------------------------------------------------------
# JSON 加载工具（res://）
# ---------------------------------------------------------
func load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_warning("[ModManager] JSON not found: %s" % path)
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("[ModManager] JSON parse failed: %s" % path)
		return {}
	return parsed


# ---------------------------------------------------------
# JSON 加载工具（user://）
# ---------------------------------------------------------
func load_json_user(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	var parsed = JSON.parse_string(f.get_as_text())
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}


# ---------------------------------------------------------
# JSON 写入工具（user://）
# ---------------------------------------------------------
func save_json_user(path: String, data: Dictionary) -> void:
	var dir := path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(dir)
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(data, "\t"))


# ---------------------------------------------------------
# 版本比较工具
# 返回 1 = a>b，0 = 相等，-1 = a<b
# ---------------------------------------------------------
func compare_version(a: String, b: String) -> int:
	var pa := a.split(".")
	var pb := b.split(".")
	var _len = max(pa.size(), pb.size())
	for i in _len:
		var va := int(pa[i]) if i < pa.size() else 0
		var vb := int(pb[i]) if i < pb.size() else 0
		if va > vb:
			return 1
		if va < vb:
			return -1
	return 0


# ---------------------------------------------------------
# 合并 user:// 与 res:// 配置/数据
# 规则：
# - user_version > default_version → 使用 user
# - user_version == default_version → 使用 user
# - user_version < default_version → 使用 default
# ---------------------------------------------------------
func merge_user_and_default(default: Dictionary, user: Dictionary, label: String, mod_name: String) -> Dictionary:
	var dv := str(default.get("version", "0.0.0"))
	var uv := str(user.get("version", "0.0.0"))

	var cmp := compare_version(uv, dv)

	if cmp > 0:
		print("[ModManager] Using user %s for mod %s (user_version=%s > default_version=%s)" % [label, mod_name, uv, dv])
		return user
	if cmp == 0:
		print("[ModManager] Using user %s for mod %s (version=%s)" % [label, mod_name, uv])
		return user

	print("[ModManager] Using default %s for mod %s (default_version=%s > user_version=%s)" % [label, mod_name, dv, uv])
	return default


# ---------------------------------------------------------
# 扫描 mod（只读 config，不实例化）
# ---------------------------------------------------------
func scan_mods(mods_path: String = MODS_ROOT) -> Dictionary:
	var mods: Dictionary = {}
	var dir := DirAccess.open(mods_path)
	if dir == null:
		push_error("[ModManager] Cannot open mods directory: %s" % mods_path)
		return mods

	dir.list_dir_begin()
	var name := dir.get_next()

	while name != "":
		if name != "." and name != ".." and dir.current_is_dir():
			var mod_path := "%s/%s" % [mods_path, name]
			var config_path := "%s/Config/ModuleConfig.json" % mod_path
			var config := load_json(config_path)
			if config.is_empty():
				push_warning("[ModManager] Mod %s missing config" % name)
			else:
				mods[name] = {
					"path": mod_path,
					"config": config
				}
		name = dir.get_next()

	dir.list_dir_end()
	return mods


# ---------------------------------------------------------
# 构建依赖图
# graph: { mod_name: [required_dep1, required_dep2, ...] }
# ---------------------------------------------------------
func build_dependency_graph(mods: Dictionary) -> Dictionary:
	var graph := {}
	for mod_name in mods.keys():
		var config: Dictionary = mods[mod_name].config
		var deps: Array = config.get("dependencies", {}).get("required", [])
		graph[mod_name] = deps
	return graph


# ---------------------------------------------------------
# 循环依赖检测（外部 DFS）
# ---------------------------------------------------------
func detect_cycle(graph: Dictionary) -> bool:
	var visiting := {}
	var visited := {}

	for mod_name in graph.keys():
		if _dfs_cycle(graph, mod_name, visiting, visited):
			push_error("[ModManager] Circular dependency detected at %s" % mod_name)
			return true

	return false


func _dfs_cycle(graph: Dictionary, mod_name: String, visiting: Dictionary, visited: Dictionary) -> bool:
	if visited.get(mod_name, false):
		return false
	if visiting.get(mod_name, false):
		return true

	visiting[mod_name] = true

	for dep in graph.get(mod_name, []):
		if graph.has(dep):
			if _dfs_cycle(graph, dep, visiting, visited):
				return true

	visiting.erase(mod_name)
	visited[mod_name] = true
	return false


# ---------------------------------------------------------
# 拓扑排序（外部 DFS）
# ---------------------------------------------------------
func topological_sort(graph: Dictionary) -> Array:
	var sorted: Array = []
	var visited := {}

	for mod_name in graph.keys():
		if not visited.get(mod_name, false):
			_dfs_topo(graph, mod_name, visited, sorted)

	return sorted


func _dfs_topo(graph: Dictionary, mod_name: String, visited: Dictionary, sorted: Array) -> void:
	if visited.get(mod_name, false):
		return

	visited[mod_name] = true

	for dep in graph.get(mod_name, []):
		if graph.has(dep):
			_dfs_topo(graph, dep, visited, sorted)

	sorted.append(mod_name)


# ---------------------------------------------------------
# 计算按依赖顺序排序的 mod 加载顺序
# 返回 [mod_name, mod_name, ...]
# ---------------------------------------------------------
func get_mod_load_order(mods_path: String = MODS_ROOT) -> Array:
	var mods = scan_mods(mods_path)
	if mods.is_empty():
		return []

	var graph = build_dependency_graph(mods)

	if detect_cycle(graph):
		push_error("[ModManager] Cannot load mods due to circular dependency")
		return []

	var sorted = topological_sort(graph)
	return sorted


# ---------------------------------------------------------
# 加载所有 mod（按依赖顺序）
# ---------------------------------------------------------
func load_all_mods(mods_path: String = MODS_ROOT) -> void:
	print("[ModManager] Scanning & loading mods from: %s" % mods_path)

	var order: Array = get_mod_load_order(mods_path)
	if order.is_empty():
		print("[ModManager] No mods to load or dependency error.")
		return

	# 先按顺序 load（只实例化，不启用）
	for mod_name in order:
		if not load_mod(mod_name, mods_path):
			push_warning("[ModManager] Failed to load mod: %s" % mod_name)

	# 再按顺序 enable（会自动启用依赖）
	for mod_name in order:
		if not loaded_mods.has(mod_name):
			continue
		var config: Dictionary = loaded_mods[mod_name].config
		if config.get("enabled", true):
			enable_mod(mod_name)


# ---------------------------------------------------------
# 加载单个 mod（不处理依赖，只负责实例化）
# 新增：user:// 配置/数据版本对比与合并
# ---------------------------------------------------------
func load_mod(mod_name: String, mods_path: String = MODS_ROOT) -> bool:
	if mod_name in loaded_mods:
		print("[ModManager] Mod already loaded: %s" % mod_name)
		return true

	var mod_path := "%s/%s" % [mods_path, mod_name]
	print("[ModManager] Loading mod: %s" % mod_path)

	# 默认配置（res://）
	var config_path := "%s/Config/ModuleConfig.json" % mod_path
	var data_path   := "%s/Data/ModuleData.json" % mod_path

	var default_config := load_json(config_path)
	var default_data   := load_json(data_path)

	if default_config.is_empty() or default_data.is_empty():
		push_warning("[ModManager] Mod %s missing config or data" % mod_name)
		return false

	# user 配置（user://）
	var user_config_path := "user://mods/%s/Config/ModuleConfig.json" % mod_name
	var user_data_path   := "user://mods/%s/Data/ModuleData.json" % mod_name

	var user_config := load_json_user(user_config_path)
	var user_data   := load_json_user(user_data_path)

	# 合并（版本对比）
	var final_config := merge_user_and_default(default_config, user_config, "config", mod_name)
	var final_data   := merge_user_and_default(default_data, user_data, "data", mod_name)

	# 写回 user（保证 user 始终最新）
	save_json_user(user_config_path, final_config)
	save_json_user(user_data_path, final_data)

	loaded_mods[mod_name] = {
		"config": final_config,
		"data": final_data,
		"path": mod_path,
		"script": null,
		"scene": null,
		"enabled": false,
		"loaded": false
	}

	# 加载 mod 脚本
	var entry_script_path = "%s/Scripts/ModEntry.gd" % [mod_path]
	if not ResourceLoader.exists(entry_script_path):
		push_warning("[ModManager] Entry script not found: %s" % entry_script_path)
		loaded_mods.erase(mod_name)
		return false
	var entry_script: Script = load(entry_script_path)

	# 加载入口场景
	var scene_res
	var scene_instance: Node

	var entry_scene_path = final_config.get("entry_scene", "")
	if entry_scene_path == "":
		push_warning("[ModManager] Mod %s has no entry_scene, using empty Node" % mod_name)
		scene_instance = Node.new()
		scene_instance.name = "[Mod] %s" % mod_name
	elif not ResourceLoader.exists(entry_scene_path):
		push_warning("[ModManager] Entry scene not found: %s" % entry_scene_path)
		loaded_mods.erase(mod_name)
		return false
	else:
		scene_res = load(entry_scene_path)
		scene_instance = scene_res.instantiate()

	# 挂载脚本 & 注入数据
	scene_instance.set_script(entry_script)
	scene_instance.mod_name = mod_name
	scene_instance.mod_data = loaded_mods[mod_name].data
	scene_instance.mod_config = loaded_mods[mod_name].config

	# 记录 scene
	loaded_mods[mod_name].scene = scene_instance

	# 挂到 ModsLayer（仍保留原有 TODO）
	push_warning("[ModManager] [TODO] 通过 GameCore/GameSceneLayerManager 来控制挂载 mod 节点的位置")
	GameCore.get_mods_layer().add_child(scene_instance)

	# 调用模块加载生命周期
	var load_result := true
	if scene_instance.has_method("load_mod"):
		load_result = scene_instance.load_mod()

	loaded_mods[mod_name].loaded = load_result

	print("[ModManager] Mod loaded (instantiated) successfully: %s" % mod_name)
	return true


# ---------------------------------------------------------
# 启用 mod（会自动启用前置依赖）
# ---------------------------------------------------------
func enable_mod(mod_name: String) -> bool:
	if not loaded_mods.has(mod_name):
		print("[ModManager] Mod does not exist: %s" % mod_name)
		return false
	if loaded_mods[mod_name].enabled:
		print("[ModManager] Mod already enabled: %s" % mod_name)
		return true
	if not loaded_mods[mod_name].loaded:
		push_error("[ModManager] Cannot enable mod %s because load_mod() failed." % mod_name)
		return false

	var config: Dictionary = loaded_mods[mod_name].config
	var deps: Array = config.get("dependencies", {}).get("required", [])

	# 先启用依赖
	for dep in deps:
		if not loaded_mods.has(dep):
			push_error("[ModManager] Mod %s requires %s, but it is not loaded." % [mod_name, dep])
			return false
		if not loaded_mods[dep].enabled:
			if not enable_mod(dep):
				return false

	# 再启用自己
	return _enable_mod_internal(mod_name)


func _enable_mod_internal(mod_name: String) -> bool:
	var mod = loaded_mods[mod_name]
	var scene: Node = mod.scene

	if scene == null or not is_instance_valid(scene):
		push_warning("[ModManager] Mod %s has invalid scene when enabling." % mod_name)
		return false

	mod.enabled = true
	loaded_mods[mod_name] = mod

	if scene.has_method("enable_mod"):
		scene.enable_mod()

	print("[ModManager] Mod enabled: %s" % mod_name)
	return true


# ---------------------------------------------------------
# 禁用 mod（不卸载节点，只停用逻辑）
# ---------------------------------------------------------
func disable_mod(mod_name: String) -> bool:
	push_warning("[ModManager] [TODO] 实现更完整的热禁用逻辑")
	if not loaded_mods.has(mod_name):
		print("[ModManager] Mod does not exist: %s" % mod_name)
		return false
	if not loaded_mods[mod_name].enabled:
		print("[ModManager] Mod already disabled: %s" % mod_name)
		return true

	var mod = loaded_mods[mod_name]
	var scene: Node = mod.scene

	if scene != null and is_instance_valid(scene):
		if scene.has_method("disable_mod"):
			scene.disable_mod()

	mod.enabled = false
	loaded_mods[mod_name] = mod

	print("[ModManager] Mod disabled: %s" % mod_name)
	return true


# ---------------------------------------------------------
# 卸载 mod
# ---------------------------------------------------------
func unload_mod(mod_name: String) -> bool:
	if not loaded_mods.has(mod_name):
		print("[ModManager] Mod not loaded: %s" % mod_name)
		return false

	# 先禁用
	disable_mod(mod_name)

	var mod = loaded_mods[mod_name]
	var scene: Node = mod.scene

	# 删除入口场景实例
	if scene != null and is_instance_valid(scene):
		if scene.has_method("unload_mod"):
			scene.unload_mod()
		scene.queue_free()

	loaded_mods.erase(mod_name)
	print("[ModManager] Mod unloaded: %s" % mod_name)
	return true


# ---------------------------------------------------------
# 查询接口
# ---------------------------------------------------------
func get_loaded_mods() -> Array:
	return loaded_mods.keys()


func get_mod_config(mod_name: String) -> Dictionary:
	return loaded_mods.get(mod_name, {}).get("config", {})


func get_mod_data(mod_name: String) -> Dictionary:
	return loaded_mods.get(mod_name, {}).get("data", {})


func get_mod_scene(mod_name: String) -> Node:
	return loaded_mods.get(mod_name, {}).get("scene", null)


# ---------------------------------------------------------
# mod 交互
# ---------------------------------------------------------
func call_mod(mod_name: String, method: String, ...args) -> Variant:
	if not loaded_mods.has(mod_name):
		push_error("[ModManager] Mod not found: %s" % mod_name)
		return null

	var mod_data = loaded_mods[mod_name]
	if not mod_data.enabled:
		push_error("[ModManager] Mod %s is not enabled" % mod_name)
		return null

	var scene: Node = mod_data.scene
	if scene == null:
		push_error("[ModManager] Mod %s has no scene instance" % mod_name)
		return null

	if not scene.has_method(method):
		push_error("[ModManager] Mod %s does not implement method %s" % [mod_name, method])
		return null

	return scene.callv(method, args)


# ---------------------------------------------------------
# 事件系统：过滤器 + 快速分发表 + 分发 + Once 自动移除
# ---------------------------------------------------------

# { mod_name: [ModEventListenerFilter, ...] }
var _event_filters: Dictionary = {}

# { event_key: [mod_name, mod_name...] }
# event_key = event_name 或 "*"
var _event_dispatch_table: Dictionary = {}


# ---------------------------------------------------------
# 注册事件监听器
# ---------------------------------------------------------
func register_mod_event_listener(mod_name: String, filter: ModEventListenerFilter) -> void:
	if not loaded_mods.has(mod_name):
		push_warning("[ModManager] register_mod_event_listener: mod not loaded: %s" % mod_name)
		return

	if not _event_filters.has(mod_name):
		_event_filters[mod_name] = []

	_event_filters[mod_name].append(filter)

	_update_dispatch_table_for_filter(mod_name, filter)


# ---------------------------------------------------------
# 注销事件监听器
# ---------------------------------------------------------
func unregister_mod_event_listener(mod_name: String, filter: ModEventListenerFilter) -> void:
	if not _event_filters.has(mod_name):
		return

	_event_filters[mod_name].erase(filter)

	if _event_filters[mod_name].is_empty():
		_event_filters.erase(mod_name)

	_rebuild_dispatch_table()


# ---------------------------------------------------------
# 更新 dispatch table（单个 filter）
# ---------------------------------------------------------
func _update_dispatch_table_for_filter(mod_name: String, filter: ModEventListenerFilter) -> void:
	var key := "*"

	if filter.event_filter_type == ModEventListenerFilter.EventFilterType.TARGET \
	and filter.event_name != "":
		key = filter.event_name

	if not _event_dispatch_table.has(key):
		_event_dispatch_table[key] = []

	if not _event_dispatch_table[key].has(mod_name):
		_event_dispatch_table[key].append(mod_name)


# ---------------------------------------------------------
# 重建 dispatch table（用于 unregister）
# ---------------------------------------------------------
func _rebuild_dispatch_table() -> void:
	_event_dispatch_table.clear()

	for mod_name in _event_filters.keys():
		for filter in _event_filters[mod_name]:
			_update_dispatch_table_for_filter(mod_name, filter)


# ---------------------------------------------------------
# 匹配过滤器（返回匹配的 filter 或 null）
# ---------------------------------------------------------
func _match_filter_for_mod(target_mod: String, from_mod: String, event_name: String) -> ModEventListenerFilter:
	if not _event_filters.has(target_mod):
		return null

	for filter in _event_filters[target_mod]:
		if filter.matches(from_mod, event_name):
			return filter

	return null


# ---------------------------------------------------------
# 分发事件（核心）
# ---------------------------------------------------------
func emit_mod_event(from_mod: String, event_name: String, event_data: Dictionary = {}) -> void:
	var targets: Array = []

	# 精确匹配
	if _event_dispatch_table.has(event_name):
		targets.append_array(_event_dispatch_table[event_name])

	# ANY 匹配
	if _event_dispatch_table.has("*"):
		targets.append_array(_event_dispatch_table["*"])

	if targets.is_empty():
		return

	targets = targets.duplicate()
	targets = GameCore.ArrayTools.deduplicate(targets)

	var to_remove: Array = []

	for mod_name in targets:
		if not loaded_mods.has(mod_name):
			continue

		var mod_info = loaded_mods[mod_name]
		if not mod_info.enabled:
			continue

		var scene: Node = mod_info.scene
		if scene == null or not is_instance_valid(scene):
			continue

		var matched_filter := _match_filter_for_mod(mod_name, from_mod, event_name)
		if matched_filter == null:
			continue

		# 分发事件
		scene.call_deferred("on_mod_event", from_mod, event_name, event_data)

		# Once 自动移除
		if matched_filter.listen_type == ModEventListenerFilter.ListenType.ONCE:
			to_remove.append({"mod": mod_name, "filter": matched_filter})

	# 移除一次性监听器
	for item in to_remove:
		unregister_mod_event_listener(item.mod, item.filter)
