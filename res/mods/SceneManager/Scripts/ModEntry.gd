## ---------------------------------------------------------
## SceneManager 模块（ModInterface 版本）
##
## 功能说明：
## - 负责场景切换（不关心场景名）
## - 只接收 path + type（字符串）
## - SceneType 字符串：
##   - "WORLD"
##   - "UI_MAIN"
##   - "UI_OVERLAY"
## - UI_MAIN 挂载到 CanvasUILayer（Middle）
## - UI_OVERLAY 挂载到 CanvasUILayer（Top）
## - WORLD 挂载到 GameSceneLayer
##
## ---------------------------------------------------------

extends ModInterface

@export var default_use_fade: bool = true
@export var fade_time: float = 0.35

var _current_main_scene: Node = null
var _ui_overlay_stack: Array[Node] = []


# ---------------------------------------------------------
# FadeRect 获取
# ---------------------------------------------------------
func _get_fade_rect() -> Control:
	var fade_rect: Control = GameCore.mod_manager.call_mod("CanvasUILayer", "get_fade_rect")
	return fade_rect


# ---------------------------------------------------------
# Fade 动画
# ---------------------------------------------------------
func _fade_out() -> void:
	var fade_rect := _get_fade_rect()
	if fade_rect == null:
		return

	fade_rect.visible = true
	fade_rect.modulate.a = 0.0

	var tween := create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, fade_time)
	await tween.finished


func _fade_in() -> void:
	var fade_rect := _get_fade_rect()
	if fade_rect == null:
		return

	fade_rect.visible = true
	fade_rect.modulate.a = 1.0

	var tween := create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, fade_time)
	await tween.finished

	fade_rect.visible = false


# ---------------------------------------------------------
# 内部：加载 WORLD 场景
# ---------------------------------------------------------
func _load_world_scene(path: String) -> void:
	var scene_res: PackedScene = load(path)
	if scene_res == null:
		push_error("[SceneManager] Failed to load WORLD scene: %s" % path)
		return

	if _current_main_scene and _current_main_scene.is_inside_tree():
		_current_main_scene.queue_free()

	var new_scene: Node = scene_res.instantiate()
	_current_main_scene = new_scene
	GameCore.get_game_scene_layer().add_child(new_scene)


# ---------------------------------------------------------
# 内部：加载 UI_MAIN 场景
# ---------------------------------------------------------
func _load_ui_main_scene(path: String) -> void:
	var scene_res: PackedScene = load(path)
	if scene_res == null:
		push_error("[SceneManager] Failed to load UI_MAIN scene: %s" % path)
		return

	# 清理旧主场景
	if _current_main_scene and _current_main_scene.is_inside_tree():
		_current_main_scene.queue_free()

	# 清理所有 UI_OVERLAY
	for ui in _ui_overlay_stack:
		if ui and ui.is_inside_tree():
			ui.queue_free()
	_ui_overlay_stack.clear()

	var ui_scene: Node = scene_res.instantiate()

	var layer: Control = GameCore.mod_manager.call_mod("CanvasUILayer", "get_ui_layer_middle_window_layer")
	layer.add_child(ui_scene)

	_current_main_scene = ui_scene


# ---------------------------------------------------------
# 内部：加载 UI_OVERLAY 场景
# ---------------------------------------------------------
func _load_ui_overlay_scene(path: String) -> void:
	var scene_res: PackedScene = load(path)
	if scene_res == null:
		push_error("[SceneManager] Failed to load UI_OVERLAY scene: %s" % path)
		return

	var ui_scene: Node = scene_res.instantiate()
	_ui_overlay_stack.append(ui_scene)

	var top_layer: Control = GameCore.mod_manager.call_mod("CanvasUILayer", "get_ui_layer_top_window_layer")
	top_layer.add_child(ui_scene)


# ---------------------------------------------------------
# 对外：切换场景（path + type）
# ---------------------------------------------------------
func change_scene(path: String, type: String, use_fade: bool = default_use_fade) -> void:
	if use_fade:
		await _fade_out()

	match type:
		"WORLD":
			_load_world_scene(path)

		"UI_MAIN":
			_load_ui_main_scene(path)

		"UI_OVERLAY":
			_load_ui_overlay_scene(path)

		_:
			push_warning("[SceneManager] Unknown SceneType: %s" % type)

	if use_fade:
		await _fade_in()


# ---------------------------------------------------------
# 对外：push UI_OVERLAY
# ---------------------------------------------------------
func push_scene(path: String, type: String, use_fade: bool = default_use_fade) -> void:
	if type != "UI_OVERLAY":
		push_warning("[SceneManager] push_scene: only UI_OVERLAY can be pushed")
		return

	if use_fade:
		await _fade_out()

	_load_ui_overlay_scene(path)

	if use_fade:
		await _fade_in()


# ---------------------------------------------------------
# 对外：pop UI_OVERLAY
# ---------------------------------------------------------
func pop_scene(use_fade: bool = default_use_fade) -> void:
	if _ui_overlay_stack.is_empty():
		push_warning("[SceneManager] pop_scene: stack empty")
		return

	if use_fade:
		await _fade_out()

	var ui_scene: Node = _ui_overlay_stack.pop_back()
	if ui_scene and ui_scene.is_inside_tree():
		ui_scene.queue_free()

	if use_fade:
		await _fade_in()
