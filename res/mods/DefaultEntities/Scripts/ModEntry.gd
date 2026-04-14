extends ModInterface

func _on_mod_enable() -> void:
	# 加载本地 JSON
	var path = get_mod_path().path_join("Data/Entities.json")
	var packet = GameCore.mod_manager.load_json(path)
	
	# 主动向 EntityManager 注册
	if not packet.is_empty():
		GameCore.mod_manager.call_mod("EntityManager", "register_entity_packet", mod_name, packet)
