extends BaseScene


@export var home_cage_placement_list: Array[BaseCage] = []
@export var unlocked_cages = []
@onready var HomeCageContainer = $HomeCageContainer
@onready var UnlockedCageContainer = $UnlockedCageContainer


# ##############################################################################
# funs
# ##############################################################################


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	unlocked_cages = CageManager.get_normal_unlocked_cages()
	load_cage_tiles()
	state_machine.send_event("ToIdle")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


# ##############################################################################
# funs
# ##############################################################################


func load_cage_tiles():
	# 加载已经解锁的 cage 
	unlocked_cdge_dict = CageManager.unlocked_cdge_dict
	for CageUID: CageManager.E_CageUID in unlocked_cdge_dict:
		if not cage.cage_uid == CageManager.E_CageType.Empty:
			var cage_node = NodePoolManager.get_recyle_item(NodePoolManager.E_PoolObjType.CageEditScene_LockedCage)
			if not cage_node:
				cage_node = CageManager.STATIC_CageUIDToThumbCageRes[cage.cage_uid].instantiate()
			cage_node.cage_entity_uid_in_edit_scene = cage.cage_uid
			add_child(cage_node)
	# 加载已经放置的 cage 
	home_cage_placement_list = CageManager.home_cage_placement_list
	for cage: BaseCage in home_cage_placement_list:
		if not cage.cage_uid == CageManager.E_CageType.Empty:
			var cage_node = NodePoolManager.get_recyle_item(NodePoolManager.E_PoolObjType.CageEditScene_LockedCage)
			if not cage_node:
				cage_node = CageManager.STATIC_CageUIDToThumbCageRes[cage.cage_uid].instantiate()
			cage_node.cage_entity_uid_in_edit_scene = cage.cage_uid
			add_child(cage_node)


func save_cage_tiles():
	pass


func handle_cage_input_event(event: CageInputEvent):
	match state_machine_state:
		"Idle":
			pass
		"StartDrag":
			print(event)
		"OnDrage":
			pass


# ##############################################################################
# cage funcs
# ##############################################################################


func set_cage(pos, cage_uid):
	pass


# ##############################################################################
# state machine
# ##############################################################################

@export_category("State Machine")
@onready var state_machine = $StateChart
@export var state_machine_state = "Initiate"
@export var drag_target: Node2D


func _on_idle_state_entered() -> void:
	state_machine_state = "Idle"


func _on_start_drag_state_entered() -> void:
	state_machine_state = "StartDrag"


func _on_on_drag_state_entered() -> void:
	state_machine_state = "OnDrag"


# ##############################################################################
# END
# ##############################################################################
