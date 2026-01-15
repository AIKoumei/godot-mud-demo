#*
#* do not ues
#* 
#* pursue_target.gd
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

## How close should the agent be to the desired position to return SUCCESS.
const TOLERANCE := 64.0

## Blackboard variable that stores our target (expecting Node2D).
@export var target_entity_uid_var: StringName = &"target_entity_uid"

## Desired distance from target.
@export var approach_distance: float = 100.0

var _waypoint: Vector2


# Display a customized name (requires @tool).
func _generate_name() -> String:
	return "pursue target %s" % [LimboUtility.decorate_var(target_entity_uid_var)]


# Called each time this task is entered.
func _enter() -> void:
	#print(target_entity_uid_var)
	var target: Node2D = EntityManager.get_related_node_by_entity_uid(blackboard.get_var(target_entity_uid_var, null))
	if is_instance_valid(target):
		# Movement is performed in smaller steps.
		# For each step, we select a new waypoint.
		_select_new_waypoint(Physic2dSystem.get_desired_position(agent, target))


# Called each time this task is ticked (aka executed).
func _tick(_delta: float) -> Status:
	var target: Node2D = EntityManager.get_related_node_by_entity_uid(blackboard.get_var(target_entity_uid_var, null))
	if not is_instance_valid(target):
		return FAILURE

	var desired_pos: Vector2 = Physic2dSystem.get_desired_position(agent, target)
	if agent.global_position.distance_to(desired_pos) < TOLERANCE:
		return SUCCESS

	if agent.global_position.distance_to(_waypoint) < TOLERANCE:
		_select_new_waypoint(desired_pos)

	var speed: float = ActorUtil.get_actor_movement_speed(agent.entity.UID)
	var desired_velocity: Vector2 = agent.global_position.direction_to(_waypoint) * speed
	agent.move(desired_velocity)
	#agent.update_facing()
	return RUNNING


## Select an intermidiate waypoint towards the desired position.
func _select_new_waypoint(desired_position: Vector2) -> void:
	var distance_vector: Vector2 = desired_position - agent.global_position
	var angle_variation: float = randf_range(-0.2, 0.2)
	_waypoint = agent.global_position + distance_vector.limit_length(150.0).rotated(angle_variation)
