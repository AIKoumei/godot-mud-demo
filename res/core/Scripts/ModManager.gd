## Mod 管理核心脚本
## 负责 mod 扫描、加载、卸载、入口场景调度
class_name ModManager
extends RefCounted

const VERSION := "v0.0.1"

## 已加载的 mod 数据
var loaded_mods: Dictionary = {}   # { mod_name: {config, data, path, scene, enabled} }

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
# 加载所有 mod
# ---------------------------------------------------------
func load_all_mods(mods_path: String = MODS_ROOT) -> void:
	print("[ModManager] Scanning mods from: %s" % mods_path)

	var dir := DirAccess.open(mods_path)
	if dir == null:
		push_error("[ModManager] Cannot open mods directory: %s" % mods_path)
		return

	dir.list_dir_begin()
	var name := dir.get_next()

	while name != "":
		if name != "." and name != ".." and name != "mod_template" and dir.current_is_dir():
			load_mod(name, mods_path)
		name = dir.get_next()

	dir.list_dir_end()


# ---------------------------------------------------------
# 加载单个 mod
# ---------------------------------------------------------
func load_mod(mod_name: String, mods_path: String = MODS_ROOT) -> bool:
	if mod_name in loaded_mods:
		print("[ModManager] Mod already loaded: %s" % mod_name)
		return false

	var mod_path := "%s/%s" % [mods_path, mod_name]
	print("[ModManager] Loading mod: %s" % mod_path)

	# 读取配置
	var config_path := "%s/Config/ModuleConfig.json" % mod_path
	var data_path   := "%s/Config/ModuleData.json" % mod_path

	var config := load_json(config_path)
	var data   := load_json(data_path)

	if config.is_empty() or data.is_empty():
		push_warning("[ModManager] [Mod:%s] missing config or data" % mod_name)
		return false
		
	loaded_mods[mod_name] = {
		"config": config,
		"data": data,
		"path": mod_path,
		"script": null,
		"scene": null,
		"enabled": false
	}

	# 加载 mod 脚本
	var entry_script_path = "%s/Scripts/ModEntry.gd" % [loaded_mods[mod_name].path]
	if not ResourceLoader.exists(entry_script_path):
		push_warning("[ModManager] Entry script not found: %s" % entry_script_path)
		return false
	var entry_script = load(entry_script_path) as Script
	
	# 加载入口场景
	var scene_res
	var scene_instance
	
	var entry_scene_path = config.get("entry_scene", "")
	if entry_scene_path == "":
		push_warning("[ModManager] Mod %s has no entry_scene" % mod_name)
		# 默认给一个空 Node
		scene_instance = Node.new()
		scene_instance.name = "[Mod] %s" % mod_name
	elif not ResourceLoader.exists(entry_scene_path):
		push_warning("[ModManager] Entry scene not found: %s" % entry_scene_path)
		return false
	else:
		scene_res = load(entry_scene_path)
		scene_instance = scene_res.instantiate()
		
	scene_instance.set_script(entry_script)
	scene_instance.mod_name = mod_name
	scene_instance.mod_data = loaded_mods[mod_name].data
	scene_instance.mod_config = loaded_mods[mod_name].config
	loaded_mods[mod_name].scene = scene_instance

	# 添加到场景树
	# [TODO] 通过 GameCore/GameSceneLayerManager 来控制挂载 mod 节点的位置
	push_warning("[ModManager] [TODO] 通过 GameCore/GameSceneLayerManager 来控制挂载 mod 节点的位置")
	GameCore.get_mods_layer().add_child(scene_instance)
	
	scene_instance.load_mod()
	
	if not config.get("enabled", true):
		return true
	
	return enable_mod(mod_name)

func enable_mod(mod_name: String) -> bool:
	if not mod_name or not loaded_mods.get(mod_name):
		print("[ModManager] Mod is not exists: %s" % mod_name)
		return false
	if loaded_mods[mod_name].enabled:
		print("[ModManager] Mod is already enabled")
		return false
	
	loaded_mods[mod_name].enabled = true
	
	# [TODO]
	# [x] 没有重新写入 config/data/path，
	# 虽然它们已经在 load_mod() 中写入了，但如果未来你想支持：
	# 	[x] reload mod
	# 	[x] 修改 config 后重新 enable
	# 	[x] 热重载

	print("[ModManager] Mod loaded successfully: %s" % mod_name)
	loaded_mods[mod_name].scene.enable_mod()
	return true

func disable_mod(mod_name: String) -> bool:
	# [TODO] 实现热禁用节点
	#	未来需要：
	#		[x] 热更新 mod
	#		[x] 临时禁用 mod
	#		[x] 切换 mod
	#	实现：
	#		[x] 清理脚本引用
	#		[x] 清理事件绑定
	#		[x] 清理资源引用
	push_warning("[ModManager] [TODO] 实现热禁用节点")
	if not mod_name or not loaded_mods.get(mod_name):
		print("[ModManager] Mod is not exists: %s" % mod_name)
		return false
	if not loaded_mods[mod_name].enabled:
		print("[ModManager] Mod is already disable")
		return false
	loaded_mods[mod_name].scene.disable_mod()
	return true


# ---------------------------------------------------------
# 卸载 mod
# ---------------------------------------------------------
func unload_mod(mod_name: String) -> bool:
	if mod_name not in loaded_mods:
		print("[ModManager] Mod not loaded: %s" % mod_name)
		return false

	disable_mod(mod_name)
	
	var mod = loaded_mods[mod_name]
	
	# 删除入口场景实例
	if mod["scene"] != null and is_instance_valid(mod["scene"]):
		mod["scene"].unload_mod()
		mod["scene"].queue_free()

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
func call_mod(mod_name, func_name = "", args = null) -> void:
	if args == null : args = {}
	if not loaded_mods.has(mod_name):
		push_warning("[ModManager] 无效的 mod_name : %s" % [mod_name])
		return
	var mod = loaded_mods[mod_name]
	if not mod.enabled:
		push_warning("[ModManager] mod : %s 未开启" % [mod_name])
		return
	if not func_name or func_name == "":
		push_warning("[ModManager] 无效的 func_name : %s" % [func_name])
		return
	if mod.scene and mod.scene.has_method(func_name):
		mod.scene.call(func_name, args)
	return
