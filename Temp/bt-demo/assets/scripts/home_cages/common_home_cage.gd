extends BaseHomeCage


class_name CommonHomeCage


@export var cage_uid: CageManager.E_CageUID = CageManager.E_CageUID.Empty
@export var cage_entity_uid_in_edit_scene = -1


# ##############################################################################
# funcs
# ##############################################################################


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	super._process(delta)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)


# ##############################################################################
# funcs
# ##############################################################################

## 用于 item 被放入 pool 的时候清空/重置状态
func empty():
	super.empty()


func reactive():
	super.reactive()


func init_entity():
	super.init_entity()


func update_entity() -> void:
	super.update_entity()


# ##############################################################################
# cage funcs
# ##############################################################################


func _on_area_entered(area: Area2D) -> void:
	print("[%s] [UID:%s] _on_area_entered" % [Time.get_datetime_string_from_system(false, true), entity.UID])


func _input_event(viewport: Viewport, event: InputEvent, shape_idx: int) -> void:
	print("[%s] [UID:%s] _input_event" % [Time.get_datetime_string_from_system(false, true), entity.UID])
	if "handle_cage_input_event" in get_parent():
		var cage_input_event = CageInputEvent.new()
		get_parent().handle_cage_input_event(cage_input_event)


# ##############################################################################
# END
# ##############################################################################
