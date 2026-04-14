## res/mods/EntityManager/Scripts/ModEntry.gd
## 实体管理模块
## 功能：管理游戏中的实体模板和实体类型
## 配置文件：%s/Data/Entities.json
##
## 主要功能：
## 1. 注册实体模板和实体类型
## 2. 查询实体模板和实体类型
## 3. 从JSON文件加载实体配置
##
## 使用示例：
## # 示例1：注册单个实体模板
## var entity_data = {
##     "entity_type": "human",
##     "attributes": {
##         "description": "测试实体",
##         "roles": ["test"]
##     }
## }
## EntityManager.register_entity("MyMod", "test_entity", entity_data)
##
## # 示例2：批量注册实体
## var packet = {
##     "data": {
##         "entities": {
##             "entity1": { "entity_type": "human", "attributes": { "description": "实体1" } },
##             "entity2": { "entity_type": "item", "attributes": { "description": "实体2" } }
##         },
##         "entity_types": {
##             "test_type": { "entity_type": "test", "parent_entity_type": ["entity"] }
##         }
##     }
## }
## EntityManager.register_entity_packet("MyMod", packet)
##
## # 示例3：从JSON文件加载实体
## var file_path = "res://mods/MyMod/Data/Entities.json"
## EntityManager.regist_entities_from_json("MyMod", file_path)
##
## # 示例4：查询实体模板
## var entity_template = EntityManager.get_entity_template("test_entity")
## print(entity_template)
##
## # 示例5：查询实体类型
## var entity_type = EntityManager.get_entity_type("human")
## print(entity_type)
##


extends ModInterface

## 成员变量
## 1. 核心存储: { "entity_id": { ...blueprint_data... } }
##    用于存储所有注册的实体模板
var _entity_templates: Dictionary = {}

## 2. 实体类型存储: { "entity_type": { ...type_data... } }
##    用于存储所有注册的实体类型
var _entity_types: Dictionary = {}

## 3. 索引：按实体类型索引实体模板
##    格式: { "entity_type": [entity_template_id, ...] }
var _indexer_entity_templates_by_type: Dictionary = {}

## 4. 索引：按父类型索引子实体类型
##    格式: { "parent_type": [child_type1, child_type2, ...] }
var _indexer_child_entity_types_by_parent_type: Dictionary = {}

## 5. 索引：按子类型索引父实体类型
##    格式: { "child_type": [parent_type1, parent_type2, ...] }
var _indexer_parent_entity_types_by_child_type: Dictionary = {}

## 模块启用时执行
## 功能：加载Entities.json文件并注册所有实体模板和实体类型
## 实现：
## 1. 获取模块路径
## 2. 构建Entities.json文件路径
## 3. 调用regist_entities_from_json方法加载并注册实体
func _on_mod_enable() -> void:
	# 加载Entities.json文件
	var mod_name = "EntityManager"
	if GameCore.mod_manager.loaded_mods.has(mod_name):
		var mod_path = GameCore.mod_manager.loaded_mods[mod_name].path
		var entities_file = "%s/Data/Entities.json" % mod_path
		regist_entities_from_json(mod_name, entities_file)
	else:
		push_error("[EntityManager] 模块未找到: %s" % mod_name)

## ---------------------------------------------------------
## 外部接口：注册相关
## ---------------------------------------------------------

## 接口 A：注册单个实体模板 (供脚本动态调用)
## @param source_mod: 提交者的 mod_name
## @param entity_id: 实体的唯一标识符
## @param blueprint: 实体的数据结构
func register_entity(source_mod: String, entity_id: String, blueprint: Dictionary) -> bool:
	if _entity_templates.has(entity_id):
		var existing_mod = _entity_templates[entity_id].get("_source_mod", "Unknown")
		push_warning("[EntityManager] 注册冲突: ID '%s' 已被 Mod '%s' 占用" % [entity_id, existing_mod])
		return false
	
	# 注入来源元数据
	blueprint["_source_mod"] = source_mod
	# 赋值 entity_id，用于唯一标识该实体
	blueprint["entity_id"] = entity_id
	_entity_templates[entity_id] = blueprint
	
	# 更新实体模板按类型索引
	var entity_type = blueprint.get("entity_type", "")
	if entity_type:
		if not _indexer_entity_templates_by_type.has(entity_type):
			_indexer_entity_templates_by_type[entity_type] = []
		_indexer_entity_templates_by_type[entity_type].append(entity_id)
	
	# print("[EntityManager] Mod '%s' 成功注册了单个实体: %s" % [source_mod, entity_id])
	return true

