## ---------------------------------------------------------
## UnitInstanceManager 模块（运行时单位实例管理）
##
## 功能说明：
## - 管理游戏运行时的单位实例（UnitInstance）
## - 仅负责“数据层”，不生成场景节点
## - 支持实例数据结构版本管理（version）
## - 按 unit_role 分类管理运行时数据（WorldOnly / BattleOnly / Both）
## - 支持 World 和 Battle 两种 owner（实例当前所属运行环境）
## - 自动维护实例索引（按模板、按 owner）
## - 提供实例创建、查询、更新、销毁、owner 切换接口
##
## 实例数据结构（示例）：
## {
##   "version": "1.0.0",
##   "instance_id": "agumon#0001",
##   "template_id": "agumon",
##   "unit_role": "Both",        # 决定 runtime.world / runtime.battle 的结构
##   "owner": "World",           # 当前实例属于哪个系统（World / Battle）
##   "mod": "DefaultUnits",
##
##   "runtime": {
##     "world": {
##       "position": Vector2(0, 0),
##       "state": "Idle",
##       "location": "file_island"
##     },
##
##     "battle": {
##       "current_hp": 100,
##       "max_hp": 100,
##       "atk": 15,
##       "def": 8,
##       "speed": 5,
##       "buffs": []
##     }
##   }
## }
##
## 字段说明：
## - version：实例数据结构版本，用于未来升级兼容
## - unit_role：模板定义的角色类型（WorldOnly / BattleOnly / Both）
## - owner：实例当前所属运行环境（World / Battle）
## - runtime.world：世界地图运行时数据（仅 WorldOnly / Both 存在）
## - runtime.battle：战斗运行时数据（仅 BattleOnly / Both 存在）
##
## 依赖：
## - UnitManager（必须，用于获取单位模板数据）
##
## 调用方式（其他 Mod）：
## GameCore.mod_manager.call_mod("UnitInstanceManager", "create_instance", ["agumon", "World"])
## GameCore.mod_manager.call_mod("UnitInstanceManager", "get_instance", ["agumon#0001"])
## GameCore.mod_manager.call_mod("UnitInstanceManager", "switch_owner", ["agumon#0001", "Battle"])
## GameCore.mod_manager.call_mod("UnitInstanceManager", "damage_instance", ["agumon#0001", 10])
##
## ---------------------------------------------------------

extends ModInterface
class_name UnitInstanceManager

## ---------------------------------------------------------
## UnitInstanceManager（数据层最终版）
## - 只管理运行时单位实例的数据
## - 不生成场景节点，不依赖 World / Battle 具体实现
## - 支持 owner 切换（仅更新数据）
## - 实例结构带 version + unit_role + runtime.world/battle
## ---------------------------------------------------------

## 全部实例：instance_id → instance_data
var instances: Dictionary = {}

## 按模板分类：template_id → [instance_id]
var instances_by_template: Dictionary = {}

## 按 owner 分类：World / Battle
var world_instances: Dictionary = {}
var battle_instances: Dictionary = {}

## 自增实例编号
var _instance_counter: int = 0

## 当前实例数据结构版本
const INSTANCE_VERSION: String = "1.0.0"


func _on_mod_load() -> bool:
	print("[UnitInstanceManager] 模块加载完成")
	return true


# =========================================================
# 创建实例（只处理数据，不生成节点）
# owner: "World" / "Battle"
# =========================================================
func create_instance(template_id: String, owner: String = "World") -> Dictionary:
	var template: Dictionary = GameCore.mod_manager.call_mod("UnitManager", "get_unit", template_id)

	if template.is_empty():
		push_error("[UnitInstanceManager] 创建实例失败，模板不存在: %s" % template_id)
		return {}

	_instance_counter += 1
	var instance_id: String = "%s#%04d" % [template_id, _instance_counter]

	var role: String = template.get("unit_role", "WorldOnly")

	var instance: Dictionary = {
		"version": INSTANCE_VERSION,
		"instance_id": instance_id,
		"template_id": template_id,
		"unit_role": role,
		"mod": template.get("mod", ""),
		"owner": owner,  # World / Battle

		"runtime": {}
	}

	# 世界运行时数据
	if role in ["WorldOnly", "Both"]:
		instance["runtime"]["world"] = {
			"position": Vector2.ZERO,
			"state": "Idle",
			"location": template.get("location", "")
		}

	# 战斗运行时数据
	if role in ["BattleOnly", "Both"]:
		var stats: Dictionary = template.get("battle_stats", {})
		instance["runtime"]["battle"] = {
			"current_hp": stats.get("hp", 1),
			"max_hp": stats.get("hp", 1),
			"atk": stats.get("atk", 0),
			"def": stats.get("def", 0),
			"speed": stats.get("speed", 0),
			"buffs": []
		}

	# 写入全局表
	instances[instance_id] = instance

	# 按模板分类
	var arr: Array = instances_by_template.get(template_id, [])
	arr.append(instance_id)
	instances_by_template[template_id] = arr

	# 按 owner 分类
	if owner == "World":
		world_instances[instance_id] = instance
	elif owner == "Battle":
		battle_instances[instance_id] = instance

	print("[UnitInstanceManager] 创建实例: %s (模板=%s, owner=%s)" % [instance_id, template_id, owner])
	return instance


