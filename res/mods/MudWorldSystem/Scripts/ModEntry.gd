## res://mods/MudWorldSystem/Scripts/ModEntry.gd
## --------------------------------------------------------------------------
## MudWorldSystem 模块
##
## 职责：
## 1. 协调世界加载流 (Map -> Instance -> Units)。
## 2. 调度交互流程并维护数据同步。
## 3. 提供对外的业务入口。
## --------------------------------------------------------------------------
extends ModInterface


func init_mud_world():
	# 从配置中生成地图的示例
	GameCore.mod_manager.call_mod("WorldMapInstanceManager", "gen_all_locations")


# ---------------------------------------------------------
# 1. 世界生命周期管理
# ---------------------------------------------------------

## 进入一个新地点
func enter_location(location_data: Dictionary) -> void:
	var loc_name = location_data.get("name", "")
	
	# A. 获取解析后的地图数据
	var map_res = GameCore.mod_manager.call_mod("WorldMapManager", "get_map_data", {"name": loc_name})
	
	# B. 初始化物理/逻辑房间实例
	GameCore.mod_manager.call_mod("WorldMapInstanceManager", "activate_location_instances", map_res)
	
	# C. 生成地点内的 Entity
	_populate_location_entities(map_res)

func _populate_location_entities(map_data: Dictionary):
	# 逻辑：从房间数据中提取需要生成的 NPC 或道具
	# 示例调用工厂并注册到 UnitManager
	pass

# ---------------------------------------------------------
# 2. 交互逻辑调度 (Orchestration)
# ---------------------------------------------------------

## 发起交互请求
## @param req: { "action_id": String, "source_id": String, "target_id": String }
func request_interaction(req: Dictionary) -> void:
	var s_id = req.get("source_id", "")
	var t_id = req.get("target_id", "")
	var a_id = req.get("action_id", "")

	# 1. 通过 UnitManager 获取最新的实体数据字典 (Authoritative Data)
	var source = GameCore.mod_manager.call_mod("UnitManager", "get_entity", {"id": s_id})
	var target = GameCore.mod_manager.call_mod("UnitManager", "get_entity", {"id": t_id})
	
	if source.is_empty() or target.is_empty():
		return

	# 2. 调用交互系统模块执行
	var result = GameCore.mod_manager.call_mod("MudEntityInteractionSystem", "execute_interaction", {
		"action_id": a_id,
		"source": source,
		"target": target
	})

	# 3. 数据同步 (由于实体是 Dictionary，需回写修改后的属性)
	# 即使只有一方修改了，为了系统健壮性也建议同步
	if result.get("status") == "success" or result.get("status") == "ok":
		GameCore.mod_manager.call_mod("UnitManager", "update_entity", {"id": s_id, "data": source})
		GameCore.mod_manager.call_mod("UnitManager", "update_entity", {"id": t_id, "data": target})
	
	# 4. 反馈交互结果给玩家
	_handle_result_output(result)

# ---------------------------------------------------------
# 3. 辅助功能
# ---------------------------------------------------------

func _handle_result_output(result: Dictionary):
	var msg = result.get("msg", "")
	if msg != "":
		# 调用 UI 模块显示文本
		GameCore.mod_manager.call_mod("MudUIManager", "append_log", {"text": msg})
