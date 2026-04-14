extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_new_game_pressed() -> void:
	GameCore.mod_manager.call_mod("GameManager", "new_game")
	## TODO 先给个默认 slot
	#GameCore.Settings.GameSettings.GameSlot = 1
	#GameCore.mod_manager.call_mod("DefaultGameScene", "change_scene", "NewGameScene")
	pass # Replace with function body.


func _on_load_game_pressed() -> void:
	pass # Replace with function body.


func _on_settings_pressed() -> void:
	pass # Replace with function body.


func _on_exit_game_pressed() -> void:
	pass # Replace with function body.
