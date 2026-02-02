extends Control


@onready var progress_bar = $Panel/MarginContainer/VBoxContainer/ProgressBar
@onready var message_text = $Panel/MarginContainer/VBoxContainer/ProgressBar/Message


# Called when the node enters the scene tree for the first time.
var locations_count := 0
var loaded_locations_count := 0
func _ready() -> void:
	set_message("确认资源")
	await get_tree().create_timer(0.2).timeout
	set_message("加载资源")
	await get_tree().create_timer(0.2).timeout
	set_message("加载 mod")
	await get_tree().create_timer(0.2).timeout
	set_message("初始化 mod")
	await get_tree().create_timer(0.2).timeout
	set_message("生成 Digimon World")
	await get_tree().create_timer(0.2).timeout
	locations_count = GameCore.mod_manager.call_mod("LocationManager", "get_all_locations_size")
	loaded_locations_count = 0
	# TODO 以后需要将一些逻辑放到 WorldMapManager 的逻辑中
	GameCore.mod_manager.call_mod("WorldMapInstanceManager", "gen_all_locations")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_mod_event(_mod_name: String, event_name: String, event_data: Dictionary) -> void:
	# TODO 以后需要将一些逻辑放到 WorldMapManager 的逻辑中
	if _mod_name == "WorldMapGenerator" and event_name == "after_one_location_generate_finished":
		locations_count = GameCore.mod_manager.call_mod("LocationManager", "get_all_locations_size")
		var location_name = event_data.get("location_name", "")
		loaded_locations_count += 1
		#prints(location_name, loaded_locations_count, locations_count)
		set_message("生成 Digimon World，地点 %s（%s/%s）" % [location_name, loaded_locations_count, locations_count])
	elif _mod_name == "WorldMapInstanceManager" and event_name == "after_gen_all_locations_finished":
		GameCore.mod_manager.call_mod("WorldMapInstanceManager", "save_all_location_instances")


func set_message(msg) -> void:
	if not msg is String:
		msg = ""
	message_text.text = msg
