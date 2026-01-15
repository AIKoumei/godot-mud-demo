extends Node2D


class_name BaseScene


@export var UILayer: CanvasLayer


# ##############################################################################
# funcs
# ##############################################################################


func show_ui_layer():
	if not UILayer: return
	UILayer.visible = true


func hide_ui_layer():
	if not UILayer: return
	UILayer.visible = false


func on_scene_enter():
	show_ui_layer()


func on_scene_exit():
	hide_ui_layer()


# ##############################################################################
# END
# ##############################################################################
