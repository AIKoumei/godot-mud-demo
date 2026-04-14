extends Node2D
class_name WorldMapScene

# ---------------------------------------------------------
# 节点引用
# ---------------------------------------------------------
@onready var PathLayer: TileMapLayer = $MapLayer/PathLayer
@onready var GroundLayer: TileMapLayer = $MapLayer/GroundLayer
@onready var EntityLayer: Node2D = $MapLayer/EntityLayer

var entity_node_player = null

## 当前地图实例 ID
var cur_map_instance_id: String = ""

## 存储实体实例 ID 对应的 MapNode 节点
var entity_instance_id_to_map_node: Dictionary = {}

# 用 GroundLayer 作为 tilemap（用于 map_to_local）
@onready var tilemap: TileMapLayer = GroundLayer
@export_category("Camera")
@onready var camera_root:Node2D = $CameraRoot
@onready var camera:Camera2D = $CameraRoot/Camera2D
## 用于控制摄像机的移动
@export var camera_settings = {
	"target":null,
	"target_position":null,
	"is_moving":false,
}

# MapMudCell 场景（运行时加载）
var MudCellScene: PackedScene = null

# 存储 pos -> MapMudCell
var _cells: Dictionary = {}

# mod 根路径（用于加载图标）
var mod_root_path: String = ""

const BUILDING_TYPES = {
	"item_shop": {
		"name": "道具商店",
		"required": {
			"entity_type": { "shopkeeper": {}, "vending_machine": {} },
			"entity": {} 
		}
	},
	"equipment_shop": {
		"name": "装备商店",
		"required": {
			"entity_type": { "blacksmith": {} },
			"entity": {}
		}
	},
	"quest_center": {
		"name": "任务中心",
		"required": {
			"entity_type": { "quest_master": {} },
			"entity": {}
		}
	},
	"training_center": {
		"name": "训练中心",
		"required": {
			"entity_type": { "trainer": {} },
			"entity": {}
		}
	},
	"home_shop": {
		"name": "家园商店",
		"required": {
			"entity_type": { "interior_designer": {} },
			"entity": {}
		}
	},
	"home": {
		"name": "家园",
		"required": { "entity_type": {}, "entity": {} }
	},
	"union_room": {
		"name": "联盟大厅",
		"required": { "entity_type": {}, "entity": {} }
	}
}


# ---------------------------------------------------------
# 生命周期
# ---------------------------------------------------------
func _ready() -> void:
	var parent = self.get_parent()
	if parent.has_signal("on_input_event"):
		parent.on_input_event.connect(_on_input_event)
	
	for key in BUILDING_TYPES.keys():
		if not entity_type_to_tile_id.has(key):
			entity_type_to_tile_id[key] = entity_type_to_tile_id["building"]
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
var connection_to_tile_id_pos = {
	1:Vector2i(0,1),#北
	2:Vector2i(1,0),#西
	4:Vector2i(1,1),#南
	8:Vector2i(0,0),#东
	5:Vector2i(2,1),#北南
	10:Vector2i(2,0),#东西
}

var entity_type_to_tile_id = {
	"map_cell":27,
	"cneter":239,
	"wall":230,
	"gate":237,
	"road":242,
	"secondary_road":242,
	"building":232,
	"building_entrance":234,
}

