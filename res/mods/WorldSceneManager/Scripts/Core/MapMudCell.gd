extends Node2D
class_name MapMudCell

@onready var InfoLayer: Node2D = $InfoLayer
@onready var MapUnit: Node2D = $MapUnit
@onready var UnitIcon: Sprite2D = $MapUnit/Icon

@onready var MapTag: Node2D = $MapTag
@onready var TagIcon: Sprite2D = $MapTag/Icon


# ---------------------------------------------------------
# 设置 entity 图标
# ---------------------------------------------------------
func set_entity_icon(path: String) -> void:
	if ResourceLoader.exists(path):
		var tex := ResourceLoader.load(path)
		if tex is Texture2D:
			UnitIcon.texture = tex
	else:
		push_warning("[MapMudCell] entity icon not found: %s" % path)


# ---------------------------------------------------------
# 设置 flag 图标
# ---------------------------------------------------------
func set_flag_icon(path: String, offset: Vector2) -> void:
	if ResourceLoader.exists(path):
		var tex := ResourceLoader.load(path)
		if tex is Texture2D:
			TagIcon.texture = tex
			TagIcon.position = offset
	else:
		push_warning("[MapMudCell] flag icon not found: %s" % path)
