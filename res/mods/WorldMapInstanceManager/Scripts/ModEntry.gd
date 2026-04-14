## res/mods/WorldMapInstanceManager/Scripts/ModEntry.gd
## 世界地图实例管理模块
## 功能：管理多个 location 的运行时实例，处理地图玩法层的运行时数据
## 配置：使用全局种子 GameCore.Settings.GameSettings.WorldSeed
##
## 主要功能：
## 1. 管理地图实例的生命周期
## 2. 处理实体在地图上的位置信息
## 3. 处理地图格子的修改（破坏、建造、掉落等）
## 4. 响应实体创建和销毁事件
## 5. 保存和加载地图实例数据
##
## 数据结构（示例）：
## _mud_map_instances = {
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
## 使用示例：
## # 示例1：生成所有地图实例
## WorldMapInstanceManager.gen_all_locations()
##
## # 示例2：加载某个地图实例
## WorldMapInstanceManager.load_location("file_island")
##
## # 示例3：获取当前地图实例
## var current_instance = WorldMapInstanceManager.get_current_instance()
##
## # 示例4：创建实体
## var entity_cfg = {
##     "entity_template_id": "human",
##     "map_instance_id": "file_island",
##     "map_position": Vector2(10, 10),
##     "attributes": { "level": 5, "hp": 100 }
## }
## var entity = WorldMapInstanceManager.create_entity(entity_cfg)
##
## # 示例5：设置实体位置
## WorldMapInstanceManager.set_entity_position(entity.instance_id, {
##     "map_instance_id": "file_island",
##     "map_position": Vector2(15, 15)
## })
##
## # 示例6：获取地图上的所有实体
## var entities = WorldMapInstanceManager.get_entities_by_map("file_island")
##
## # 示例7：修改地图格子数据
## WorldMapInstanceManager.merge_tile_data("file_island", 5, 5, { "tile": "water", "passable": false })
##

extends ModInterface
class_name WorldMapInstanceManager

## 成员变量
## 1. 存储所有地图实例
var _mud_map_instances: Dictionary = {}
## 2. 当前位置 ID
var _current_location_id: String = ""

## 3. 维护基于 map_instance_id 的 entity 位置信息
## 数据结构: {map_instance_id: {x_y: {entity_instance_id: {}}}}
var _entity_positions: Dictionary = {}

## 4. 以 map_instance_id 为索引的 entity 索引表
## 数据结构: {map_instance_id: {entity_instance_id: {}}}
var _entity_by_map: Dictionary = {}

## 5. 以 entity_instance_id 为索引的地图索引表
## 数据结构: {entity_instance_id: map_instance_id}
var _map_by_entity: Dictionary = {}

## 6. 随机数生成器
var _rng: RandomNumberGenerator


func _on_mod_load() -> bool:
	# 初始化随机数生成器
	_rng = RandomNumberGenerator.new()
	_rng.seed = GameCore.Settings.GameSettings.WorldSeed
	
	print("[WorldMapInstanceManager] 模块已加载")
	register_event_listener_with_name(ModEventListenerFilter.new()
		.set_listen_type(ModEventListenerFilter.ListenType.ALWAYS)
		.set_mod_filter_type(ModEventListenerFilter.ModFilterType.ANY)
		.set_mod_name("SceneManager")
		.set_event_filter_type(ModEventListenerFilter.EventFilterType.TARGET)
		.set_event_name("SaveAllMapInstanceData")
		, "SaveAllMapInstanceData"
	)
	
	register_event_listener_with_name(ModEventListenerFilter.new()
		.set_listen_type(ModEventListenerFilter.ListenType.ALWAYS)
		.set_mod_filter_type(ModEventListenerFilter.ModFilterType.TARGET)
		.set_mod_name("EntityInstanceManager")
		.set_event_filter_type(ModEventListenerFilter.EventFilterType.TARGET)
		.set_event_name("entity_created")
		, "EntityInstanceManager.entity_created"
	)
	
	register_event_listener_with_name(ModEventListenerFilter.new()
		.set_listen_type(ModEventListenerFilter.ListenType.ALWAYS)
		.set_mod_filter_type(ModEventListenerFilter.ModFilterType.TARGET)
		.set_mod_name("EntityInstanceManager")
		.set_event_filter_type(ModEventListenerFilter.EventFilterType.TARGET)
		.set_event_name("entity_destroyed")
		, "EntityInstanceManager.entity_destroyed"
	)
	
	return true

