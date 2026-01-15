extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	AudioManager.play_BGM(AudioManager.STATIC_RES.digimon_bgm_10)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_new_game_button_pressed() -> void:
	SceneManager.to_game_scene("NewGameScene")


func _on_load_game_button_pressed() -> void:
	SceneManager.PopupMessage("Not ready")
	SceneManager.to_game_scene("LoadGameScene")


func _on_settings_button_pressed() -> void:
	SceneManager.PopupMessage("Not ready")


func _on_exit_game_button_pressed() -> void:
	GameManager.exit_game()
