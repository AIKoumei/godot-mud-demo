## res://mods/WorldMapManager/Scripts/Core/MudMapGenerator.gd
## --------------------------------------------------------------------------
## MudMapGenerator
## --------------------------------------------------------------------------
class_name MudMapGenerator

# --------------------------------------------------------------------------
# I. 静态成员变量 (Static Member Variables)
# --------------------------------------------------------------------------

## 用于存储生成的 mud map template
static var mud_map_templates: Dictionary = {}

# --------------------------------------------------------------------------
# II. 主生成功能
# --------------------------------------------------------------------------

## 生成 mud map template
## @param config: 配置字典，包含 name 和 map_type
## @return: 生成的 mud map template
static func generate_mud_map_template(config: Dictionary) -> Dictionary:
	# 设置全局种子，确保可重复生成相同结果
	_set_global_seed()
	
	# 生成 metadata
	var metadata = {
		"version": "1.0.0",
		"generate_at": _get_current_time(),
		"config": config
	}
	
	# 获取 location 配置
	var location_name = config.get("name", "unknown")
	var location_data = _get_location_data(location_name)
	
	# 确定地图类型
	var map_type = config.get("map_type", "")
	if map_type == "":
		# 从 location 配置中获取 mud_map_type
		map_type = location_data.get("mud_map_type", "wilderness")
	
	# 生成基础数据结构（符合 README 1.2 输出）：
	## {
	##     metadata: {version, generate_at, config},
	##     data: {
	##         map_id: location_name,
	##         map_name: location_name,
	##         map_type: "town"|"wilderness",
	##         map_sub_type: "village"|"town"|"city"|"mountain"|"jungle"|"forest"|"swamp"|"desert"|"ice"|"snow"|"water"|"land"|"space"|"void"|"other",
	##         map_size: [width, height],
	##         blocks: {"block_id": {size: [width, height], nodes: [[x,y]...]}},
	##         map_nodes: [
	##             {
	##                 entity_type: "entity"|"plain"|"grass"|"dirt"|"rock"|"water"|"ice"|"snow"|"other",
	##                 attributes: {
	##                     map_position: [x, y],
	##                     description: "", // 可选
	##                     passable: {}, // 可选
	##                     encounter_id_list: [], // 可选
	##                     ...
	##                 }
	##             },
	##             {
	##                 entity_type: "entity"|"decoration"|"item"|"human"|"digimon"|"other",
	##                 attributes: {
	##                     map_position: [x, y],
	##                     description: "", // 可选
	##                     actions: {}, // 可选
	##                     ...
	##                 }
	##             }
	##         ],
	##         encounters: {}
	##     }
	## }
	var data = {
		"map_id": location_name,
		"map_name": location_name,
		"map_type": map_type,
		"map_sub_type": _get_default_map_sub_type(map_type),
		"map_size": [0, 0],
		"blocks": {},
		"map_nodes": [],
		"encounters": {}
	}
	
	# 根据 map_type 调用不同的生成器
	if map_type == "town":
		_generate_town_map(data, config)
	elif map_type == "wilderness":
		_generate_wilderness_map(data, config)
	
	# 构建最终结果
	var result = {
		"metadata": metadata,
		"data": data
	}
	
	# 存储生成的模板
	mud_map_templates[data.get("map_id")] = result
	
	return result


## 设置全局种子
static func _set_global_seed() -> void:
	# 使用 GameCore.Settings.GameSettings.WorldSeed 作为全局种子
	if Engine.has_meta("GameCore"):
		var world_seed = GameCore.mod_manager.get_mod("Settings").GameSettings.get("WorldSeed", 0)
		# 使用 RandomNumberGenerator 来设置种子
		var rng = RandomNumberGenerator.new()
		rng.seed = world_seed
		# 保存 rng 到全局，以便其他方法使用
		Engine.set_meta("MudMapGeneratorRng", rng)

# --------------------------------------------------------------------------
# III. 生成逻辑实现
# --------------------------------------------------------------------------

