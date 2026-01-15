extends BaseUtil

enum SkillType {
	Normal
	,Liner
	,PingPong
	,Circle
}

enum SkillLifeStatus {
	Ready
	,Alive = 100
	,Dead
	,Pause
	,Freaze = 200
	# 持续消耗时间，但是位置不动了
	,Stuck
}

enum SkillShapeType {
	Rectangle
	,Circle
}

enum STATIC_SkillAliveType {
	Normal
	,AliveUntilLifetime
	,AlwaysAlive
}

enum STATIC_SkillEventType {
	NoTarget
	,Target
	,AlwaysAlive
}

# 不同的子弹会加载不同的场景资源，需要标识区分
var STATIC_SkillType = {
	TestBullet = "TestBullet"
}

enum STATIC_EffectType {
	Damage
	,Heal
	,AddEffect
	,UseSkill
}

func get_skill_default_entity():
	return {
		type = SkillType.Normal
		,shape_type = SkillShapeType.Rectangle
		#
		,alive_type = STATIC_SkillAliveType.Normal
		# alive in second
		,hp = 1
		,hp_max = 1
		,lifetime = 3
		,lifetime_max = 3
		# alive | dead
		,life_status = SkillLifeStatus.Alive
		#
		,damage = 1
		#
		,movement_speed = 64*600
		#
		,effect_id_list = []
	}

func get_skill_instance_default_entity():
	return EntityManager.apply_entity({
		skill_id = 0
		# res settings
		,skill_type = STATIC_SkillType.TestBullet
		# worldmap attribute
		,team = GlobalEnv.Teams.__Empty__
		,position = Vector2.ZERO
		,direction = Vector2.ZERO
		,active_status = GlobalEnv.STATIC_ActiveStatus.Active
		# settings for TeamComponent
		,no_collision_layer = true
	}, get_skill_default_entity())


# ##############################################################################
# funcs
# ##############################################################################


func load_skill_configs(skill_id):
	return get_skill_default_entity()


func get_entity_by_skill_id(skill_id):
	return get_skill_default_entity()


func get_skill_type_by_skill_id(skill_id):
	return STATIC_SkillType.TestBullet


# ##############################################################################
# funcs
# ##############################################################################


func is_skill_usable(onwer_actor_entity, skill_id):
	return true


func create_skill_event(new_event = {}):
	var event = {
		"onwer_actor_entity" : false
		,"skill_id" : 0
		,"target_list" : []
	}
	for key in new_event.keys():
		event[key] = new_event[key]
	return event

func use_skill(event):
	var onwer_actor_entity = event.onwer_actor_entity
	var skill_id = event.skill_id
	var target_list = event.target_list
	
	SkillManager.create_skill(EntityManager.get_related_node_by_entity_uid(onwer_actor_entity.UID), skill_id)
	
	
	
