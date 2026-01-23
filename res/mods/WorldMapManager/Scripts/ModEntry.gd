extends ModInterface
class_name WorldMapManager

var _locations: Dictionary = {}
var _version: int = 1

func _on_mod_load() -> bool:
	var path = "%s/Data/WorldMaps.json" % get_mod_path()
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("[WorldMapManager] Cannot read file: %s" % path)
		return false

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("[WorldMapManager] Invalid JSON format")
		return false

	_version = parsed.get("version", 1)
	_locations = parsed.get("locations", {})

	print("[WorldMapManager] Loaded %d locations" % _locations.size())
	return true


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