## 生成城镇地图
## @param data: 地图数据字典
## @param config: 配置字典
static func _generate_town_map(data: Dictionary, config: Dictionary) -> void:
	# 通过 LocationManager 获取 location 配置
	var location_name = config.get("name", config.get("location_name", "unknown"))
	var location_data = _get_location_data(location_name)
	if location_data.is_empty():
		push_error("[MudMapGenerator] 无法获取 location 数据: %s" % location_name)
		return

	# 调用 TownGen.gd 生成城镇地图数据
	var seed = config.get("seed", 0)
	var config_dict = TownGen.gen_config(null, null, seed)
	var map_generator = TownGen.new(config_dict)
	var town_data = map_generator.run()
	
	# TODO 临时覆盖配置，因为 config 中使用了 generator 的旧数据，同样的，调用 mud map generate 的地方也需要修改
	config.map_data = town_data.data.duplicate()

	# 处理城镇数据
	if town_data and town_data.has("data"):
		var town_data_data = town_data["data"]
		
		# 处理总节点
		if town_data_data.has("total_nodes"):
			for node_key:String in town_data_data["total_nodes"].keys():
				var node = town_data_data["total_nodes"][node_key]
				var node_key_str_vec = node_key.split(",")
				var node_position = [int(node_key_str_vec[0]), int(node_key_str_vec[1])]
				
				# 从 EntityManager 获取对应类型的实体配置
				var entity_type = ""
				var node_type = node.get("type", "")
				if node_type == "mask":
					entity_type = "plain"
				elif node_type == "primary_road":
					entity_type = "floor"
				elif node_type == "secondary_road":
					entity_type = "floor"
				elif node_type == "wall":
					entity_type = "wall"
				elif node_type == "gate":
					entity_type = "gate"
				elif node_type == "gate_wall":
					entity_type = "gate_wall"

				var templates = _get_entity_templates_by_type(entity_type)
				
				if location_name == "test_Town":
					pass
					if node_position == [12,11]:
						pass
		
				if not templates.is_empty():
					# 随机选择一个实体配置
					var rng = _get_rng()
					var template = templates.values()[rng.randi() % templates.size()]
					
					# 拷贝 template 并做特异化处理（符合 README 1.2 输出数据结构）
					var map_node = template.duplicate(true)
					# 确保根级别 entity_type 字段存在
					if not map_node.has("entity_type"):
						map_node["entity_type"] = entity_type
					# 确保 attributes 存在
					if not map_node.has("attributes"):
						map_node["attributes"] = {}
					# 设置 attributes 字段（符合 README 1.2 结构）
					map_node["attributes"]["map_position"] = node_position
					# 添加 encounter_id_list（遇敌列表）
					map_node["attributes"]["encounter_id_list"] = []
					data["map_nodes"].append(map_node)
	
		# 处理地图块
		#if town_data_data.has("blocks"):
			#for block_id in town_data_data["blocks"]:
				#var block = town_data_data["blocks"][block_id]
				#data["blocks"][block_id] = {
					#"size": block.get("size", [0, 0]),
					#"map_position": block.get("position", [0, 0]),
					#"nodes": block.get("nodes", [])
				#}
				#
				## 处理块中的节点
				#for node in block.get("nodes", []):
					## 从 EntityManager 获取 floor 类型的实体配置
					#var floor_templates = _get_entity_templates_by_type("floor")
					#if not floor_templates.is_empty():
						## 随机选择一个实体配置
						#var rng = _get_rng()
						#var template = floor_templates.values()[rng.randi() % floor_templates.size()]
						#
						## 处理 node 字符串，转换为 [x,y] 数组
						#var position_array = []
						#if node is String:
							#var parts = node.split(",")
							#if parts.size() == 2:
								#position_array = [int(parts[0]), int(parts[1])]
						#elif node is Array and node.size() == 2:
							#position_array = node
						#else:
							#position_array = [0, 0]
						#
						## 拷贝 template 并做特异化处理（符合 README 1.3.1.2 数据结构）
						#var map_node = template.duplicate(true)
						## 设置根级别字段
						#map_node["entity_type"] = template.get("type","floor")
						## 确保 attributes 存在
						#if not map_node.has("attributes"):
							#map_node["attributes"] = {}
						## 设置 attributes 字段
						#map_node["attributes"]["map_position"] = position_array
						#map_node["attributes"]["passable"] = map_node.get("attributes", {}).get("passable", {})
						#map_node["attributes"]["block_id"] = block_id
						## 添加 encounter_id_list（遇敌列表）
						#map_node["attributes"]["encounter_id_list"] = []
						#data["map_nodes"].append(map_node)

	# 在 gate 位置添加 exit 实体
	_add_exit_entities(data, config)

