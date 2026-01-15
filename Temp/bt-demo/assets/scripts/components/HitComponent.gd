extends BaseComponent
class_name HitComponent

@export var hp : float = 0
@export var hp_max : float = 0

func _on_ready() -> void:
	self._init_entity()

func _init_entity():
	var root = get_root_node()
	
func hit_target(value: float):
	pass
