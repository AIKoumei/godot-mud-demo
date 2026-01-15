extends BaseEvent


class_name BaseMapObjEvent


# ##############################################################################
# funcs
# ##############################################################################

enum E_ObjType {
	Poop
	,Food
	,Medicine
	,Cake
}

@export var event_inited = false
@export var obj_type = E_ObjType.Poop
@export var entity_uid = -1


func ready():
	event_inited = true


func is_ready():
	return event_inited


# ##############################################################################
# END
# ##############################################################################
