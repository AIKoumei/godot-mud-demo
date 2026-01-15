extends BaseManager

#class_name EntityManager

var _uid : int = 0
var EntityTable = {}

func create_entity():
	_uid+=1
	var entity = {"UID" = _uid}
	EntityTable[entity.UID] = entity
	return entity

func create_skill_entity():
	_uid+=1
	var entity = SkillUtil.get_skill_default_entity()
	entity.UID = _uid
	EntityTable[entity.UID] = entity
	return entity

func create_skill_instance_entity():
	_uid+=1
	var entity = SkillUtil.get_skill_instance_default_entity()
	entity.UID = _uid
	EntityTable[entity.UID] = entity
	return entity

var EntityToNodeTable = {}

func regist_entity(entity, node):
	EntityToNodeTable[entity.UID] = node

func unregist_entity(entity):
	EntityToNodeTable.erase(entity.UID)

func free_entity(entity):
	unregist_entity(entity)
	EntityTable.erase(entity.UID)

func get_entity(entity_uid):
	return EntityTable[entity_uid]
	
func apply_entity(entity, other_entity):
	for key in other_entity.keys():
		entity[key] = other_entity[key]
	return entity

func get_related_node_by_entity_uid(entity_uid):
	return EntityToNodeTable[entity_uid]
