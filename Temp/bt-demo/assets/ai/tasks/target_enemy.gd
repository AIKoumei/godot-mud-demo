@tool
extends BTAction
## Empty description. [br]
## Returns [code]SUCCESS[/code].


@export var target_entity_uid_var: StringName = &"target_entity_uid"


# Display a customized name (requires @tool).
func _generate_name() -> String:
	return "target enemy : ➜%s" % [
		LimboUtility.decorate_var(target_entity_uid_var)
	]


# Called each time this task is ticked (aka executed).
func _tick(_delta: float) -> Status:
	if not "entity" in agent:
		return FAILURE
	if not GlobalEnv.EntityKeyNames.enemies in agent.entity:
		return FAILURE
	if agent.entity.enemies.size() == 0:
		return FAILURE
		
	blackboard.set_var(target_entity_uid_var, agent.entity.enemies.keys().pick_random())
	
	return SUCCESS
