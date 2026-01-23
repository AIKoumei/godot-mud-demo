## ---------------------------------------------------------
## DefaultLocations 模块（基础地点数据）
##
## 功能说明：
## - 提供游戏初始地点数据（数码世界与现实世界）
## - 支持从 JSON 文件批量加载地点数据
## - 在 _on_mod_load() 加载 JSON
## - 在 _on_mod_enable() 注册地点（更符合模块生命周期哲学）
##
## 地点数据格式：
## {
##   "id": "file_island",
##   "name": "文件岛",
##   "world_type": "DigitalWorld",
##   "type": "Island",
##   "parent": "file_continent",
##   "map_path": "res://maps/file_island.tscn",
##   "spawn_point": "Entry",
##   "tags": ["digital", "island"]
## }
##
## ---------------------------------------------------------

extends ModInterface

var _locations: Dictionary = {}   # 在 load 阶段加载，在 enable 阶段注册


# ---------------------------------------------------------
# 生命周期：模块加载（只加载 JSON，不注册）
# ---------------------------------------------------------
func _on_mod_load() -> bool:
	print("[DefaultLocations] 加载基础地点数据...")

	var json_path := "%s/Data/Locations.json" % get_mod_path()
	var file := FileAccess.open(json_path, FileAccess.READ)

	if file == null:
		push_warning("[DefaultLocations] 无法读取地点文件: %s" % json_path)
		return false

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("[DefaultLocations] JSON 格式错误: %s" % json_path)
		return false

	_locations = parsed

	print("[DefaultLocations] JSON 加载完成，共 %d 个地点" % _locations.size())
	return true


# ---------------------------------------------------------
# 生命周期：模块启用（此时依赖模块已启用）
# ---------------------------------------------------------
func _on_mod_enable() -> void:
	print("[DefaultLocations] 注册地点数据...")

	for id in _locations.keys():
		var loc_data: Dictionary = _locations[id]

		# 直接调用 LocationManager（此时已启用）
		var ok = GameCore.mod_manager.call_mod(
			"LocationManager",
			"register_location",
			loc_data
		)

		if ok == null or ok == false:
			push_warning("[DefaultLocations] 注册地点失败: %s" % id)

	print("[DefaultLocations] 地点注册完成")


# ---------------------------------------------------------
# 获取当前 mod 的根目录
# ---------------------------------------------------------
func get_mod_path() -> String:
	return GameCore.mod_manager.loaded_mods[mod_name].path
