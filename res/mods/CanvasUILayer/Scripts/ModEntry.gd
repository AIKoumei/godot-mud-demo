## ---------------------------------------------------------
## CanvasUILayer 模块（ModInterface 版本）
##
## 功能说明：
## - 提供全局 CanvasLayer 节点管理
## - 分层管理 UI 元素（Bottom/Middle/Top/Tips 四层）
## - 提供 UI 场景挂载接口（按层挂载）
## - 提供 FadeRect（用于场景过渡）
##
## 依赖：
## - ModInterface（基础接口）
## - GameCore（用于添加 CanvasLayer 节点）
##
## 调用方式（其他 Mod）：
## GameCore.mod_manager.call_mod("CanvasUILayer", "get_ui_layer_top_window_layer")
## GameCore.mod_manager.call_mod("CanvasUILayer", "add_ui_to_top_layer", ui_scene)
## GameCore.mod_manager.call_mod("CanvasUILayer", "get_fade_rect")
##
## ---------------------------------------------------------

extends ModInterface

var scene_path_CanvasUILayer: String = "res://res/mods/CanvasUILayer/Scenes/UIScenes/CanvasUILayer.tscn"

@export var CanvasUILayer: CanvasLayer
@export var BottomWindowLayer: Control
@export var MiddleWindowLayer: Control
@export var TopWindowLayer: Control
@export var TipsWindowLayer: Control
@export var FadeRect: Control


# ---------------------------------------------------------
# 生命周期：模块加载
# ---------------------------------------------------------
func _on_mod_load() -> bool:
	var is_load_succeed: bool = super._on_mod_load()

	if not ResourceLoader.exists(scene_path_CanvasUILayer):
		push_warning("[%s] scene resource not found: %s" % [mod_name, scene_path_CanvasUILayer])
		return false

	var scene_res: PackedScene = load(scene_path_CanvasUILayer)
	var instance: Node = scene_res.instantiate()

	if instance is CanvasLayer:
		CanvasUILayer = instance as CanvasLayer
	else:
		push_error("[%s] Loaded scene is not a CanvasLayer: %s" % [mod_name, scene_path_CanvasUILayer])
		return false

	get_tree().root.get_node_or_null("Main").add_child(CanvasUILayer)

	BottomWindowLayer = CanvasUILayer.get_node_or_null("Control/BottomWindowLayer")
	MiddleWindowLayer = CanvasUILayer.get_node_or_null("Control/MiddleWindowLayer")
	TopWindowLayer = CanvasUILayer.get_node_or_null("Control/TopWindowLayer")
	TipsWindowLayer = CanvasUILayer.get_node_or_null("Control/TipsWindowLayer")
	FadeRect = CanvasUILayer.get_node_or_null("Control/TopWindowLayer/Fade/FadeRect")

	if BottomWindowLayer == null or MiddleWindowLayer == null or TopWindowLayer == null or TipsWindowLayer == null:
		push_warning("[%s] Some UI layers are missing in CanvasUILayer scene." % mod_name)

	if FadeRect == null:
		push_warning("[%s] FadeRect not found at path: Control/TopWindowLayer/Fade/FadeRect" % mod_name)

	return is_load_succeed


# ---------------------------------------------------------
# 生命周期：模块卸载
# ---------------------------------------------------------
func _on_mod_unload() -> void:
	super._on_mod_unload()

	if CanvasUILayer and CanvasUILayer.is_inside_tree():
		CanvasUILayer.queue_free()

	CanvasUILayer = null
	BottomWindowLayer = null
	MiddleWindowLayer = null
	TopWindowLayer = null
	TipsWindowLayer = null
	FadeRect = null


# ---------------------------------------------------------
# 外部访问接口：层级
# ---------------------------------------------------------
func get_ui_layer_bottom_window_layer() -> Control:
	return BottomWindowLayer

func get_ui_layer_middle_window_layer() -> Control:
	return MiddleWindowLayer

func get_ui_layer_top_window_layer() -> Control:
	return TopWindowLayer

func get_ui_layer_tips_window_layer() -> Control:
	return TipsWindowLayer

func get_fade_rect() -> Control:
	return FadeRect


# ---------------------------------------------------------
# 外部访问接口：挂载 UI 场景
# ---------------------------------------------------------
func add_ui_to_bottom_layer(node: Node) -> void:
	if BottomWindowLayer and node:
		BottomWindowLayer.add_child(node)


func add_ui_to_middle_layer(node: Node) -> void:
	if MiddleWindowLayer and node:
		MiddleWindowLayer.add_child(node)


func add_ui_to_top_layer(node: Node) -> void:
	if TopWindowLayer and node:
		TopWindowLayer.add_child(node)


func add_ui_to_tips_layer(node: Node) -> void:
	if TipsWindowLayer and node:
		TipsWindowLayer.add_child(node)