## ---------------------------------------------------------
## 创建地图实例
## 通过 WorldMapManager 获取的 template，进行实例化
## 实例化后，需要赋值 instance_id，作为地图实例的唯一标识符
## 实例化地图的时候，遍历 map_nodes ，通过 EntityInstanceManager 实例化实体
## @param location_id: 地图位置 ID
## @return: 是否创建成功
## ---------------------------------------------------------
func create_map(location_id: String) -> bool:
	# 从 WorldMapManager 获取地图模板
	var template = GameCore.mod_manager.call_mod(
		"WorldMapManager",
		"get_location_static",
		location_id
	) as Dictionary
	
	if template == null or template.is_empty():
		push_error("[WorldMapInstanceManager] 无法获取地图模板: %s" % location_id)
		return false
	
	# 创建地图实例
	var instance = {
		"version": template.get("version", 1),
		"location_id": location_id,
		"map_data": template.get("map_data", []).duplicate(true),
		"state": {
			"weather": template.get("metadata", {}).get("weather_type", "sunny"),
			"light_level": 1.0
		},
		"instance_id": "map_instance_%s_%d" % [location_id, _rng.randi()]
	}
	
	# 存储地图实例
	_mud_map_instances[location_id] = instance
	
	# 实例化地图中的实体
	var map_nodes = template.get("map_nodes", [])
	for node in map_nodes:
		var entity_template_id = node.get("entity_template_id", "")
		if entity_template_id != "":
			# 构建实体配置
			var entity_cfg = {
				"entity_id": entity_template_id,
				"map_instance_id": location_id,
				"map_position": Vector2(node.get("x", 0), node.get("y", 0)),
				"attributes": {
					"map_data": {
						"map_instance_id": location_id,
						"position": Vector2(node.get("x", 0), node.get("y", 0))
					}
				}
			}
			
			# 调用 EntityInstanceManager 创建实体实例
			var entity_instance = GameCore.mod_manager.call_mod(
				"EntityInstanceManager",
				"create_entity",
				entity_cfg
			) as Dictionary
			
			if not entity_instance.is_empty():
				print("[WorldMapInstanceManager] 实体实例创建成功: %s" % entity_instance.get("instance_id", ""))
	
	print("[WorldMapInstanceManager] 地图实例创建成功: %s" % location_id)
	return true


func _on_mod_event(_mod_name: String, event_name: String, event_data: Dictionary) -> void:
	super._on_mod_event(_mod_name, event_name, event_data)
	if _mod_name == "WorldMapManager" and event_name == "after_gen_all_location_map_finished":
		#var mud_map_datas = event_data.get("mud_maps",{}) as Dictionary
		#_mud_map_instances = mud_map_datas.duplicate_deep()
		# TODO 从 mud entity Factory 中实例化 mud map 中的 entity ，并且在本模块中维护 entity_instances 表 {entity_id : {metadata:{},data:{}}}
		after_gen_all_locations_finished()
	# TODO 加一个 popup msg
	elif event_name == "SaveAllMapInstanceData":
		save_all_location_instances()
	# 处理 EntityInstanceManager 事件
	elif _mod_name == "EntityInstanceManager":
		if event_name == "entity_created":
			# 处理实体创建事件
			var entity = event_data.get("entity", {})
			if not entity.is_empty():
				var entity_instance_id = entity.get("instance_id", "")
				var attributes = entity.get("attributes", {})
				var map_data = attributes.get("map_data", {})
				if not map_data.is_empty() and entity_instance_id != "":
					var map_instance_id = map_data.get("map_instance_id", "")
					var position = map_data.get("map_position", Vector2.ZERO)
					if map_instance_id != "":
						# 设置实体位置
						set_entity_position(entity_instance_id, {
							"map_instance_id": map_instance_id,
							"map_position": position
						})
		elif event_name == "entity_destroyed":
			# 处理实体销毁事件
			var entity_instance_id = event_data.get("instance_id", "")
			if entity_instance_id != "":
				# 从所有地图实例中移除该实体
				_remove_entity_from_all_positions(entity_instance_id)

