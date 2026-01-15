extends Node2D


@onready var NodeTree = {
	GameSceneLayer = $GameSceneLayer
	,MessageLayer = $MessageLayer
	,UILayer = $UILayer
	,Camera = $Camera2D
	,SceneStateMachine = $SceneStateMachine
	,DebuggerLayer = $DebuggerLayer
}


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SceneManager.init_manager()
	SceneManager.init_NodeTree(NodeTree)
	SceneManager.init_game_scene_camera($Camera2D)
	SceneManager.init_SceneStateMachine($SceneStateMachine)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	#print($SceneStateMachine._state)


func _on_logo_scene_state_entered() -> void:
	SceneManager.SwitchToGameScene(SceneManager.STATIC_Game_Scene_Names.LogoScene)
	$SceneStateMachine.send_event("ToStartMenuScene")
	


func _on_logo_scene_state_exited() -> void:
	pass # Replace with function body.


func _on_start_menu_scene_state_entered() -> void:
	SceneManager.SwitchToGameScene(SceneManager.STATIC_Game_Scene_Names.StartMenuScene)


func _on_start_menu_scene_state_exited() -> void:
	pass # Replace with function body.


func _on_new_game_scene_state_entered() -> void:
	SceneManager.SwitchToGameScene(SceneManager.STATIC_Game_Scene_Names.NewGameScene)


func _on_new_game_scene_state_exited() -> void:
	pass # Replace with function body.


func _on_load_game_scene_state_entered() -> void:
	SceneManager.SwitchToGameScene(SceneManager.STATIC_Game_Scene_Names.LoadGameScene)


func _on_load_game_scene_state_exited() -> void:
	pass # Replace with function body.


func _on_auto_game_scene_after_load_game_scene_state_entered() -> void:
	SceneManager.SwitchToGameScene(SceneManager.STATIC_Game_Scene_Names.AutoGameSceneAfterLoadGameScene)
	pass # Replace with function body.


func _on_auto_game_scene_after_load_game_scene_state_exited() -> void:
	pass # Replace with function body.


func _on_home_scene_state_entered() -> void:
	SceneManager.SwitchToGameScene(SceneManager.STATIC_Game_Scene_Names.HomeScene)


func _on_home_scene_state_exited() -> void:
	pass # Replace with function body.


func _on_before_battle_scene_state_entered() -> void:
	pass # Replace with function body.


func _on_before_battle_scene_state_exited() -> void:
	pass # Replace with function body.


func _on_battle_scene_state_entered() -> void:
	pass # Replace with function body.


func _on_battle_scene_state_exited() -> void:
	pass # Replace with function body.


func _on_after_battle_scene_state_entered() -> void:
	pass # Replace with function body.


func _on_after_battle_scene_state_exited() -> void:
	pass # Replace with function body.


func _on_before_adventure_scene_state_entered() -> void:
	pass # Replace with function body.


func _on_before_adventure_scene_state_exited() -> void:
	pass # Replace with function body.


func _on_adventure_scene_state_entered() -> void:
	pass # Replace with function body.


func _on_adventure_scene_state_exited() -> void:
	pass # Replace with function body.


func _on_after_adventure_scene_state_entered() -> void:
	pass # Replace with function body.


func _on_after_adventure_scene_state_exited() -> void:
	pass # Replace with function body.


func _on_game_pause_scene_state_entered() -> void:
	pass # Replace with function body.


func _on_game_pause_scene_state_exited() -> void:
	pass # Replace with function body.


func _on_game_pass_scene_state_entered() -> void:
	pass # Replace with function body.


func _on_game_pass_scene_state_exited() -> void:
	pass # Replace with function body.


func _on_cage_edit_scene_state_entered() -> void:
	SceneManager.SwitchToGameScene(SceneManager.STATIC_Game_Scene_Names.CageEditScene)


func _on_cage_edit_scene_state_exited() -> void:
	pass # Replace with function body.