## 生成郊外地图
## @param data: 地图数据字典
## @param config: 配置字典
static func _generate_wilderness_map(data: Dictionary, config: Dictionary) -> void:
	# 通过 LocationManager 获取 location 配置
	var location_name = config.get("name", config.get("location_name", "unknown"))
	var location_data = _get_location_data(location_name) as Dictionary
	if location_data.is_empty():
		push_error("[MudMapGenerator] 无法获取 location 数据: %s" % location_name)
		return

	# 调用 WildernessGen.gd 生成郊外地图数据
	# 注意：WildernessGen 使用静态方法，不需要实例化
	var seed = config.get("seed", 0)
	var width = config.get("width", 16)
	var height = config.get("height", 16)
	var wilderness_data = WildernessGen.generate_map(seed, width, height)

	
	# TODO 临时覆盖配置，因为 config 中使用了 generator 的旧数据，同样的，调用 mud map generate 的地方也需要修改
	config.map_data = wilderness_data.data.duplicate()

	# 处理郊外数据
	if wilderness_data and wilderness_data.has("data"):
		var wilderness_data_data = wilderness_data["data"]
		
		# 处理高度等级
		if wilderness_data_data.has("final_height_level"):
			var height_levels = wilderness_data_data["final_height_level"]
			data["height_levels"] = height_levels
			
			# 设置地图大小
			data["map_size"] = [height_levels.size(), height_levels[0].size()]
			
			# 高度等级映射表
			var height_to_type = {
				0: "abyssal_sea",
				1: "coastal_sea",
				2: "flat",
				3: "plain",
				4: "hill",
				5: "mountain_slope",
				6: "peak"
			}
			
			# 遍历高度等级
			for x in height_levels.size():
				for y in height_levels[x].size():
					var height_level = height_levels[x][y]
					var terrain_type = height_to_type.get(height_level, "flat")
					
					# 从 EntityManager 获取对应类型的实体配置
					var templates = _get_entity_templates_by_type(terrain_type)
					if not templates.is_empty():
						# 随机选择一个实体配置
						var rng = _get_rng()
						var template = templates.values()[rng.randi() % templates.size()]
						
						# 拷贝 template 并做特异化处理（符合 README 1.2 输出数据结构）
						var map_node = template.duplicate(true)
						# 确保根级别 entity_type 字段存在
						if not map_node.has("entity_type"):
							map_node["entity_type"] = terrain_type
						# 确保 attributes 存在
						if not map_node.has("attributes"):
							map_node["attributes"] = {}
						# 设置 attributes 字段（符合 README 1.2 结构）
						map_node["attributes"]["map_position"] = [x, y]
						map_node["attributes"]["height_level"] = height_level
						# 添加 encounter_id_list（遇敌 列表）
						map_node["attributes"]["encounter_id_list"] = []
						data["map_nodes"].append(map_node)

	# 在地图边缘添加 exit 实体
	_add_exit_entities(data, config)

# --------------------------------------------------------------------------
# IV. 辅助方法
# --------------------------------------------------------------------------

## 获取当前时间
## @return: 当前时间字符串，格式为 YYYY-MM-DD HH:MM:SS
static func _get_current_time() -> String:
	return Time.get_datetime_string_from_system()

## 获取默认地图子类型
## @param map_type: 地图类型
## @return: 默认地图子类型
static func _get_default_map_sub_type(map_type: String) -> String:
	if map_type == "town":
		return "village"
	elif map_type == "wilderness":
		return "land"
	else:
		return "other"

