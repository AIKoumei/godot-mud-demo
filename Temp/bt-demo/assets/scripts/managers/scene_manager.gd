extends BaseManager

@export var cur_physics_process_delta = 0
@export var cur_process_delta = 0
func _process(delta: float) -> void:
	cur_process_delta = delta
func _physics_process(delta: float) -> void:
	is_camera_moved = false
	cur_physics_process_delta = delta


# ##############################################################################
# laod res
# ##############################################################################


var STATIC_RES = {
	"LogoScene" : preload("res://assets/scenes/game_scene/logo_scene.tscn")
	,"StartMenuScene" : preload("res://assets/scenes/game_scene/start_menu_scene.tscn")
	,"NewGameScene" : preload("res://assets/scenes/game_scene/new_game_scene.tscn")
	,"LoadGameScene" : preload("res://assets/scenes/game_scene/load_game_scene.tscn")
	,"AutoGameSceneAfterLoadGameScene" : preload("res://assets/scenes/game_scene/auto_game_scene_after_load_game_scene.tscn")
	,"HomeScene" : preload("res://assets/scenes/game_scene/home_scene/home_scene.tscn")
	,"BeforeBattleScene" : preload("res://assets/scenes/game_scene/before_battle_scene.tscn")
	,"BattleScene" : preload("res://assets/scenes/game_scene/battle_scene.tscn")
	,"AfterBattleScene" : preload("res://assets/scenes/game_scene/after_battle_scene.tscn")
	,"BeforeAdventureScene" : preload("res://assets/scenes/game_scene/before_adventure_scene.tscn")
	,"AdventureScene" : preload("res://assets/scenes/game_scene/adventure_scene.tscn")
	,"AfterAdventureScene" : preload("res://assets/scenes/game_scene/after_adventure_scene.tscn")
	,"GamePauseScene" : preload("res://assets/scenes/game_scene/game_pause_scene.tscn")
	,"GamePassScene" : preload("res://assets/scenes/game_scene/game_pass_scene.tscn")
	# home scene
	,"CageEditScene" : preload("res://assets/scenes/game_scene/home_scene/home_cage_edit_scene.tscn")
	# map objs
	,"MapObj_Food" : preload("res://assets/scenes/scene_items/map_obj_food.tscn")
	# windows
	,"CommonPopupMessageWindowScene" : preload("res://assets/scenes/message_scene/common_popup_message_window_scene.tscn")
}


var _manager_inited = false
func init_manager() -> void:
	if _manager_inited: return
	_manager_inited = true
	self.init_message_layer()


var NodeTree
func init_NodeTree(node_tree) -> void:
	NodeTree = node_tree


var SceneStateMachine: StateChart
func init_SceneStateMachine(sm) -> void:
	SceneStateMachine = sm

var STATIC_To_Game_Scene = {
	"StartMenuScene" = "ToStartMenuScene"
	,"NewGameScene" = "ToNewGameScene"
	,"LoadGameScene" = "ToLoadGameScene"
	,"AutoGameSceneAfterLoadGameScene" = "ToAutoGameSceneAfterLoadGameScene"
	,"HomeScene" = "ToHomeScene"
	,"BeforeBattleScene" = "ToBeforeBattleScene"
	,"BattleScene" = "ToBattleScene"
	,"AfterBattleScene" = "ToAfterBattleScene"
	,"BeforeAdventureScene" = "ToBeforeAdventureScene"
	,"AdventureScene" = "ToAdventureScene"
	,"AfterAdventureScene" = "ToAfterAdventureScene"
	,"GamePauseScene" = "ToGamePauseScene"
	,"GameOverScene" = "ToGameOverScene"
	,"GamePassScene" = "ToGamePassScene"
	#
	,"CageEditScene" = "ToCageEditScene"
}
func to_game_scene(scene_name):
	if not SceneStateMachine: return
	if not scene_name in STATIC_To_Game_Scene: return
	SceneStateMachine.send_event(STATIC_To_Game_Scene[scene_name])


# ##############################################################################
# camera funcs
# ##############################################################################


@export_category("camera")
@export var camera: Camera2D
@export var is_camera_moved = false

func init_game_scene_camera(_camera) -> void:
	camera = _camera
	camera_zoom = camera.get_zoom()
	camera_offset = camera.get_offset()


@export var camera_zoom: Vector2
@export var camera_zoom_step: Vector2 = Vector2(0.1,0.1)
@export var camera_zoom_min: Vector2 = Vector2(0.1,0.1)
@export var camera_zoom_max: Vector2 = Vector2(3,3)

func zoom_in_camera() -> void:
	if not camera_zoom:
		camera_zoom = camera.get_zoom()
	camera_zoom = camera_zoom + camera_zoom_step
	camera_zoom = Vector2(min(camera_zoom_max.x, camera_zoom.x), min(camera_zoom_max.y, camera_zoom.y))
	camera.set_zoom(camera_zoom)

