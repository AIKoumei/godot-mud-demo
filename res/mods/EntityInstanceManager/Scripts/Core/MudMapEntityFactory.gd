## res/mods/EntityInstanceManager/Scripts/Core/MudMapEntityFactory.gd
## 实体工厂模块
## 功能：创建和管理实体实例，提供各种实体类型的创建方法
## 配置：使用全局种子 GameCore.Settings.GameSettings.WorldSeed
##
## 主要功能：
## 1. 生成基础实体结构
## 2. 创建各种类型的实体实例（玩家、NPC、物品、建筑等）
## 3. 批量创建实体实例
## 4. 管理实体实例的生命周期
##
## 使用示例：
## # 示例1：创建基础实体结构
## var base_entity = MudMapEntityFactory.create_base_entity("测试实体", "test")
##
## # 示例2：创建带重写逻辑的 NPC
## var special_npc = MudMapEntityFactory.create_special_npc("商人", "fast_open")
##
## # 示例3：创建玩家实体
## var player = MudMapEntityFactory.create_player("玩家1", {"level": 1, "hp": 100})
##
## # 示例4：创建 NPC 实体
## var npc = MudMapEntityFactory.create_npc("村民", "human", {"level": 5, "hp": 50})
##
## # 示例5：创建物品实体
## var item = MudMapEntityFactory.create_item("药水", "health_potion", {"effect": "heal", "value": 50})
##
## # 示例6：创建建筑实体
## var building = MudMapEntityFactory.create_building("商店", "building_block", {"description": "道具商店"})
##
## # 示例7：批量创建实体
## var entities_cfg = [
##     {"entity_id": "human", "name": "村民1"},
##     {"entity_id": "human", "name": "村民2"}
## ]
## var entities = MudMapEntityFactory.create_entity_instances(entities_cfg)
##
## # 示例8：获取实体实例
## var entity = MudMapEntityFactory.get_entity_instance("1001")
##
## # 示例9：获取所有实体实例
## var all_entities = MudMapEntityFactory.get_all_entity_instances()
##
## # 示例10：销毁实体实例
## MudMapEntityFactory.destroy_entity_instance("1001")
##
## # 示例11：注册实体实例
## var entity_data = {"instance_id": "1002", "entity_id": "human", "name": "村民3"}
## MudMapEntityFactory.register_entity_instance(entity_data)
##

class_name MudMapEntityFactory

## 静态成员变量
## 1. 随机数生成器
static var _rng: RandomNumberGenerator

## 初始化随机数生成器
static func _init_rng():
	if _rng == null:
		_rng = RandomNumberGenerator.new()
		_rng.seed = GameCore.Settings.GameSettings.WorldSeed

## 生成最基础的 Entity 字典结构
## @param name: 实体名称
## @return: 基础实体字典结构
static func create_base_entity(name: String, entity_type: String) -> Dictionary:
	# 初始化随机数生成器
	_init_rng()
	
	return {
		"metadata": {
			"version": "1.0",
			"generate_at": Time.get_unix_time_from_system()
		},
		"data": {
			"name": name,
			"entity_type": entity_type,
			"attributes": {
				"actions": {}, # 存放 action_id: bool
				"tags": {}     # 存放业务标签
			}
		}
	}

## 示例：生成一个带重写逻辑的角色
## @param name: NPC 名称
## @param override_action: 重写的动作
## @return: 带重写逻辑的 NPC 实体
static func create_special_npc(name: String, override_action: String = "") -> Dictionary:
	# 初始化随机数生成器
	_init_rng()
	
	var npc = create_base_entity(name, "character")
	if override_action != "":
		# 设置重写：当该 NPC 尝试 "open" 时，实际调用 "fast_open"
		npc.data.attributes["action_overrides"] = {"open": override_action}
	return npc

## 通过 EntityInstanceManager 创建实体实例并放置到地图
## @param entity_cfg: 包含 entity_id, map_instance_id, map_position 的配置字典
## @return: 创建的实体实例数据
static func create_entity_instance(entity_cfg: Dictionary) -> Dictionary:
	# 初始化随机数生成器
	_init_rng()
	
	if not entity_cfg.has("entity_id"):
		push_error("[MudMapEntityFactory] create_entity_instance: entity_id is required")
		return {}
	
	var entity_id = entity_cfg.get("entity_id", "")
	
	# 1. 通过 EntityManager 获取实体模板
	var entity_template = GameCore.mod_manager.call_mod(
		"EntityManager",
		"get_entity_template",
		entity_id
	)
	
	if entity_template == null or entity_template.is_empty():
		push_warning("[MudMapEntityFactory] create_entity_instance: failed to create entity instance for %s" % entity_id)
		return {}
	
	# 2. 创建实体实例
	# merge entity_template with entity_cfg
	var entity_instance = GameCore.DictionaryTools.merge(
		entity_template,
		entity_cfg
	)

	return entity_instance

