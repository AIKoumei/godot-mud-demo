## #############################################################################
## 	这里放着 location map 的固定配置
## 	
## 	需要大改
## 	可能需要协同 WorldMapGenerator 做固定 location map 的覆盖生成，而不是全随机生成
## #############################################################################

extends ModInterface
class_name WorldMapManager

# 运行时加载 MudMapGenerator 类

var _locations: Dictionary = {} # location map config
var _location_maps: Dictionary = {} # location gen map
var _location_mud_maps: Dictionary = {} # location mud map
var _version: int = 1


func _on_mod_load() -> bool:
	# 运行时加载 MudMapGenerator 类
	if MudMapGenerator == null:
		push_error("[WorldMapManager] 无法加载 MudMapGenerator.gd")
		return false
	print("[WorldMapManager] Loaded %d locations" % _locations.size())
	return true


func _on_mod_event(_mod_name: String, event_name: String, event_data: Dictionary) -> void:
	super._on_mod_event(_mod_name, event_name, event_data)
	if _mod_name == "WorldMapGenerator" and event_name == "after_gen_all_location_map_finished":
		_location_maps = event_data.get("location_map_datas",{}) as Dictionary
		generate_all_refined_map()
	# TODO 加一个 popup msg
	elif event_name == "SaveAllMapTemplateData":
		save_all_location_maps()


func get_location_static(location_id: String) -> Dictionary:
	return _locations.get(location_id, {})


func get_map_data(location_id: String) -> Array:
	return _locations.get(location_id, {}).get("map_data", [])


func get_spawn_points(location_id: String) -> Dictionary:
	return _locations.get(location_id, {}).get("spawn_points", {})


func get_metadata(location_id: String) -> Dictionary:
	return _locations.get(location_id, {}).get("metadata", {})


func get_mod_path() -> String:
	return GameCore.mod_manager.loaded_mods[mod_name].path
	

func gen_all_locations():
	# 监听生成地图完成
	register_event_listener_with_name(ModEventListenerFilter.new()
		.set_listen_type(ModEventListenerFilter.ListenType.ONCE)
		.set_mod_filter_type(ModEventListenerFilter.ModFilterType.TARGET)
		.set_mod_name("WorldMapGenerator")
		.set_event_filter_type(ModEventListenerFilter.EventFilterType.TARGET)
		.set_event_name("after_gen_all_location_map_finished")
		, "after_gen_all_location_map_finished"
	)
	GameCore.mod_manager.call_mod("WorldMapGenerator", "gen_all_location_map")
	

func after_gen_all_location_map_finished():
	save_all_location_maps()
	emit_mod_event.call_deferred("after_gen_all_location_map_finished", {
		"mud_maps":_location_mud_maps
	})

func save_all_location_maps():
	if GameCore.debugging and SaveManager.has_mod_slot_file(GameCore.Settings.GameSettings.GameSlot, "%s/map_%s.sav" % [mod_name, _location_mud_maps.keys()[0].uri_encode()]):
		return
	for data in _location_mud_maps.values():
		var map_name = data.get("data",{}).get("map_name", "unknow_map")
		if map_name == "unknow_map":
			push_warning("[%s] save_all_location_maps 中未知的 map_name" % mod_name)
		SaveManager.save_mod_slot_data(GameCore.Settings.GameSettings.GameSlot, "%s/map_%s"%[mod_name, map_name.uri_encode()], data)


# 线程相关变量
var map_process_thread: Thread = Thread.new() # 地图处理线程
var map_process_mutex: Mutex = Mutex.new() # 互斥锁（保证数据安全）
var is_map_process_running: bool = false # 标记线程是否运行

func _gen_all_location_map():
	for map in _location_maps.values():
		var map_name = map.get("name", "")
		if map_name == "":
			continue
		map_process_mutex.lock()
		_location_mud_maps[map_name] = MudMapGenerator.generate_mud_map_template(map).duplicate_deep()
		map_process_mutex.unlock()
		#emit_mod_event("generate_one_refined_map_template", {
		#	"map_name":map_name,
		#	"map_data":_location_mud_maps[map_name]
		#})
		after_one_location_generate_finished(_location_mud_maps[map_name])
		
	after_gen_all_location_map_finished.call_deferred()
	
	is_map_process_running = false


# --------------------------------------------------------------------------
# VI. mud_map_template 管理功能
# --------------------------------------------------------------------------

## 获取 mud_map_template
## @param map_id: 地图 ID
## @return: mud_map_template 数据
func get_mud_map_template(map_id: String) -> Dictionary:
	return _location_mud_maps.get(map_id, {})

## 添加或更新 mud_map_template
## @param map_id: 地图 ID
## @param template: mud_map_template 数据
func add_or_update_mud_map_template(map_id: String, template: Dictionary) -> void:
	_location_mud_maps[map_id] = template

## 删除 mud_map_template
## @param map_id: 地图 ID
func remove_mud_map_template(map_id: String) -> void:
	if _location_mud_maps.has(map_id):
		_location_mud_maps.erase(map_id)

## 获取所有 mud_map_template
## @return: 所有 mud_map_template 数据
func get_all_mud_map_templates() -> Dictionary:
	return _location_mud_maps

## 获取 mud_map_template 数量
## @return: mud_map_template 数量
func get_mud_map_templates_count() -> int:
	return _location_mud_maps.size()

	
func after_one_location_generate_finished(mud_map):
	var map_name = mud_map.get("data", {}).get("map_name", "")
	var map_data = _location_mud_maps.get(map_name, mud_map)
	emit_mod_event("generate_one_refined_map_template", {
		"map_name":map_name,
		"map_data":map_data
	})

func generate_all_refined_map():
	if is_map_process_running: return
	is_map_process_running = true
	
	if GameCore.debugging and SaveManager.has_mod_slot_file(GameCore.Settings.GameSettings.GameSlot, "%s/map_%s.sav" % [mod_name, _location_maps.keys()[0].uri_encode()]):
		print("从缓存中加载 _location_mud_maps")
		for map in _location_maps.values():
			var map_name = map.get("name","")
			if map_name == "":
				continue
			if GameCore.debugging and SaveManager.has_mod_slot_file(GameCore.Settings.GameSettings.GameSlot, "%s/map_%s.sav" % [mod_name, map_name.uri_encode()]):
				_location_mud_maps[map_name] = SaveManager.load_mod_slot_data(GameCore.Settings.GameSettings.GameSlot, "%s/map_%s" % [mod_name, map_name.uri_encode()])
			else:
				_location_mud_maps[map_name] = MudMapGenerator.generate_mud_map_template(map).duplicate_deep()
			after_one_location_generate_finished(_location_mud_maps[map_name])
			await get_tree().create_timer(0).timeout
		is_map_process_running = false
		after_gen_all_location_map_finished.call_deferred()
		return


	map_process_thread.start(_gen_all_location_map)
