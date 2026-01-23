## 游戏核心脚本
## 负责游戏初始化、主循环、资源加载
extends Node

# 版本信息
const VERSION = "v.0.0.1"


# 当前游戏状态
var mod_manager = ModManager.new()
@export var SceneStateMachine = null

var ArrayTools = _ArrayTools.new()


## 初始化游戏核心
func _ready():
	print("GameCore initialized, version: %s" % VERSION)
	_initialize_game()

## 游戏主循环
func _process(delta: float) -> void:
	pass

## 初始化游戏
func _initialize_game() -> void:
	print("Initializing game...")
	# 初始化配置
	# 初始化管理器
	# 初始化 SceneStateMachine
	SceneStateMachine = get_tree().get_root().get_node_or_null("Main/SceneStateMachine")
	if SceneStateMachine == null:
		push_error("SceneStateMachine not found!")
		return
	
	SceneStateMachine.get_node("SceneControlState/LogoScene").state_entered.connect(_on_logo_scene_state_entered)
	SceneStateMachine.get_node("SceneControlState/InitiateGameScene").state_entered.connect(_on_initiate_game_scene_state_entered)
	SceneStateMachine.get_node("SceneControlState/LoadingGameScene").state_entered.connect(_on_loading_game_scene_state_entered)
	SceneStateMachine.get_node("SceneControlState/StartMenuScene").state_entered.connect(_on_start_menu_scene_state_entered)

## 加载资源
func _load_resources() -> void:
	print("Loading resources...")
	# 加载游戏资源
	# 加载完成后设置游戏状态为运行中

## 更新游戏
func _update_game(delta: float) -> void:
	# 游戏主逻辑更新
	pass

## 更新暂停状态
func _update_paused(delta: float) -> void:
	# 暂停状态更新
	pass

## 关闭游戏
func _shutdown_game() -> void:
	print("Shutting down game...")
	# 清理资源
	# 保存游戏状态
	get_tree().quit()


# ---------------------------------------------------------
# 获取 layer
# ---------------------------------------------------------
func get_mods_layer() -> Node:
	return get_tree().get_root().get_node("Main/ModsLayer")


func get_game_scene_layer() -> Node:
	return get_tree().get_root().get_node("Main/GameSceneLayer")


func get_pause_scene_layer() -> Node:
	return get_tree().get_root().get_node("Main/PauseSceneLayer")


func get_main_layer() -> Node:
	return get_tree().get_root().get_node("Main")


func get_UI_layer() -> Node:
	return get_tree().get_root().get_node("Main/CanvasLayer")


# ---------------------------------------------------------
# state machine
# ---------------------------------------------------------


func _on_logo_scene_state_entered() -> void:
	pass # Replace with function body.
	print("Play Game Logo...")
	SceneStateMachine.send_event("ToInitiateGameScene")


func _on_initiate_game_scene_state_entered() -> void:
	print("Initiate Game...")
	_load_resources()
	mod_manager.load_all_mods()
	SceneStateMachine.send_event("ToLoadingGameScene")


func _on_loading_game_scene_state_entered() -> void:
	print("Loading Game...")
	SceneStateMachine.send_event("ToStartMenuScene")


func _on_start_menu_scene_state_entered() -> void:
	print("Game Menu...")
	GameCore.mod_manager.call_mod("DefaultGameScene", "change_scene", "StartMenu")