## 接口 B：批量注册 JSON 数据包 (适配你设计的 metadata/data 结构)
## @param source_mod: 提交者的 mod_name
## @param packet: 包含 metadata 和 data.entities 的字典
func register_entity_packet(source_mod: String, packet: Dictionary) -> void:
	if not packet.has("data") or not packet.data.has("entities"):
		push_error("[EntityManager] Mod '%s' 提交的数据包格式非法" % source_mod)
		return
		
	# 注册实体模板
	if packet.data.has("entities"):
		var entities_dict = packet.data.entities
		var count = 0
		
		for entity_id in entities_dict:
			if register_entity(source_mod, entity_id, entities_dict[entity_id]):
				count += 1
			
		print("[EntityManager] Mod '%s' 批量注册了 %d 个实体模板" % [source_mod, count])
	
	# 注册实体类型
	if packet.data.has("entity_types"):
		var entity_types_dict = packet.data.entity_types
		var type_count = 0
		
		for type_id in entity_types_dict:
			if not _entity_types.has(type_id):
				_entity_types[type_id] = entity_types_dict[type_id]
				type_count += 1
				
				# 更新实体类型索引
				var entity_type_data = entity_types_dict[type_id]
				
				# 初始化自身类型的索引（如果不存在）
				if not _indexer_child_entity_types_by_parent_type.has(type_id):
					_indexer_child_entity_types_by_parent_type[type_id] = [type_id]
				if not _indexer_parent_entity_types_by_child_type.has(type_id):
					_indexer_parent_entity_types_by_child_type[type_id] = [type_id]
				
				# 处理 parent_entity_type：当前类型的父类型列表
				if entity_type_data.has("parent_entity_type"):
					for parent_type in entity_type_data.parent_entity_type:
						if not _indexer_child_entity_types_by_parent_type.has(parent_type):
							_indexer_child_entity_types_by_parent_type[parent_type] = [parent_type]
						if type_id not in _indexer_child_entity_types_by_parent_type[parent_type]:
							_indexer_child_entity_types_by_parent_type[parent_type].append(type_id)
						
						# 更新子类型到父类型的索引
						if not _indexer_parent_entity_types_by_child_type.has(type_id):
							_indexer_parent_entity_types_by_child_type[type_id] = [type_id]
						if parent_type not in _indexer_parent_entity_types_by_child_type[type_id]:
							_indexer_parent_entity_types_by_child_type[type_id].append(parent_type)
				
				# 处理 child_entity_type：当前类型的子类型列表
				if entity_type_data.has("child_entity_type"):
					for child_type in entity_type_data.child_entity_type:
						if not _indexer_child_entity_types_by_parent_type.has(type_id):
							_indexer_child_entity_types_by_parent_type[type_id] = [type_id]
						if child_type not in _indexer_child_entity_types_by_parent_type[type_id]:
							_indexer_child_entity_types_by_parent_type[type_id].append(child_type)
						
						# 更新子类型到父类型的索引
						if not _indexer_parent_entity_types_by_child_type.has(child_type):
							_indexer_parent_entity_types_by_child_type[child_type] = [child_type]
						if type_id not in _indexer_parent_entity_types_by_child_type[child_type]:
							_indexer_parent_entity_types_by_child_type[child_type].append(type_id)
		
		# 注册完成后，重新构建完整的索引（包含所有子孙和父类型）
		_build_entity_types_indexes()
			
		print("[EntityManager] Mod '%s' 批量注册了 %d 个实体类型" % [source_mod, type_count])

## 接口 C：从JSON文件注册实体模板和实体类型
## 功能：读取JSON文件并注册其中的实体模板和实体类型
## @param source_mod: 提交者的 mod_name
## @param file_path: JSON文件路径
## 实现：
## 1. 打开并读取JSON文件
## 2. 解析JSON内容
## 3. 调用register_entity_packet方法注册实体
func regist_entities_from_json(source_mod: String, file_path: String) -> void:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		file.close()
		
		# 解析JSON
		var packet = JSON.parse_string(content)
		if packet:
			# 注册实体模板和实体类型
			register_entity_packet(source_mod, packet)
			print("[EntityManager] 成功从文件加载并注册了实体模板和实体类型: %s" % file_path)
		else:
			push_error("[EntityManager] 解析JSON文件失败: %s" % file_path)
	else:
		push_error("[EntityManager] 无法打开JSON文件: %s" % file_path)