## 从所有位置移除实体
func _remove_entity_from_all_positions(entity_instance_id: String) -> void:
	for map_instance_id in _entity_positions.keys():
		_remove_entity_from_old_position(entity_instance_id, map_instance_id)
	
	# 从所有地图实例的 map_nodes 中移除
	for map_instance_id in _mud_map_instances.keys():
		var map_instance = _mud_map_instances[map_instance_id]
		var map_data = map_instance.get("data", {})
		
		if map_data.has("map_nodes"):
			var map_nodes = map_data["map_nodes"]
			for pos_key in map_nodes.keys():
				var nodes = map_nodes[pos_key]
				for i in range(nodes.size() - 1, -1, -1):
					if nodes[i].get("entity_instance_id") == entity_instance_id:
						nodes.remove_at(i)
						# 如果该位置没有其他实体，移除该位置
						if nodes.is_empty():
							map_nodes.erase(pos_key)
						# 设置 map_nodes_dirty
						if map_data.has("map_nodes_dirty"):
							map_data["map_nodes_dirty"][pos_key] = true
						break
			
			# 更新地图实例
			map_instance["data"] = map_data
			_mud_map_instances[map_instance_id] = map_instance
	
	# 从两个索引表中移除
	_remove_entity_from_all_indices(entity_instance_id)

## 从所有索引表中移除实体
func _remove_entity_from_all_indices(entity_instance_id: String) -> void:
	# 从以 map_instance_id 为索引的 entity 索引表中移除
	if _map_by_entity.has(entity_instance_id):
		var map_instance_id = _map_by_entity[entity_instance_id]
		if _entity_by_map.has(map_instance_id):
			_entity_by_map[map_instance_id].erase(entity_instance_id)
			# 如果该地图没有其他实体，移除该地图的索引
			if _entity_by_map[map_instance_id].is_empty():
				_entity_by_map.erase(map_instance_id)
	
	# 从以 entity_instance_id 为索引的地图索引表中移除
	_map_by_entity.erase(entity_instance_id)


func init_mud_maps():
	var cur_index = 0
	var map_templates = GameCore.mod_manager.call_mod("WorldMapManager", "get_all_mud_map_templates") as Dictionary
	var total_index = map_templates.size()
	# 从 WorldMapManager 中拷贝 map template，然后实例化
	for map_name in map_templates.keys():
		cur_index += 1
		# 获取地图模板
		var template = map_templates[map_name]
		
		# 实例化地图
		var instance = template.duplicate_deep()
		# 先移除来自于模板的实体
		instance.get("data",{}).map_nodes = {}
		# 添加 map_nodes_dirty
		instance.get("data",{}).map_nodes_dirty = {}
		# 赋值 map_instance_id 作为地图实例的唯一标识符
		instance.get("data",{})["map_instance_id"] = map_name
		
		# 存储地图实例
		_mud_map_instances[map_name] = instance
		
		# 实例化地图中的实体
		var map_nodes = template.get("data", {}).get("map_nodes", [])
		for node in map_nodes:
			var entity_template_id = node.get("entity_id", "")
			if entity_template_id != "":
				# 构建实体配置
				var entity_cfg = node
				# 添加 map_instance_id 到配置
				entity_cfg["map_instance_id"] = map_name
				
				# 调用 EntityInstanceManager 创建实体实例
				var entity_instance = GameCore.mod_manager.call_mod(
					"EntityInstanceManager",
					"create_entity",
					entity_cfg
				) as Dictionary
				
				if not entity_instance.is_empty():
					# 实例化实体后，将该 map_node 替换为包含 entity_instance_id 的结构
					var entity_instance_id = entity_instance.get("entity_instance_id", "")
					if entity_instance_id != "":
						var map_position = entity_instance.get("attributes", {}).get("map_position", Vector2.ZERO)
						var map_pos_key = "%d,%d" % [int(map_position[0]), int(map_position[1])]
						
						# 确保 map_nodes 中该位置存在
						if not instance.get("data",{})["map_nodes"].has(map_pos_key):
							instance.get("data",{})["map_nodes"][map_pos_key] = []
						
						# 添加实体到 map_nodes
						instance.get("data",{})["map_nodes"][map_pos_key].append({
							"entity_instance_id":entity_instance_id,
							"entity_type":entity_instance.get("entity_type", "unknown")
						})
						
						# 设置 map_nodes_dirty
						instance.get("data",{})["map_nodes_dirty"][map_pos_key] = true
						
						print("[WorldMapInstanceManager] 实体实例创建成功: %s" % entity_instance_id)
		
		# 发送单个完成信号
		emit_mod_event("init_one_mud_map_entities", {
			"map_name":map_name,
			"cur_index":cur_index,
			"total_index":total_index,
		})
		await get_tree().create_timer(0.01).timeout



