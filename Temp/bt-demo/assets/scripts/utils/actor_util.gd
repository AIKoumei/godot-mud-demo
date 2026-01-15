extends BaseUtil

enum STATIC_ActorAttributes {
	hp
	,hp_max
	,atk
	,def
	,spd
	,movement_speed
	 # battle
	,cooldown_normal_attack
	,cooldown_special_attack
}
var STATIC_ActorAttributesNames = {
	hp = "hp"
	,hp_max = "hp_max"
	,atk = "atk"
	,def = "def"
	,spd = "spd"
	,movement_speed = "movement_speed"
	 # skill
	,learded_skill_list = []
	 # battle
	,cooldown_normal_attack = "cooldown_normal_attack"
	,cooldown_special_attack = "cooldown_special_attack"
}

enum STATIC_ActorAliveStatus {
	Dead
	,Alive
	,Sleep
}

func get_actor_default_entity():
	return {
		# mapworld attributes
		movement_speed = 64*400
		,escape_target_speed = 64*300
		,pursue_target_speed = 64*400
		,team = GlobalEnv.Teams.__Empty__
		,position = Vector2.ZERO
		,direction = Vector2.ZERO
		# battle attributes
		,hp = 10
		,hp_max = 10
		,atk = 1
		,def = 1
		,spd = 1
	 	# skill
		,normal_attack_skill_id = 0
		,learded_skill_list = []
		 # battle
		,cooldown_normal_attack = 0
		,cooldown_normal_attack_max = 2
		,cooldown_special_attack = 0
		,cooldown_special_attack_max = 0
	}


# ##############################################################################
# mapworld funcs
# ##############################################################################


func get_actor_movement_speed(actor_entity_uid):
	var entity = EntityManager.get_entity(actor_entity_uid)
	return entity.get("movement_speed", 64*4)


# ##############################################################################
# battle funcs
# ##############################################################################
