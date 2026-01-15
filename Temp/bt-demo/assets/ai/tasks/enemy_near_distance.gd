@tool
extends BTCondition
## InRange condition checks if the agent is within a range of target,
## defined by [member distance_min] and [member distance_max]. [br]
## Returns [code]SUCCESS[/code] if the agent is within the given range;
## otherwise, returns [code]FAILURE[/code].

@export var target_entity_uid_var: StringName = &"target_entity_uid"
@export var target_pos_var: StringName = &"target_pos"


# Display a customized name (requires @tool).
func _generate_name() -> String:
	return "EnemyInDistance : ➜%s" % [
		LimboUtility.decorate_var(target_entity_uid_var)
		#,LimboUtility.decorate_var(target_pos_var)
	]


# Called each time this task is ticked (aka executed).
func _tick(_delta: float) -> Status:
	#var pos: Vector2
	#var is_good_position: bool = false
	#while not is_good_position:
		## Randomize until we find a good position (good position == not outside the arena).
		#var angle: float = randf() * TAU
		#var rand_distance: float = randf_range(range_min, range_max)
		#pos = agent.global_position + Vector2(sin(angle), cos(angle)) * rand_distance
		#is_good_position = agent.is_good_position(pos)
	#blackboard.set_var(position_var, pos)
	if not "entity" in agent:
		return FAILURE
	if not GlobalEnv.EntityKeyNames.enemies in agent.entity:
		return FAILURE
	if agent.entity.enemies.size() == 0:
		return FAILURE
		
	blackboard.set_var(target_entity_uid_var, agent.entity.enemies.keys().pick_random())
	
	return SUCCESS