# ---------------------------------------------------------
# 加载某个 location 的实例（如果不存在则创建）
# ---------------------------------------------------------
func load_location(location_id: String) -> bool:
	if _mud_map_instances.has(location_id):
		_current_location_id = location_id
		print("[WorldMapInstanceManager] Reuse existing instance:", location_id)
		return true

	var static_data = GameCore.mod_manager.call_mod(
		"WorldMapManager",
		"get_location_static",
		location_id
	) as Dictionary

	#if static_data == null or static_data.is_empty():
		#push_error("[WorldMapInstanceManager] Invalid location: %s" % location_id)
		#return false

	var instance: Dictionary = {
		"version": static_data.get("version", 1),
		"location_id": location_id,
		"map_data": static_data.get("map_data", []).duplicate(true),
		"state": {
			"weather": static_data.get("metadata", {}).get("weather_type", "sunny"),
			"light_level": 1.0
		}
	}

	_mud_map_instances[location_id] = instance
	_current_location_id = location_id

	print("[WorldMapInstanceManager] Created instance for:", location_id)
	return true

# ----------------------------
# 	流程：
# 		1、WorldMapManager 生成 mud map template
# 		2、接收到信号后， WorldMapInstanceManager 生成 mud map instance
# 		3、WorldMapInstanceManager 细化 mud map instance
# 		3.1、生成建筑
# ----------------------------
func gen_all_locations():
	# 监听生成地图完成
	register_event_listener_with_name(ModEventListenerFilter.new()
		.set_listen_type(ModEventListenerFilter.ListenType.ONCE)
		.set_mod_filter_type(ModEventListenerFilter.ModFilterType.TARGET)
		.set_mod_name("WorldMapManager")
		.set_event_filter_type(ModEventListenerFilter.EventFilterType.TARGET)
		.set_event_name("after_gen_all_location_map_finished")
		, "after_gen_all_location_map_finished"
	)
	# 从配置中生成地图模板
	GameCore.mod_manager.call_mod("WorldMapManager", "gen_all_locations")

func after_gen_all_locations_finished():
	await init_mud_maps()
	save_all_location_instances()
	emit_mod_event("after_gen_all_locations_finished", {
		"map_count":_mud_map_instances.size(),
		"map_instances":_mud_map_instances
	})


func save_all_location_instances():
	print("WorldMapInstanceManager.save_all_location_instances")
	for data in _mud_map_instances.values():
		var map_name = data.get("data",{}).get("map_name", "unknow_map")
		if map_name == "unknow_map":
			push_warning("[%s] save_all_location_instances 中未知的 name" % mod_name)
		if GameCore.debugging and SaveManager.has_mod_slot_file(GameCore.Settings.GameSettings.GameSlot, "%s/map_%s.sav" % [mod_name, map_name.uri_encode()]):
			continue
		SaveManager.save_mod_slot_data(GameCore.Settings.GameSettings.GameSlot, "%s/map_%s"%[mod_name, map_name.uri_encode()], data)
	GameCore.mod_manager.call_mod("EntityInstanceManager", "save_entity_instances")


# ---------------------------------------------------------
# 获取当前实例
# ---------------------------------------------------------
func get_current_instance() -> Dictionary:
	return _mud_map_instances.get(_current_location_id, {})


# ---------------------------------------------------------
# 获取某个实例
# ---------------------------------------------------------
func get_instance(location_id: String) -> Dictionary:
	return _mud_map_instances.get(location_id, {})


func get_all_mud_map_instances() -> Dictionary:
	return _mud_map_instances


# ---------------------------------------------------------
## 获取某个实例的 map_data
## ---------------------------------------------------------
func get_map_data(location_id: String) -> Array:
	return _mud_map_instances.get(location_id, {}).get("map_data", [])

## ---------------------------------------------------------
## 根据 map_instance_id 获取所有 entity 的接口方法
## @param map_instance_id: 地图实例 ID
## @return 返回该地图上的所有实体实例 ID 列表
## ---------------------------------------------------------
func get_entities_by_map(map_instance_id: String) -> Array:
	if _entity_by_map.has(map_instance_id):
		return _entity_by_map[map_instance_id].keys()
	return []

