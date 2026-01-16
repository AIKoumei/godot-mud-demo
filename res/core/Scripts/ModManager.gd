## Mod 管理核心脚本
## 负责 mod 扫描、依赖解析、加载、卸载、入口场景调度
class_name ModManager
extends RefCounted

const VERSION := "v0.0.1"

## 已加载的 mod 数据
## { mod_name: {config, data, path, scene, enabled} }
var loaded_mods: Dictionary = {}

## 默认 mod 根目录
const MODS_ROOT := "res://res/mods"


# ---------------------------------------------------------
# 生命周期
# ---------------------------------------------------------
func _init() -> void:
	print("[ModManager] Initialized, version: %s" % VERSION)


# ---------------------------------------------------------
# JSON 加载工具
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
# ---------------------------------------------------------
func load_mod(mod_name: String, mods_path: String = MODS_ROOT) -> bool:
	if mod_name in loaded_mods:
		print("[ModManager] Mod already loaded: %s" % mod_name)
		return true

	var mod_path := "%s/%s" % [mods_path, mod_name]
	print("[ModManager] Loading mod: %s" % mod_path)

	# 读取配置
	var config_path := "%s/Config/ModuleConfig.json" % mod_path
	var data_path   := "%s/Config/ModuleData.json" % mod_path

	var config := load_json(config_path)
	var data   := load_json(data_path)

	if config.is_empty() or data.is_empty():
		push_warning("[ModManager] Mod %s missing config or data" % mod_name)
		return false

	loaded_mods[mod_name] = {
		"config": config,
		"data": data,
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

	var entry_scene_path = config.get("entry_scene", "")
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

	# 挂到 ModsLayer
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

	# 关键：使用 callv，并把 ...args 转成数组
	return scene.callv(method, args)
