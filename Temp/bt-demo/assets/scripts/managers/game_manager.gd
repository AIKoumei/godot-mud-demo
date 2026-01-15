extends BaseManager


var _manager_inited = false
#var node_trush = Node.new()
func _init() -> void:
	if _manager_inited: return
	_manager_inited = true
	#self.add_child(node_trush)
	#node_trush.name = "Trush"


# ##############################################################################
# game datas
# ##############################################################################


func save_game_data(game_slot: int):
	# TODO 保存游戏到 game slot
	var data = {}
	#
	for manager: BaseManager in manager_regist_dict.keys():
		manager.save_to_data(data)
	# save game data


func load_game_data(game_slot: int):
	# TODO 从 game slot 中加载游戏存档
	var data = {}
	#
	for manager: BaseManager in manager_regist_dict.keys():
		manager.load_from_data(data)


# ##############################################################################
# funcs
# ##############################################################################


func new_game():
	pass


var game_start_event: GameStartEvent
func SetGameStartEvent(event: GameStartEvent):
	game_start_event = event


func load_game(save_slot):
	pass


func exit_game():
	get_tree().quit()


# ##############################################################################
# message
# ##############################################################################


@onready var MessageLayer = $MessageLayer


func PopMessage(event: MessageEvent):
	if not MessageLayer:return
	if not event:return
	
	pass


# ##############################################################################
# ENDS
# ##############################################################################
