extends BaseComponent
class_name ActorComponent

@export var damage : float

func _on_ready() -> void:
	self._init_entity()

func _init_entity():
	EntityManager.apply_entity(get_root_entity(), ActorUtil.get_actor_default_entity())
	#print(get_root_entity())
