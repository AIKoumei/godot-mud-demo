## res/mods/UnitInstanceManager/Scripts/ModEntry.gd
extends ModInterface

# 存储所有逻辑单位实例: { instance_id: UnitEntityObject }
var _entities: Dictionary = {}
var _next_id: int = 1000 # 自增 ID 种子

func _on_mod_load() -> bool:
	return true

## 核心接口：创建逻辑单位（不挂载场景树）
## @return 返回创建的逻辑实体数据对象
func create_unit_entity(unit_id: String, initial_data: Dictionary = {}) -> Dictionary:
	# 1. 获取模板
	var template = GameCore.mod_manager.call_mod("UnitManager", "get_unit_template", [unit_id])
	if template == null or template.is_empty():
		push_error("[UnitInstanceManager] 创建失败: 模板不存在 %s" % unit_id)
		return {}

	# 2. 构建逻辑实体对象 (使用字典或自定义对象)
	var entity_id = _generate_unique_id()
	var entity = {
		"instance_id": entity_id,
		"unit_id": unit_id,
		"base_info": template.get("base_info", {}).duplicate(),
		"stats": template.get("base_stats", {}).duplicate(),
		"components": template.get("components", {}).duplicate(),
		"runtime_data": {
			"pos": initial_data.get("pos", Vector2.ZERO),
			"state": "idle",
			"owner_mod": template._source_mod
		}
	}

	# 3. 记录并维护
	_entities[entity_id] = entity
	
	# 4. 抛出事件：通知可视化模块（如 WorldMap）去渲染这个单位
	GameCore.mod_manager.emit_mod_event(mod_name, "unit_entity_created", {"entity": entity})
	
	return entity

## 接口：销毁逻辑实体
func destroy_unit_entity(instance_id: int):
	if _entities.has(instance_id):
		var entity = _entities[instance_id]
		_entities.erase(instance_id)
		# 通知可视化模块移除渲染
		GameCore.mod_manager.emit_mod_event(mod_name, "unit_entity_destroyed", {"instance_id": instance_id})

func get_entity(instance_id: int) -> Dictionary:
	return _entities.get(instance_id, {})

func get_all_entities() -> Array:
	return _entities.values()

func _generate_unique_id() -> int:
	_next_id += 1
	return _next_id
