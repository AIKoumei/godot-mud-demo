extends BaseScene


class_name HomeScene


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	UILayer = $CanvasLayer
	set_cage()
	tile_map_layer.set_cell(Vector2i(0,0), 60, Vector2i.ZERO)
	tile_map_layer.set_cell(Vector2i(0,-1), 60, Vector2i.ZERO)
	tile_map_layer.set_cell(Vector2i(0,1), 60, Vector2i.ZERO)
	tile_map_layer.set_cell(Vector2i(1,0), 49, Vector2i.ZERO)
	tile_map_layer.set_cell(Vector2i(-1,0), 49, Vector2i.ZERO)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
	
# ##############################################################################
# funcs
# ##############################################################################


@onready var tile_map_layer = $TileMapLayer


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		event = event as InputEventMouseButton
		var map_vec = tile_map_layer.local_to_map(tile_map_layer.to_local(get_local_mouse_position()))
		print(get_local_mouse_position(), " ", tile_map_layer.to_local(get_local_mouse_position()), " ", map_vec)
	
	# camera
	if true: return
	
	if event.is_action("KEY_R1"):
		SceneManager.zoom_in_camera()
	elif event.is_action("KEY_R2"):
		SceneManager.zoom_out_camera()
	var direction = Input.get_vector("KEY_LEFT", "KEY_RIGHT", "KEY_DOWN", "KEY_UP")
	SceneManager.move_camera(direction)
	
	if event.is_action_pressed("MOUSE_LEFT_CLICK"):
		if event is InputEventMouse:
			handle_mouse_click_event(event)


func set_cage():
	var cage_tile_map_layer = $TileMapLayer/HomeRestCage.get_node("./TileMapLayer") as TileMapLayer
	var target_vec_i = Vector2i(-3,4)
	var target_vec = Vector2((Vector2(1,1).normalized()*target_vec_i.x).x, target_vec_i.y)
	if target_vec_i.x%2 == 1:
		target_vec = Vector2(target_vec.x,target_vec.y - 0.5)
	print("target_vec ", target_vec)
	var g_target_vec = to_global(target_vec*64)
	var map_vec = tile_map_layer.local_to_map(tile_map_layer.to_local(g_target_vec))
	print("g_target_vec ", g_target_vec, " map_vec ", map_vec)
	var new_vec
	var y_offset = -1 if abs(map_vec.x)%2 == 1 else 0
	for vec in cage_tile_map_layer.get_used_cells():
		var id = cage_tile_map_layer.get_cell_source_id(vec)
		new_vec = vec + map_vec
		if abs(new_vec.x - map_vec.x) == 1:
			new_vec.y += y_offset
		#print(vec, " ", new_vec)
		tile_map_layer.set_cell(new_vec, id, Vector2i.ZERO)
	tile_map_layer.set_cell(map_vec, 59, Vector2i.ZERO)
	$TileMapLayer/HomeRestCage.position = tile_map_layer.to_global(tile_map_layer.map_to_local(map_vec))
	print("target_vec ", target_vec, " ", $TileMapLayer/HomeRestCage.position)
	pass


# ##############################################################################
# funcs
# ##############################################################################


@onready var map_obj_layer: Node2D = $MapObjLayer


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