# =========================================================
# 销毁实例（只处理数据）
# =========================================================
func destroy_instance(instance_id: String) -> void:
	if not instances.has(instance_id):
		push_warning("[UnitInstanceManager] 实例不存在: %s" % instance_id)
		return

	var inst: Dictionary = instances[instance_id]
	var template_id: String = inst["template_id"]
	var owner: String = inst.get("owner", "World")

	instances.erase(instance_id)

	# 模板索引
	var arr: Array = instances_by_template.get(template_id, [])
	arr.erase(instance_id)
	instances_by_template[template_id] = arr

	# owner 索引
	if owner == "World":
		world_instances.erase(instance_id)
	elif owner == "Battle":
		battle_instances.erase(instance_id)

	print("[UnitInstanceManager] 实例销毁: %s" % instance_id)


# =========================================================
# owner 切换（World ↔ Battle，仅更新数据）
# 具体场景生成/销毁由 World/Battle 模块负责
# =========================================================
func switch_owner(instance_id: String, new_owner: String) -> void:
	var inst: Dictionary = instances.get(instance_id, {})
	if inst.is_empty():
		push_warning("[UnitInstanceManager] owner 切换失败，实例不存在: %s" % instance_id)
		return

	var old_owner: String = inst.get("owner", "World")
	if old_owner == new_owner:
		return

	inst["owner"] = new_owner
	instances[instance_id] = inst

	# 从旧 owner 表移除
	if old_owner == "World":
		world_instances.erase(instance_id)
	elif old_owner == "Battle":
		battle_instances.erase(instance_id)

	# 加入新 owner 表
	if new_owner == "World":
		world_instances[instance_id] = inst
	elif new_owner == "Battle":
		battle_instances[instance_id] = inst

	print("[UnitInstanceManager] 实例 %s owner 切换: %s → %s" % [instance_id, old_owner, new_owner])


# =========================================================
# 查询接口
# =========================================================
func get_instance(instance_id: String) -> Dictionary:
	return instances.get(instance_id, {})


func get_instances_by_template(template_id: String) -> Array:
	return instances_by_template.get(template_id, [])


func get_world_instances() -> Array:
	return world_instances.keys()


func get_battle_instances() -> Array:
	return battle_instances.keys()


func get_all_instances() -> Array:
	return instances.keys()


# =========================================================
# 更新实例（按 unit_role 分类操作 runtime）
# =========================================================

# 世界：位置
func set_instance_position(instance_id: String, pos: Vector2) -> void:
	var inst: Dictionary = instances.get(instance_id, {})
	if inst.is_empty():
		return

	if inst["unit_role"] in ["WorldOnly", "Both"] and inst["runtime"].has("world"):
		inst["runtime"]["world"]["position"] = pos
		instances[instance_id] = inst


# 世界：状态
func set_instance_state(instance_id: String, state: String) -> void:
	var inst: Dictionary = instances.get(instance_id, {})
	if inst.is_empty():
		return

	if inst["unit_role"] in ["WorldOnly", "Both"] and inst["runtime"].has("world"):
		inst["runtime"]["world"]["state"] = state
		instances[instance_id] = inst


# 战斗：扣血
func damage_instance(instance_id: String, amount: int) -> void:
	var inst: Dictionary = instances.get(instance_id, {})
	if inst.is_empty():
		return

	if inst["unit_role"] in ["BattleOnly", "Both"] and inst["runtime"].has("battle"):
		var battle: Dictionary = inst["runtime"]["battle"]
		battle["current_hp"] = max(0, battle["current_hp"] - amount)
		inst["runtime"]["battle"] = battle
		instances[instance_id] = inst


# 战斗：治疗
func heal_instance(instance_id: String, amount: int) -> void:
	var inst: Dictionary = instances.get(instance_id, {})
	if inst.is_empty():
		return

	if inst["unit_role"] in ["BattleOnly", "Both"] and inst["runtime"].has("battle"):
		var battle: Dictionary = inst["runtime"]["battle"]
		battle["current_hp"] = min(battle["max_hp"], battle["current_hp"] + amount)
		inst["runtime"]["battle"] = battle
		instances[instance_id] = inst