## 渲染入口：从地图实例渲染地图
## @param location_id: 地图位置 ID
## 输入数据结构：
##   location_id: String - 地图的唯一标识符
## 输出：无
## 功能：
##   1. 从 WorldMapInstanceManager 获取地图实例数据
##   2. 遍历 map_nodes 渲染地图单元格和实体
##   3. 渲染玩家实体
##   4. 设置摄像机跟踪玩家
func render_from_instance(location_id: String) -> void:
	# 设置当前地图实例 ID
	cur_map_instance_id = location_id
	
	# 通过 WorldMapInstanceManager.get_instance 获取目标地图实例
	var map_instance = GameCore.mod_manager.call_mod(
		"WorldMapInstanceManager",
		"get_instance",
		location_id
	) as Dictionary
	
	if map_instance and not map_instance.is_empty():
		## 渲染路径连接
		#var path_connection_indexer = map_instance.get("data",{}).get("path_connection_indexer", {})
		#for pos_key in path_connection_indexer.keys():
			#var connection = path_connection_indexer[pos_key] as int
			#if connection_to_tile_id_pos.has(connection):
				#var pos_str = pos_key.split(",")
				#var pos_vec = Vector2i(int(pos_str[0]),int(pos_str[1]))
				#PathLayer.set_cell(pos_vec, 0, connection_to_tile_id_pos[connection])
		
		# 遍历 map_instance.data.map_nodes 渲染实体
		## map_nodes 数据结构：
		## {
		##     "x,y": [
		##         {
		##             entity_instance_id: "entity_instance_id",
		##             entity_type: "entity_type",
		##         },
		##         ...
		##     ],
		##     ...
		## }
		var map_nodes = map_instance.get("data",{}).get("map_nodes", {})
		var map_instance_id = map_instance.get("data",{}).get("map_instance_id", location_id)
		
		# 遍历所有地图位置
		for pos_key in map_nodes.keys():
			# 解析位置坐标
			var pos_str = pos_key.split(",")
			var pos_vec = Vector2i(int(pos_str[0]), int(pos_str[1]))
			
			# 获取排序后的实体列表
			var sorted_nodes = GameCore.mod_manager.call_mod(
				"WorldMapInstanceManager",
				"get_sorted_map_nodes_at_map_position",
				{
					"map_instance_id": map_instance_id,
					"map_position": pos_vec
				}
			) as Array
			
			# 渲染每个实体
			for node in sorted_nodes:
				var entity_type = node.get("entity_type", "unknown")
				var tile_id = _get_tile_id_by_entity_type(entity_type)
				GroundLayer.set_cell(pos_vec, tile_id, Vector2i.ZERO)
		
		# 渲染 player
		# 通过 PlayerManager 获取玩家实体实例
		var player_instance_id = GameCore.mod_manager.call_mod("PlayerManager", "get_player_entity_instance_id")
		if player_instance_id != "":
			# 获取玩家实体数据
			var player_entity = GameCore.mod_manager.call_mod("EntityInstanceManager", "get_entity", player_instance_id)
			if player_entity and not player_entity.is_empty():
				# 获取地图位置
				var pos = player_entity.get("attributes",{}).get("map_position", [0, 0])
				var pos_vec = Vector2i(pos[0], pos[1])
				
				# 通过 CachePoolManager 获取或创建 MapMudCell
				var map_mud_cell_path = "res://res/mods/WorldSceneManager/Scenes/GameScenes/MapMudCell.tscn"
				var map_mud_cell = GameCore.mod_manager.call_mod("CachePoolManager", "get_cached", map_mud_cell_path)
				
				# 如果缓存中没有，创建新的
				if map_mud_cell == null:
					if MudCellScene != null:
						map_mud_cell = MudCellScene.instantiate()
					else:
						# 作为后备，直接加载
						var scene = load(map_mud_cell_path)
						if scene != null:
							map_mud_cell = scene.instantiate()
				
				if map_mud_cell != null:
					# 设置节点位置
					map_mud_cell.position = tilemap.map_to_local(pos_vec)
					# 挂到 EntityLayer 下
					EntityLayer.add_child(map_mud_cell)
					
					entity_node_player = map_mud_cell
					camera_settings.target = entity_node_player
		
		print("[WorldMapScene] 渲染地图: %s" % location_id)
	else:
		print("[WorldMapScene] 地图实例不存在: %s" % location_id)


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

