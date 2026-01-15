extends BaseScene


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	var event = GameManager.game_start_event
	if not event:
		push_error("empty GameStartEvent while entering game scene")
		event = GameStartEvent.new()
	match event.game_start_type:
		GameStartEvent.E_GameStartType.NewGame:
			SceneManager.to_game_scene("HomeScene")
		GameStartEvent.E_GameStartType.LoadGame:
			pass
		GameStartEvent.E_GameStartType.PassGame:
			pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
