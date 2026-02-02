## res/mods/UnitManager/Scripts/ModEntry.gd
extends ModInterface

# 核心存储: { "unit_id": { ...blueprint_data... } }
var _unit_templates: Dictionary = {}

func _on_mod_load() -> bool:
	return true

# ---------------------------------------------------------
# 外部接口：注册相关
# ---------------------------------------------------------

## 接口 A：注册单个单位模板 (供脚本动态调用)
## @param source_mod: 提交者的 mod_name
## @param unit_id: 单位的唯一标识符
## @param blueprint: 单位的数据结构
func register_unit(source_mod: String, unit_id: String, blueprint: Dictionary) -> bool:
	if _unit_templates.has(unit_id):
		var existing_mod = _unit_templates[unit_id].get("_source_mod", "Unknown")
		push_warning("[UnitManager] 注册冲突: ID '%s' 已被 Mod '%s' 占用" % [unit_id, existing_mod])
		return false
	
	# 注入来源元数据
	blueprint["_source_mod"] = source_mod
	_unit_templates[unit_id] = blueprint
	# print("[UnitManager] Mod '%s' 成功注册了单个单位: %s" % [source_mod, unit_id])
	return true

## 接口 B：批量注册 JSON 数据包 (适配你设计的 metadata/data 结构)
## @param source_mod: 提交者的 mod_name
## @param packet: 包含 metadata 和 data.units 的字典
func register_unit_packet(source_mod: String, packet: Dictionary) -> void:
	if not packet.has("data") or not packet.data.has("units"):
		push_error("[UnitManager] Mod '%s' 提交的数据包格式非法" % source_mod)
		return
		
	var units_dict = packet.data.units
	var count = 0
	
	for unit_id in units_dict:
		if register_unit(source_mod, unit_id, units_dict[unit_id]):
			count += 1
			
	print("[UnitManager] Mod '%s' 批量注册了 %d 个单位模板" % [source_mod, count])

# ---------------------------------------------------------
# 外部接口：查询相关
# ---------------------------------------------------------

func get_unit_template(unit_id: String) -> Dictionary:
	return _unit_templates.get(unit_id, {})

func has_template(unit_id: String) -> bool:
	return _unit_templates.has(unit_id)
