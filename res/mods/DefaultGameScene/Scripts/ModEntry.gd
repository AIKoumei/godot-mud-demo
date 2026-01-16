## ---------------------------------------------------------
## DefaultGameScene 模块（ModInterface 版本）
##
## 功能说明：
## - 维护游戏场景配置（路径 + 类型）
## - SceneType 使用字符串，跨模块可访问：
##   - "WORLD"
##   - "UI_MAIN"
##   - "UI_OVERLAY"
## - 提供统一的场景切换接口（封装 SceneManager）
##
## ---------------------------------------------------------

extends ModInterface

# ---------------------------------------------------------
# 场景路径（Inspector 可视化）
# ---------------------------------------------------------
@export var GameWorldScene: String
@export var BattleScene: String

@export var StartMenuScene: String = "res://res/mods/DefaultGameScene/Scenes/UIScenes/StartMenuScene.tscn"
@export var PauseMenuScene: String
@export var GameOverScene: String

# ---------------------------------------------------------
# 内部场景表
# ---------------------------------------------------------
var _scene_table: Dictionary = {}


# ---------------------------------------------------------
# 生命周期：模块加载
# ---------------------------------------------------------
func _on_mod_load() -> bool:
	var ok := super._on_mod_load()

	_scene_table = {
		"GameWorld": {
			"path": GameWorldScene,
			"type": "WORLD"
		},
		"BattleScene": {
			"path": BattleScene,
			"type": "WORLD"
		},
		"StartMenu": {
			"path": StartMenuScene,
			"type": "UI_MAIN"
		},
		"PauseMenu": {
			"path": PauseMenuScene,
			"type": "UI_OVERLAY"
		},
		"GameOver": {
			"path": GameOverScene,
			"type": "UI_MAIN"
		}
	}

	return ok


# ---------------------------------------------------------
# 外部访问接口
# ---------------------------------------------------------
func get_scene_info(scene_name: String) -> Dictionary:
	return _scene_table.get(scene_name, {})


# ---------------------------------------------------------
# 对外场景切换接口（封装 SceneManager）
# ---------------------------------------------------------
func change_scene(scene_name: String, use_fade: bool = true) -> void:
	var info := get_scene_info(scene_name)
	if info.is_empty():
		push_error("[%s] change_scene: scene not found: %s" % [mod_name, scene_name])
		return

	GameCore.mod_manager.call_mod(
		"SceneManager",
		"change_scene",
		info.path,
		info.type,
		use_fade
	)


func push_scene(scene_name: String, use_fade: bool = true) -> void:
	var info := get_scene_info(scene_name)
	if info.is_empty():
		push_error("[%s] push_scene: scene not found: %s" % [mod_name, scene_name])
		return

	GameCore.mod_manager.call_mod(
		"SceneManager",
		"push_scene",
		info.path,
		info.type,
		use_fade
	)


func pop_scene(use_fade: bool = true) -> void:
	GameCore.mod_manager.call_mod("SceneManager", "pop_scene", use_fade)
