extends Control


@onready var BookPanel = $BookPanel


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_drag_button_pressed() -> void:
	SceneManager.set_home_scene_tool_action(HomeScene.E_ToolAction.Hand)


func _on_food_button_pressed() -> void:
	SceneManager.set_home_scene_tool_action(HomeScene.E_ToolAction.Food)


func _on_medicine_button_pressed() -> void:
	SceneManager.set_home_scene_tool_action(HomeScene.E_ToolAction.Medicine)


func _on_poop_button_pressed() -> void:
	SceneManager.set_home_scene_tool_action(HomeScene.E_ToolAction.Poop)


func _on_bandage_button_pressed() -> void:
	SceneManager.set_home_scene_tool_action(HomeScene.E_ToolAction.Bandage)


func _on_cure_button_pressed() -> void:
	SceneManager.set_home_scene_tool_action(HomeScene.E_ToolAction.Cure)


func _on_book_button_pressed() -> void:
	SceneManager.set_home_scene_tool_action(HomeScene.E_ToolAction.Book)
	BookPanel.visible = true


func _on_door_button_pressed() -> void:
	SceneManager.set_home_scene_tool_action(HomeScene.E_ToolAction.Door)


func _on_book_panel_background_gui_input(event: InputEvent) -> void:
	if not BookPanel.visible: return
	
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == MouseButton.MOUSE_BUTTON_LEFT:
				BookPanel.visible = false


func _on_cae_edit_button_pressed() -> void:
	SceneManager.to_game_scene("CageEditScene")
