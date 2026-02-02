## #############################################################################
## SaveManager.gd - 用户数据存取模块
## 结构：
##   1. 业务逻辑层 (save_game, load_game, 预览信息获取)
##   2. Slot 抽象层 (对特定存档位的操作)
##   3. Mod 扩展层 (针对 Mod 的专用接口)
##   4. 文件核心层 (最底层的 JSON/加密 读写实现)
##   5. 工具函数层 (路径扫描、物理删除等)
## #############################################################################

extends Node

# 默认配置
const DEFAULT_SAVE_PATH = "user://saves"
const SECRET_KEY = "YourCustomKey_4.6"

# ------------------------------------------------------------------------------
# 1. 业务逻辑层 (Business Logic)
# ------------------------------------------------------------------------------

## 保存完整游戏状态 (主存档 + 预览信息)
func save_game(slot_id: int):
	# TODO: 获取实际游戏数据
	var game_data = {} 
	save_slot_data(slot_id, "save.sav", game_data, true) # 主存档通常建议加密
	
	# 保存预览小数据 (用于 Load 界面展示)
	var preview_info = {
		"player_name": "勇者",
		"level": 15,
		"save_time": Time.get_datetime_string_from_system()
	}
	save_slot_data(slot_id, "info.json", preview_info, false)

## 加载主游戏存档
func load_game(slot_id: int) -> Dictionary:
	var loaded_data = load_slot_data(slot_id, "save.sav", true)
	if not loaded_data.is_empty():
		print("加载 存档位 %d 成功" % slot_id)
	return loaded_data

## 获取所有可用存档的预览信息列表 (用于 UI 渲染列表)
func get_all_save_slots_info() -> Array[Dictionary]:
	var all_info: Array[Dictionary] = []
	var available_ids = get_available_slots()
	
	for id in available_ids:
		var info = load_game_slot_info(id)
		if not info.is_empty():
			all_info.append(info)
		else:
			all_info.append({
				"slot_id": id,
				"player_name": "未知存档",
				"level": 0,
				"save_time": "损坏或无数据"
			})
	return all_info

## 读取单个存档位的预览数据
func load_game_slot_info(slot_id: int) -> Dictionary:
	var info = load_slot_data(slot_id, "info.json", false)
	if info.is_empty():
		return {}
	info["slot_id"] = slot_id # 注入 ID 方便 UI 识别
	return info

# ------------------------------------------------------------------------------
# 2. Slot 抽象层 (Slot Abstraction) - 新增检查函数
# ------------------------------------------------------------------------------

## 检查特定的存档位 (文件夹) 是否存在
func has_slot(slot_id: int) -> bool:
	var path = "user://saves/slot_%d" % slot_id
	return DirAccess.dir_exists_absolute(path)

## 检查指定 Slot 内的某个文件是否存在
## @param filepath: 相对于 slot 目录的路径，例如 "save.sav" 或 "mods/my_mod.sav"
func has_slot_file(slot_id: int, filepath: String) -> bool:
	var base_dir = "user://saves/slot_%d" % slot_id
	var full_path = base_dir.path_join(filepath)
	var file_exists = FileAccess.file_exists(full_path)
	return file_exists

func has_mod_slot_file(slot_id: int, filepath: String) -> bool:
	var base_dir = "user://saves/slot_%d/mods" % slot_id
	var full_path = base_dir.path_join(filepath)
	var file_exists = FileAccess.file_exists(full_path)
	return file_exists

## 对指定 Slot 目录下的文件进行存
func save_slot_data(slot_id: int, filepath: String, data: Dictionary, encrypt: bool = false):
	var base_dir = "user://saves/slot_%d" % slot_id
	var full_path = base_dir.path_join(filepath) 
	return save_dict_to_path(data, full_path, encrypt)

## 对指定 Slot 目录下的文件进行取
func load_slot_data(slot_id: int, filepath: String, encrypt: bool = false) -> Dictionary:
	var base_dir = "user://saves/slot_%d" % slot_id
	var full_path = base_dir.path_join(filepath)
	return load_dict_from_path(full_path, encrypt)

