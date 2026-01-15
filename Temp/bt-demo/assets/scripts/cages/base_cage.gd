extends BaseEntityOwner


class_name BaseCage


@export var cage_uid: CageManager.E_CageUID = CageManager.E_CageUID.Empty


# ##############################################################################
# cage funcs
# ##############################################################################


func get_cage_configs():
	return CageManager.STATIC_CageConfigs[cage_uid]


func get_cage_size_mark_list():
	return get_cage_configs().cage_size_mark_list


func get_cage_uid():
	return cage_uid


func get_cage_type():
	return get_cage_configs().cage_type


func get_train_type():
	return get_cage_configs().train_type


func get_train_value():
	return get_cage_configs().train_value


# ##############################################################################
# funcs
# ##############################################################################


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	EntityManager.regist_entity(self.entity, self)


func _physics_process(delta: float) -> void:
	super.update_entity()


# ##############################################################################
# funcs
# ##############################################################################

## 用于 item 被放入 pool 的时候清空/重置状态
func empty():
	pass


func reactive():
	pass


func init_entity():
	pass


func update_entity() -> void:
	pass


# ##############################################################################
# END
# ##############################################################################
