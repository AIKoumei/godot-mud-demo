## #############################################################################
## 	这里放着 location map 的固定配置
## 	
## 	需要大改
## 	可能需要协同 WorldMapGenerator 做固定 location map 的覆盖生成，而不是全随机生成
## #############################################################################

extends ModInterface
class_name WorldMapManager

var _locations: Dictionary = {} # location map config
var _location_maps: Dictionary = {} # location gen map
var _location_mud_maps: Dictionary = {} # location mud map
var _version: int = 1

func _on_mod_load() -> bool:
	var path = "%s/Data/WorldMaps.json" % get_mod_path()
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("[WorldMapManager] Cannot read file: %s" % path)
		return true

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("[WorldMapManager] Invalid JSON format")
		return true

	_version = parsed.get("version", 1)
	_locations = parsed.get("locations", {})

	print("[WorldMapManager] Loaded %d locations" % _locations.size())
	return true


func _on_mod_event(_mod_name: String, event_name: String, event_data: Dictionary) -> void:
	super._on_mod_event(_mod_name, event_name, event_data)
	if _mod_name == "WorldMapGenerator" and event_name == "after_gen_all_location_map_finished":
		_location_maps = event_data.get("location_map_datas",{}) as Dictionary
		after_gen_all_location_map_finished()
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
	for map in _location_maps.values():
		var map_name = map.get("name","")
		if map_name == "":
			continue
		_location_mud_maps[map_name] = MudMapConverter.convert(map)
		_location_mud_maps[map_name] = MudMapGenerator.generate_refined_map(_location_mud_maps[map_name])
		emit_mod_event("generate_one_refined_map_template", {
			"map_name":map_name,
			"map_data":_location_mud_maps[map_name]
		})
		await get_tree().create_timer(0.0).timeout
	save_all_location_maps()
	emit_mod_event.call_deferred("after_gen_all_location_map_finished", {
		"mud_maps":_location_mud_maps
	})

func save_all_location_maps():
	if GameCore.debugging and SaveManager.has_mod_slot_file(GameCore.Settings.GameSettings.GameSlot, "%s/%s.sav" % [mod_name, _location_mud_maps.values()[0]]):
		return
	for data in _location_mud_maps.values():
		var map_name = data.get("metadata",{}).get("map_name", "unknow_map")
		if map_name == "unknow_map":
			push_warning("[%s] save_all_location_maps 中未知的 map_name" % mod_name)
		SaveManager.save_mod_slot_data(GameCore.Settings.GameSettings.GameSlot, "%s/map_%s"%[mod_name, map_name.uri_encode()], data)
