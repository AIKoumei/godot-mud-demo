extends BaseComponent
class_name AttackableComponent


@export var cooldown_normal_attack : float = 0
@export var cooldown_normal_attack_max : float = 0
@export var cooldown_special_attack : float = 0
@export var cooldown_special_attack_max : float = 0


# ##############################################################################
# 可以使用技能的能力
# ##############################################################################


func _on_ready() -> void:
	var entity = get_root_entity()
	cooldown_normal_attack = entity.cooldown_normal_attack
	cooldown_normal_attack_max = entity.cooldown_normal_attack_max
	cooldown_special_attack = entity.cooldown_special_attack
	cooldown_special_attack_max = entity.cooldown_special_attack_max

func _physics_process(delta: float):
	#print(Time.get_time_string_from_system() + " " + get_root_node().name + " _physics_process " + "%s - %s = %s"%[cooldown_normal_attack, delta, cooldown_normal_attack-delta])
	cooldown_normal_attack = max(cooldown_normal_attack - delta, 0)
	cooldown_special_attack = max(cooldown_special_attack - delta, 0)
	update_actor_eneity()

func use_normal_attack():
	if cooldown_normal_attack > 0:
		return
	cooldown_normal_attack = cooldown_normal_attack_max
	update_actor_eneity()
	#
	print(Time.get_time_string_from_system() + " " + get_root_node().name + " use_normal_attack")
	#
	SkillUtil.use_skill(SkillUtil.create_skill_event({
		"onwer_actor_entity" : get_root_entity()
		,"skill_id" : 1
		,"target_list" : []
	}))
	
func use_skill(skill_id):
	SkillUtil.use_skill(SkillUtil.create_skill_event({
		"onwer_actor_entity" : get_root_entity()
		,"skill_id" : skill_id
		,"target_list" : []
	}))
	
func use_skill_with_target_list(skill_id, target_list):
	pass


# ##############################################################################
# funcs
# ##############################################################################


func update_actor_eneity():
	EntityManager.apply_entity(get_root_entity(), {
		"cooldown_normal_attack" : cooldown_normal_attack
		,"cooldown_special_attack" : cooldown_special_attack
	})
	
	
