extends Control

@export var game_seed = randi()
@onready var node_option_game_seed = $Panel/MarginContainer/VSplitContainer/MarginContainer2/MarginContainer/VBoxContainer/Seed/LineEdit


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_on_game_seed_button_pressed()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func set_options(data) -> void:
	if data.get("option","") == "":
		return
	
	var option = data.get("option","")
	var value = str(data.get("value",""))
	if option == "game_seed" and not value == "":
		node_option_game_seed.text = value


func _on_game_seed_button_pressed() -> void:
	game_seed = randi()
	set_options({"option":"game_seed","value":game_seed})


func _on_back_button_pressed() -> void:
	GameCore.mod_manager.call_mod("DefaultGameScene", "change_scene", "StartMenu")


func _on_new_game_button_pressed() -> void:
	GameCore.Settings.GameSettings.WorldSeed = int(node_option_game_seed.text)
	GameCore.mod_manager.call_mod("DefaultGameScene", "change_scene", "WorldGenerateScene")
