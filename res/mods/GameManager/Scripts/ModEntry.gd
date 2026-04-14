extends ModInterface

enum GameState {
	TITLE,
	NEW_GAME,
	LOADING,
	RUNNING,
	PAUSED,
	SAVING
}

var state: GameState = GameState.TITLE


func _on_mod_init() -> void:
	print("[GameManager] 模块初始化完成，当前状态:", state)


func _on_mod_enable() -> void:
	print("[GameManager] 模块已启用")
	register_event_listener_with_name(ModEventListenerFilter.new()
		.set_listen_type(ModEventListenerFilter.ListenType.ALWAYS)
		.set_mod_filter_type(ModEventListenerFilter.ModFilterType.TARGET)
		.set_mod_name("WorldMapInstanceManager")
		.set_event_filter_type(ModEventListenerFilter.EventFilterType.TARGET)
		.set_event_name("after_gen_all_locations_finished")
		, "WorldMapInstanceManager.after_gen_all_locations_finished"
	)
	register_event_listener_with_name(ModEventListenerFilter.new()
		.set_listen_type(ModEventListenerFilter.ListenType.ALWAYS)
		.set_mod_filter_type(ModEventListenerFilter.ModFilterType.TARGET)
		.set_mod_name("GameCore.UIScene")
		.set_event_filter_type(ModEventListenerFilter.EventFilterType.TARGET)
		.set_event_name("after_scene_ready.DigimonVpetUI")
		, "GameCore.UIScene.after_scene_ready.DigimonVpetUI"
	)


func _on_mod_load() -> bool:
	print("[GameManager] 模块已加载")
	return true


func _on_mod_unload() -> void:
	print("[GameManager] 模块卸载中")


# ---------------------------------------------------------
# New Game：新游戏流程
# ---------------------------------------------------------
## 过期的成员
var _listener = null
## 过期的方法
func __new_game() -> void:
	print("[GameManager] New Game")
	state = GameState.NEW_GAME

	# -----------------------------------------------------
	# 1. 初始化玩家元数据
	# -----------------------------------------------------
	GameCore.mod_manager.call_mod("PlayerDataManager", "create_default_player")

	# -----------------------------------------------------
	# 2. 初始化玩家队伍（模板 ID 列表）
	# -----------------------------------------------------
	var team_templates = GameCore.mod_manager.call_mod(
		"PlayerDataManager",
        "create_default_team"
	) as Array

	if team_templates == null:
		push_error("[GameManager] create_default_team returned null")
		team_templates = []

	# -----------------------------------------------------
	# 3. 创建玩家队伍的 EntityInstance（运行时实例）
	# -----------------------------------------------------
	var team_instances: Array = []

	for template_id in team_templates:
		var inst = GameCore.mod_manager.call_mod(
			"EntityInstanceManager",
			"create_entity",
			template_id,
			{"position": Vector2.ZERO}
		) as Dictionary

		if inst != null and not inst.is_empty() and inst.has("instance_id"):
			team_instances.append(inst["instance_id"])
		else:
			push_warning("[GameManager] create_entity failed for template: %s" % template_id)

	# -----------------------------------------------------
	# 允许空队伍
	# -----------------------------------------------------
	GameCore.mod_manager.call_mod(
		"PlayerDataManager",
		"set_player_team",
		team_instances
	)

	# -----------------------------------------------------
	# 4. 初始化游戏时间
	# -----------------------------------------------------
	GameCore.mod_manager.call_mod("Time", "reset_to_day1")

	# -----------------------------------------------------
	# 5. 获取出生点（地图 + 坐标）
	# -----------------------------------------------------
	var start_map = GameCore.mod_manager.call_mod("PlayerDataManager", "get_start_map")
	if start_map == null or start_map == "":
		push_error("[GameManager] Invalid start_map")
		return

	var start_point = GameCore.mod_manager.call_mod(
		"PlayerDataManager",
		"get_start_spawn_point"
	) as Dictionary

	if start_point == null or start_point.is_empty():
		push_error("[GameManager] Invalid start_spawn_point")
		return

	# -----------------------------------------------------
	# 6. 加载地图实例（数据层，多实例管理）
	# -----------------------------------------------------
	var ok_inst = GameCore.mod_manager.call_mod(
		"WorldMapInstanceManager",
		"load_location",
		start_map
	)

	if ok_inst == null or ok_inst == false:
		push_error("[GameManager] WorldMapInstanceManager.load_location failed")
		return

	# -----------------------------------------------------
	# 7. 设置玩家在地图玩法上的逻辑位置（数据层）
	# -----------------------------------------------------
	if team_instances.size() > 0:
		var player_id = team_instances[0]

		GameCore.mod_manager.call_mod(
			"WorldMapInstanceManager",
			"set_entity_position",
			start_map,
			player_id,
			start_point.get("x", 0),
			start_point.get("y", 0)
		)
		
	# 切换场景，准备玩法可视化
	# 切换到 DigimonVpetUI
	_listener = register_event_listener(ModEventListenerFilter.new()
		.set_listen_type(ModEventListenerFilter.ListenType.ALWAYS)
		.set_mod_filter_type(ModEventListenerFilter.ModFilterType.TARGET)
		.set_mod_name("SceneManager")
		.set_event_filter_type(ModEventListenerFilter.EventFilterType.TARGET)
		.set_event_name("after_change_scene")
	)
	GameCore.mod_manager.call_mod("DefaultGameScene", "change_scene", "DigimonVpetUI")
