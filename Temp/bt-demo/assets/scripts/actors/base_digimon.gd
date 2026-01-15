extends BaseActor

class_name BaseDigimon

#@export var entity = EntityManager.create_entity()

@onready var item_layer = $ItemLayer

enum E_ScenePositionType {
	Unknow
	,Home
	,Battle
	,Adventure
}
@export var scene_position_type = E_ScenePositionType.Unknow ## 所在场景
@export var satiety = 100 ## 饱腹感
enum E_TaskType {
	Idle
	,Rest
	,FindFood
	,Training
	,Pooping
	,Adventure
	,Battle
	,Sleep
}
@export var task_type = E_TaskType.Idle ## 正在执行的任务


# ##############################################################################
# funcs
# ##############################################################################


func _physics_process(delta: float) -> void:
	self.update_entity()


func update_entity() -> void:
	self.entity.position = self.global_position
	self.entity.direction = Vector2.RIGHT.rotated(self.global_rotation)
	self.entity.scene_position_type = scene_position_type
	self.entity.satiety = satiety


# ##############################################################################
# funcs
# ##############################################################################


func handle_map_obj_event(event: BaseMapObjEvent):
	if not event.is_ready():
		return
	match event.obj_type:
		BaseMapObjEvent.E_ObjType.Poop:
			pass
		BaseMapObjEvent.E_ObjType.Food:
			if is_cur_task(E_TaskType.FindFood):
				eat_food(event)


func is_cur_task(_task_type: E_TaskType):
	return task_type == _task_type


func eat_food(event: BaseMapObjEvent):
	var food = EntityManager.get_related_node_by_entity_uid(event.entity_uid) as MapObjFood
	food.consume_by(self)
	if food.is_bad_food():
		play_eat_bad_food()
	else:
		play_eat_food()


func play_eat_bad_food():
	pass

	
func play_eat_food():
	play_eat()


func play_eat():
	pass


# ##############################################################################
# END
# ##############################################################################
