extends ModInterface
class_name WorldMapInstanceManager

## ---------------------------------------------------------
## WorldMapInstanceManager 模块（世界地图运行时实例管理）
##
## 功能说明：
## - 管理多个 location 的运行时实例（map_data + state）
## - 从 WorldMapManager 复制静态地图数据，生成可修改的实例
## - 负责地图玩法层的运行时数据（破坏、建造、掉落、单位位置等）
## - 不负责可视化（由 WorldSceneManager 负责）
##
## 数据结构（示例）：
## _instances = {
##   "file_island": {
##       "version": 1,
##       "location_id": "file_island",
##       "map_data": [
##           { "x": 0, "y": 0, "tile": "grass" },
##           { "x": 1, "y": 0, "tile": "tree", "breakable": true, "hp": 20 },
##           { "x": 2, "y": 0, "tile": "rock", "breakable": true, "hp": 40 },
##           { "x": 3, "y": 4, "drop": { "item": "wood", "amount": 1 } },
##           { "x": 10, "y": 5, "building": { "type": "small_house" } },
##           { "x": 6, "y": 7, "unit": { "instance_id": "agumon#0002" } }
##       ],
##       "state": {
##           "weather": "sunny",
##           "light_level": 1.0
##       }
##   }
## }
##
## ---------------------------------------------------------

var _instances: Dictionary = {}
var _current_location_id: String = ""


func _on_mod_load() -> bool:
	print("[WorldMapInstanceManager] 模块已加载")
	return true


# ---------------------------------------------------------
# 加载某个 location 的实例（如果不存在则创建）
# ---------------------------------------------------------
func load_location(location_id: String) -> bool:
	if _instances.has(location_id):
		_current_location_id = location_id
		print("[WorldMapInstanceManager] Reuse existing instance:", location_id)
		return true

	var static_data = GameCore.mod_manager.call_mod(
		"WorldMapManager",
		"get_location_static",
		location_id
	) as Dictionary

	if static_data == null or static_data.is_empty():
		push_error("[WorldMapInstanceManager] Invalid location: %s" % location_id)
		return false

	var instance: Dictionary = {
		"version": static_data.get("version", 1),
		"location_id": location_id,
		"map_data": static_data.get("map_data", []).duplicate(true),
		"state": {
			"weather": static_data.get("metadata", {}).get("weather_type", "sunny"),
			"light_level": 1.0
		}
	}

	_instances[location_id] = instance
	_current_location_id = location_id

	print("[WorldMapInstanceManager] Created instance for:", location_id)
	return true


# ---------------------------------------------------------
# 获取当前实例
# ---------------------------------------------------------
func get_current_instance() -> Dictionary:
	return _instances.get(_current_location_id, {})


# ---------------------------------------------------------
# 获取某个实例
# ---------------------------------------------------------
func get_instance(location_id: String) -> Dictionary:
	return _instances.get(location_id, {})


# ---------------------------------------------------------
# 获取某个实例的 map_data
# ---------------------------------------------------------
func get_map_data(location_id: String) -> Array:
	return _instances.get(location_id, {}).get("map_data", [])


# ---------------------------------------------------------
# 设置单位在地图玩法上的逻辑位置
# （在 map_data 中写入 unit 信息）
# ---------------------------------------------------------
func set_unit_position(location_id: String, unit_instance_id: String, x: int, y: int) -> void:
	if not _instances.has(location_id):
		push_warning("[WorldMapInstanceManager] set_unit_position: no instance for %s" % location_id)
		return

	var inst: Dictionary = _instances[location_id]
	var map_data: Array = inst.get("map_data", [])

	# 先移除旧位置上的该单位
	for tile in map_data:
		if tile.has("unit") and tile["unit"].get("instance_id", "") == unit_instance_id:
			tile.erase("unit")

	# 再在新位置写入
	var found: bool = false
	for tile in map_data:
		if int(tile.get("x", -1)) == x and int(tile.get("y", -1)) == y:
			tile["unit"] = { "instance_id": unit_instance_id }
			found = true
			break

	# 如果该格子不存在，则创建一个新格子
	if not found:
		map_data.append({
			"x": x,
			"y": y,
			"unit": { "instance_id": unit_instance_id }
		})

	inst["map_data"] = map_data
	_instances[location_id] = inst


# ---------------------------------------------------------
# 通用格子修改接口（破坏、建造、掉落等）
# ---------------------------------------------------------
func merge_tile_data(location_id: String, x: int, y: int, data: Dictionary) -> void:
	if not _instances.has(location_id):
		push_warning("[WorldMapInstanceManager] merge_tile_data: no instance for %s" % location_id)
		return

	var inst: Dictionary = _instances[location_id]
	var map_data: Array = inst.get("map_data", [])

	var found: bool = false
	for tile in map_data:
		if int(tile.get("x", -1)) == x and int(tile.get("y", -1)) == y:
			tile.merge(data)
			found = true
			break

	if not found:
		var new_tile: Dictionary = { "x": x, "y": y }
		new_tile.merge(data)
		map_data.append(new_tile)

	inst["map_data"] = map_data
	_instances[location_id] = inst


# ---------------------------------------------------------
# 世界更新（所有实例）
# ---------------------------------------------------------
func update(delta: float) -> void:
	for location_id in _instances.keys():
		_update_instance(location_id, delta)


func _update_instance(location_id: String, delta: float) -> void:
	var inst: Dictionary = _instances[location_id]
	# TODO: 天气变化、单位 AI、掉落物刷新等
	pass
