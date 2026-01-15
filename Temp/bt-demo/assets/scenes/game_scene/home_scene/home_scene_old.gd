extends Node2D




@onready var map_obj_layer: Node2D = $MapObjLayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _physics_process(delta: float) -> void:
	pass


func _unhandled_input(event: InputEvent) -> void:
	#print("? _unhandled_input")
	if event.is_action("KEY_R1"):
		SceneManager.zoom_in_camera()
	elif event.is_action("KEY_R2"):
		SceneManager.zoom_out_camera()
	var direction = Input.get_vector("KEY_LEFT", "KEY_RIGHT", "KEY_DOWN", "KEY_UP")
	SceneManager.move_camera(direction)
	
	if event.is_action_pressed("MOUSE_LEFT_CLICK"):
		if event is InputEventMouse:
			handle_mouse_click_event(event)


# ##############################################################################
# funcs
# ##############################################################################


enum E_ToolAction {
	Empty
	,Hand
	,Food
	,Medicine
	,Poop
	,Bandage
	,Cure
	,Book
	,Door
}

@export var tool_action: E_ToolAction = E_ToolAction.Empty

func handle_mouse_click_event(event: InputEvent):
	event = event as InputEventMouse
	tool_action = SceneManager.get_home_scene_tool_action()
	match tool_action:
		E_ToolAction.Empty:
			pass
		E_ToolAction.Hand:
			pass
		E_ToolAction.Food:
			var food = SceneManager.get_reusable_scene("MapObj_Food")
			NodeUtil.active_node(food)
			NodeUtil.show_node(food)
			map_obj_layer.add_child(food)
			food.global_position = get_global_mouse_position()
		E_ToolAction.Poop:
			pass
		E_ToolAction.Medicine:
			pass
		E_ToolAction.Bandage:
			pass
		E_ToolAction.Cure:
			pass
		E_ToolAction.Book:
			pass
		E_ToolAction.Door:
			pass


# ##############################################################################
# END
# ##############################################################################
