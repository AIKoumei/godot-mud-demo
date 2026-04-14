extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameCore.mod_manager.emit_ui_scene_event("after_scene_ready.DigimonVpetUI")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func get_game_scene_subviewport():
	return $MarginRoot/VBoxRoot/MainRow/FieldPanel/FieldMargin/FieldView/SubViewportContainer/SubViewport


func _on_mod_event(_mod_name: String, event_name: String, event_data: Dictionary) -> void:
	prints("[DigimonVpetUI] 收到事件：", _mod_name, event_name)


func _on_sub_viewport_container_gui_input(event: InputEvent) -> void:
	prints("_on_sub_viewport_container_gui_input", event)