## 获取 location 数据
## @param location_name: location 名称
## @return: location 数据字典
static func _get_location_data(location_name: String) -> Dictionary:
	# 通过 LocationManager 获取 location 配置
	return GameCore.mod_manager.call_mod("LocationManager", "get_location", location_name)

## 从 EntityManager 获取对应类型的实体配置
## @param entity_type: 实体类型
## @return: 实体配置字典
static func _get_entity_templates_by_type(entity_type: String) -> Dictionary:
	# 通过 EntityManager 获取实体模板
	return GameCore.mod_manager.call_mod("EntityManager", "get_entity_templates_by_type", entity_type)


## 添加 exit 实体
## @param data: 地图数据字典
## @param config: 配置字典
static func _add_exit_entities(data: Dictionary, config: Dictionary) -> void:
	# 获取当前地点名称
	var current_location = config.get("name", config.get("location_name", "unknown"))
	
	# 通过 LocationManager 获取 relationship 配置
	var relationships = _get_location_relationships(current_location)
	
	# 如果没有关系，不需要添加 exit 实体
	if relationships.size() == 0:
		return
	
	# 获取地图类型
	var map_type = data.get("map_type", "wilderness")
	
	# 根据地图类型添加不同位置的 exit 实体
	# 暂时取消该逻辑
	if false:
		if map_type == "town":
			# 在 gate 位置添加 exit 实体
			_add_town_exit_entities(data, relationships)
		elif map_type == "wilderness":
			# 在地图边缘的高度等级3位置添加 exit 实体
			_add_wilderness_exit_entities(data, relationships)
		else:
			# 默认在随机位置添加 exit 实体
			_add_default_exit_entities(data, relationships)


## 在城镇地图的 gate 位置添加 exit 实体
## @param data: 地图数据字典
## @param relationships: 关系数组
static func _add_town_exit_entities(data: Dictionary, relationships: Array) -> void:
	# 寻找 gate 位置
	var gate_positions = []
	for node in data.get("map_nodes", []):
		pass
		#var attributes = node.get("attributes", {})
		#if attributes.get("map_cell_type", "") == "gate":
		#	gate_positions.append(attributes.get("map_position", [0, 0]))
		## 另一种尝试
		#if GameCore.mod_manager.call_mod("EntityManager", "is_entity_type", node.get("entity_type",""), "gate"):
		#	gate_positions.append(node.get("attributes", {}).get("map_position", [0, 0]))
	
	# 如果没有 gate 位置，使用默认位置
	if gate_positions.size() == 0:
		return
		gate_positions.append([0, 0])
	
	# 在每个 gate 位置添加 exit 实体（符合 README 1.2 输出数据结构）
	for position in gate_positions:
		# 生成 exit 实体，包含所有的 relationship 数据
		## exit 实体数据结构（符合 README 1.2）：
		## {
		##     entity_type: "exit",
		##     attributes: {
		##         description: "地图出口",
		##         map_position: [x, y],
		##         portal: [location_id, ...],
		##         ...
		##     }
		## }
		var exit_entity = {
			"entity_type": "exit",
			"attributes": {
				"description": "地图出口",
				"map_position": position,
				"portal": []
			}
		}
		
		# 为 exit 实体添加所有的 relationship 数据到 portal 数组
		for related_location in relationships:
			exit_entity["attributes"]["portal"].append(related_location)
		
		data["map_nodes"].append(exit_entity)


