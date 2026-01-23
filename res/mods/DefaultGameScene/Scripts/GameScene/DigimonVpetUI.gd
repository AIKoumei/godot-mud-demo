extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func get_game_scene_subviewport():
	return $MarginRoot/VBoxRoot/MainRow/FieldPanel/FieldMargin/FieldView/SubViewportContainer/SubViewport