## 创建实体实例的基础数据，不包含实例id
## @param entity_cfg: 包含 entity_id 等配置的字典
## @return: 实体实例的基础数据
static func create_entity(entity_cfg: Dictionary) -> Dictionary:
	# 初始化随机数生成器
	_init_rng()
	
	if not entity_cfg.has("entity_id"):
		push_error("[MudMapEntityFactory] create_entity: entity_id is required")
		return {}
	
	var entity_id = entity_cfg.get("entity_id", "")
	
	# 1. 通过 EntityManager 获取实体模板
	var entity_template = GameCore.mod_manager.call_mod(
		"EntityManager",
		"get_entity_template",
		entity_id
	)
	
	if entity_template == null or entity_template.is_empty():
		push_warning("[MudMapEntityFactory] create_entity: failed to create entity instance for %s" % entity_id)
		return {}
	
	# 2. 创建实体实例
	# merge entity_template with entity_cfg
	var entity_instance = GameCore.DictionaryTools.merge(
		entity_template,
		entity_cfg
	)

	return entity_instance

## 创建玩家实体
## @param player_name: 玩家名称
## @param player_attributes: 玩家属性
## @return: 玩家实体实例
static func create_player(player_name: String, player_attributes: Dictionary = {}) -> Dictionary:
	# 初始化随机数生成器
	_init_rng()
	
	var player_cfg = {
		"entity_id": "player",
		"name": player_name,
		"attributes": player_attributes,
		"roles": ["player"]
	}
	
	return create_entity_instance(player_cfg)

## 创建 NPC 实体
## @param npc_name: NPC 名称
## @param npc_type: NPC 类型
## @param npc_attributes: NPC 属性
## @return: NPC 实体实例
static func create_npc(npc_name: String, npc_type: String = "human", npc_attributes: Dictionary = {}) -> Dictionary:
	# 初始化随机数生成器
	_init_rng()
	
	var npc_cfg = {
		"entity_id": npc_type,
		"name": npc_name,
		"attributes": npc_attributes,
		"roles": ["npc", npc_type]
	}
	return create_entity_instance(npc_cfg)

## 创建物品实体
## @param item_name: 物品名称
## @param item_type: 物品类型
## @param item_attributes: 物品属性
## @return: 物品实体实例
static func create_item(item_name: String, item_type: String = "item", item_attributes: Dictionary = {}) -> Dictionary:
	# 初始化随机数生成器
	_init_rng()
	
	var item_cfg = {
		"entity_id": item_type,
		"name": item_name,
		"attributes": item_attributes,
		"roles": ["item", item_type]
	}
	return create_entity_instance(item_cfg)

## 创建建筑实体
## @param building_name: 建筑名称
## @param building_type: 建筑类型
## @param building_attributes: 建筑属性
## @return: 建筑实体实例
static func create_building(building_name: String, building_type: String = "building_block", building_attributes: Dictionary = {}) -> Dictionary:
	# 初始化随机数生成器
	_init_rng()
	
	var building_cfg = {
		"entity_id": building_type,
		"name": building_name,
		"attributes": building_attributes,
		"roles": ["building", building_type]
	}
	return create_entity_instance(building_cfg)

## 批量创建实体实例
## @param entities_cfg: 实体配置数组
## @return: 创建的实体实例数组
static func create_entity_instances(entities_cfg: Array) -> Array:
	# 初始化随机数生成器
	_init_rng()
	
	var created_entities = []
	for entity_cfg in entities_cfg:
		var entity_instance = create_entity_instance(entity_cfg)
		if not entity_instance.is_empty():
			created_entities.append(entity_instance)
	return created_entities

## 获取实体实例
## @param instance_id: 实体实例 ID
## @return: 实体实例数据
static func get_entity_instance(instance_id: String) -> Dictionary:
	return GameCore.mod_manager.call_mod("EntityInstanceManager", "get_entity", instance_id)

## 获取所有实体实例
## @return: 实体实例数组
static func get_all_entity_instances() -> Array:
	return GameCore.mod_manager.call_mod("EntityInstanceManager", "get_all_entities")

## 销毁实体实例
## @param instance_id: 实体实例 ID
static func destroy_entity_instance(instance_id: String):
	GameCore.mod_manager.call_mod("EntityInstanceManager", "delete_entity", instance_id)

## 注册实体实例
## @param entity_data: 实体实例数据
## @return: 是否注册成功
static func register_entity_instance(entity_data: Dictionary) -> bool:
	return GameCore.mod_manager.call_mod("EntityInstanceManager", "register_entity_instance", entity_data)
