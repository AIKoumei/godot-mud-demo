extends TileMapLayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	#set_cell(Vector2.ZERO, 1, Vector2i(0, 0))
	#set_cell(Vector2(0,1), 2, Vector2i(0, 0))
	#set_cell(Vector2(1,0), 20, Vector2i(0, 0))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_changed() -> void:
	print("_on_changed")
	call_deferred("on_changed")
func on_changed() -> void:
	print("on_changed")
	update_internals()
	pass # Replace with function body.
