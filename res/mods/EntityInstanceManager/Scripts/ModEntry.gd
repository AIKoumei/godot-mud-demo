## res/mods/EntityInstanceManager/Scripts/ModEntry.gd
## 实体实例管理模块
## 功能：管理游戏中的实体实例，包括创建、销毁、查询等操作
## 配置：使用全局种子 GameCore.Settings.GameSettings.WorldSeed
##
## 主要功能：
## 1. 创建逻辑实体实例
## 2. 销毁逻辑实体实例
## 3. 查询实体实例
## 4. 注册实体实例
##
## 实体实例数据结构：
## {
##     "instance_id": entity_instance_id,
##     "entity_id": entity_template_id,
##     "name": name
##     "entity_type": entity_type
##     "map_instance_id": map_instance_id,
##     "map_position": map_position,
##     "attributes": attributes
## }
##
## 使用示例：
## # 示例1：创建实体实例
## var entity_cfg = {
##     "entity_id": "test_entity",
##     "attributes": {
##         "description": "测试实体",
##         "roles": ["test"]
##     }
## }
## var entity = EntityInstanceManager.create_entity(entity_cfg)
##
## # 示例2：销毁实体实例
## EntityInstanceManager.delete_entity(entity.instance_id)
##
## # 示例3：查询实体实例
## var entity = EntityInstanceManager.get_entity(instance_id)
##
## # 示例4：获取所有实体实例
## var entities = EntityInstanceManager.get_all_entities()
##
## # 示例5：创建并放置到地图的实体实例
## var map_entity_cfg = {
##     "entity_id": "test_entity",
##     "map_instance_id": "map_1",
##     "map_position": Vector2(10, 10)
## }
## var map_entity = EntityInstanceManager.create_entity(map_entity_cfg)
##
## # 示例6：更新实体实例
## var update_cfg = {
##     "name": "更新后的测试实体",
##     "attributes": {
##         "description": "更新后的测试实体描述"
##     }
## }
## EntityInstanceManager.update_entity(entity.instance_id, update_cfg)
##
## # 示例7：快捷注册实体实例
## var entity_data = {
##     "instance_id": "1001",
##     "entity_id": "test_entity",
##     "name": "测试实体",
##     "entity_type": "human",
##     "map_instance_id": "map_1",
##     "map_position": Vector2(10, 10),
##     "attributes": {}
## }
## EntityInstanceManager.register_entity_instance(entity_data)
##

extends ModInterface
class_name EntityInstanceManager

## 成员变量
## 1. 存储所有逻辑实体实例: { instance_id: EntityObject }
var _entities: Dictionary = {}
## 2. 自增 ID 种子
var _next_id: int = 1000
## 3. 随机数生成器
var _rng: RandomNumberGenerator

## 模块启用时执行
## 功能：初始化随机数生成器
func _on_mod_enable() -> void:
	# 初始化随机数生成器
	_rng = RandomNumberGenerator.new()
	_rng.seed = GameCore.Settings.GameSettings.WorldSeed
	
	# 注册事件监听器，监听保存事件
	register_event_listener_with_name(ModEventListenerFilter.new()
		.set_listen_type(ModEventListenerFilter.ListenType.ALWAYS)
		.set_mod_filter_type(ModEventListenerFilter.ModFilterType.ANY)
		.set_mod_name("SceneManager")
		.set_event_filter_type(ModEventListenerFilter.EventFilterType.TARGET)
		.set_event_name("SaveAllMapInstanceData")
		, "SaveAllMapInstanceData"
	)

## 核心接口：创建逻辑实体（不挂载场景树）
## @param entity_cfg: 实体配置数据，包含 entity_id、attributes_data、map_instance_id、map_position 等信息
## @return 返回创建的逻辑实体数据对象
func create_entity(entity_cfg: Dictionary) -> Dictionary:
	## 1. 构建实体配置
	if not entity_cfg.has("entity_id"):
		push_warning("[EntityInstanceManager] 创建失败: 缺少 entity_id")
		return {}
	
	## 2. 通过 MudMapEntityFactory 创建实体实例
	var entity = MudMapEntityFactory.create_entity(entity_cfg)
	
	if entity == null or entity.is_empty():
		push_warning("[EntityInstanceManager] 创建失败: 模板不存在 %s" % entity_cfg.get("entity_id"))
		return {}

	## 3. 确保实例 ID 存在（必须拥有 entity_instance_id）
	var instance_id = entity.get("instance_id", "")
	if instance_id == "":
		instance_id = _generate_unique_id()
		entity["instance_id"] = instance_id
		entity["entity_instance_id"] = instance_id
	elif not entity.has("entity_instance_id"):
		# 确保同时设置 entity_instance_id
		entity["entity_instance_id"] = instance_id

	## 4. 确保实体类型存在
	if not entity.has("entity_type"):
		entity["entity_type"] = entity.get("type", "unknown")

	## 5. 记录并维护
	_entities[instance_id] = entity
	
	## 6. 抛出事件：通知可视化模块（如 WorldMap）去渲染这个实体
	GameCore.mod_manager.emit_mod_event(mod_name, "entity_created", {"entity": entity})
	
	return entity

