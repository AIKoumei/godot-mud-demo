extends Node

## Get the closest flanking position to target.
func get_desired_position(actor: Node2D, target: Node2D, approach_distance = 128) -> Vector2:
	var side: float = signf(actor.global_position.x - target.global_position.x)
	var desired_pos: Vector2 = target.global_position
	desired_pos.x += approach_distance * side
	return desired_pos