## ---------------------------------------------------------
## 根据 cfg 创建 entity 的接口方法
## @param cfg: 配置字典，包含 entity_template_id, map_position, attributes 等信息
## @return 返回创建的实体实例数据
## ---------------------------------------------------------
func create_entity(cfg: Dictionary) -> Dictionary:
	# 提取必要参数
	var entity_template_id = cfg.get("entity_template_id", "")
	var map_instance_id = cfg.get("map_instance_id", "")
	var map_position = cfg.get("map_position", Vector2.ZERO)
	var attributes = cfg.get("attributes", {})

	# 检查必要参数
	if entity_template_id == "" or map_instance_id == "":
		push_warning("[WorldMapInstanceManager] create_entity: entity_template_id and map_instance_id are required")
		return {}

	# 构建 entity_cfg
	var entity_cfg = {
		"entity_id": entity_template_id,
		"map_instance_id": map_instance_id,
		"map_position": map_position,
		"attributes": attributes
	}

	# 调用 EntityInstanceManager 创建实体实例
	var entity_instance = GameCore.mod_manager.call_mod(
		"EntityInstanceManager",
		"create_entity",
		entity_cfg
	) as Dictionary

	if not entity_instance.is_empty():
		print("[WorldMapInstanceManager] 实体创建成功: %s" % entity_instance.get("instance_id", ""))
	else:
		print("[WorldMapInstanceManager] 实体创建失败")

	return entity_instance


# ---------------------------------------------------------
# 设置实体在地图玩法上的逻辑位置
# （在 _entity_positions 中维护 entity 位置信息）
# ---------------------------------------------------------
## @param entity_instance_id: 实体实例 ID
## @param cfg: 配置字典，包含 map_instance_id, map_position 等信息
func set_entity_position(entity_instance_id: String, cfg: Dictionary) -> void:
	# 从配置中提取必要参数
	var map_instance_id = cfg.get("map_instance_id", "")
	var map_position = cfg.get("map_position", Vector2.ZERO)
	var x = int(cfg.get("x", map_position.x))
	var y = int(cfg.get("y", map_position.y))

	# 检查必要参数
	if map_instance_id == "":
		push_warning("[WorldMapInstanceManager] set_entity_position: map_instance_id is required")
		return

	# 确保 map_instance_id 在 _entity_positions 中存在
	if not _entity_positions.has(map_instance_id):
		_entity_positions[map_instance_id] = {}

	# 生成位置键
	var pos_key = "%d_%d" % [x, y]

	# 先移除旧位置上的该实体
	_remove_entity_from_all_indices(entity_instance_id)

	# 在新位置写入
	if not _entity_positions[map_instance_id].has(pos_key):
		_entity_positions[map_instance_id][pos_key] = {}
	
	# 存储实体实例 ID，字典内容留空
	_entity_positions[map_instance_id][pos_key][entity_instance_id] = {}

	# 更新两个索引表
	# 1. 以 map_instance_id 为索引的 entity 索引表
	if not _entity_by_map.has(map_instance_id):
		_entity_by_map[map_instance_id] = {}
	_entity_by_map[map_instance_id][entity_instance_id] = {}

	# 2. 以 entity_instance_id 为索引的地图索引表
	_map_by_entity[entity_instance_id] = map_instance_id

	print("[WorldMapInstanceManager] Entity %s placed at %s:%s,%s" % [entity_instance_id, map_instance_id, x, y])

## 从旧位置移除实体
func _remove_entity_from_old_position(entity_instance_id: String, map_instance_id: String) -> void:
	if not _entity_positions.has(map_instance_id):
		return

	var positions = _entity_positions[map_instance_id]
	for pos_key in positions.keys():
		if positions[pos_key].has(entity_instance_id):
			positions[pos_key].erase(entity_instance_id)
			# 如果该位置没有其他实体，移除该位置
			if positions[pos_key].is_empty():
				positions.erase(pos_key)
			break


# ---------------------------------------------------------
# 通用格子修改接口（破坏、建造、掉落等）
# ---------------------------------------------------------
func merge_tile_data(location_id: String, x: int, y: int, data: Dictionary) -> void:
	if not _mud_map_instances.has(location_id):
		push_warning("[WorldMapInstanceManager] merge_tile_data: no instance for %s" % location_id)
		return

	var inst: Dictionary = _mud_map_instances[location_id]
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
	_mud_map_instances[location_id] = inst


# ---------------------------------------------------------
# 世界更新（所有实例）
# ---------------------------------------------------------
func update(delta: float) -> void:
	for location_id in _mud_map_instances.keys():
		_update_instance(location_id, delta)


func _update_instance(location_id: String, delta: float) -> void:
	var inst: Dictionary = _mud_map_instances[location_id]
	# TODO: 天气变化、单位 AI、掉落物刷新等
	pass