func zoom_out_camera() -> void:
	if not camera_zoom:
		camera_zoom = camera.get_zoom()
	camera_zoom = camera_zoom - camera_zoom_step
	camera_zoom = Vector2(max(camera_zoom_min.x, camera_zoom.x), max(camera_zoom_min.y, camera_zoom.y))
	camera.set_zoom(camera_zoom)

@export var camera_offset: Vector2
@export var camera_move_step: Vector2 = Vector2(128, 128)

func move_camera(direction: Vector2) -> void:
	if is_camera_moved: return
	is_camera_moved = true
	#match direction:
		#GlobalEnv.E_Direction.UP:
			#camera.set_offset(camera_offset.lerp(Vector2(camera_offset.x, camera_offset.y - camera_move_step.y * 1/camera_zoom.x), 1.0 - exp(-cur_physics_process_delta * 10)))
		#GlobalEnv.E_Direction.DOWN:
			#camera.set_offset(camera_offset.lerp(Vector2(camera_offset.x, camera_offset.y + camera_move_step.y * 1/camera_zoom.x), 1.0 - exp(-cur_physics_process_delta * 10)))
		#GlobalEnv.E_Direction.LEFT:
			#camera.set_offset(camera_offset.lerp(Vector2(camera_offset.x - camera_move_step.x * 1/camera_zoom.x, camera_offset.y), 1.0 - exp(-cur_physics_process_delta * 10)))
		#GlobalEnv.E_Direction.RIGHT:
			#camera.set_offset(camera_offset.lerp(Vector2(camera_offset.x + camera_move_step.x * 1/camera_zoom.x, camera_offset.y), 1.0 - exp(-cur_physics_process_delta * 10)))
	camera.set_offset(camera_offset.lerp(Vector2(camera_offset.x + camera_move_step.x*1/camera_zoom.x*direction.x, camera_offset.y - camera_move_step.y*1/camera_zoom.y*direction.y), 1.0 - exp(-cur_physics_process_delta * 10)))
	camera_offset = camera.get_offset()

func move_up_camera() -> void:
	move_camera(Vector2.UP)

func move_down_camera() -> void:
	move_camera(Vector2.DOWN)

func move_left_camera() -> void:
	move_camera(Vector2.LEFT)

func move_right_camera() -> void:
	move_camera(Vector2.RIGHT)

func move_to_target(target: Node) -> void:
	pass


# ##############################################################################
# home scene funcs
# ##############################################################################


@export var home_scene_tool_action: HomeScene.E_ToolAction = HomeScene.E_ToolAction.Empty

func set_home_scene_tool_action(action: HomeScene.E_ToolAction):
	print("set_home_scene_tool_action ", action)
	home_scene_tool_action = action

func get_home_scene_tool_action():
	return home_scene_tool_action


# ##############################################################################
# game scene funcs
# ##############################################################################


var STATIC_Game_Scene_Names = {
	"LogoScene" : "LogoScene"
	,"StartMenuScene" : "StartMenuScene"
	,"NewGameScene" : "NewGameScene"
	,"LoadGameScene" : "LoadGameScene"
	,"AutoGameSceneAfterLoadGameScene" : "AutoGameSceneAfterLoadGameScene"
	,"HomeScene" : "HomeScene"
	,"BeforeBattleScene" : "BeforeBattleScene"
	,"BattleScene" : "BattleScene"
	,"AfterBattleScene" : "AfterBattleScene"
	,"BeforeAdventureScene" : "BeforeAdventureScene"
	,"AdventureScene" : "AdventureScene"
	,"AfterAdventureScene" : "AfterAdventureScene"
	,"GamePauseScene" : "GamePauseScene"
	,"GamePassScene" : "GamePassScene"
	#
	,"CageEditScene" : "CageEditScene"
}
var game_scene_cache = {}
var cur_game_scene
func SwitchToGameScene(scene_name):
	#
	camera.set_zoom(Vector2.ONE)
	#
	var scene_layer = NodeTree.GameSceneLayer
	for scene in game_scene_cache.values():
		NodeUtil.deactive_node(scene)
		NodeUtil.hide_node(scene)
	var scene
	if scene_name in game_scene_cache:
		scene = game_scene_cache[scene_name]
		NodeUtil.active_node(scene)
		NodeUtil.show_node(scene)
	else:
		scene = STATIC_RES[scene_name].instantiate()
	game_scene_cache[scene_name] = scene
	scene_layer.add_child(scene)
	if cur_game_scene and "on_scene_exit" in cur_game_scene:
		cur_game_scene.on_scene_exit()
	cur_game_scene = scene
	if cur_game_scene and "on_scene_enter" in cur_game_scene:
		cur_game_scene.on_scene_enter()
	return scene


# ##############################################################################
# reusable scene
# ##############################################################################