## 获取实体类型对应的 tile ID
## @param entity_type: 实体类型
## @return: 实体类型的 tile ID
## 实现逻辑：
##   1. 首先检查当前实体类型是否有对应的 tile ID
##   2. 如果没有，则递归查找父类型的 tile ID
##   3. 如果都没有找到，返回 0
func _get_tile_id_by_entity_type(entity_type: String) -> int:
	# 检查当前实体类型是否有对应的 tile ID
	if entity_type_to_tile_id.has(entity_type):
		return entity_type_to_tile_id[entity_type]
	
	# 获取父类型列表
	var parent_types = GameCore.mod_manager.call_mod(
		"EntityManager",
		"get_parent_entity_type_by_child_type",
		entity_type
	) as Array
	
	# 遍历父类型，查找是否有对应的 tile ID
	for parent_type in parent_types:
		var parent_tile_id = _get_tile_id_by_entity_type(parent_type)
		if parent_tile_id != 0 or entity_type_to_tile_id.has(parent_type):
			return parent_tile_id
	
	# 如果都没有找到，返回 0
	return 0


# ---------------------------------------------------------
# 渲染 info 层（MapMudCell）
# ---------------------------------------------------------
func _render_info_cells(map_data: Array, entity_instances: Array = []) -> void:
	if MudCellScene == null:
		push_error("[WorldMapScene] MudCellScene is null, cannot instantiate.")
		return

	# 渲染地图原有的实体和标记
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

		EntityLayer.add_child(mud_cell)
		_cells[pos] = mud_cell

	# 渲染从 EntityInstanceManager 获取的实体实例
	for entity in entity_instances:
		var entity_map_data = entity.get("attributes", {}).get("map_data", {})
		var pos = entity_map_data.get("position", Vector2i(0, 0))
		
		# 检查该位置是否已有单元格
		if not _cells.has(pos):
			# 实例化 MapMudCell.tscn
			var mud_cell: MapMudCell = MudCellScene.instantiate()
			mud_cell.position = tilemap.map_to_local(pos)
			EntityLayer.add_child(mud_cell)
			_cells[pos] = mud_cell
		
		# 渲染实体
		if _cells.has(pos):
			var mud_cell = _cells[pos]
			# 构建实体数据
			var entity_data = {
				"type": entity.get("entity_type", "unknown")
			}
			_render_entity(mud_cell, entity_data)


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

	for n in EntityLayer.get_children():
		n.queue_free()

	_cells.clear()

# ---------------------------------------------------------
# 摄像机跟踪
# ---------------------------------------------------------
func _process(delta: float) -> void:
	# 平滑移动速度
	const SMOOTH_SPEED = 5.0
	
	# 检查 target 是否存在
	if camera_settings.get("target", null) != null:
		var target_global_pos = camera_settings["target"].global_position
		target_global_pos = camera_root.to_global(camera_root.to_local(target_global_pos) + Vector2(32,32))
		
		# 检查 target 的位置是否发生变化
		if camera_settings["target_position"] == null or target_global_pos != camera_settings["target_position"] or camera_root.global_position.distance_to(camera_settings["target_position"]) > 1.0:
			# 更新 target_position
			camera_settings["target_position"] = target_global_pos
			# 平滑移动摄像机父节点
			camera_root.global_position = camera_root.global_position.lerp(target_global_pos, SMOOTH_SPEED * delta)
	else:
		# 检查是否有 target_position 并且 is_moving 为 false
		if camera_settings["target_position"] != null and not camera_settings["is_moving"]:
			# 平滑移动摄像机父节点到 target_position
			var new_position = camera_root.global_position.lerp(camera_settings["target_position"], SMOOTH_SPEED * delta)
			new_position = camera_root.to_local(new_position) + Vector2(32,32)
			camera_root.position = new_position
			
			# 检查是否已经到达目标位置
			if camera_root.global_position.distance_to(camera_settings["target_position"]) < 1.0:
				# 到达目标位置，置空 target_position
				camera_settings["target_position"] = null
				camera_settings["is_moving"] = false

func _on_input_event(event: InputEvent):
	prints("_on_input_event", event)

var selected_position = null
@onready var selected_img = $MapLayer/SelectedPathLayer/Selected

