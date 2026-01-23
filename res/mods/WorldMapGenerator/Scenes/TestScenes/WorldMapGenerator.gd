extends Node2D

# ============================================================
# WorldGenerator.gd（方案 A：无线程 + 分步动画）
# ============================================================

@export var cell_size: int = 4
@export var world_width: int = 256
@export var world_height: int = 180

var current_layer: String = "all"
var world: WorldData
var is_generating: bool = false

# UI 按钮
var btn_gen: Button
var btn_layer_all: Button
var btn_layer_height: Button
var btn_layer_temp: Button
var btn_layer_humidity: Button
var btn_layer_water: Button
var btn_layer_river: Button
var btn_layer_biome: Button
var btn_layer_region: Button


# ===========================
# 初始化
# ===========================
func _ready() -> void:
	btn_gen = $CanvasLayer/Control/HBoxContainer/GenButton
	btn_layer_all = $CanvasLayer/Control/HBoxContainer2/LayerAll
	btn_layer_height = $CanvasLayer/Control/HBoxContainer2/Layerheightmap
	btn_layer_temp = $CanvasLayer/Control/HBoxContainer2/Layertemperature
	btn_layer_humidity = $CanvasLayer/Control/HBoxContainer2/Layerhumidity
	btn_layer_water = $CanvasLayer/Control/HBoxContainer2/Layerwater_amount
	btn_layer_river = $CanvasLayer/Control/HBoxContainer2/Layerriver
	btn_layer_biome = $CanvasLayer/Control/HBoxContainer2/Layerbiome
	btn_layer_region = $CanvasLayer/Control/HBoxContainer2/Layerregion_id

	btn_gen.pressed.connect(_on_gen_pressed)
	btn_layer_all.pressed.connect(func() -> void: _switch_layer("all"))
	btn_layer_height.pressed.connect(func() -> void: _switch_layer("height"))
	btn_layer_temp.pressed.connect(func() -> void: _switch_layer("temperature"))
	btn_layer_humidity.pressed.connect(func() -> void: _switch_layer("humidity"))
	btn_layer_water.pressed.connect(func() -> void: _switch_layer("water"))
	btn_layer_river.pressed.connect(func() -> void: _switch_layer("river"))
	btn_layer_biome.pressed.connect(func() -> void: _switch_layer("biome"))
	btn_layer_region.pressed.connect(func() -> void: _switch_layer("region"))

	_start_generate_sequence()


# ===========================
# 按钮事件
# ===========================
func _on_gen_pressed() -> void:
	_start_generate_sequence()


func _switch_layer(layer: String) -> void:
	if current_layer == layer:
		current_layer = "all"
	else:
		current_layer = layer

	queue_redraw()



# ===========================
# 主线程协程：分步生成世界（不卡 UI）
# ===========================
func _start_generate_sequence() -> void:
	if is_generating:
		return
	is_generating = true
	_generate_sequence_async()


@warning_ignore("unused_parameter")
func _generate_sequence_async() -> void:
	await _run_worldgen_steps()
	is_generating = false
	current_layer = "all"
	queue_redraw()


func _run_worldgen_steps() -> void:
	var steps: Array = WorldGen.generate_world_steps(world_width, world_height, randi())

	for step_callable in steps:
		var callable_step: Callable = step_callable
		var result: Dictionary = callable_step.call()
		var step_name: String = result["step"]
		var data: WorldData = result["world"]

		world = data

		match step_name:
			"continent":
				current_layer = "height"
			"height":
				current_layer = "height"
			"climate":
				current_layer = "temperature"
			"thermal":
				current_layer = "height"
			"hydraulic":
				current_layer = "water"
			"wind":
				current_layer = "height"
			"river":
				current_layer = "river"
			"biome":
				current_layer = "biome"
			"region":
				current_layer = "region"
			_:
				current_layer = "all"

		queue_redraw()

		# 动画节奏（主线程安全）
		await get_tree().create_timer(0.03).timeout


# ===========================
# 绘制
# ===========================
func _draw() -> void:
	if world == null:
		return

	match current_layer:
		"all":
			_draw_biome()
			_draw_river()
		"height":
			_draw_height()
		"temperature":
			_draw_temperature()
		"humidity":
			_draw_humidity()
		"water":
			_draw_water()
		"river":
			_draw_river()
		"biome":
			_draw_biome()
		"region":
			_draw_region()
		_:
			_draw_biome()


# ===========================
# 各层绘制函数
# ===========================
func _draw_height() -> void:
	for x: int in range(world.width):
		for y: int in range(world.height):
			var h: float = world.heightmap[x][y]
			_draw_cell(x, y, Color(h, h, h))


func _draw_temperature() -> void:
	for x: int in range(world.width):
		for y: int in range(world.height):
			var t: float = world.temperature[x][y]
			_draw_cell(x, y, Color(t, 0.0, 1.0 - t))


func _draw_humidity() -> void:
	for x: int in range(world.width):
		for y: int in range(world.height):
			var h: float = world.humidity[x][y]
			_draw_cell(x, y, Color(0.0, h, 0.0))


func _draw_water() -> void:
	for x: int in range(world.width):
		for y: int in range(world.height):
			var w: float = world.water_amount[x][y]
			var b: float = min(w * 5.0, 1.0)
			_draw_cell(x, y, Color(0.0, 0.0, b))


func _draw_river() -> void:
	for x: int in range(world.width):
		for y: int in range(world.height):
			if world.river[x][y]:
				_draw_cell(x, y, Color(0.0, 0.2, 1.0))


func _draw_biome() -> void:
	for x: int in range(world.width):
		for y: int in range(world.height):
			var biome: String = world.biome[x][y]
			_draw_cell(x, y, _biome_color(biome))


func _draw_region() -> void:
	for x: int in range(world.width):
		for y: int in range(world.height):
			var id: int = world.region_id[x][y]
			if id >= 0:
				var c: Color = Color.from_hsv(float(id % 20) / 20.0, 0.6, 0.9)
				_draw_cell(x, y, c)


func _draw_cell(x: int, y: int, c: Color) -> void:
	var pos: Vector2 = Vector2(x * cell_size, y * cell_size)
	var rect: Rect2 = Rect2(pos, Vector2(cell_size, cell_size))
	draw_rect(rect, c, true)


func _biome_color(b: String) -> Color:
	match b:
		"ocean_deep":
			return Color(0.0, 0.0, 0.3)
		"ocean_shallow":
			return Color(0.0, 0.4, 0.7)
		"coast":
			return Color(0.9, 0.85, 0.6)
		"forest":
			return Color(0.0, 0.5, 0.0)
		"woodland":
			return Color(0.3, 0.6, 0.3)
		"grassland":
			return Color(0.6, 0.8, 0.4)
		"desert":
			return Color(0.9, 0.8, 0.4)
		"swamp":
			return Color(0.2, 0.3, 0.1)
		"jungle":
			return Color(0.0, 0.6, 0.2)
		"mountain":
			return Color(0.5, 0.5, 0.5)
		"snow_mountain":
			return Color(0.95, 0.95, 1.0)
		"river":
			return Color(0.0, 0.2, 1.0)
		_:
			return Color(1.0, 0.0, 1.0)