## 删除指定 Slot 的所有目录和文件
func delete_slot(slot_id: int):
	var path = "user://saves/slot_%d" % slot_id
	if DirAccess.dir_exists_absolute(path):
		var err = OS.move_to_trash(ProjectSettings.globalize_path(path))
		if err != OK:
			_delete_dir_recursive(path)
		print("存档位 %d 已彻底删除" % slot_id)

# ------------------------------------------------------------------------------
# 3. Mod 扩展层 (Mod Extensions)
# ------------------------------------------------------------------------------

## Mod 专用存档接口
func save_mod_slot_data(slot_id: int, mod_name: String, data: Dictionary, encrypt: bool = false):
	return save_slot_data(slot_id, "mods/%s.sav" % mod_name, data, encrypt)

## Mod 专用读取接口
func load_mod_slot_data(slot_id: int, mod_name: String, encrypt: bool = false) -> Dictionary:
	return load_slot_data(slot_id, "mods/%s.sav" % mod_name, encrypt)

# ------------------------------------------------------------------------------
# 4. 文件核心层 (File Core IO)
# ------------------------------------------------------------------------------

## 将字典序列化为 JSON 并写入文件
func save_dict_to_path(data: Dictionary, path: String, encrypt: bool = false):
	var dir = path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir):
		DirAccess.make_dir_recursive_absolute(dir)
	
	var file: FileAccess
	if encrypt:
		file = FileAccess.open_encrypted_with_pass(path, FileAccess.WRITE, SECRET_KEY)
	else:
		file = FileAccess.open(path, FileAccess.WRITE)
		
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()
		return OK
	return FileAccess.get_open_error()

## 从文件读取 JSON 并解析回字典
func load_dict_from_path(path: String, encrypt: bool = false) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}

	var file: FileAccess
	if encrypt:
		file = FileAccess.open_encrypted_with_pass(path, FileAccess.READ, SECRET_KEY)
	else:
		file = FileAccess.open(path, FileAccess.READ)
		
	if file:
		var json_string = file.get_as_text()
		file.close()
		var json = JSON.new()
		if json.parse(json_string) == OK and json.data is Dictionary:
			return json.data
	return {}

# ------------------------------------------------------------------------------
# 5. 工具函数层 (Utilities)
# ------------------------------------------------------------------------------

## 获取所有 slot_ 开头的目录 ID 列表
func get_available_slots() -> Array[int]:
	var slots: Array[int] = []
	var path = "user://saves/"
	if not DirAccess.dir_exists_absolute(path):
		return slots
		
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir() and file_name.begins_with("slot_"):
				slots.append(file_name.get_slice("_", 1).to_int())
			file_name = dir.get_next()
	slots.sort()
	return slots

## 物理递归删除目录
func _delete_dir_recursive(path: String):
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				_delete_dir_recursive(path.path_join(file_name))
			else:
				dir.remove(file_name)
			file_name = dir.get_next()
		DirAccess.remove_absolute(path)



func wrap_data_with_metadata(data: Dictionary, extra_metadata: Dictionary = {}) -> Dictionary:
	# 1. 定义基础/默认元数据
	var final_metadata = {
		"version": "1.0",
		"generated_at": Time.get_datetime_string_from_system(),
	}

	# 2. 如果提供了额外的元数据，则合并它们
	if not extra_metadata.is_empty():
		for key in extra_metadata:
			final_metadata[key] = extra_metadata[key]
		# 强制更新时间戳，确保它是最新的保存时刻
		final_metadata["generated_at"] = Time.get_datetime_string_from_system()

	return {
		"metadata": final_metadata,
		"data": data
	}

# 调用示例
func save_current_units(slot_id: int):
	#var payload = { "units": UnitInstanceManager.get_all_serialized_units() }
	var payload = { }
	var final_packet = wrap_data_with_metadata(payload,{
			"version": "1.0",
			"generated_at": Time.get_datetime_string_from_system(),
			"total_units": payload.get("units", {}).size()
		})
	save_slot_data(slot_id, "temp/units_state.sav", final_packet)
