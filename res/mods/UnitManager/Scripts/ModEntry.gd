## ---------------------------------------------------------
## UnitManager 模块（单位模板管理）
##
## 功能说明：
## - 维护全局单位模板数据库
## - 支持按类型（Player/NPC/Enemy/Boss）分类管理
## - 支持按角色（WorldOnly/BattleOnly/Both）分类
## - 提供单位注册、查询、更新接口
## - 自动维护多种索引（类型、mod、地点）
## - 支持单位数据结构版本管理
##
## 单位模板数据格式：
## {
##   "id": "agumon",
##   "name": "亚古兽",
##   "unit_type": "Player",
##   "unit_role": "Both",
##   "model_path": "res://models/agumon.tscn",
##   "base_stats": {
##     "hp": 100,
##     "attack": 15,
##     "defense": 8
##   },
##   "skills": ["pepper_breath"],
##   "location": "file_island"
## }
##
## 依赖：
## - ModInterface（基础接口）
##
## 调用方式（其他 Mod）：
## GameCore.mod_manager.call_mod("UnitManager", "register_unit", [unit_data])
## GameCore.mod_manager.call_mod("UnitManager", "get_unit", [unit_id])
## GameCore.mod_manager.call_mod("UnitManager", "get_units_by_type", ["Player"])
##
## ---------------------------------------------------------
extends ModInterface
class_name UnitManager

## ---------------------------------------------------------
## 常量定义
## ---------------------------------------------------------

const UNIT_TYPE_PLAYER: String = "Player"
const UNIT_TYPE_NPC: String = "NPC"
const UNIT_TYPE_ENEMY: String = "Enemy"
const UNIT_TYPE_BOSS: String = "Boss"

const UNIT_ROLE_WORLD_ONLY: String = "WorldOnly"
const UNIT_ROLE_BATTLE_ONLY: String = "BattleOnly"
const UNIT_ROLE_BOTH: String = "Both"


## ---------------------------------------------------------
## 数据结构（全部显式类型）
## ---------------------------------------------------------

## 全量单位：id → data
var units: Dictionary = {}

## 分类索引
var units_by_type: Dictionary = {}     # type → [id, ...]
var units_by_mod: Dictionary = {}      # mod_name → [id, ...]
var units_by_location: Dictionary = {} # location_id → [id, ...]

## 按 unit_role 拆分
var world_units: Dictionary = {}       # id → data
var battle_units: Dictionary = {}      # id → data
var both_units: Dictionary = {}        # id → data


## ---------------------------------------------------------
## 生命周期
## ---------------------------------------------------------

func _on_mod_init() -> void:
	_init_type_buckets()
	print("[UnitManager] 初始化完成")


func _init_type_buckets() -> void:
	var all_types: Array = [
		UNIT_TYPE_PLAYER,
		UNIT_TYPE_NPC,
		UNIT_TYPE_ENEMY,
		UNIT_TYPE_BOSS
	]

	for t: String in all_types:
		units_by_type[t] = []


## ---------------------------------------------------------
## 注册单个单位（显式类型）
## ---------------------------------------------------------

func register_unit(data: Dictionary) -> void:
	if not data.has("id") or not data.has("mod") or not data.has("type"):
		push_error("[UnitManager] 注册单位失败：缺少必要字段 id/mod/type")
		return

	var id: String = str(data["id"])
	var mod_name: String = str(data["mod"])
	var type_name: String = str(data["type"])
	var role: String = str(data.get("unit_role", UNIT_ROLE_WORLD_ONLY))

	var location_id: String = ""
	if data.has("location") and data["location"] != null:
		location_id = str(data["location"])

	## 写入全量表
	units[id] = data

	## 按 type 索引
	var type_arr: Array = units_by_type.get(type_name, [])
	if not type_arr.has(id):
		type_arr.append(id)
		units_by_type[type_name] = type_arr

	## 按 mod 索引
	var mod_arr: Array = units_by_mod.get(mod_name, [])
	if not mod_arr.has(id):
		mod_arr.append(id)
		units_by_mod[mod_name] = mod_arr

	## 按 location 索引
	if location_id != "":
		var loc_arr: Array = units_by_location.get(location_id, [])
		if not loc_arr.has(id):
			loc_arr.append(id)
			units_by_location[location_id] = loc_arr

	## 按 unit_role 分类
	match role:
		UNIT_ROLE_WORLD_ONLY:
			world_units[id] = data

		UNIT_ROLE_BATTLE_ONLY:
			battle_units[id] = data

		UNIT_ROLE_BOTH:
			both_units[id] = data
			world_units[id] = data
			battle_units[id] = data

		_:
			push_warning("[UnitManager] 未知 unit_role=%s, id=%s，按 WorldOnly 处理" % [role, id])
			world_units[id] = data


