extends BaseManager


#class_name EntityManager


# ##############################################################################
# laod res
# ##############################################################################


var _manager_inited = false
func _init() -> void:
	if _manager_inited: return
	_manager_inited = true


var STATIC_RES = {
	#audio = preload()
	digimon_bgm_1 = preload("res://assets/audio/bgm/base/Digimon World Championship OST #1 Friendly Competition.mp3")
	,digimon_bgm_2 = preload("res://assets/audio/bgm/base/Digimon World Championship OST #2 Arena 2.mp3")
	,digimon_bgm_3 = preload("res://assets/audio/bgm/base/Digimon World Championship OST #3 Dark Arena or Championship Arena.mp3")
	,digimon_bgm_4 = preload("res://assets/audio/bgm/base/Digimon World Championship OST #4.mp3")
	,digimon_bgm_5 = preload("res://assets/audio/bgm/base/Digimon World Championship OST #5 You Lost.mp3")
	,digimon_bgm_6 = preload("res://assets/audio/bgm/base/Digimon World Championship OST #6 Victory.mp3")
	,digimon_bgm_7 = preload("res://assets/audio/bgm/base/Digimon World Championship OST #7 Welcome to the Championships Opening Cinematic.mp3")
	,digimon_bgm_8 = preload("res://assets/audio/bgm/base/Digimon World Championship OST #8 Fight in a Hostile Terrain.mp3")
	,digimon_bgm_9 = preload("res://assets/audio/bgm/base/Digimon World Championship OST #9 Browsing the Shops.mp3")
	,digimon_bgm_10 = preload("res://assets/audio/bgm/base/Digimon World Championship OST #10 Let s begin.mp3")
	,digimon_bgm_11 = preload("res://assets/audio/bgm/base/Digimon World Championship OST #11 Where to Hunt.mp3")
	,digimon_bgm_12 = preload("res://assets/audio/bgm/base/Digimon World Championship OST #12.mp3")
	,digimon_bgm_13 = preload("res://assets/audio/bgm/base/Digimon World Championship OST #13 What to Pick.mp3")
	,digimon_bgm_14 = preload("res://assets/audio/bgm/base/Digimon World Championship OST #14 Let s Hunt 1.mp3")
	,digimon_bgm_15 = preload("res://assets/audio/bgm/base/Digimon World Championship OST #15 Let s Hunt 2.mp3")
	,digimon_bgm_16 = preload("res://assets/audio/bgm/base/Digimon World Championship OST #16 Let s Hunt 3.mp3")
	,digimon_bgm_17 = preload("res://assets/audio/bgm/base/Digimon World Championship OST #17 Field Fight.mp3")
	,digimon_bgm_18 = preload("res://assets/audio/bgm/base/Digimon World Championship OST #18 You Are The Champ.mp3")
	,digimon_bgm_19 = preload("res://assets/audio/bgm/base/Digimon World Championship OST #19 Welcome to the Digital World.mp3")
	,digimon_bgm_20 = preload("res://assets/audio/bgm/base/Digimon World Championship OST #20 Let s take a look.mp3")
	,digimon_bgm_21 = preload("res://assets/audio/bgm/base/Digimon World Championship OST #21 Home Sweet Home.mp3")
	,digimon_bgm_22 = preload("res://assets/audio/bgm/base/Digimon World Championship OST #22 Let s Hunt 4.mp3")
	,digimon_bgm_23 = preload("res://assets/audio/bgm/base/Digimon World Championship OST #23 Let s Hunt 5.mp3")
	,digimon_bgm_24 = preload("res://assets/audio/bgm/base/Digimon World Championship OST #24 Let s Hunt 6.mp3")
	,digimon_bgm_25 = preload("res://assets/audio/bgm/base/Digimon World Championship OST #25 Let s Hunt 7.mp3")
	,digimon_bgm_26 = preload("res://assets/audio/bgm/base/Digimon World Championship OST #26 Let s Hunt 8.mp3")
	,digimon_bgm_27 = preload("res://assets/audio/bgm/base/Digimon World Championship OST #27 Aquatic Fight.mp3")
}

func get_res_file_type(audio_res):
	return STATIC_Audio_File_Type[audio_res.resource_path.split(".")[-1].to_upper()]

var STATIC_Audio_File_Type = {
	"MP3":"MP3"
}


# ##############################################################################
# funcs
# ##############################################################################


enum STATIC_Audio_Bus_Type {
	Master
	,BGM
	,SE
	,Environment
	,Voice
}

var STATIC_Audio_Bus_Names = {
	STATIC_Audio_Bus_Type.Master : "Master"
	,STATIC_Audio_Bus_Type.BGM : "BGM"
	,STATIC_Audio_Bus_Type.SE : "SE"
	,STATIC_Audio_Bus_Type.Environment : "Environment"
	,STATIC_Audio_Bus_Type.Voice : "Voice"
}

var Tracks = {}

func get_idle_track(bus_type: STATIC_Audio_Bus_Type):
	if not bus_type in Tracks:
		Tracks[bus_type] = []
	if bus_type == STATIC_Audio_Bus_Type.BGM:
		if Tracks[bus_type].size()>0:
			return Tracks[bus_type][0]
	for track:AudioStreamPlayer in Tracks[bus_type]:
		if not track.is_playing():
			return track
	var track = AudioStreamPlayer.new()
	if bus_type == STATIC_Audio_Bus_Type.BGM:
		track.finished.connect(on_bgm_track_finished)
	track.process_mode = Node.PROCESS_MODE_ALWAYS
	track.set_bus(STATIC_Audio_Bus_Names[bus_type])
	self.add_child(track)
	Tracks[bus_type].append(track)
	return track

func on_bgm_track_finished():
	print("on_bgm_track_finished")
	for track in Tracks[STATIC_Audio_Bus_Type.BGM]:
		if not track.is_playing():
			track.play()

func on_scene_change(event: AudioOnSceneChangeEvent):
	if event.clear_all_bgm:
		for track in Tracks[STATIC_Audio_Bus_Type.BGM]:
			track.stop()

func play(bus_type: STATIC_Audio_Bus_Type, audio_res, volume=100):
	var track = get_idle_track(bus_type)
	if bus_type == STATIC_Audio_Bus_Type.BGM and track.get_stream() == audio_res:
		return
	track.set_stream(audio_res)
	track.set_volume_linear(volume/100.0)
	track.play(0)

func play_BGM(audio_res):
	self.play(STATIC_Audio_Bus_Type.BGM, audio_res)


# ##############################################################################
# END
# ##############################################################################
