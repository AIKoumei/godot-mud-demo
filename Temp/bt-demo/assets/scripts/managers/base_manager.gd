extends Node

class_name BaseManager


@export_category("Manager")
@export var manager_name = ""


func _ready() -> void:
	self.process_mode = Node.PROCESS_MODE_ALWAYS

# ##############################################################################
# common
# ##############################################################################


@export var manager_regist_dict: Dictionary[BaseManager, String] = {}

func regist_to_manager(manager: BaseManager, key:String):
	if key == null or key == "": 
		push_error("regist_to_manager 中没有 key")
		return
	manager.manager_regist_dict[self] = key


func load_from_data(data: Dictionary):
	return data


func save_to_data(data: Dictionary) -> Dictionary:
	return data


func get_save_data_template() -> Dictionary:
	return {}


func get_save_data() -> Dictionary:
	return {}


# ##############################################################################
# END
# ##############################################################################
