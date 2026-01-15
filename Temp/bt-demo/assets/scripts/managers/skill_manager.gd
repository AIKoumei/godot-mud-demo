extends BaseManager

#class_name EntityManager


@export var SkillRecylePool = {}


# ##############################################################################
# laod res
# ##############################################################################


var STATIC_RES = {
	TestBullet = preload("res://assets/actors/TestBullet.tscn")
}


var _manager_inited = false
var node_trush = Node.new()
func _init() -> void:
	if _manager_inited: return
	_manager_inited = true
	self.add_child(node_trush)
	node_trush.name = "Trush"



# ##############################################################################
# reuse funcs
# ##############################################################################


func drop_to_trush(skill: BaseSkill):
	skill.process_mode = Node.PROCESS_MODE_DISABLED
	if not skill.entity.skill_type in SkillRecylePool:
		SkillRecylePool[skill.entity.skill_type] = []
	SkillRecylePool[skill.entity.skill_type].append(skill)
	skill.get_parent().remove_child(skill)
	node_trush.add_child(skill)
	#skill.get_parent().call_deferred("remove_child", skill)

func get_recyle_item(skill_type):
	if skill_type in SkillRecylePool and SkillRecylePool[skill_type].size() > 0:
		var skill = SkillRecylePool[skill_type].pop_front()
		node_trush.remove_child(skill)
		return skill
	#skill.process_mode = Node.PROCESS_MODE_INHERIT



# ##############################################################################
# funcs
# ##############################################################################


func create_skill(node: Node, skill_id):
	var skill_type = SkillUtil.get_skill_type_by_skill_id(skill_id)
	var skill = get_recyle_item(skill_type) as BaseSkill
	if not skill:
		skill = STATIC_RES.TestBullet.instantiate() as BaseSkill
	skill.empty()
	skill.init_by_skill_id(skill_id)
	skill.init_by_onwer_entity(node.entity)
	get_node("/root").add_child(skill)
	skill.active()
