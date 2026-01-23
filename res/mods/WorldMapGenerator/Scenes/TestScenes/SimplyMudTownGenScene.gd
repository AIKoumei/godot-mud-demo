extends Node2D

@export var cell_size: int = 8

var nodes: Dictionary = {}
var render_offset: Vector2 = Vector2.ZERO

# 按你给的场景结构精确定位节点
@onready var gen_button: Button = $CanvasLayer/Control/MarginContainer/HBoxContainer/GenButton
@onready var town_info: TextEdit = $CanvasLayer/Control/MarginContainer/Control/Control/MarginContainer/TownConfigInfo


func _ready() -> void:
	gen_button.pressed.connect(_on_gen_pressed)
	_generate_and_render()


func _on_gen_pressed() -> void:
	_generate_and_render()


func _generate_and_render() -> void:
	#var cfg = SimplyMudTownGen.gen_config({
		#"seed" = 1671011281,
		#"size_type" = "LARGE",
		#"shape_type" = "CIRCLE",
		#"irregularity" = 0.56,
		#"smoothness" = 0.33,
	#})
	var cfg = SimplyMudTownGen.gen_config()

	nodes = SimplyMudTownGen.generate_town(cfg)
	if nodes.is_empty():
		return

	_update_config_info(cfg)

	# 让 center 居中渲染
	var center_node = nodes[0]
	var cx = center_node.pos.x
	var cy = center_node.pos.y

	var center_render_pos = Vector2(cx * cell_size, cy * cell_size)
	var screen_center = get_viewport_rect().size / 2.0
	render_offset = center_render_pos - screen_center

	queue_redraw()


func _update_config_info(cfg: Dictionary) -> void:
	var text = ""
	text += "Seed: %s\n" % cfg["seed"]
	text += "Size Type: %s\n" % cfg["size_type"]
	text += "Shape: %s\n" % cfg["shape_type"]
	text += "Irregularity: %.2f\n" % cfg["irregularity"]
	text += "Smoothness: %.2f\n" % cfg["smoothness"]

	town_info.text = text


func _draw() -> void:
	if nodes.is_empty():
		return

	# 画所有节点
	for n in nodes.values():
		var pos = n.pos
		var screen_pos = Vector2(pos.x * cell_size, pos.y * cell_size) - render_offset

		var color = SimplyMudTownGen.NODE_COLOR.get(n.type, Color.WHITE)
		draw_rect(Rect2(screen_pos, Vector2(cell_size, cell_size)), color)
