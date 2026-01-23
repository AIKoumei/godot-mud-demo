extends ModInterface
class_name WorldSceneManager

## ---------------------------------------------------------
## WorldSceneManager：世界场景可视化协调层
##
## 职责：
## - 持有一个 WorldMapScene 实例（只创建一次）
## - 当 location 改变时调用 world_map_scene.render_from_instance()
## - 管理玩家节点（spawn_player_at）
## - 不负责地图玩法逻辑（由 WorldMapInstanceManager 负责）
## - 不负责地图渲染细节（由 WorldMapScene 负责）
##
## ---------------------------------------------------------

var _current_location_id: String = ""
var _root_node: Node = null
var _world_map_scene: WorldMapScene = null
var _player_node: Node2D = null


# ---------------------------------------------------------
# 模块加载
# ---------------------------------------------------------
func _on_mod_load() -> bool:
	print("[WorldSceneManager] 模块已加载")
	return true


# ---------------------------------------------------------
# 设置场景根节点（通常是 UI 场景中的 SubViewport Root）
# ---------------------------------------------------------
func set_root_node(root: Node) -> void:
	_root_node = root


# ---------------------------------------------------------
# 加载 location 的世界场景（可视化层）
# ---------------------------------------------------------
func load_scene_for_location(location_id: String) -> bool:
	_current_location_id = location_id

	# 1. 确保 root_node 存在
	if _root_node == null:
		_root_node = get_tree().get_current_scene()
		if _root_node == null:
			push_error("[WorldSceneManager] No root node to attach world scene")
			return false

	# 2. 如果没有 WorldMapScene，则创建一个
	if _world_map_scene == null or not is_instance_valid(_world_map_scene):
		var WorldMapScenePath = "res://res/mods/WorldSceneManager/Scenes/GameScenes/WorldRootScene.tscn"
		var wms: WorldMapScene = null
		if not ResourceLoader.exists(WorldMapScenePath):
			push_warning("[ModManager] Entry scene not found: %s" % WorldMapScenePath)
			wms = WorldMapScene.new()
		else:
			var scene_res = load(WorldMapScenePath)
			wms = scene_res.instantiate()
		wms.name = "WorldMapScene"

		# 设置 mod 根目录（图标路径依赖）
		var mod_root_raw: Variant = GameCore.mod_manager.call_mod("ModInfo", "get_mod_root_path")
		if mod_root_raw is String:
			var mod_root: String = mod_root_raw
			wms.set_mod_root(mod_root)

		_root_node.add_child(wms)
		_world_map_scene = wms

	# 3. 调用 WorldMapScene 渲染地图
	_world_map_scene.render_from_instance(location_id)

	print("[WorldSceneManager] Scene rendered for location:", location_id)
	return true


# ---------------------------------------------------------
# 生成玩家节点（可视化层）
# start_point: {x, y}
# ---------------------------------------------------------
func spawn_player_at(player_instance_id: String, start_point: Dictionary) -> bool:
	if _root_node == null:
		push_error("[WorldSceneManager] No root node to spawn player")
		return false

	# 1. 移除旧玩家节点
	if _player_node != null and is_instance_valid(_player_node):
		_player_node.queue_free()
		_player_node = null

	# 2. 获取玩家实例数据
	var inst_raw: Variant = GameCore.mod_manager.call_mod(
		"UnitInstanceManager",
		"get_instance",
		player_instance_id
	)

	if not (inst_raw is Dictionary):
		push_error("[WorldSceneManager] Invalid player instance: %s" % player_instance_id)
		return false

	var inst_data: Dictionary = inst_raw
	var scene_path: String = String(inst_data.get("scene_path", ""))

	# 3. 创建玩家节点
	var player: Node2D = null

	if scene_path == "":
		# 占位节点
		var node: Node2D = Node2D.new()
		node.name = "Player_%s" % player_instance_id
		player = node
	else:
		var res: Resource = ResourceLoader.load(scene_path)
		if not (res is PackedScene):
			push_error("[WorldSceneManager] Failed to load player scene: %s" % scene_path)
			return false

		var packed: PackedScene = res
		var inst: Node = packed.instantiate()
		if inst is Node2D:
			player = inst
		else:
			push_error("[WorldSceneManager] Player scene is not Node2D: %s" % scene_path)
			return false

	# 4. 设置位置
	player.position = Vector2(
		float(start_point.get("x", 0)),
		float(start_point.get("y", 0))
	)

	# 5. 挂载到 root_node
	_root_node.add_child(player)
	_player_node = player

	print("[WorldSceneManager] Player spawned at:", player.position)
	return true


# ---------------------------------------------------------
# 可选：世界更新（摄像机、动画等）
# ---------------------------------------------------------
func update(delta: float) -> void:
	# TODO: 摄像机跟随、单位动画更新等
	pass