## ---------------------------------------------------------
## 批量注册（显式类型）
## ---------------------------------------------------------

func register_units_from_json(json_path: String) -> void:
	var file: FileAccess = FileAccess.open(json_path, FileAccess.READ)
	if file == null:
		push_error("[UnitManager] 无法读取 JSON 文件: %s" % json_path)
		return

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("[UnitManager] JSON 格式错误: %s" % json_path)
		return

	var dict: Dictionary = parsed
	for key: String in dict.keys():
		var v: Variant = dict[key]
		if typeof(v) == TYPE_DICTIONARY:
			var unit_data: Dictionary = v
			if not unit_data.has("id"):
				unit_data["id"] = key
			register_unit(unit_data)


## ---------------------------------------------------------
## 基础查询（显式类型）
## ---------------------------------------------------------

func get_unit(unit_id: String) -> Dictionary:
	var v: Variant = units.get(unit_id)
	return v if typeof(v) == TYPE_DICTIONARY else {}


func has_unit(unit_id: String) -> bool:
	return units.has(unit_id)


func get_all_units() -> Array:
	return units.keys()


## ---------------------------------------------------------
## 按类型 / mod / 地点 / 标签查询
## ---------------------------------------------------------

func get_units_by_type(type_name: String) -> Array:
	return units_by_type.get(type_name, [])


func get_units_by_mod(mod_name: String) -> Array:
	return units_by_mod.get(mod_name, [])


func get_units_by_location(location_id: String) -> Array:
	return units_by_location.get(location_id, [])


func get_units_by_tag(tag: String) -> Array:
	var result: Array = []
	for id: String in units.keys():
		var data: Dictionary = units[id]
		var tags_v: Variant = data.get("tags", [])
		if typeof(tags_v) == TYPE_ARRAY:
			var tags: Array = tags_v
			if tag in tags:
				result.append(id)
	return result


## ---------------------------------------------------------
## 按 unit_role 查询（显式类型）
## ---------------------------------------------------------

func get_world_unit_ids() -> Array:
	return world_units.keys()


func get_battle_unit_ids() -> Array:
	return battle_units.keys()


func get_both_unit_ids() -> Array:
	return both_units.keys()


func get_world_units_data() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for id: String in world_units.keys():
		result.append(world_units[id])
	return result


func get_battle_units_data() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for id: String in battle_units.keys():
		result.append(battle_units[id])
	return result


func get_both_units_data() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for id: String in both_units.keys():
		result.append(both_units[id])
	return result


## ---------------------------------------------------------
## 更新单位所在地点（显式类型）
## ---------------------------------------------------------

func set_unit_location(unit_id: String, new_location_id: String) -> void:
	if not units.has(unit_id):
		push_error("[UnitManager] set_unit_location 失败：单位不存在: %s" % unit_id)
		return

	var data: Dictionary = units[unit_id]
	var old_location_id: String = str(data.get("location", ""))

	## 从旧地点移除
	if old_location_id != "":
		var old_arr: Array = units_by_location.get(old_location_id, [])
		if old_arr.has(unit_id):
			old_arr.erase(unit_id)
			units_by_location[old_location_id] = old_arr

	## 写入新地点
	data["location"] = new_location_id
	units[unit_id] = data

	if new_location_id != "":
		var new_arr: Array = units_by_location.get(new_location_id, [])
		if not new_arr.has(unit_id):
			new_arr.append(unit_id)
			units_by_location[new_location_id] = new_arr
