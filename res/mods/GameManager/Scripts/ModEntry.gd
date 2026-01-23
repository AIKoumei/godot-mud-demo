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


func _on_mod_load() -> bool:
	print("[GameManager] 模块已加载")
	return true


func _on_mod_unload() -> void:
	print("[GameManager] 模块卸载中")


# ---------------------------------------------------------
# New Game：新游戏流程
# ---------------------------------------------------------
func new_game() -> void:
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
	# 3. 创建玩家队伍的 UnitInstance（运行时实例）
	# -----------------------------------------------------
	var team_instances: Array = []

	for template_id in team_templates:
		var inst = GameCore.mod_manager.call_mod(
			"UnitInstanceManager",
			"create_instance",
			template_id,
            "World"
		) as Dictionary

		if inst != null and not inst.is_empty() and inst.has("instance_id"):
			team_instances.append(inst["instance_id"])
		else:
			push_warning("[GameManager] create_instance failed for template: %s" % template_id)

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
			"set_unit_position",
			start_map,
			player_id,
			start_point.get("x", 0),
			start_point.get("y", 0)
		)
		
	# 切换场景，准备玩法可视化
	# 切换到 DigimonVpetUI
	register_event_listener(ModEventListenerFilter.new()
		.set_listen_type(ModEventListenerFilter.ListenType.ALWAYS)
		.set_mod_filter_type(ModEventListenerFilter.ModFilterType.TARGET)
		.set_mod_name("SceneManager")
		.set_event_filter_type(ModEventListenerFilter.EventFilterType.TARGET)
		.set_event_name("after_change_scene")
	)
	GameCore.mod_manager.call_mod("DefaultGameScene", "change_scene", "DigimonVpetUI")

func init_game_scene_after_DigimonVpetUI():
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
	if state == GameState.RUNNING:
		#GameCore.mod_manager.call_mod("Time", "update", delta)
		#GameCore.mod_manager.call_mod("Party", "update", delta)
		#GameCore.mod_manager.call_mod("World", "update", delta)
		GameCore.mod_manager.call_mod("WorldMapInstanceManager", "update", delta)


# ---------------------------------------------------------
# 接收事件（可选）
# ---------------------------------------------------------
func _on_mod_event(_mod_name: String, event_name: String, event_data: Dictionary) -> void:
	print("[GameManager] 收到事件：", _mod_name, event_name)
	if _mod_name == "SceneManager" and event_name == "after_change_scene" and event_data.get("scene_name") == "DigimonVpetUI":
		init_game_scene_after_DigimonVpetUI()
		unregister_event_listener(ModEventListenerFilter.new()
			.set_listen_type(ModEventListenerFilter.ListenType.ALWAYS)
			.set_mod_filter_type(ModEventListenerFilter.ModFilterType.TARGET)
			.set_mod_name("SceneManager")
			.set_event_filter_type(ModEventListenerFilter.EventFilterType.TARGET)
			.set_event_name("after_change_scene")
		)