## ---------------------------------------------------------
## 外部接口：查询相关
## ---------------------------------------------------------

## 获取实体模板信息
## @param entity_id: 实体模板ID
## @return: 实体模板数据字典，如果不存在返回空字典
func get_entity_template(entity_id: String) -> Dictionary:
	return _entity_templates.get(entity_id, {})

## 检查是否存在实体模板
## @param entity_id: 实体模板ID
## @return: 是否存在该实体模板
func has_template(entity_id: String) -> bool:
	return _entity_templates.has(entity_id)

## ---------------------------------------------------------
## 外部接口：实体类型查询相关
## ---------------------------------------------------------

## 获取实体类型信息
## @param type_id: 实体类型ID
## @return: 实体类型数据字典
func get_entity_type(type_id: String) -> Dictionary:
	return _entity_types.get(type_id, {})

## 检查是否存在实体类型
## @param type_id: 实体类型ID
## @return: 是否存在该实体类型
func has_entity_type(type_id: String) -> bool:
	return _entity_types.has(type_id)

## ---------------------------------------------------------
## 外部接口：实体类型查询相关
## ---------------------------------------------------------

## 获取指定实体类型的所有实体模板
## 优先查询索引，若索引中不存在，则查询entity_templates字典，并更新索引
## @param entity_type: 实体类型
## @return: 实体模板字典，键为实体ID，值为实体模板
func get_entity_templates_by_type(entity_type: String) -> Dictionary:
	var result = {}
	
	# 优先查询索引
	if _indexer_entity_templates_by_type.has(entity_type):
		for entity_id in _indexer_entity_templates_by_type[entity_type]:
			if _entity_templates.has(entity_id):
				result[entity_id] = _entity_templates[entity_id]
	else:
		# 索引不存在，查询entity_templates字典并更新索引
		for entity_id in _entity_templates:
			var blueprint = _entity_templates[entity_id]
			if blueprint.get("entity_type") == entity_type:
				result[entity_id] = blueprint
				if not _indexer_entity_templates_by_type.has(entity_type):
					_indexer_entity_templates_by_type[entity_type] = []
				_indexer_entity_templates_by_type[entity_type].append(entity_id)
	
	return result

## 判断指定实体类型是否属于该大类
## 建立索引：indexer_child_entity_types_by_parent_type[entity_type] = [entity_type,child_entity_type,...]，包含所有子孙类型
## 建立索引：indexer_parent_entity_types_by_child_type[entity_type] = [entity_type,parent_entity_type,...]，包含所有父类型
## 查询时优先查询索引，若索引中不存在，则查询entity_templates字典，并更新索引
## @param entity_type: 实体类型
## @param target_type: 目标类型
## @return: 是否属于该大类
func is_entity_type(entity_type: String, target_type: String) -> bool:
	# 检查实体类型是否存在
	if not _entity_types.has(entity_type) or not _entity_types.has(target_type):
		return false
	
	# 优先查询索引
	if _indexer_parent_entity_types_by_child_type.has(entity_type):
		return target_type in _indexer_parent_entity_types_by_child_type[entity_type]
	else:
		# 索引不存在，构建索引后再查询
		_build_entity_types_indexes()
		if _indexer_parent_entity_types_by_child_type.has(entity_type):
			return target_type in _indexer_parent_entity_types_by_child_type[entity_type]
	
	return false

## 检查指定实体类型是否是另一个类型的子类型（包括间接子类型）
## @param child_type: 子实体类型
## @param parent_type: 父实体类型
## @return: 是否是子类型
func is_sub_entity_type(child_type: String, parent_type: String) -> bool:
	# 检查实体类型是否存在
	if not _entity_types.has(child_type) or not _entity_types.has(parent_type):
		return false
	
	# 优先查询索引
	if _indexer_child_entity_types_by_parent_type.has(parent_type):
		return child_type in _indexer_child_entity_types_by_parent_type[parent_type]
	else:
		# 索引不存在，构建索引后再查询
		_build_entity_types_indexes()
		if _indexer_child_entity_types_by_parent_type.has(parent_type):
			return child_type in _indexer_child_entity_types_by_parent_type[parent_type]
	
	return false

