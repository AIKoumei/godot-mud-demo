extends Node2D

@export var cell_size := 16

var town: SimplyMudTownGen.SimplyMudTownData = null

# ============================================================
# 图层开关
# ============================================================
var draw_layers := {
	"all": true,

	# NodeType 图层
	"center": true,
	"wall": true,
	"del_wall": true,
	"start_wall": true,
	"end_wall": true,
	"patch_wall": true,
	"main_road": true,
	"secondary_roads": true,
	"gate": true,
	"gate_wall": true,

	# 生成层
	"mask": true,
	"edge": true,
	"patched_edge": true,
	"blocks": true,
}

var items := {}

@onready var draw_options_root = $CanvasLayer/Control/DrawOptions/Container/VBoxContainer
@onready var draw_item_template = $CanvasLayer/Control/DrawOptions/CheckBtnItem
@onready var gen_button = $CanvasLayer/Control/MarginContainer/HBoxContainer/GenButton
@onready var config_info = $CanvasLayer/Control/MarginContainer/Control/Control/MarginContainer/TownConfigInfo


# ============================================================
# 初始化
# ============================================================
func _ready():
	_setup_draw_options()
	gen_button.connect("pressed", Callable(self, "_on_gen_pressed"))


# ============================================================
# 生成按钮
# ============================================================
func _on_gen_pressed():
	var cfg = SimplyMudTownGen.gen_config({
		"irregularity": 0.537380397319794,
		"seed": 1554892494,
		"shape_type": "RECT",
		"size_type": "LARGE",
		"smoothness": 0.170388698577881
	})
	config_info.text = JSON.stringify(cfg, "\t")

	town = SimplyMudTownGen.generate_town(cfg)
	queue_redraw()


# ============================================================
# 图层 UI 构建
# ============================================================
func _setup_draw_options():
	draw_item_template.visible = false

	for layer_name in draw_layers.keys():
		var item = draw_item_template.duplicate()
		item.visible = true
		draw_options_root.add_child(item)

		var check_btn = item.get_node("CheckButton")
		var only_box = item.get_node("OnlyDrawSelfBox")

		check_btn.text = layer_name
		check_btn.set_pressed(true)
		only_box.set_pressed(false)

		items[layer_name] = {
			"check": check_btn,
			"only": only_box
		}

		check_btn.connect("toggled", Callable(self, "_on_check_toggled").bind(layer_name))
		only_box.connect("toggled", Callable(self, "_on_only_toggled").bind(layer_name))


# ============================================================
# CheckButton：普通开关
# ============================================================
func _on_check_toggled(pressed: bool, layer_name: String):
	if layer_name == "all":
		for name in items.keys():
			items[name]["check"].set_pressed_no_signal(pressed)
			items[name]["only"].set_pressed_no_signal(false)
			draw_layers[name] = pressed
		queue_redraw()
		return

	items["all"]["only"].set_pressed_no_signal(false)

	if not pressed:
		items["all"]["check"].set_pressed_no_signal(false)
		draw_layers["all"] = false

	draw_layers[layer_name] = pressed
	queue_redraw()


# ============================================================
# OnlyDrawSelfBox：单选模式
# ============================================================
func _on_only_toggled(pressed: bool, layer_name: String):
	if not pressed:
		return

	if layer_name == "all":
		for name in items.keys():
			items[name]["check"].set_pressed_no_signal(true)
			items[name]["only"].set_pressed_no_signal(false)
			draw_layers[name] = true
		items["all"]["only"].set_pressed_no_signal(true)
		queue_redraw()
		return

	items[layer_name]["check"].set_pressed_no_signal(true)
	draw_layers[layer_name] = true

	for name in items.keys():
		if name == layer_name:
			continue
		items[name]["check"].set_pressed_no_signal(false)
		items[name]["only"].set_pressed_no_signal(false)
		draw_layers[name] = false

	items["all"]["check"].set_pressed_no_signal(false)
	items["all"]["only"].set_pressed_no_signal(false)
	draw_layers["all"] = false

	queue_redraw()


# ============================================================
# 绘制入口
# ============================================================
func _draw():
	if town == null:
		return

	# 生成层
	if draw_layers["mask"]:
		_draw_mask_layer(town.mask)

	if draw_layers["edge"]:
		_draw_mask_layer(town.edge)

	if draw_layers["patched_edge"]:
		_draw_mask_layer(town.patched_edge)

	if draw_layers["blocks"]:
		_draw_blocks_layer(town.blocks)

	# NodeType 层
	_draw_nodes()


# ============================================================
# 绘制 NodeType
# ============================================================
func _draw_nodes():
	for node in town.nodes.values():
		var t = node.type

		match t:
			SimplyMudTownGen.NodeType.CENTER:
				if draw_layers["center"]:
					_draw_node(node)

			SimplyMudTownGen.NodeType.WALL:
				if draw_layers["wall"]:
					_draw_node(node)

			SimplyMudTownGen.NodeType.DEL_WALL:
				if draw_layers["del_wall"]:
					_draw_node(node)

			SimplyMudTownGen.NodeType.START_WALL:
				if draw_layers["start_wall"]:
					_draw_node(node)

			SimplyMudTownGen.NodeType.END_WALL:
				if draw_layers["end_wall"]:
					_draw_node(node)

			SimplyMudTownGen.NodeType.PATCH_WALL:
				if draw_layers["patch_wall"]:
					_draw_node(node)

			SimplyMudTownGen.NodeType.MAIN_ROAD:
				if draw_layers["main_road"]:
					_draw_node(node)

			SimplyMudTownGen.NodeType.SECONDARY_ROADS:
				if draw_layers["secondary_roads"]:
					_draw_node(node)

			SimplyMudTownGen.NodeType.GATE:
				if draw_layers["gate"]:
					_draw_node(node)

			SimplyMudTownGen.NodeType.GATE_WALL:
				if draw_layers["gate_wall"]:
					_draw_node(node)


# ============================================================
# 绘制 mask/edge/patched_edge
# ============================================================
func _draw_mask_layer(dict: Dictionary):
	for pos in dict.keys():
		_draw_rect(pos, Color(0.4, 0.4, 0.4, 1.0), false, 1.0)


# ============================================================
# 绘制 blocks
# ============================================================
func _draw_blocks_layer(blocks):
	for rect in blocks:
		_draw_rect_rect(rect["x"], rect["y"], rect["w"], rect["h"], rect["color"])


# ============================================================
# 底层绘制函数（统一坐标转换）
# ============================================================
func _draw_node(node):
	var color = SimplyMudTownGen.NODE_COLOR[node.type]
	_draw_rect(node.pos, color, true)

func _draw_rect(pos: Vector2i, color: Color, filled := true, width := 1.0):
	var screen_pos = Vector2(
		(pos.x - town.center.x) * cell_size + get_viewport_rect().size.x/2,
		(pos.y - town.center.y) * cell_size + get_viewport_rect().size.y/2
	)
	draw_rect(Rect2(screen_pos, Vector2(cell_size, cell_size)), color, filled, width)

func _draw_rect_rect(x, y, w, h, color):
	var screen_pos = Vector2(
		(x - town.center.x) * cell_size + get_viewport_rect().size.x/2,
		(y - town.center.y) * cell_size + get_viewport_rect().size.y/2
	)
	draw_rect(Rect2(screen_pos, Vector2(w * cell_size, h * cell_size)), color, false, 2.0)