## ---------------------------------------------------------
## 移动实体
## 原则上，EntityInstanceManager 以及其他涉及在地图上移动 entity 的操作都需要经过 move_entity 方法进行
## @param args: 包含以下字段的字典
##   - entity_instance_id: 实体实例 ID
##   - new_map_instance_id: 地图实例 ID（可选）
##   - new_map_position: 实体新的位置
## ---------------------------------------------------------
func move_entity(args: Dictionary) -> void:
	var entity_instance_id = args.get("entity_instance_id", "")
	var new_map_instance_id = args.get("new_map_instance_id", "")
	var new_map_position = args.get("new_map_position", Vector2.ZERO)
	
	if entity_instance_id == "":
		push_warning("[WorldMapInstanceManager] move_entity: entity_instance_id is required")
		return
	
	# 从 EntityInstanceManager 中获取 entity_instance
	var entity_instance = GameCore.mod_manager.call_mod(
		"EntityInstanceManager",
		"get_entity",
		entity_instance_id
	) as Dictionary
	
	if entity_instance.is_empty():
		push_warning("[WorldMapInstanceManager] move_entity: entity not found")
		return
	
	# 如果没有提供 new_map_instance_id，从 entity_instance 中获取
	if new_map_instance_id == "":
		var attributes = entity_instance.get("attributes", {})
		new_map_instance_id = attributes.get("map_instance_id", "")
	
	if new_map_instance_id == "":
		push_warning("[WorldMapInstanceManager] move_entity: map_instance_id is required")
		return
	
	# 调用 add_entity 添加到新位置
	add_entity({
		"entity_instance_id": entity_instance_id,
		"map_instance_id": new_map_instance_id,
		"map_position": new_map_position
	})
	
	# 通知 EntityInstanceManager 更新实体位置
	GameCore.mod_manager.call_mod(
		"EntityInstanceManager",
		"update_entity_position",
		entity_instance_id,
		{
			"map_instance_id": new_map_instance_id,
			"map_position": new_map_position
		}
	)

## ---------------------------------------------------------
## 移除实体
## @param args: 包含以下字段的字典
##   - entity_instance_id: 实体实例 ID
##   - map_instance_id: 地图实例 ID（可选）
## ---------------------------------------------------------
func remove_entity(args: Dictionary) -> void:
	var entity_instance_id = args.get("entity_instance_id", "")
	var map_instance_id = args.get("map_instance_id", "")
	
	if entity_instance_id == "":
		push_warning("[WorldMapInstanceManager] remove_entity: entity_instance_id is required")
		return
	
	# 从 EntityInstanceManager 中获取 entity_instance
	var entity_instance = GameCore.mod_manager.call_mod(
		"EntityInstanceManager",
		"get_entity",
		entity_instance_id
	) as Dictionary
	
	if entity_instance.is_empty():
		push_warning("[WorldMapInstanceManager] remove_entity: entity not found")
		return
	
	# 如果没有提供 map_instance_id，从 entity_instance 中获取
	if map_instance_id == "":
		var attributes = entity_instance.get("attributes", {})
		map_instance_id = attributes.get("map_instance_id", "")
	
	if map_instance_id == "":
		push_warning("[WorldMapInstanceManager] remove_entity: map_instance_id is required")
		return
	
	# 从 _entity_positions 中移除
	if _entity_positions.has(map_instance_id):
		var attributes = entity_instance.get("attributes", {})
		var map_position = attributes.get("map_position", Vector2.ZERO)
		var pos_key = "%d_%d" % [int(map_position.x), int(map_position.y)]
		var map_pos_key = "%d,%d" % [int(map_position.x), int(map_position.y)]
		
		if _entity_positions[map_instance_id].has(pos_key):
			_entity_positions[map_instance_id][pos_key].erase(entity_instance_id)
			# 如果该位置没有其他实体，移除该位置
			if _entity_positions[map_instance_id][pos_key].is_empty():
				_entity_positions[map_instance_id].erase(pos_key)
	
	# 从 map_nodes 中移除并设置 map_nodes_dirty
	if _mud_map_instances.has(map_instance_id):
		var map_instance = _mud_map_instances[map_instance_id]
		var map_data = map_instance.get("data", {})
		
		if map_data.has("map_nodes"):
			var map_nodes = map_data["map_nodes"]
			for pos_key in map_nodes.keys():
				var nodes = map_nodes[pos_key]
				for i in range(nodes.size() - 1, -1, -1):
					if nodes[i].get("entity_instance_id") == entity_instance_id:
						nodes.remove_at(i)
						# 如果该位置没有其他实体，移除该位置
						if nodes.is_empty():
							map_nodes.erase(pos_key)
						# 设置 map_nodes_dirty
						if map_data.has("map_nodes_dirty"):
							map_data["map_nodes_dirty"][pos_key] = true
						break
			
			# 更新地图实例
			map_instance["data"] = map_data
			_mud_map_instances[map_instance_id] = map_instance
	
	# 从索引表中移除
	_remove_entity_from_all_indices(entity_instance_id)