var STATIC_Reusable_Scene_To_Pool_Obj = {
	# map objs
	"MapObj_Food" : NodePoolManager.E_PoolObjType.MapObj_Food
	# windows
	,"CommonPopupMessageWindowScene" : NodePoolManager.E_PoolObjType.Scene_CommonPopupMessageWindowScene
}

func get_reusable_scene(scene_name):
	var scene = NodePoolManager.get_recyle_item(STATIC_Reusable_Scene_To_Pool_Obj[scene_name])
	if not scene:
		scene = STATIC_RES[scene_name].instantiate()
	else:
		NodeUtil.active_node(scene)
		NodeUtil.show_node(scene)
	return scene


# ##############################################################################
# message window
# ##############################################################################


@onready var MessageLayer = {
	"LeftTopLayer" = get_node("/root/MainScene/UICanvasLayer/UILayer/MessageLayer/LeftTopLayer")
	,"LeftCenterLayer" = get_node("/root/MainScene/UICanvasLayer/UILayer/MessageLayer/LeftCenterLayer")
	,"LeftBottomLayer" = get_node("/root/MainScene/UICanvasLayer/UILayer/MessageLayer/LeftBottomLayer")
	,"CenterTopLayer" = get_node("/root/MainScene/UICanvasLayer/UILayer/MessageLayer/CenterTopLayer")
	,"CenterCenterLayer" = get_node("/root/MainScene/UICanvasLayer/UILayer/MessageLayer/CenterCenterLayer")
	,"CenterBottomLayer" = get_node("/root/MainScene/UICanvasLayer/UILayer/MessageLayer/CenterBottomLayer")
	,"RightTopLayer" = get_node("/root/MainScene/UICanvasLayer/UILayer/MessageLayer/RightTopLayer")
	,"RightCenterLayer" = get_node("/root/MainScene/UICanvasLayer/UILayer/MessageLayer/RightCenterLayer")
	,"RightBottomLayer" = get_node("/root/MainScene/UICanvasLayer/UILayer/MessageLayer/RightBottomLayer")
}
func init_message_layer():
	pass
	#MessageLayer["LeftTopLayer"] = get_node("/root/MainScene/UILayer/MessageLayer/LeftTopLayer")
	#MessageLayer["LeftCenterLayer"] = get_node("/root/MainScene/UILayer/MessageLayer/LeftCenterLayer")
	#MessageLayer["LeftBottomLayer"] = get_node("/root/MainScene/UILayer/MessageLayer/LeftBottomLayer")
	#MessageLayer["CenterTopLayer"] = get_node("/root/MainScene/UILayer/MessageLayer/CenterTopLayer")
	#MessageLayer["CenterCenterLayer"] = get_node("/root/MainScene/UILayer/MessageLayer/CenterCenterLayer")
	#MessageLayer["CenterBottomLayer"] = get_node("/root/MainScene/UILayer/MessageLayer/CenterBottomLayer")
	#MessageLayer["RightTopLayer"] = get_node("/root/MainScene/UILayer/MessageLayer/RightTopLayer")
	#MessageLayer["RightCenterLayer"] = get_node("/root/MainScene/UILayer/MessageLayer/RightCenterLayer")
	#MessageLayer["RightBottomLayer"] = get_node("/root/MainScene/UILayer/MessageLayer/RightBottomLayer")
	

var STATIC_Popup_MSG_Position_To_Layer_Name = {
	PopupMessageEvent.STATIC_Position_Type.LeftTop : "LeftTopLayer"
	,PopupMessageEvent.STATIC_Position_Type.LeftCenter : "LeftCenterLayer"
	,PopupMessageEvent.STATIC_Position_Type.LeftBottom : "LeftBottomLayer"
	,PopupMessageEvent.STATIC_Position_Type.CenterTop : "CenterTopLayer"
	,PopupMessageEvent.STATIC_Position_Type.CenterCenter : "CenterCenterLayer"
	,PopupMessageEvent.STATIC_Position_Type.CenterBottom : "CenterBottomLayer"
	,PopupMessageEvent.STATIC_Position_Type.RightTop : "RightTopLayer"
	,PopupMessageEvent.STATIC_Position_Type.RightCenter : "RightCenterLayer"
	,PopupMessageEvent.STATIC_Position_Type.RightBottom : "RightBottomLayer"
}


func HandlePopupMessageEvent(event: PopupMessageEvent):
	var message_scene = get_reusable_scene("CommonPopupMessageWindowScene")
	message_scene.handle_message_event(event)
	var layer = MessageLayer[STATIC_Popup_MSG_Position_To_Layer_Name[event.position_type]]
	layer.add_child(message_scene)


# fast func
func PopupMessage(message_text):
	var event = PopupMessageEvent.new()
	event.message_text = "Not ready"
	event.position_type = event.STATIC_Position_Type.CenterTop
	HandlePopupMessageEvent(event)


# ##############################################################################
# cage scene
# ##############################################################################




# ##############################################################################
# END
# ##############################################################################