## 接口：删除逻辑实体
## @param entity_instance_id: 实体实例 ID
func delete_entity(entity_instance_id: String):
	if _entities.has(entity_instance_id):
		var entity = _entities[entity_instance_id]
		_entities.erase(entity_instance_id)
		## 通知可视化模块移除渲染
		GameCore.mod_manager.emit_mod_event(mod_name, "entity_destroyed", {"instance_id": entity_instance_id})

## 接口：获取实体实例
## @param instance_id: 实体实例 ID
## @return: 实体实例数据字典
func get_entity(instance_id: String) -> Dictionary:
	return _entities.get(instance_id, {})

## 接口：获取所有实体实例
## @return: 实体实例数据数组
func get_all_entities() -> Array:
	return _entities.values()

## 接口：根据实体类型获取实体实例
## @param entity_type: 实体类型
## @return: 实体实例数据数组
func get_entities_by_type(entity_type: String) -> Array:
	var result = []
	for entity in _entities.values():
		if entity.get("entity_type") == entity_type:
			result.append(entity)
	return result

## 接口：根据地图实例 ID 获取实体实例
## @param map_instance_id: 地图实例 ID
## @return: 实体实例数据数组
func get_entities_by_map(map_instance_id: String) -> Array:
	var result = []
	for entity in _entities.values():
		if entity.get("map_instance_id") == map_instance_id:
			result.append(entity)
	return result

# 已取消 create_entity_instance 方法，统一使用 create_entity 方法

## 快捷注册实体实例
## @param entity_data: 实体实例数据
## @return: 是否注册成功
func register_entity_instance(entity_data: Dictionary) -> bool:
	if entity_data.is_empty():
		return false
	
	var instance_id = entity_data.get("instance_id", "")
	if instance_id == "":
		return false
	
	# 确保 entity_instance_id 和 instance_id 保持一致
	if not entity_data.has("entity_instance_id"):
		entity_data["entity_instance_id"] = instance_id
	if entity_data.get("instance_id", "") != instance_id:
		entity_data["instance_id"] = instance_id
	
	_entities[instance_id] = entity_data
	print("[EntityInstanceManager] 实体实例已快捷注册: %s" % instance_id)
	return true

## 接口：更新实体实例
## @param entity_instance_id: 实体实例 ID
## @param entity_cfg: 要更新的实体数据
## @return: 更新后的实体实例数据
func update_entity(entity_instance_id: String, entity_cfg: Dictionary) -> Dictionary:
	if not _entities.has(entity_instance_id):
		return {}
	
	var entity = _entities[entity_instance_id]
	entity = GameCore.DictionaryTools.merge(entity, entity_cfg)
	
	# 确保 entity_instance_id 和 instance_id 保持一致
	if not entity.has("entity_instance_id"):
		entity["entity_instance_id"] = entity_instance_id
	if entity.get("instance_id", "") != entity_instance_id:
		entity["instance_id"] = entity_instance_id
	
	_entities[entity_instance_id] = entity
	
	## 抛出事件：通知可视化模块更新渲染
	GameCore.mod_manager.emit_mod_event(mod_name, "entity_updated", {"entity": entity})
	
	return entity

## 内部方法：生成唯一 ID
## @return: 唯一 ID 字符串
func _generate_unique_id() -> String:
	## 使用随机数生成器确保可重复生成
	_next_id += 1
	return str(_next_id)

## 事件处理方法
func _on_mod_event(_mod_name: String, event_name: String, event_data: Dictionary) -> void:
	super._on_mod_event(_mod_name, event_name, event_data)
	if event_name == "SaveAllMapInstanceData":
		save_entity_instances()

## 保存所有实体实例
## 功能：将所有实体实例保存到磁盘
func save_entity_instances():
	print("EntityInstanceManager.save_entity_instances")
	for instance_id in _entities.keys():
		var entity = _entities[instance_id]
		# 为每个实体生成一个唯一的文件名
		var file_name = "entity_%s" % instance_id.uri_encode()
		if GameCore.debugging and SaveManager.has_mod_slot_file(GameCore.Settings.GameSettings.GameSlot, "%s/%s.sav" % [mod_name, file_name]):
			continue
		SaveManager.save_mod_slot_data(GameCore.Settings.GameSettings.GameSlot, "%s/%s" % [mod_name, file_name], entity)