## ---------------------------------------------------------
## 添加实体
## @param args: 包含以下字段的字典
##   - entity_instance_id: 实体实例 ID
##   - map_instance_id: 地图实例 ID
##   - map_position: 实体位置
## ---------------------------------------------------------
func add_entity(args: Dictionary) -> void:
	var entity_instance_id = args.get("entity_instance_id", "")
	var map_instance_id = args.get("map_instance_id", "")
	var map_position = args.get("map_position", Vector2.ZERO)
	
	if entity_instance_id == "":
		push_warning("[WorldMapInstanceManager] add_entity: entity_instance_id is required")
		return
	
	# 从 EntityInstanceManager 中获取 entity_instance
	var entity_instance = GameCore.mod_manager.call_mod(
		"EntityInstanceManager",
		"get_entity",
		entity_instance_id
	) as Dictionary
	
	if entity_instance.is_empty():
		push_warning("[WorldMapInstanceManager] add_entity: entity not found")
		return
	
	# 如果没有提供 map_instance_id，从 entity_instance 中获取
	if map_instance_id == "":
		var attributes = entity_instance.get("attributes", {})
		map_instance_id = attributes.get("map_instance_id", "")
	
	if map_instance_id == "":
		push_warning("[WorldMapInstanceManager] add_entity: map_instance_id is required")
		return
	
	# 先移除实体（如果已存在）
	remove_entity({"entity_instance_id": entity_instance_id})
	
	# 确保地图实例存在
	if not _mud_map_instances.has(map_instance_id):
		push_warning("[WorldMapInstanceManager] add_entity: map instance not found")
		return
	
	# 确保 _entity_positions 中存在该地图实例
	if not _entity_positions.has(map_instance_id):
		_entity_positions[map_instance_id] = {}
	
	# 生成位置键
	var x = int(map_position.x)
	var y = int(map_position.y)
	var pos_key = "%d_%d" % [x, y]
	var map_pos_key = "%d,%d" % [x, y]
	
	# 在新位置写入
	if not _entity_positions[map_instance_id].has(pos_key):
		_entity_positions[map_instance_id][pos_key] = {}
	
	# 存储实体实例 ID
	_entity_positions[map_instance_id][pos_key][entity_instance_id] = {}
	
	# 更新两个索引表
	# 1. 以 map_instance_id 为索引的 entity 索引表
	if not _entity_by_map.has(map_instance_id):
		_entity_by_map[map_instance_id] = {}
	_entity_by_map[map_instance_id][entity_instance_id] = {}
	
	# 2. 以 entity_instance_id 为索引的地图索引表
	_map_by_entity[entity_instance_id] = map_instance_id
	
	# 更新 map_nodes 和 map_nodes_dirty
	var map_instance = _mud_map_instances[map_instance_id]
	var map_data = map_instance.get("data", {})
	
	# 确保 map_nodes 存在
	if not map_data.has("map_nodes"):
		map_data["map_nodes"] = {}
	
	# 确保 map_nodes_dirty 存在
	if not map_data.has("map_nodes_dirty"):
		map_data["map_nodes_dirty"] = {}
	
	# 添加实体到 map_nodes
	if not map_data["map_nodes"].has(map_pos_key):
		map_data["map_nodes"][map_pos_key] = []
	
	# 检查实体是否已存在
	var entity_exists = false
	for node in map_data["map_nodes"][map_pos_key]:
		if node.get("entity_instance_id") == entity_instance_id:
			entity_exists = true
			break
	
	if not entity_exists:
		map_data["map_nodes"][map_pos_key].append({
			"entity_instance_id": entity_instance_id,
			"entity_type": entity_instance.get("entity_type", "unknown")
		})
	
	# 设置 map_nodes_dirty
	map_data["map_nodes_dirty"][map_pos_key] = true
	
	# 更新地图实例
	map_instance["data"] = map_data
	_mud_map_instances[map_instance_id] = map_instance
	
	print("[WorldMapInstanceManager] Entity %s added at %s:%s,%s" % [entity_instance_id, map_instance_id, x, y])

