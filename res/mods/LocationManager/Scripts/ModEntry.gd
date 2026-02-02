## ---------------------------------------------------------
## LocationManager 模块（分级地点数据管理 / ModInterface 版本）
##
## 功能说明：
## - 维护全局地点数据库（可被多个 Mod 扩展）
## - 提供单个地点注册与 JSON 批量导入接口
## - 提供按 ID / 类型 / 父级 / 层级类型 等多种查询方式
## - 自动维护父子关系（children），可用于构建地点树、快速旅行 UI 等
## - 支持数据结构版本字段 version，用于升级地点数据
##
## 单个地点数据格式（基于 Locations.json）：
## {
##   "name": "地点名称",
##   "Kanji/Kana": {"content": "日文名称", "url": "链接"},
##   "inhabitants": {"居民1": [{"text": "居民详情", "url": "链接"}]},
##   "url": "参考链接",
##   "introduce": "简介",
##   "description": "详细描述",
##   "type": {"content": "类型", "url": "链接"},
##   "location level type": "层级类型",
##   "version": "1.0.0"
## }
##
## 地点关系数据格式（基于 Locations.json）：
## "relationships": {
##   "父地点ID": ["子地点ID1", "子地点ID2", ...]
## }
##
## 支持的层级类型：
## - World：世界层级
## - Continent：大陆层级
## - Region：区域层级
## - Area：地区层级
## - Location：地点层级
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

## 支持的层级类型
const LEVEL_TYPE_WORLD: String = "World"
const LEVEL_TYPE_CONTINENT: String = "Continent"
const LEVEL_TYPE_REGION: String = "Region"
const LEVEL_TYPE_AREA: String = "Area"
const LEVEL_TYPE_LOCATION: String = "Location"

## 全部地点：id → data
var locations: Dictionary = {}

## 按类型分类：type → [id, ...]
var locations_by_type: Dictionary = {}

## 按层级类型分类：level_type → [id, ...]
var locations_by_level_type: Dictionary = {}

## 按父级分类：parent_id → [id, ...]
var children_map: Dictionary = {}

## 按居民分类：inhabitant → [id, ...]
var locations_by_inhabitant: Dictionary = {}


func _on_mod_init() -> void:
	_init_type_buckets()


func _init_type_buckets() -> void:
	# 初始化层级类型桶
	var level_types: Array = [
		LEVEL_TYPE_WORLD,
		LEVEL_TYPE_CONTINENT,
		LEVEL_TYPE_REGION,
		LEVEL_TYPE_AREA,
		LEVEL_TYPE_LOCATION
	]
	for level_type in level_types:
		locations_by_level_type[level_type] = []

	# 类型桶会在注册时自动创建


func register_location(data: Dictionary) -> void:
	if not data.has("id") or not data.has("name") or not data.has("type"):
		push_error("[LocationManager] 注册地点失败：缺少必要字段 id/name/type")
		return

	#var data_version: String = str(data.get("version", ""))
	#if data_version == "":
		#push_warning("[LocationManager] 地点数据缺少 version 字段，将视为旧版本，id=" + str(data["id"]))
		#data_version = "0.0.0"
#
	#if data_version != VERSION:
		#push_warning("[LocationManager] 地点数据版本不匹配，尝试升级: id=%s, data_version=%s, mod_version=%s" % [str(data["id"]), data_version, VERSION])
		#data = _upgrade_location_data(data, data_version, VERSION)
		#data["version"] = VERSION
	#else:
		#data["version"] = VERSION

	var id: String = str(data["id"])
	var type_name: String = str(data["type"].get("content", "Unknown")) if typeof(data["type"]) == TYPE_DICTIONARY else str(data["type"])
	var level_type: String = str(data.get("location level type", "Location"))

	locations[id] = data

	# 按类型分类
	var type_arr: Array = locations_by_type.get(type_name, [])
	if id not in type_arr:
		type_arr.append(id)
		locations_by_type[type_name] = type_arr

	# 按层级类型分类
	var level_arr: Array = locations_by_level_type.get(level_type, [])
	if id not in level_arr:
		level_arr.append(id)
		locations_by_level_type[level_type] = level_arr

	# 按居民分类
	if data.has("inhabitants"):
		var inhabitants: Dictionary = data["inhabitants"]
		for inhabitant in inhabitants.keys():
			var inhabitant_arr: Array = locations_by_inhabitant.get(inhabitant, [])
			if id not in inhabitant_arr:
				inhabitant_arr.append(id)
				locations_by_inhabitant[inhabitant] = inhabitant_arr

	# 注意：不再使用 parent 字段维护父子关系，改为通过 relationships 数据管理
	# 父子关系将在 register_locations_from_json 函数中通过 relationships 部分构建


