extends Node


class_name MessageEvent


enum STATIC_Position_Type {
	LeftTop
	,LeftCenter
	,LeftBottom
	,CenterTop
	,CenterCenter
	,CenterBottom
	,RightTop
	,RightCenter
	,RightBottom
}

@export var message_text: String = ""
@export var alive_time: float = 2.0
@export var position_type: STATIC_Position_Type = STATIC_Position_Type.CenterTop