## ---------------------------------------------------------
## 对地图位置的实体按 render_order 排序
## @param args: 包含以下字段的字典
##   - map_instance_id: 地图实例 ID
##   - map_position: 地图位置
## ---------------------------------------------------------
func sort_map_nodes(args: Dictionary) -> void:
	var map_instance_id = args.get("map_instance_id", "")
	var map_position = args.get("map_position", Vector2.ZERO)
	
	if map_instance_id == "":
		push_warning("[WorldMapInstanceManager] sort_map_nodes: map_instance_id is required")
		return
	
	var x = int(map_position.x)
	var y = int(map_position.y)
	var map_pos_key = "%d,%d" % [x, y]
	
	# 检查地图实例是否存在
	if not _mud_map_instances.has(map_instance_id):
		push_warning("[WorldMapInstanceManager] sort_map_nodes: map instance not found")
		return
	
	var map_instance = _mud_map_instances[map_instance_id]
	var map_data = map_instance.get("data", {})
	
	# 检查 map_nodes_dirty 是否为 true
	if map_data.has("map_nodes_dirty"):
		if not map_data["map_nodes_dirty"].get(map_pos_key, false):
			return
	
	# 检查 map_nodes 是否存在该位置
	if not map_data.has("map_nodes"):
		return
	
	if not map_data["map_nodes"].has(map_pos_key):
		return
	
	var nodes = map_data["map_nodes"][map_pos_key]
	
	# 对 nodes 按 render_order 排序
	# 使用冒泡排序，因为不能在函数内创建匿名函数
	var n = nodes.size()
	for i in range(n):
		for j in range(0, n - i - 1):
			var a = nodes[j]
			var b = nodes[j + 1]
			
			var a_entity_type = a.get("entity_type", "unknown")
			var b_entity_type = b.get("entity_type", "unknown")
			
			var a_render_order = GameCore.mod_manager.call_mod(
				"EntityManager",
				"get_render_order",
				a_entity_type
			) as int
			
			var b_render_order = GameCore.mod_manager.call_mod(
				"EntityManager",
				"get_render_order",
				b_entity_type
			) as int
			
			# 如果 a 的 render_order 大于 b 的，交换它们
			if a_render_order > b_render_order:
				nodes[j] = b
				nodes[j + 1] = a
	
	# 更新 map_nodes
	map_data["map_nodes"][map_pos_key] = nodes
	
	# 清除 map_nodes_dirty 标记
	if map_data.has("map_nodes_dirty"):
		map_data["map_nodes_dirty"][map_pos_key] = false
	
	# 更新地图实例
	map_instance["data"] = map_data
	_mud_map_instances[map_instance_id] = map_instance

## ---------------------------------------------------------
## 获取排序后的地图位置实体列表
## @param args: 包含以下字段的字典
##   - map_instance_id: 地图实例 ID
##   - map_position: 地图位置
## @return: 排序后的实体实例列表
## ---------------------------------------------------------
func get_sorted_map_nodes_at_map_position(args: Dictionary) -> Array:
	var map_instance_id = args.get("map_instance_id", "")
	var map_position = args.get("map_position", Vector2.ZERO)
	
	if map_instance_id == "":
		push_warning("[WorldMapInstanceManager] get_sorted_map_nodes_at_map_position: map_instance_id is required")
		return []
	
	var x = int(map_position.x)
	var y = int(map_position.y)
	var map_pos_key = "%d,%d" % [x, y]
	
	# 检查地图实例是否存在
	if not _mud_map_instances.has(map_instance_id):
		push_warning("[WorldMapInstanceManager] get_sorted_map_nodes_at_map_position: map instance not found")
		return []
	
	var map_instance = _mud_map_instances[map_instance_id]
	var map_data = map_instance.get("data", {})
	
	# 检查 map_nodes_dirty 是否为 true
	if map_data.has("map_nodes_dirty"):
		if map_data["map_nodes_dirty"].get(map_pos_key, false):
			# 需要排序
			sort_map_nodes({
				"map_instance_id": map_instance_id,
				"map_position": map_position
			})
	
	# 检查 map_nodes 是否存在该位置
	if not map_data.has("map_nodes"):
		return []
	
	if not map_data["map_nodes"].has(map_pos_key):
		return []
	
	# 返回排序后的实体列表
	return map_data["map_nodes"][map_pos_key]
