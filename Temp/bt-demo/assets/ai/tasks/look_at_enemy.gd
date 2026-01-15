#*
#* lock_at_enemy.gd
#* =============================================================================
#* Copyright (c) 2023-present Serhii Snitsaruk and the LimboAI contributors.
#*
#* Use of this source code is governed by an MIT-style
#* license that can be found in the LICENSE file or at
#* https://opensource.org/licenses/MIT.
#* =============================================================================
#*
@tool
extends BTAction
## Move towards the target until the agent is flanking it. [br]
## Returns [code]RUNNING[/code] while moving towards the target but not yet at the desired position. [br]
## Returns [code]SUCCESS[/code] when at the desired position relative to the target (flanking it). [br]
## Returns [code]FAILURE[/code] if the target is not a valid [Node2D] instance. [br]

## Blackboard variable that stores our target (expecting Node2D).
@export var target_entity_uid_var: StringName = &"target_entity_uid"



# Called each time this task is ticked (aka executed).
func _tick(_delta: float) -> Status:
	var target: Node2D = EntityManager.get_related_node_by_entity_uid(blackboard.get_var(target_entity_uid_var, null))
	if not is_instance_valid(target):
		return FAILURE
	
	agent.look_at(target.global_position)
	return SUCCESS
