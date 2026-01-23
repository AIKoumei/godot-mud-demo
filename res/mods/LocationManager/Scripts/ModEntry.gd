## ---------------------------------------------------------
## LocationManager 模块（分级地点数据管理 / ModInterface 版本）
##
## 功能说明：
## - 维护全局地点数据库（可被多个 Mod 扩展）
## - 支持数码世界（Digital World）与现实世界（Real World）两套分级结构
## - 提供单个地点注册与 JSON 批量导入接口
## - 提供按 ID / 类型 / 父级 / 世界类型 / 标签 等多种查询方式
## - 自动维护父子关系（children），可用于构建地点树、快速旅行 UI 等
## - 支持数据结构版本字段 version，用于升级地点数据
##
## 单个地点数据格式（顶层必须包含 version）：
## {
##   "version": "1.0.0",
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
## 数码世界（Digital World）最终层级结构
##
##   DigitalWorld（世界根）
##     └── Continent（大陆）
##            ├── Island（岛屿）
##            │      └── Region（地域）
##            │
##            └── Field（场域）
##                   └── Zone（区域，最终可进入地点）
##
## 约束：
## - Region 的父级必须是 Island
## - Field 的父级必须是 Continent
## - Zone 的父级必须是 Field
## - Region 下没有 Field，也没有 Zone
##
## ---------------------------------------------------------
## 现实世界（Real World）层级结构
##
##   RealWorld（世界根）
##     └── Country（国家）
##            └── City（城市）
##                   └── Location（地点，最终可进入地点）
##
## ---------------------------------------------------------
## 可能涉及的外部模块（交互提示）
##
## - World：根据地点数据加载地图、切换场景、生成玩家
## - GameManager：新游戏出生点、读档恢复地点、切换地点逻辑
## - PlayerData：保存/读取玩家当前所在地点 ID
## - Save：存档记录当前地点、读档恢复地点
## - UI：世界地图 UI、地点选择 UI、快速旅行界面
## - Quest：任务目标地点、区域触发事件
## - NPC：NPC 出生地点、移动路线、驻留区域
## - Encounter/Event：区域事件、随机遭遇、区域触发器
## - FastTravel：快速旅行地点列表、地点树展示
## - LocationGenerator：外部 Mod 自动生成地点数据时调用本模块注册接口
##
## ---------------------------------------------------------

extends ModInterface

var VERSION: String = "1.0.0"

const WORLD_TYPE_DIGITAL: String = "DigitalWorld"
const WORLD_TYPE_REAL: String = "RealWorld"

const TYPE_DIGITAL_WORLD: String = "DigitalWorld"
const TYPE_CONTINENT: String = "Continent"
const TYPE_ISLAND: String = "Island"
const TYPE_REGION: String = "Region"
const TYPE_FIELD: String = "Field"
const TYPE_ZONE: String = "Zone"

const TYPE_REAL_WORLD: String = "RealWorld"
const TYPE_COUNTRY: String = "Country"
const TYPE_CITY: String = "City"
const TYPE_LOCATION: String = "Location"

var locations: Dictionary = {}
var locations_by_type: Dictionary = {}
var children_map: Dictionary = {}


func _on_mod_init() -> void:
	_init_type_buckets()


func _init_type_buckets() -> void:
	var all_types: Array = [
		TYPE_DIGITAL_WORLD,
		TYPE_CONTINENT,
		TYPE_ISLAND,
		TYPE_REGION,
		TYPE_FIELD,
		TYPE_ZONE,
		TYPE_REAL_WORLD,
		TYPE_COUNTRY,
		TYPE_CITY,
		TYPE_LOCATION
	]
	for t in all_types:
		var type_name: String = t
		locations_by_type[type_name] = []


func register_location(data: Dictionary) -> void:
	if not data.has("id") or not data.has("world_type") or not data.has("type"):
		push_error("[LocationManager] 注册地点失败：缺少必要字段 id/world_type/type")
		return

	var data_version: String = str(data.get("version", ""))
	if data_version == "":
		push_warning("[LocationManager] 地点数据缺少 version 字段，将视为旧版本，id=" + str(data["id"]))
		data_version = "0.0.0"

	if data_version != VERSION:
		push_warning("[LocationManager] 地点数据版本不匹配，尝试升级: id=%s, data_version=%s, mod_version=%s" % [str(data["id"]), data_version, VERSION])
		data = _upgrade_location_data(data, data_version, VERSION)
		data["version"] = VERSION
	else:
		data["version"] = VERSION

	var id: String = str(data["id"])
	var type_name: String = str(data["type"])
	var parent_id: String = ""
	if data.has("parent") and data["parent"] != null:
		parent_id = str(data["parent"])

	locations[id] = data

	var arr: Array = locations_by_type.get(type_name, [])
	if id not in arr:
		arr.append(id)
		locations_by_type[type_name] = arr

	if parent_id != "":
		var child_arr: Array = children_map.get(parent_id, [])
		if id not in child_arr:
			child_arr.append(id)
			children_map[parent_id] = child_arr


func register_locations_from_json(json_path: String) -> void:
	var file: FileAccess = FileAccess.open(json_path, FileAccess.READ)
	if file == null:
		push_error("[LocationManager] 无法读取 JSON 文件: " + json_path)
		return

	var content: String = file.get_as_text()
	var parsed: Variant = JSON.parse_string(content)

	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("[LocationManager] JSON 格式错误: " + json_path)
		return

	var dict: Dictionary = parsed
	for key in dict.keys():
		var data_variant: Variant = dict[key]
		if typeof(data_variant) == TYPE_DICTIONARY:
			var loc_data: Dictionary = data_variant
			if not loc_data.has("id"):
				loc_data["id"] = key
			register_location(loc_data)


func get_location(location_id: String) -> Dictionary:
	var result: Variant = locations.get(location_id)
	if typeof(result) == TYPE_DICTIONARY:
		return result
	return {}


func has_location(location_id: String) -> bool:
	return locations.has(location_id)


func get_location_children(location_id: String) -> Array:
	var arr: Array = children_map.get(location_id, [])
	return arr


func get_location_parent(location_id: String) -> String:
	if not locations.has(location_id):
		return ""
	var data: Dictionary = locations[location_id]
	var parent_value: Variant = data.get("parent", "")
	return str(parent_value)


func get_locations_by_type(type_name: String) -> Array:
	var arr: Array = locations_by_type.get(type_name, [])
	return arr


func get_locations_by_world_type(world_type: String) -> Array:
	var result: Array = []
	for id in locations.keys():
		var data: Dictionary = locations[id]
		var wt: String = str(data.get("world_type", ""))
		if wt == world_type:
			result.append(id)
	return result


func get_locations_by_tag(tag: String) -> Array:
	var result: Array = []
	for id in locations.keys():
		var data: Dictionary = locations[id]
		var tags_variant: Variant = data.get("tags", [])
		if typeof(tags_variant) == TYPE_ARRAY:
			var tags: Array = tags_variant
			if tag in tags:
				result.append(id)
	return result


func get_all_locations() -> Array:
	return locations.keys()


func get_root_locations() -> Array:
	var result: Array = []
	for id in locations.keys():
		var parent_id: String = get_location_parent(id)
		if parent_id == "":
			result.append(id)
	return result


func _upgrade_location_data(old_data: Dictionary, old_version: String, new_version: String) -> Dictionary:
	# 这里可以根据 old_version → new_version 做字段迁移
	# 当前默认直接返回旧数据
	return old_data
