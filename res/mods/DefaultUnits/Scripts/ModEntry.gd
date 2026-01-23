## ---------------------------------------------------------
## DefaultUnits 模块（基础单位数据）
##
## 功能说明：
## - 提供游戏初始单位数据（数码宝贝、NPC、敌人等）
## - 支持从 JSON 文件批量加载单位数据
## - 在 _on_mod_load() 加载 JSON
## - 在 _on_mod_enable() 注册单位（更符合模块生命周期哲学）
##
## 单位数据格式：
## {
##   "id": "agumon",
##   "name": "亚古兽",
##   "unit_type": "Player",
##   "unit_role": "Both",
##   "model_path": "res://models/agumon.tscn",
##   "base_stats": { ... },
##   "skills": [...]
## }
##
## ---------------------------------------------------------

extends ModInterface

var _units_dict: Dictionary = {}   # load 阶段加载，enable 阶段注册


# ---------------------------------------------------------
# 生命周期：模块加载（只加载 JSON，不注册）
# ---------------------------------------------------------
func _on_mod_load() -> bool:
	print("[DefaultUnits] 加载基础单位数据...")

	var json_path: String = "%s/Data/Units.json" % get_mod_path()
	var file: FileAccess = FileAccess.open(json_path, FileAccess.READ)

	if file == null:
		push_warning("[DefaultUnits] 无法读取单位文件: %s" % json_path)
		return false

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("[DefaultUnits] JSON 格式错误: %s" % json_path)
		return false

	_units_dict = parsed

	print("[DefaultUnits] JSON 加载完成，包含角色组: %s" % str(_units_dict.keys()))
	return true


# ---------------------------------------------------------
# 生命周期：模块启用（此时 UnitManager 已启用）
# ---------------------------------------------------------
func _on_mod_enable() -> void:
	print("[DefaultUnits] 注册单位数据...")

	_register_role_group("WorldOnly")
	_register_role_group("BattleOnly")
	_register_role_group("Both")

	print("[DefaultUnits] 单位注册完成")


# ---------------------------------------------------------
# 注册某个 unit_role 下的所有单位
# ---------------------------------------------------------
func _register_role_group(role: String) -> void:
	if not _units_dict.has(role):
		return

	var group: Dictionary = _units_dict[role]

	for id: String in group.keys():
		var unit_data: Dictionary = group[id]

		var ok = GameCore.mod_manager.call_mod(
			"UnitManager",
			"register_unit",
			unit_data
		)

		if ok == null or ok == false:
			push_warning("[DefaultUnits] 注册单位失败: %s" % id)


# ---------------------------------------------------------
# 获取当前 mod 的根目录
# ---------------------------------------------------------
func get_mod_path() -> String:
	return GameCore.mod_manager.loaded_mods[mod_name].path