## 处理输入事件
## 功能：
##   1. 处理鼠标左键点击：选择地图位置
##   2. 处理鼠标左键双击：移动玩家到目标位置
##   3. 处理鼠标右键：取消选择
## 输入数据结构：
##   event: InputEvent - 输入事件
## 输出：无
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		#prints("_input : InputEventMouseButton", event)
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				var ground_position = GroundLayer.get_local_mouse_position()
				var map_position = GroundLayer.local_to_map(ground_position)
				prints("map_position", map_position, GameCore.BaseTools.veci_to_pos_str(map_position))
				if not selected_position or not selected_position == map_position:
					prints("_input : InputEventMouseButton", event)
					#var mouse_position = event.global_position
					#var ground_position = GroundLayer.to_local(mouse_position)
					selected_position = map_position
					selected_img.visible = true
					selected_img.global_position = GroundLayer.to_global(GroundLayer.map_to_local(map_position)-Vector2(32,32))
				elif selected_position == map_position:
					# move player
					## play move animation
					# cancel selection
					selected_position = null
					selected_img.visible = false
			else:
				# cancel selection
				selected_position = null
				selected_img.visible = false
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				# cancel selection
				selected_position = null
				selected_img.visible = false

## ---------------------------------------------------------
## 移动实体到指定地图位置
## @param args: 包含以下字段的字典
##   - map_position: Vector2i 目标地图位置
##   - entity_instance_id: String 实体实例 ID（可选，默认使用玩家）
## ---------------------------------------------------------
func move_entity_to_map_position(args: Dictionary) -> void:
	var map_position = args.get("map_position", null)
	var entity_instance_id = args.get("entity_instance_id", "")
	
	# 如果没有 map_position，返回
	if map_position == null:
		push_warning("[WorldMapScene] move_entity_to_map_position: map_position is required")
		return
	
	if entity_instance_id == "":
		push_warning("[WorldMapScene] move_entity_to_map_position: entity_instance_id is required")
		return
	
	## TODO: 检查地图位置是否可通行
	## var is_passable = GameCore.mod_manager.call_mod("WorldMapInstanceManager", "check_map_node_passable_by_entity_instance_id_list", {
	##     "map_instance_id": cur_map_instance_id,
	##     "map_position": map_position,
	##     "entity_instance_id_list": [entity_instance_id]
	## })
	## if not is_passable:
	##     push_warning("[WorldMapScene] move_entity_to_map_position: position not passable")
	##     return
	
	## TODO: 播放移动动画
	## play_move_animation({
	##     "map_position": map_position,
	##     "entity_instance_id": entity_instance_id
	## })
	
	## TODO: 等待移动动画完成后执行以下操作
	
	## TODO: 更新实体位置
	## GameCore.mod_manager.call_mod("WorldMapInstanceManager", "modify_entity_position", {
	##     "map_instance_id": cur_map_instance_id,
	##     "map_position": map_position,
	##     "entity_instance_id": entity_instance_id
	## })
	
	## TODO: 检查地图格子遭遇
	## mud_world_system.check_map_node_encounter(...)
	
	print("[WorldMapScene] move_entity_to_map_position: TODO - 完整功能待实现")

## ---------------------------------------------------------
## 播放移动动画
## @param args: 包含以下字段的字典
##   - map_position: Vector2i 目标地图位置
##   - entity_instance_id: String 实体实例 ID
## ---------------------------------------------------------
func play_move_animation(args: Dictionary) -> void:
	var map_position = args.get("map_position", null)
	var entity_instance_id = args.get("entity_instance_id", "")
	
	if map_position == null:
		map_position = selected_position
	
	if map_position == null:
		push_warning("[WorldMapScene] play_move_animation: map_position is required")
		return
	
	if entity_instance_id == "":
		push_warning("[WorldMapScene] play_move_animation: entity_instance_id is required")
		return
	
	## TODO: 播放移动动画
	## TODO: 更新玩家实体的位置
	## TODO: 更新玩家实体的渲染位置
	## TODO: 移动动画完成后，调用后续操作
	
	print("[WorldMapScene] play_move_animation: TODO - 完整功能待实现")