## 过期的方法
func __init_game_scene_after_DigimonVpetUI():
	if _listener:
		unregister_event_listener(_listener)
		_listener = null
	# -----------------------------------------------------
	# 8. 加载地图场景（可视化层，只渲染当前 location）
	# -----------------------------------------------------

	
	# 在加载了 UI_Main 的 DigimonVpetUI 场景后，找出 subviewport 设置成游戏世界场景的 root node
	var node = GameCore.mod_manager.call_mod(
		"SceneManager",
		"get_current_main_scene"
	)
	if node != null and node.has_method("get_game_scene_subviewport"):
		GameCore.mod_manager.call_mod(
			"WorldSceneManager",
			"set_root_node",
			node.get_game_scene_subviewport()
		)
		
	var start_map = GameCore.mod_manager.call_mod("PlayerDataManager", "get_start_map")
	if start_map == null or start_map == "":
		push_error("[GameManager] Invalid start_map")
		return
	
	var ok_scene = GameCore.mod_manager.call_mod(
		"WorldSceneManager",
		"load_scene_for_location",
		start_map
	)

	if ok_scene == null or ok_scene == false:
		push_error("[GameManager] WorldSceneManager.load_scene_for_location failed")
		return

	# -----------------------------------------------------
	# 9. 生成玩家节点（如果队伍为空则跳过，可视化层）
	# -----------------------------------------------------
	var team_instances = GameCore.mod_manager.call_mod(
		"PlayerDataManager",
		"get_player_team"
	)
	if team_instances.size() > 0:
		var player_id = team_instances[0]

		var start_point = GameCore.mod_manager.call_mod(
			"PlayerDataManager",
	        "get_start_spawn_point"
		) as Dictionary

		if start_point == null or start_point.is_empty():
			push_error("[GameManager] Invalid start_spawn_point")
			return

		var ok_spawn = GameCore.mod_manager.call_mod(
			"WorldSceneManager",
			"spawn_player_at",
			player_id,
			start_point
		)

		if ok_spawn == null or ok_spawn == false:
			push_error("[GameManager] spawn_player_at failed")
			return

	# -----------------------------------------------------
	# 10. 初始化 UI
	# -----------------------------------------------------
	GameCore.mod_manager.call_mod("UI", "show_main_ui")
	GameCore.mod_manager.call_mod("UI", "bind_player_data")

	# -----------------------------------------------------
	# 11. 创建初始存档
	# -----------------------------------------------------
	GameCore.mod_manager.call_mod("Save", "create_new_save")

	state = GameState.RUNNING
	print("[GameManager] 游戏已开始运行")