## 在郊外地图的边缘高度等级3位置添加 exit 实体
## @param data: 地图数据字典
## @param relationships: 关系数组
static func _add_wilderness_exit_entities(data: Dictionary, relationships: Array) -> void:
	# 获取高度等级数据
	var height_levels = data.get("height_levels", [])
	if height_levels.size() == 0:
		# 如果没有高度等级数据，使用默认位置
		_add_default_exit_entities(data, relationships)
		return
	
	# 寻找地图边缘的高度等级3位置
	var edge_level3_positions = []
	var width = height_levels.size()
	var height = height_levels[0].size()
	
	for x in width:
		for y in height:
			# 检查是否在地图边缘
			if x == 0 or x == width - 1 or y == 0 or y == height - 1:
				# 检查是否高度等级为3
				if height_levels[x][y] == 3:
					edge_level3_positions.append([x, y])
	
	# 如果没有找到合适位置，使用默认位置
	if edge_level3_positions.size() == 0:
		edge_level3_positions.append([0, 0])
	
	# 在每个找到的位置添加 exit 实体（符合 README 1.2 输出数据结构）
	for position in edge_level3_positions:
		# 生成 exit 实体，包含所有的 relationship 数据
		## exit 实体数据结构（符合 README 1.2）：
		## {
		##     entity_type: "exit",
		##     attributes: {
		##         description: "地图出口",
		##         map_position: [x, y],
		##         portal: [location_id, ...],
		##         ...
		##     }
		## }
		var exit_entity = {
			"entity_type": "exit",
			"attributes": {
				"description": "地图出口",
				"map_position": position,
				"portal": []
			}
		}
		
		# 为 exit 实体添加所有的 relationship 数据到 portal 数组
		for related_location in relationships:
			exit_entity["attributes"]["portal"].append(related_location)
		
		data["map_nodes"].append(exit_entity)


## 在默认位置添加 exit 实体
## @param data: 地图数据字典
## @param relationships: 关系数组
static func _add_default_exit_entities(data: Dictionary, relationships: Array) -> void:
	# 随机选择一个位置作为 exit 位置
	var exit_position = _get_random_exit_position(data)
	if exit_position == null:
		exit_position = [0, 0]
	
	# 生成 exit 实体，包含所有的 relationship 数据（符合 README 1.2 输出数据结构）
	## exit 实体数据结构（符合 README 1.2）：
	## {
	##     entity_type: "exit",
	##     attributes: {
	##         description: "地图出口",
	##         map_position: [x, y],
	##         portal: [location_id, ...],
	##         ...
	##     }
	## }
	var exit_entity = {
		"entity_type": "exit",
		"attributes": {
			"description": "地图出口",
			"map_position": exit_position,
			"portal": []
		}
	}
	
	# 为 exit 实体添加所有的 relationship 数据到 portal 数组
	for related_location in relationships:
		exit_entity["attributes"]["portal"].append(related_location)
	
	data["map_nodes"].append(exit_entity)


## 获取地点关系
## @param location_name: 地点名称
## @return: 相关地点数组
static func _get_location_relationships(location_name: String) -> Array:
	# 通过 LocationManager 获取关系配置
	if Engine.has_meta("GameCore"):
		# 通过 LocationManager.get_relationship 获取 relationship 配置
		var relationships = GameCore.mod_manager.call_mod("LocationManager", "get_relationship", location_name)
		if typeof(relationships) == TYPE_ARRAY:
			return relationships
	return []


## 获取随机数生成器
## @return: RandomNumberGenerator 实例
static func _get_rng() -> RandomNumberGenerator:
	if Engine.has_meta("MudMapGeneratorRng"):
		return Engine.get_meta("MudMapGeneratorRng")
	# 如果没有设置，创建一个新的
	var rng = RandomNumberGenerator.new()
	rng.seed = 0
	Engine.set_meta("MudMapGeneratorRng", rng)
	return rng

## 获取随机 exit 位置
## @param data: 地图数据字典
## @return: 位置数组或 null
static func _get_random_exit_position(data: Dictionary) -> Array:
	# 获取地图大小
	var map_size = data.get("map_size", [10, 10])
	var width = map_size[0]
	var height = map_size[1]
	
	# 如果地图大小为 0，返回默认位置
	if width == 0 or height == 0:
		return [0, 0]
	
	# 获取随机数生成器
	var rng = _get_rng()
	
	# 随机选择地图边缘的位置
	var edge = rng.randi() % 4  # 0: 上, 1: 右, 2: 下, 3: 左
	
	match edge:
		0:  # 上
			return [rng.randi() % width, 0]
		1:  # 右
			return [width - 1, rng.randi() % height]
		2:  # 下
			return [rng.randi() % width, height - 1]
		3:  # 左
			return [0, rng.randi() % height]
	
	return [0, 0]
