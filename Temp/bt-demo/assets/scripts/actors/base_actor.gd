extends CharacterBody2D

class_name BaseActor

@export var entity = EntityManager.create_entity()
#@export var team : GlobalEnv.Teams = GlobalEnv.Teams.Enemy

const SPEED = 64*400
const JUMP_VELOCITY = -400.0



# ##############################################################################
# component
# ##############################################################################


@export_category("[X]Component")
@export var inited_component_num :int = 0
@export var inited_components :Array[String] = []


# no used
func on_component_init_once(component:Node):
	self.inited_component_num += 1
	self.inited_components.append(component.name)

# no used
func is_components_inited():
	return self.get_node("./Components").get_child_count() <= self.inited_component_num

# ##############################################################################
# funcs
# ##############################################################################


func _physics_process(delta: float) -> void:
	self.update_entity()


# ##############################################################################
# funcs
# ##############################################################################


func _on_ready() -> void:
	EntityManager.regist_entity(self.entity, self)


func update_entity() -> void:
	self.entity.position = self.global_position
	self.entity.direction = Vector2.RIGHT.rotated(self.global_rotation)


# ##############################################################################
# funcs
# ##############################################################################


## Is specified position inside the arena (not inside an obstacle)?
func is_good_position(p_position: Vector2) -> bool:
	var space_state := get_world_2d().direct_space_state
	var params := PhysicsPointQueryParameters2D.new()
	params.position = p_position
	params.collision_mask = 1 # Obstacle layer has value 1
	var collision := space_state.intersect_point(params)
	return collision.is_empty()


func move(p_velocity: Vector2) -> void:
	velocity = lerp(velocity, p_velocity, 0.2)
	move_and_slide()

#
#func _on_tree_entered() -> void:
	#self.entity.team = self.team