## 获取指定实体类型的实体，包括父类型的实体
## 查询时优先查询索引，若索引中不存在，则查询indexer_parent_entity_types_by_child_type字典，并更新索引
## @param entity_type: 实体类型
## @return: 实体模板字典，键为实体ID，值为实体模板
func get_entity_templates_with_parent_by_type(entity_type: String) -> Dictionary:
	var result = {}
	
	# 获取指定实体类型的所有父类型（包括自身）
	var parent_types = _get_all_parent_entity_types(entity_type)
	
	# 对于每个类型，获取该类型的所有实体模板
	for type_name in parent_types:
		var type_templates = get_entity_templates_by_type(type_name)
		# 合并到结果字典中
		for entity_id in type_templates:
			result[entity_id] = type_templates[entity_id]
	
	return result

## 获取指定实体类型的实体，包括子类型的实体
## 查询时优先查询索引，若索引中不存在，则查询indexer_child_entity_types_by_parent_type字典，并更新索引
## @param entity_type: 实体类型
## @return: 实体模板字典，键为实体ID，值为实体模板
func get_entity_templates_with_child_by_type(entity_type: String) -> Dictionary:
	var result = {}
	
	# 获取指定实体类型的所有子类型（包括自身）
	var child_types = _get_all_child_entity_types(entity_type)
	
	# 对于每个类型，获取该类型的所有实体模板
	for type_name in child_types:
		var type_templates = get_entity_templates_by_type(type_name)
		# 合并到结果字典中
		for entity_id in type_templates:
			result[entity_id] = type_templates[entity_id]
	
	return result

## ---------------------------------------------------------
## 内部方法：索引相关
## ---------------------------------------------------------

## 构建所有索引
func _build_all_indexes() -> void:
	# 构建实体模板按类型索引
	_build_entity_templates_by_type_index()
	
	# 构建实体类型索引
	_build_entity_types_indexes()

## 构建实体模板按类型索引
func _build_entity_templates_by_type_index() -> void:
	_indexer_entity_templates_by_type.clear()
	
	for entity_id in _entity_templates:
		var blueprint = _entity_templates[entity_id]
		var entity_type = blueprint.get("entity_type", "")
		if entity_type:
			if not _indexer_entity_templates_by_type.has(entity_type):
				_indexer_entity_templates_by_type[entity_type] = []
			_indexer_entity_templates_by_type[entity_type].append(entity_id)

## 构建实体类型索引
## 功能：构建包含所有子孙类型和父类型的完整索引
## 实现：
## 1. 初始化每个类型的索引，添加自身
## 2. 构建直接的父子关系（处理 parent_entity_type 和 child_entity_type）
## 3. 使用迭代方式构建完整的子孙类型和父类型索引（直到没有新的类型可以添加）
func _build_entity_types_indexes() -> void:
	_indexer_child_entity_types_by_parent_type.clear()
	_indexer_parent_entity_types_by_child_type.clear()
	
	# 首先为每个类型初始化索引，添加自身
	for type_id in _entity_types:
		_indexer_child_entity_types_by_parent_type[type_id] = [type_id]
		_indexer_parent_entity_types_by_child_type[type_id] = [type_id]
	
	# 然后构建直接的父子关系
	# 遍历所有实体类型，处理 parent_entity_type 字段
	for type_id in _entity_types:
		var entity_type_data = _entity_types[type_id]
		
		# 处理 parent_entity_type：当前类型的父类型列表
		if entity_type_data.has("parent_entity_type"):
			for parent_type in entity_type_data.parent_entity_type:
				if not _indexer_child_entity_types_by_parent_type.has(parent_type):
					_indexer_child_entity_types_by_parent_type[parent_type] = [parent_type]
				if type_id not in _indexer_child_entity_types_by_parent_type[parent_type]:
					_indexer_child_entity_types_by_parent_type[parent_type].append(type_id)
				
				# 更新子类型到父类型的索引
				if not _indexer_parent_entity_types_by_child_type.has(type_id):
					_indexer_parent_entity_types_by_child_type[type_id] = [type_id]
				if parent_type not in _indexer_parent_entity_types_by_child_type[type_id]:
					_indexer_parent_entity_types_by_child_type[type_id].append(parent_type)
		
		# 处理 child_entity_type：当前类型的子类型列表
		if entity_type_data.has("child_entity_type"):
			for child_type in entity_type_data.child_entity_type:
				if not _indexer_child_entity_types_by_parent_type.has(type_id):
					_indexer_child_entity_types_by_parent_type[type_id] = [type_id]
				if child_type not in _indexer_child_entity_types_by_parent_type[type_id]:
					_indexer_child_entity_types_by_parent_type[type_id].append(child_type)
				
				# 更新子类型到父类型的索引
				if not _indexer_parent_entity_types_by_child_type.has(child_type):
					_indexer_parent_entity_types_by_child_type[child_type] = [child_type]
				if type_id not in _indexer_parent_entity_types_by_child_type[child_type]:
					_indexer_parent_entity_types_by_child_type[child_type].append(type_id)
	
	# 使用迭代方式构建包含所有子孙类型的索引
	# 迭代直到没有新的子孙类型可以添加
	var changed = true
	while changed:
		changed = false
		for type_id in _entity_types:
			var current_children = _indexer_child_entity_types_by_parent_type[type_id].duplicate()
			for child in current_children:
				if _indexer_child_entity_types_by_parent_type.has(child):
					var grand_children = _indexer_child_entity_types_by_parent_type[child]
					for grand_child in grand_children:
						if grand_child not in _indexer_child_entity_types_by_parent_type[type_id]:
							_indexer_child_entity_types_by_parent_type[type_id].append(grand_child)
							changed = true
	
	# 使用迭代方式构建包含所有父类型的索引
	# 迭代直到没有新的父类型可以添加
	changed = true
	while changed:
		changed = false
		for type_id in _entity_types:
			var current_parents = _indexer_parent_entity_types_by_child_type[type_id].duplicate()
			for parent in current_parents:
				if _indexer_parent_entity_types_by_child_type.has(parent):
					var grand_parents = _indexer_parent_entity_types_by_child_type[parent]
					for grand_parent in grand_parents:
						if grand_parent not in _indexer_parent_entity_types_by_child_type[type_id]:
							_indexer_parent_entity_types_by_child_type[type_id].append(grand_parent)
							changed = true