# ---------------------------------------------------------
signal _init_mul_map_instance_finished ## 内部信号，用于等待地图初始化完毕后继续下一步new game
signal _main_game_scene_ready ## 内部信号，用于等待地图初始化完毕后继续下一步new game
func new_game() -> void:
	# TODO 先给个默认 slot
	GameCore.Settings.GameSettings.GameSlot = 1
	GameCore.mod_manager.call_mod("DefaultGameScene", "change_scene", "NewGameScene")
	await _init_mul_map_instance_finished
	if _init_mul_map_instance_finished.has_connections():
		_init_mul_map_instance_finished.disconnect(new_game)
	# 生成玩家 entity
	var map_name = GameCore.Settings.GameSettings.PlayerSpawnMapId
	var map_position = Vector2i.ZERO
	
	# 如果 map_name 为空，随机抽取一个地图作为玩家的出生地图
	if map_name == "":
		# 获取所有可用的地图列表
		var mud_map_instances = GameCore.mod_manager.call_mod("WorldMapInstanceManager", "get_all_mud_map_instances")
		var rng = RandomNumberGenerator.new()
		rng.seed = GameCore.Settings.GameSettings.WorldSeed
		if mud_map_instances and mud_map_instances.size() > 0:
			# 随机选择一个地图
			var map_keys = mud_map_instances.keys()
			if map_keys.size() > 0:
				prints(rng.seed, rng.randi(), map_keys.size())
				var random_index = rng.randi() % map_keys.size()
				map_name = map_keys[random_index]
				if GameCore.debugging and "test_Town" in map_keys:
					map_name = "test_Town"
				print("[GameManager] 随机选择出生地图 %s: %s" % [random_index, map_name])
				# 选择地图 center 的位置
				var map_instance = mud_map_instances[map_name]
				var center_pos = map_instance.get("metadata",{}).get("config",{}).get("map_data",{}).get("center", false)
				if center_pos:
					map_position = Vector2i(center_pos[0],center_pos[1])
		else:
			# 如果没有可用地图，使用默认值
			map_name = "default_map"
			print("[GameManager] 没有可用地图，使用默认地图: %s" % map_name)
	
	# 通过 PlayerManager 创建玩家实体
	var player_entity_cfg = {
		"map_instance_id": map_name,
		"attributes":{
			"map_position": [map_position.x,map_position.y]
		},
	}
	GameCore.Settings.GameSettings.PlayerSpawnMapId = map_name
	GameCore.Settings.GameSettings.PlayerSpawnMapPosition = map_position
	
	var player_instance_id = GameCore.mod_manager.call_mod(
		"PlayerManager",
		"create_player_entity",
		"player",
		player_entity_cfg
	)
	
	# 初始化 PlayerManager 的玩家实体实例 ID
	if player_instance_id != "":
		GameCore.mod_manager.call_mod(
			"PlayerManager",
			"init_player_entity",
			player_instance_id
		)
		print("[GameManager] 玩家实体创建成功，实例 ID: %s" % player_instance_id)
	else:
		print("[GameManager] 创建玩家实体失败")
	
	# 玩家队伍初始化
	
	# 数据准备好后，进入主场景
	GameCore.mod_manager.call_mod("DefaultGameScene", "change_scene", "DigimonVpetUI")
	
	# 玩家队伍初始化
	
	await _main_game_scene_ready
	
	# 可视化功能初始化
	
	# -----------------------------------------------------
	# 8. 加载地图场景（可视化层，只渲染当前 location）
	# -----------------------------------------------------
	
	# 在加载了 UI_Main 的 DigimonVpetUI 场景后，找出 subviewport 设置成游戏世界场景的 root node
	var node = GameCore.mod_manager.call_mod(
		"SceneManager",
		"get_current_main_scene"
	)
	if node != null and node.has_method("get_game_scene_subviewport"):
		GameCore.mod_manager.call_mod(
			"WorldSceneManager",
			"set_root_node",
			node.get_game_scene_subviewport()
		)
		
	var start_map = GameCore.Settings.GameSettings.PlayerSpawnMapId
	var start_map_pos = GameCore.Settings.GameSettings.PlayerSpawnMapPosition
	
	var ok_scene = GameCore.mod_manager.call_mod(
		"WorldSceneManager",
		"load_scene_for_location",
		start_map
	)

	if ok_scene == null or ok_scene == false:
		push_error("[GameManager] WorldSceneManager.load_scene_for_location failed")
		return

	# -----------------------------------------------------
	# 9. 生成玩家节点（如果队伍为空则跳过，可视化层）
	# -----------------------------------------------------
	#var team_instances = GameCore.mod_manager.call_mod(
		#"PlayerDataManager",
		#"get_player_team"
	#)
	#if team_instances.size() > 0:
		#var player_id = team_instances[0]
