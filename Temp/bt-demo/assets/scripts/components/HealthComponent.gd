extends BaseComponent
class_name HealthComponent

@export var hp : float = 0
@export var hp_max : float = 0

func _on_ready() -> void:
	self._init_entity()
	var root = get_root_node()
	var entity = get_root_entity()
	self.hp = entity.hp
	self.hp_max = entity.hp_max

func _init_entity():
	var root = get_root_node()
	
func take_damage(value:float):
	var entity = get_root_entity()
	
	entity.hp -= value
	
	if entity.hp <= 0:
		self.on_dead()
		
	self.hp = entity.hp
	self.hp_max = entity.hp_max
		
func on_dead():
	var entity = get_root_entity()
	entity[GlobalEnv.EntityKeyNames.alive_status] = ActorUtil.STATIC_ActorAliveStatus.Dead