## 获取指定实体类型的所有子类型（包括自身）
## @param entity_type: 实体类型
## @return: 所有子类型列表
func _get_all_child_entity_types(entity_type: String) -> Array:
	# 索引已经包含所有子孙类型（包括自身）
	if _indexer_child_entity_types_by_parent_type.has(entity_type):
		return _indexer_child_entity_types_by_parent_type[entity_type]
	
	# 如果索引不存在，构建索引后再返回
	_build_entity_types_indexes()
	if _indexer_child_entity_types_by_parent_type.has(entity_type):
		return _indexer_child_entity_types_by_parent_type[entity_type]
	
	return [entity_type]

## 获取指定实体类型的直接父类型
## @param entity_type: 实体类型
## @return: 父类型列表，如果不存在父类型则返回空列表
func get_parent_entity_type_by_child_type(entity_type: String) -> Array:
	# 检查实体类型是否存在
	if not _entity_types.has(entity_type):
		return []
	
	# 获取实体类型数据
	var entity_type_data = _entity_types[entity_type]
	
	# 返回 parent_entity_type，如果不存在则返回空列表
	return entity_type_data.get("parent_entity_type", [])

## 获取指定实体类型的渲染排序索引
## @param entity_type: 实体类型
## @return: 渲染排序索引
## 实现逻辑：
##   1. 首先检查当前实体类型是否有 render_sort_index
##   2. 如果没有，则递归查找父类型的 render_sort_index
##   3. 如果都没有找到，返回 0
func get_render_order(entity_type: String) -> int:
	# 检查实体类型是否存在
	if not _entity_types.has(entity_type):
		return 0
	
	# 获取实体类型数据
	var entity_type_data = _entity_types[entity_type]
	
	# 检查当前类型是否有 render_sort_index
	if entity_type_data.has("render_sort_index"):
		return entity_type_data.render_sort_index
	
	# 获取父类型列表
	var parent_types = get_parent_entity_type_by_child_type(entity_type)
	
	# 遍历父类型，递归查找 render_sort_index
	for parent_type in parent_types:
		var parent_render_order = get_render_order(parent_type)
		if parent_render_order != 0:
			return parent_render_order
	
	# 如果都没有找到，返回 0
	return 0

## 获取指定实体类型的所有父类型（包括自身）
## @param entity_type: 实体类型
## @return: 所有父类型列表
func _get_all_parent_entity_types(entity_type: String) -> Array:
	# 索引已经包含所有父类型（包括自身）
	if _indexer_parent_entity_types_by_child_type.has(entity_type):
		return _indexer_parent_entity_types_by_child_type[entity_type]
	
	# 如果索引不存在，构建索引后再返回
	_build_entity_types_indexes()
	if _indexer_parent_entity_types_by_child_type.has(entity_type):
		return _indexer_parent_entity_types_by_child_type[entity_type]
	
	return [entity_type]
