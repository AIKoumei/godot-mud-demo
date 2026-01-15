extends BaseEvent


class_name GameStartEvent


# ##############################################################################
# funcs
# ##############################################################################

enum E_GameStartType {
	NewGame
	,LoadGame
	,PassGame
}

@export var game_start_type = E_GameStartType.NewGame
@export var load_slot = 0
@export var pass_times = 0


# ##############################################################################
# END
# ##############################################################################
