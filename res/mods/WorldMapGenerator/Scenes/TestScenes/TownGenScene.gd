extends Node2D

# ============================================================
# TownGenScene.gd
# - 连接 TownGenScene.tscn
# - 按钮切换显示层（再次点击同层 → 切回 LayerAll）
# - 调用 TownGen.generate_town()
# - 渲染各个生成层
# ============================================================

@export var cell_size: int = 6
@export var town_width: int = 120
@export var town_height: int = 80

var current_layer: String = "LayerAll"
var town: TownData


# 按钮引用
var btn_gen: Button
var btn_all: Button
var btn_shape: Button
var btn_wall: Button
var btn_poi: Button
var btn_road: Button
var btn_district: Button
var btn_lot: Button


func _ready() -> void:
	# 连接 UI
	btn_gen = $CanvasLayer/Control/HBoxContainer/GenButton
	btn_all = $CanvasLayer/Control/HBoxContainer2/LayerAll
	btn_shape = $CanvasLayer/Control/HBoxContainer2/LayerShape
	btn_wall = $CanvasLayer/Control/HBoxContainer2/LayerWall
	btn_poi = $CanvasLayer/Control/HBoxContainer2/LayerPOI
	btn_road = $CanvasLayer/Control/HBoxContainer2/LayerRoad
	btn_district = $CanvasLayer/Control/HBoxContainer2/LayerDistrict
	btn_lot = $CanvasLayer/Control/HBoxContainer2/LayerLot

	# 绑定按钮事件
	btn_gen.pressed.connect(_on_gen_pressed)
	btn_all.pressed.connect(func(): _switch_layer("LayerAll"))
	btn_shape.pressed.connect(func(): _switch_layer("LayerShape"))
	btn_wall.pressed.connect(func(): _switch_layer("LayerWall"))
	btn_poi.pressed.connect(func(): _switch_layer("LayerPOI"))
	btn_road.pressed.connect(func(): _switch_layer("LayerRoad"))
	btn_district.pressed.connect(func(): _switch_layer("LayerDistrict"))
	btn_lot.pressed.connect(func(): _switch_layer("LayerLot"))

	_generate_town()


# ============================================================
# 生成城镇
# ============================================================
func _on_gen_pressed() -> void:
	_generate_town()


var _is_first_draw = false
func _generate_town() -> void:
	town = TownGen.generate_town(town_width, town_height, randi())
	_is_first_draw = true
	queue_redraw()


# ============================================================
# 切换显示层（再次点击同层 → 切回 LayerAll）
# ============================================================
func _switch_layer(layer: String) -> void:
	if current_layer == layer:
		current_layer = "LayerAll"
	else:
		current_layer = layer
	queue_redraw()


# ============================================================
# 渲染
# ============================================================
func _draw() -> void:
	if town == null:
		return
		
	if _is_first_draw:
		_draw_shape()
		await get_tree().create_timer(1).timeout
		_draw_wall()
		await get_tree().create_timer(1).timeout
		_draw_road()
		await get_tree().create_timer(1).timeout
		_draw_poi()
		await get_tree().create_timer(1).timeout
		_draw_district()
		await get_tree().create_timer(1).timeout
		_draw_lot()
		_is_first_draw = false
		return

	match current_layer:
		"LayerAll":
			_draw_shape()
			_draw_wall()
			_draw_road()
			_draw_poi()
			_draw_district()
			_draw_lot()

		"LayerShape":
			_draw_shape()

		"LayerWall":
			_draw_wall()

		"LayerPOI":
			_draw_poi()

		"LayerRoad":
			_draw_road()

		"LayerDistrict":
			_draw_district()

		"LayerLot":
			_draw_lot()


# ============================================================
# 各层绘制函数（目前基础版）
# ============================================================

# 1. 城镇轮廓（inside / outside）
func _draw_shape() -> void:
	for x in range(town.width):
		for y in range(town.height):
			var t = town.cell_type[x][y]
			if t == "inside":
				_draw_cell(x, y, Color(0.8, 0.8, 0.8))
			elif t == "outside":
				_draw_cell(x, y, Color(0.2, 0.2, 0.2))


# 2. 城墙
func _draw_wall() -> void:
	for x in range(town.width):
		for y in range(town.height):
			if town.cell_type[x][y] == "wall":
				_draw_cell(x, y, Color(0.4, 0.2, 0.1))


# 3. POI（未来实现）
func _draw_poi() -> void:
	# 未来会画城门、广场等
	pass


# 4. 主干道（未来实现）
func _draw_road() -> void:
	# 未来会画道路
	pass


# 5. 功能分区（未来实现）
func _draw_district() -> void:
	# 未来会画不同区块
	pass


# 6. 建筑地块（未来实现）
func _draw_lot() -> void:
	# 未来会画建筑地块
	pass


# ============================================================
# 工具函数：画单格
# ============================================================
func _draw_cell(x: int, y: int, c: Color) -> void:
	var pos = Vector2(x * cell_size, y * cell_size)
	draw_rect(Rect2(pos, Vector2(cell_size, cell_size)), c, true)


func push_message(msg:String):
	$CanvasLayer/Control/Control/TownInfo.text = $CanvasLayer/Control/Control/TownInfo.text + "\n" + msg