#
		#var start_point = GameCore.mod_manager.call_mod(
			#"PlayerDataManager",
			#"get_start_spawn_point"
		#) as Dictionary
#
		#if start_point == null or start_point.is_empty():
			#push_error("[GameManager] Invalid start_spawn_point")
			#return
#
		#var ok_spawn = GameCore.mod_manager.call_mod(
			#"WorldSceneManager",
			#"spawn_player_at",
			#player_id,
			#start_point
		#)
#
		#if ok_spawn == null or ok_spawn == false:
			#push_error("[GameManager] spawn_player_at failed")
			#return

	# -----------------------------------------------------
	# 10. 初始化 UI
	# -----------------------------------------------------
	#GameCore.mod_manager.call_mod("UI", "show_main_ui")
	#GameCore.mod_manager.call_mod("UI", "bind_player_data")
	
	emit_mod_event("new_game_finished")


# ---------------------------------------------------------
# Save Game：保存游戏
# ---------------------------------------------------------
func save_game() -> void:
	if state == GameState.SAVING:
		return

	print("[GameManager] Saving...")
	state = GameState.SAVING

	GameCore.mod_manager.call_mod("Save", "save")

	state = GameState.RUNNING
	print("[GameManager] Save Complete")


# ---------------------------------------------------------
# Load Game：加载游戏
# ---------------------------------------------------------
func load_game() -> void:
	print("[GameManager] Loading...")
	state = GameState.LOADING

	GameCore.mod_manager.call_mod("Save", "load")

	GameCore.mod_manager.call_mod("UI", "show_main_ui")
	GameCore.mod_manager.call_mod("UI", "bind_player_data")

	state = GameState.RUNNING
	print("[GameManager] Load Complete")


# ---------------------------------------------------------
# Pause / Resume：暂停与恢复
# ---------------------------------------------------------
func pause_game() -> void:
	if state != GameState.RUNNING:
		return
	state = GameState.PAUSED
	get_tree().paused = true
	GameCore.mod_manager.call_mod("UI", "show_pause_menu")


func resume_game() -> void:
	if state != GameState.PAUSED:
		return
	state = GameState.RUNNING
	get_tree().paused = false
	GameCore.mod_manager.call_mod("UI", "hide_pause_menu")


# ---------------------------------------------------------
# 游戏主循环（可选）
# ---------------------------------------------------------
func _process(delta: float) -> void:
	pass
	#if state == GameState.RUNNING:
		##GameCore.mod_manager.call_mod("Time", "update", delta)
		##GameCore.mod_manager.call_mod("Party", "update", delta)
		##GameCore.mod_manager.call_mod("World", "update", delta)
		#GameCore.mod_manager.call_mod("WorldMapInstanceManager", "update", delta)


# ---------------------------------------------------------
# 接收事件（可选）
# ---------------------------------------------------------
func _on_mod_event(_mod_name: String, event_name: String, event_data: Dictionary) -> void:
	prints("[GameManager] 收到事件：", _mod_name, event_name)
	#if _mod_name == "SceneManager" and event_name == "after_change_scene" and event_data.get("scene_name") == "DigimonVpetUI":
		#init_game_scene_after_DigimonVpetUI()
		#unregister_event_listener(ModEventListenerFilter.new()
			#.set_listen_type(ModEventListenerFilter.ListenType.ALWAYS)
			#.set_mod_filter_type(ModEventListenerFilter.ModFilterType.TARGET)
			#.set_mod_name("SceneManager")
			#.set_event_filter_type(ModEventListenerFilter.EventFilterType.TARGET)
			#.set_event_name("after_change_scene")
		#)
	if _mod_name == "WorldMapInstanceManager" and event_name == "after_gen_all_locations_finished":
		emit_signal("_init_mul_map_instance_finished")
	elif _mod_name == "GameCore.UIScene" and event_name == "after_scene_ready.DigimonVpetUI":
		emit_signal("_main_game_scene_ready")
