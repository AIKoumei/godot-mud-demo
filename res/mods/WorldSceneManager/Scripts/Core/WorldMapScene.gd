extends Node2D
class_name WorldMapScene

# ---------------------------------------------------------
# 节点引用
# ---------------------------------------------------------
@onready var PathLayer: TileMapLayer = $MapLayer/PathLayer
@onready var GroundLayer: TileMapLayer = $MapLayer/GroundLayer
@onready var MapCellLayer: Node2D = $MapLayer/MapCellLayer

# 用 GroundLayer 作为 tilemap（用于 map_to_local）
@onready var tilemap: TileMapLayer = GroundLayer

# MapMudCell 场景（运行时加载）
var MudCellScene: PackedScene = null

# 存储 pos -> MapMudCell
var _cells: Dictionary = {}

# mod 根路径（用于加载图标）
var mod_root_path: String = ""


# ---------------------------------------------------------
# 生命周期
# ---------------------------------------------------------
func _ready() -> void:
	_load_mud_cell_scene()


# ---------------------------------------------------------
# 加载 MapMudCell.tscn（避免 preload 崩溃）
# ---------------------------------------------------------
func _load_mud_cell_scene() -> void:
	var path := "res://res/mods/WorldSceneManager/Scenes/GameScenes/MapMudCell.tscn"


	if not ResourceLoader.exists(path):
		push_error("[WorldMapScene] MapMudCell.tscn not found: %s" % path)
		return

	var res := ResourceLoader.load(path)
	if res is PackedScene:
		MudCellScene = res
	else:
		push_error("[WorldMapScene] Failed to load MapMudCell.tscn: %s" % path)


# ---------------------------------------------------------
# 设置 mod 根目录
# ---------------------------------------------------------
func set_mod_root(path: String) -> void:
	mod_root_path = path


# ---------------------------------------------------------
# 渲染入口
# ---------------------------------------------------------
func render_from_instance(location_id: String) -> void:
	var map_data_raw: Variant = GameCore.mod_manager.call_mod(
		"WorldMapInstanceManager",
		"get_map_data",
		location_id
	)

	if map_data_raw is Array:
		var map_data: Array = map_data_raw
		_clear_all()
		_render_path_and_ground(map_data)
		_render_info_cells(map_data)


# ---------------------------------------------------------
# 渲染 path + ground
# ---------------------------------------------------------
func _render_path_and_ground(map_data: Array) -> void:
	PathLayer.clear()
	#GroundLayer.clear()

	for cell_raw: Variant in map_data:
		if not (cell_raw is Dictionary):
			continue

		var cell: Dictionary = cell_raw
		var pos := Vector2i(cell.get("x", 0), cell.get("y", 0))

		# ground
		var tile_type := String(cell.get("tile", ""))
		var ground_id := _get_ground_tile_id(tile_type)
		if ground_id != -1:
			GroundLayer.set_cell(pos, ground_id)

		# path
		if cell.has("path"):
			var path_info: Dictionary = cell["path"]
			var path_id := _get_path_tile_id(path_info)
			if path_id != -1:
				PathLayer.set_cell(pos, path_id)
	
	print(GroundLayer.tile_set.get_source_count())
	GroundLayer.set_cell(Vector2i(0,1), 241, Vector2i.ZERO)
	GroundLayer.set_cell(Vector2i(1,1), 241)


func _get_ground_tile_id(tile_type: String) -> int:
	match tile_type:
		"water": return 0
		"deep_water": return 1
		"sand": return 2
		"lava": return 3
		"volcano_road": return 4
		"grass": return 5
		_: return -1


func _get_path_tile_id(path_info: Dictionary) -> int:
	var dir := String(path_info.get("dir", ""))
	match dir:
		"N": return 0
		"S": return 1
		"E": return 2
		"W": return 3
		_: return -1


# ---------------------------------------------------------
# 渲染 info 层（MapMudCell）
# ---------------------------------------------------------
func _render_info_cells(map_data: Array) -> void:
	if MudCellScene == null:
		push_error("[WorldMapScene] MudCellScene is null, cannot instantiate.")
		return

	for cell_raw: Variant in map_data:
		if not (cell_raw is Dictionary):
			continue

		var cell: Dictionary = cell_raw

		if not (cell.has("entity") or cell.has("flag")):
			continue

		var pos := Vector2i(cell.get("x", 0), cell.get("y", 0))

		# 实例化 MapMudCell.tscn
		var mud_cell: MapMudCell = MudCellScene.instantiate()
		mud_cell.position = tilemap.map_to_local(pos)

		if cell.has("entity"):
			_render_entity(mud_cell, cell["entity"])

		if cell.has("flag"):
			_render_flag(mud_cell, cell["flag"], pos)

		MapCellLayer.add_child(mud_cell)
		_cells[pos] = mud_cell


# ---------------------------------------------------------
# 渲染 entity
# ---------------------------------------------------------
func _render_entity(mud_cell: MapMudCell, entity_data: Dictionary) -> void:
	var entity_type := String(entity_data.get("type", ""))
	var path := "%s/Sprites/WorldMap/Icon/%s.png" % [mod_root_path, entity_type]
	mud_cell.set_entity_icon(path)


# ---------------------------------------------------------
# 渲染 flag
# ---------------------------------------------------------
func _render_flag(mud_cell: MapMudCell, flag_data: Dictionary, pos: Vector2i) -> void:
	var flag_type := String(flag_data.get("type", ""))
	var path := "%s/Sprites/WorldMap/Icon/%s.png" % [mod_root_path, flag_type]

	var size := tilemap.tile_set.tile_size
	var offset := Vector2(size.x * 0.4, -size.y * 0.4)

	mud_cell.set_flag_icon(path, offset)


# ---------------------------------------------------------
# 清理
# ---------------------------------------------------------
func _clear_all() -> void:
	#PathLayer.clear()
	#GroundLayer.clear()

	for n in MapCellLayer.get_children():
		n.queue_free()

	_cells.clear()