func register_locations_from_json(json_path: String) -> bool:
	var file: FileAccess = FileAccess.open(json_path, FileAccess.READ)
	if file == null:
		push_error("[LocationManager] 无法读取 JSON 文件: " + json_path)
		return false

	var content: String = file.get_as_text()
	var parsed: Variant = JSON.parse_string(content)

	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("[LocationManager] JSON 格式错误: " + json_path)
		return false

	# 解析新的 JSON 结构
	var data_section: Dictionary = parsed.get("data", {})
	var locations_section: Dictionary = data_section.get("locations", {})
	var relationships_section: Dictionary = data_section.get("relationships", {})

	if locations_section.is_empty():
		push_warning("[LocationManager] JSON 文件中未找到 locations 数据: " + json_path)
		return false

	for location_id in locations_section.keys():
		var loc_data: Dictionary = locations_section[location_id]
		if not loc_data.has("id"):
			loc_data["id"] = location_id
		register_location(loc_data)

	# 处理地点关系数据
	if not relationships_section.is_empty():
		for parent_id in relationships_section.keys():
			var children: Array = relationships_section[parent_id]
			for child_id in children:
				if locations.has(child_id):
					# 构建父子关系映射
					var child_arr: Array = children_map.get(parent_id, [])
					if child_id not in child_arr:
						child_arr.append(child_id)
						children_map[parent_id] = child_arr

	push_warning("[LocationManager] 从 JSON 文件成功注册 %d 个地点: " + str(locations_section.size()) + " - " + json_path)
	
	return true


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
	# 通过 relationships 数据查找父地点
	for parent_id in children_map.keys():
		var children: Array = children_map[parent_id]
		if location_id in children:
			return parent_id
	return ""


func get_locations_by_type(type_name: String) -> Array:
	var arr: Array = locations_by_type.get(type_name, [])
	return arr


func get_locations_by_level_type(level_type: String) -> Array:
	var arr: Array = locations_by_level_type.get(level_type, [])
	return arr


func get_locations_by_inhabitant(inhabitant_name: String) -> Array:
	var arr: Array = locations_by_inhabitant.get(inhabitant_name, [])
	return arr


func get_locations_by_level_hierarchy(level_type: String) -> Array:
	var result: Array = []
	var level_order: Array = [LEVEL_TYPE_WORLD, LEVEL_TYPE_CONTINENT, LEVEL_TYPE_REGION, LEVEL_TYPE_AREA, LEVEL_TYPE_LOCATION]
	var level_index: int = level_order.find(level_type)
	
	if level_index == -1:
		return result
	
	for id in locations.keys():
		var data: Dictionary = locations[id]
		var loc_level: String = str(data.get("location level type", "Location"))
		var loc_index: int = level_order.find(loc_level)
		if loc_index >= level_index:
			result.append(id)
	return result


func get_all_locations() -> Array:
	return locations.keys()


func get_all_locations_size() -> int:
	return locations.size()


func get_root_locations() -> Array:
	var result: Array = []
	# 所有不在任何子节点列表中的地点都是根地点
	var all_child_ids: Array = []
	for parent_id in children_map.keys():
		all_child_ids += children_map[parent_id]
	
	for id in locations.keys():
		if id not in all_child_ids:
			result.append(id)
	return result


func get_locations_count() -> int:
	return locations.size()


func get_location_by_name(name: String) -> Array:
	var result: Array = []
	for id in locations.keys():
		var data: Dictionary = locations[id]
		if str(data.get("name", "")).to_lower() == name.to_lower():
			result.append(id)
	return result


# Relationship 管理功能

## 添加新的父子关系
func add_relationship(parent_id: String, child_id: String) -> bool:
	if not locations.has(parent_id) or not locations.has(child_id):
		push_error("[LocationManager] 添加关系失败：父地点或子地点不存在")
		return false
	
	var child_arr: Array = children_map.get(parent_id, [])
	if child_id not in child_arr:
		child_arr.append(child_id)
		children_map[parent_id] = child_arr
		return true
	return false

## 删除指定的父子关系
func remove_relationship(parent_id: String, child_id: String) -> bool:
	if not children_map.has(parent_id):
		return false
	
	var child_arr: Array = children_map[parent_id]
	if child_id in child_arr:
		child_arr.erase(child_id)
		if child_arr.is_empty():
			children_map.erase(parent_id)
		else:
			children_map[parent_id] = child_arr
		return true
	return false

## 修改子地点的父地点
func update_relationship(old_parent_id: String, child_id: String, new_parent_id: String) -> bool:
	if not locations.has(new_parent_id):
		push_error("[LocationManager] 更新关系失败：新父地点不存在")
		return false
	
	# 先删除旧关系
	var removed: bool = remove_relationship(old_parent_id, child_id)
	# 再添加新关系
	var added: bool = add_relationship(new_parent_id, child_id)
	return removed and added

## 获取指定父地点的所有子地点
func get_relationship(parent_id: String) -> Array:
	return children_map.get(parent_id, [])

## 检查是否存在指定的父子关系
func has_relationship(parent_id: String, child_id: String) -> bool:
	if not children_map.has(parent_id):
		return false
	return child_id in children_map[parent_id]

## 获取所有关系数据
func get_all_relationships() -> Dictionary:
	return children_map


func clear_all_locations() -> void:
	locations.clear()
	locations_by_type.clear()
	locations_by_level_type.clear()
	locations_by_inhabitant.clear()
	children_map.clear()


func _upgrade_location_data(old_data: Dictionary, old_version: String, new_version: String) -> Dictionary:
	# 这里可以根据 old_version → new_version 做字段迁移
	# 当前默认直接返回旧数据
	return old_data
