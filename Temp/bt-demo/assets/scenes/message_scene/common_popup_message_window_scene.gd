extends Control


class_name CommonPopupMessageWindowScene


@export var message_text = ""
@export var alive_time = 4
@export var position_type = MessageEvent.STATIC_Position_Type.RightTop




# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if alive_time <= 0: return
	alive_time -= delta
	if alive_time <= 0:
		NodePoolManager.drop_to_trush(self, SceneManager.STATIC_Reusable_Scene_To_Pool_Obj["CommonPopupMessageWindowScene"])


func handle_message_event(event: MessageEvent):
	#message_text = event.message_text
	self.alive_time = event.alive_time
	self.position_type = event.position_type
	match self.position_type:
		MessageEvent.STATIC_Position_Type.LeftTop:
			self.set_anchors_preset(Control.LayoutPreset.PRESET_TOP_LEFT, true)
		MessageEvent.STATIC_Position_Type.LeftCenter:
			self.set_anchors_preset(Control.LayoutPreset.PRESET_CENTER_LEFT, true)
		MessageEvent.STATIC_Position_Type.LeftBottom:
			self.set_anchors_preset(Control.LayoutPreset.PRESET_BOTTOM_LEFT, true)
		#
		MessageEvent.STATIC_Position_Type.CenterTop:
			self.set_anchors_preset(Control.LayoutPreset.PRESET_CENTER_TOP, true)
		MessageEvent.STATIC_Position_Type.CenterCenter:
			self.set_anchors_preset(Control.LayoutPreset.PRESET_CENTER, true)
		MessageEvent.STATIC_Position_Type.CenterBottom:
			self.set_anchors_preset(Control.LayoutPreset.PRESET_CENTER_BOTTOM, true)
		#
		MessageEvent.STATIC_Position_Type.RightTop:
			self.set_anchors_preset(Control.LayoutPreset.PRESET_TOP_RIGHT, true)
		MessageEvent.STATIC_Position_Type.RightCenter:
			self.set_anchors_preset(Control.LayoutPreset.PRESET_CENTER_RIGHT, true)
		MessageEvent.STATIC_Position_Type.RightBottom:
			self.set_anchors_preset(Control.LayoutPreset.PRESET_BOTTOM_RIGHT, true)
	self.set_message(event.message_text)


func set_message(_message_text):
	$PanelContainer/MarginContainer/TextEdit.text = _message_text if _message_text else message_text
	self.message_text = _message_text or message_text
