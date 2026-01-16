## ---------------------------------------------------------
## PopupMessage 模块（ModInterface 版本）
##
## 功能说明：
## - 提供统一的弹窗消息接口（PopupMessage）
## - 支持多种弹窗位置（左上、左中、左下等9个位置）
## - 支持自定义消息内容和样式
## - 消息分层管理，避免UI重叠
## - 与 CanvasUILayer 模块配合使用
##
## 依赖：
## - ModInterface（基础接口）
## - CanvasUILayer（用于获取UI层节点）
##
## 调用方式（其他 Mod）：
## GameCore.mod_manager.call_mod("PopupMessage", "PopupMessage", "消息内容")
##
## ---------------------------------------------------------
extends ModInterface


## 生命周期：模块初始化
func _on_mod_init() -> void:
	super._on_mod_init()
	# 你可以在这里读取配置、初始化数据、注册事件等

## 生命周期：模块启用
func _on_mod_enable() -> void:
	super._on_mod_enable()
	# 入口场景已经实例化，可以开始逻辑

## 生命周期：模块禁用（未来支持）
func _on_mod_disable() -> void:
	super._on_mod_disable()
	# 清理 UI、暂停逻辑等

## 生命周期：模块卸载
func _on_mod_unload() -> void:
	super._on_mod_unload()
	# 清理资源、断开信号、保存数据等

## 生命周期：模块加载
func _on_mod_load() -> bool:
	var is_load_succeed = super._on_mod_load()
	# 子类实现
	return true

## 模块间通信
func _on_mod_event(_mod_name: String, event_name: String, event_data: Dictionary) -> void:
	super._on_mod_event(_mod_name, event_name, event_data)


# ---------------------------------------------------------
# 功能逻辑
# ---------------------------------------------------------


func _HandlePopupMessageEvent(event: PopupMessageEvent):
	#var message_scene = get_reusable_scene("CommonPopupMessageWindowScene")
	#message_scene.handle_message_event(event)
	#var layer = MessageLayer[STATIC_Popup_MSG_Position_To_Layer_Name[event.position_type]]
	#layer.add_child(message_scene)
	pass


#@onready var MessageLayer = {
	#"LeftTopLayer" = get_node("/root/MainScene/UICanvasLayer/UILayer/MessageLayer/LeftTopLayer")
	#,"LeftCenterLayer" = get_node("/root/MainScene/UICanvasLayer/UILayer/MessageLayer/LeftCenterLayer")
	#,"LeftBottomLayer" = get_node("/root/MainScene/UICanvasLayer/UILayer/MessageLayer/LeftBottomLayer")
	#,"CenterTopLayer" = get_node("/root/MainScene/UICanvasLayer/UILayer/MessageLayer/CenterTopLayer")
	#,"CenterCenterLayer" = get_node("/root/MainScene/UICanvasLayer/UILayer/MessageLayer/CenterCenterLayer")
	#,"CenterBottomLayer" = get_node("/root/MainScene/UICanvasLayer/UILayer/MessageLayer/CenterBottomLayer")
	#,"RightTopLayer" = get_node("/root/MainScene/UICanvasLayer/UILayer/MessageLayer/RightTopLayer")
	#,"RightCenterLayer" = get_node("/root/MainScene/UICanvasLayer/UILayer/MessageLayer/RightCenterLayer")
	#,"RightBottomLayer" = get_node("/root/MainScene/UICanvasLayer/UILayer/MessageLayer/RightBottomLayer")
#}

@export var MessageLayer = {}

func init_message_layer():
	#MessageLayer["LeftTopLayer"] = get_node("/root/MainScene/UILayer/MessageLayer/LeftTopLayer")
	#MessageLayer["LeftCenterLayer"] = get_node("/root/MainScene/UILayer/MessageLayer/LeftCenterLayer")
	#MessageLayer["LeftBottomLayer"] = get_node("/root/MainScene/UILayer/MessageLayer/LeftBottomLayer")
	#MessageLayer["CenterTopLayer"] = get_node("/root/MainScene/UILayer/MessageLayer/CenterTopLayer")
	#MessageLayer["CenterCenterLayer"] = get_node("/root/MainScene/UILayer/MessageLayer/CenterCenterLayer")
	#MessageLayer["CenterBottomLayer"] = get_node("/root/MainScene/UILayer/MessageLayer/CenterBottomLayer")
	#MessageLayer["RightTopLayer"] = get_node("/root/MainScene/UILayer/MessageLayer/RightTopLayer")
	#MessageLayer["RightCenterLayer"] = get_node("/root/MainScene/UILayer/MessageLayer/RightCenterLayer")
	#MessageLayer["RightBottomLayer"] = get_node("/root/MainScene/UILayer/MessageLayer/RightBottomLayer")
	pass
	#GameCore.mod_manager.call_mod("CanvasUILayer", "get_ui_layer_tips_window_layer")
	MessageLayer["LeftTopLayer"] = get_node("/root/MainScene/UILayer/MessageLayer/LeftTopLayer")
	MessageLayer["LeftCenterLayer"] = get_node("/root/MainScene/UILayer/MessageLayer/LeftCenterLayer")
	MessageLayer["LeftBottomLayer"] = get_node("/root/MainScene/UILayer/MessageLayer/LeftBottomLayer")
	MessageLayer["CenterTopLayer"] = get_node("/root/MainScene/UILayer/MessageLayer/CenterTopLayer")
	MessageLayer["CenterCenterLayer"] = get_node("/root/MainScene/UILayer/MessageLayer/CenterCenterLayer")
	MessageLayer["CenterBottomLayer"] = get_node("/root/MainScene/UILayer/MessageLayer/CenterBottomLayer")
	MessageLayer["RightTopLayer"] = get_node("/root/MainScene/UILayer/MessageLayer/RightTopLayer")
	MessageLayer["RightCenterLayer"] = get_node("/root/MainScene/UILayer/MessageLayer/RightCenterLayer")
	MessageLayer["RightBottomLayer"] = get_node("/root/MainScene/UILayer/MessageLayer/RightBottomLayer")
	

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

# ---------------------------------------------------------
# 外部访问
# ---------------------------------------------------------

func PopupMessage(message_text):
	#var event = PopupMessageEvent.new()
	#event.message_text = "Not ready"
	#event.position_type = event.STATIC_Position_Type.CenterTop
	#HandlePopupMessageEvent(event)
	pass
	
	
