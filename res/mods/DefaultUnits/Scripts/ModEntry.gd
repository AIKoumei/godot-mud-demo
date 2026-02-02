extends ModInterface

func _on_mod_enable() -> void:
	# 加载本地 JSON
	var path = get_mod_path().path_join("Data/Units.json")
	var packet = GameCore.mod_manager.load_json(path)
	
	# 主动向 UnitManager 注册
	if not packet.is_empty():
		GameCore.mod_manager.call_mod("UnitManager", "register_unit_packet", [mod_name, packet])
