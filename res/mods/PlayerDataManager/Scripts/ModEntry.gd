## ---------------------------------------------------------
## PlayerDataManager 模块（玩家元数据管理）
##
## 功能说明：
## - 管理玩家的“元数据（Meta-Data）”，不包含玩家角色本体数据
## - 保存玩家队伍（UnitInstance ID 列表）
## - 保存玩家所在位置（location_id + position{x,y}）
## - 保存玩家出生点（start_map + start_spawn_point{x,y}）
## - 保存玩家资源（金币、背包道具）
## - 保存玩家任务、设置等
##
## 设计说明：
## - 本模块只负责“数据层”，不负责创建 UnitInstance
##   → UnitInstanceManager 负责单位实例的创建与运行时数据
##
## - 本模块不负责生成场景节点
##   → WorldSceneManager 负责可视化与节点生成
##
## - 本模块不负责世界逻辑（地图加载、单位移动等）
##   → WorldMapInstanceManager 负责世界数据与逻辑
##
## - PlayerDataManager 是“玩家元数据的唯一来源（Single Source of Truth）”
##   所有与玩家相关的基础信息都从这里读取
##
##
## 玩家数据结构（示例）：
## {
##   "name": "Player",
##   "money": 100,
##   "inventory": [],
##   "quests": {},
##   "settings": {},
##
##   # 玩家当前所在位置（运行时位置）
##   "location_id": "file_island",
##   "position": { "x": 0, "y": 0 },
##
##   # 玩家出生点（新游戏 / 读档时使用）
##   "start_map": "file_island",
##   "start_spawn_point": { "x": 0, "y": 0 },
##
##   # 玩家队伍（UnitInstance ID 列表）
##   "team": ["player_hero#0001"]
## }
##
## 依赖：
## - 无强依赖（但通常由 GameManager 调用）
##
## ---------------------------------------------------------

extends ModInterface
class_name PlayerDataManager

## ---------------------------------------------------------
## PlayerDataManager 模块（玩家元数据管理）
## ---------------------------------------------------------

var player_data: Dictionary = {}


func _on_mod_load() -> bool:
	print("[PlayerDataManager] 模块加载完成")
	return true


# =========================================================
# 创建默认玩家数据
# =========================================================
func create_default_player() -> void:
	player_data = {
		"name": "Player",
		"money": 100,
		"inventory": [],
		"quests": {},
		"settings": {},

		# 玩家当前所在位置
		"location_id": "file_island_village",
		"position": { "x": 0, "y": 0 },

		# 玩家出生点（新游戏 / 读档时使用）
		"start_map": "file_island_village",
		"start_spawn_point": { "x": 0, "y": 0 },

		"team": []
	}

	print("[PlayerDataManager] 默认玩家数据已创建")


# =========================================================
# 队伍（模板 → 实例 ID）
# =========================================================
func create_default_team() -> Array:
	return ["player_hero"]


func set_player_team(team_instance_ids: Array) -> void:
	player_data["team"] = team_instance_ids
	print("[PlayerDataManager] 队伍实例已设置: ", team_instance_ids)


func get_player_team() -> Array:
	return player_data.get("team", [])


# =========================================================
# 位置相关（location_id + position.x/y）
# =========================================================
func set_location(location_id: String) -> void:
	player_data["location_id"] = location_id


func get_location() -> String:
	return player_data.get("location_id", "")


func set_position(x: float, y: float) -> void:
	player_data["position"] = { "x": x, "y": y }


func get_position() -> Dictionary:
	return player_data.get("position", { "x": 0.0, "y": 0.0 })


# =========================================================
# 出生点（新游戏 / 读档）
# =========================================================
func get_start_map() -> String:
	return player_data.get("start_map", "")


func get_start_spawn_point() -> Dictionary:
	return player_data.get("start_spawn_point", { "x": 0, "y": 0 })


# =========================================================
# 金钱
# =========================================================
func add_money(amount: int) -> void:
	player_data["money"] += amount


func get_money() -> int:
	return player_data.get("money", 0)


# =========================================================
# 背包
# =========================================================
func add_item(item_id: String) -> void:
	player_data["inventory"].append(item_id)


func get_inventory() -> Array:
	return player_data.get("inventory", [])


# =========================================================
# 任务
# =========================================================
func set_quest_state(quest_id: String, state: String) -> void:
	player_data["quests"][quest_id] = state


func get_quest_state(quest_id: String) -> String:
	return player_data.get("quests", {}).get(quest_id, "unknown")
