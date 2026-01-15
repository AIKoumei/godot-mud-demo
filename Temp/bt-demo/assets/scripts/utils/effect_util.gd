extends BaseUtil


enum STATIC_EffectType {
	DoNothing
	,Damage
	,Heal
	,AddEffect
	,UseSkill
}


func get_effect_default_entity():
	return {
		type = STATIC_EffectType.DoNothing
	}


# ##############################################################################
# funcs
# ##############################################################################


func apply_effect(event):
	return true
