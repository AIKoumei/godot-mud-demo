extends BaseManager


@export_category("Cage Datas")
@export var home_cage_placement_list: Array[BaseCage] = [] ## 保存家园中的cage
@export var home_cage_placement_size_mark_list: Array[CageManager.E_CageUID] = [CageManager.E_CageUID.BlankRoom,CageManager.E_CageUID.BlankRoom,CageManager.E_CageUID.BlankRoom,CageManager.E_CageUID.BlankRoom,CageManager.E_CageUID.Locked,CageManager.E_CageUID.Locked,CageManager.E_CageUID.Locked,CageManager.E_CageUID.Locked,CageManager.E_CageUID.Locked,CageManager.E_CageUID.Locked,CageManager.E_CageUID.Locked,CageManager.E_CageUID.Locked,CageManager.E_CageUID.Locked,CageManager.E_CageUID.Locked,CageManager.E_CageUID.Locked,CageManager.E_CageUID.Locked,CageManager.E_CageUID.Locked,CageManager.E_CageUID.Locked,CageManager.E_CageUID.Locked,CageManager.E_CageUID.Locked] ## 保存家园中的格子占位标记

@export var unlocked_cdge_dict: Dictionary = {
	E_CageUID.Locked : true 
	,E_CageUID.Rest : true 
} ## 保存家园中的cage



var _manager_inited = false
#var node_trush = Node.new()
func _init() -> void:
	if _manager_inited: return
	manager_name = "CageManager"
	
	regist_to_manager(GameManager, manager_name)

	for key in STATIC_ThumbCageRes.keys():
		STATIC_Res[key] = STATIC_ThumbCageRes[key]
	
	_manager_inited = true


var STATIC_ThumbCageRes = {
	"LockedCage_ThumbInEdit" = preload("res://assets/scenes/home_cage_scene/home_locked_cage_thumb_in_edit.tscn")
}


var STATIC_CageUIDToThumbCageRes = {
	E_CageUID.Locked : STATIC_ThumbCageRes["LockedCage_ThumbInEdit"]
}


var STATIC_Res = {
	"LockedCage" = preload("res://assets/scenes/home_cage_scene/home_locked_cage.tscn")
}


enum E_CageUID {
	Empty
	,Locked
	,BlankRoom
	,BlankRoom_Huge
	,Rest
}


enum E_CageType {
	Empty
	,Locked
	,BlankRoom
	,Rest
	,BabyCare
	,Adventure
	,Battle
	,Train
}


enum E_TrainType {
	HP
	,TP
	#
	,ATTACK
	,DEFEND
	,WISDON
	,SPEED
	# ATTRIBUTE_POINT
	,ATTRIBUTE_POINT ## data virus 等
	,ATTRIBUTE_POINT_DATA
	,ATTRIBUTE_POINT_VIRUS
	,ATTRIBUTE_POINT_VACCINE
	# TYPE_POINT
	,TYPE_POINT ## 虫、龙等
	,TYPE_POINT_DRAGON
	,TYPE_POINT_FIGHTER
	,TYPE_POINT_WATER
	,TYPE_POINT_MACHINE
	,TYPE_POINT_PLANT
	,TYPE_POINT_INSECT
}

var STATIC_DegradeTypeInTrain = {
	E_TrainType.HP : E_TrainType.TP
	,E_TrainType.TP : E_TrainType.HP
	,E_TrainType.ATTACK : E_TrainType.DEFEND
	,E_TrainType.DEFEND : E_TrainType.ATTACK
	,E_TrainType.WISDON : E_TrainType.SPEED
	,E_TrainType.SPEED : E_TrainType.WISDON
	# ATTRIBUTE_POINT
	,E_TrainType.ATTRIBUTE_POINT_DATA : E_TrainType.ATTRIBUTE_POINT_VACCINE
	,E_TrainType.ATTRIBUTE_POINT_VIRUS : E_TrainType.ATTRIBUTE_POINT_DATA
	,E_TrainType.ATTRIBUTE_POINT_VACCINE : E_TrainType.ATTRIBUTE_POINT_VIRUS
	# TYPE_POINT
	,E_TrainType.TYPE_POINT_DRAGON : E_TrainType.TYPE_POINT_FIGHTER
	,E_TrainType.TYPE_POINT_FIGHTER : E_TrainType.TYPE_POINT_DRAGON
	,E_TrainType.TYPE_POINT_WATER : E_TrainType.TYPE_POINT_MACHINE
	,E_TrainType.TYPE_POINT_MACHINE : E_TrainType.TYPE_POINT_WATER
	,E_TrainType.TYPE_POINT_PLANT : E_TrainType.TYPE_POINT_INSECT
	,E_TrainType.TYPE_POINT_INSECT : E_TrainType.TYPE_POINT_PLANT
}


enum E_CageSizeMark {
	Cage
	,Empty
	,Locked
}


var STATIC_CageConfigs = {
	E_CageUID.Empty : {
		cage_size_mark_list = [CageManager.E_CageSizeMark.Cage]
		,cage_uid = CageManager.E_CageUID.Empty
		,cage_type = CageManager.E_CageType.Empty
		,train_type = CageManager.E_TrainType.HP
		,train_value = 0
	}
	,E_CageUID.Locked : {
		cage_size_mark_list = [CageManager.E_CageSizeMark.Cage]
		,cage_uid = CageManager.E_CageUID.Locked
		,cage_type = CageManager.E_CageType.Locked
		,train_type = CageManager.E_TrainType.HP
		,train_value = 0
	}
	,E_CageUID.BlankRoom : {
		cage_size_mark_list = [CageManager.E_CageSizeMark.Cage]
		,cage_uid = CageManager.E_CageUID.BlankRoom
		,cage_type = CageManager.E_CageType.BlankRoom
		,train_type = CageManager.E_TrainType.HP
		,train_value = 0
	}
	,E_CageUID.BlankRoom_Huge : {
		cage_size_mark_list = [CageManager.E_CageSizeMark.Cage, CageManager.E_CageSizeMark.Cage, CageManager.E_CageSizeMark.Empty, CageManager.E_CageSizeMark.Cage, CageManager.E_CageSizeMark.Cage]
		,cage_uid = CageManager.E_CageUID.BlankRoom_Huge
		,cage_type = CageManager.E_CageType.BlankRoom
		,train_type = CageManager.E_TrainType.HP
		,train_value = 0
	}
	,E_CageUID.Rest : {
		cage_size_mark_list = [CageManager.E_CageSizeMark.Cage]
		,cage_uid = CageManager.E_CageUID.Rest
		,cage_type = CageManager.E_CageType.Rest
		,train_type = CageManager.E_TrainType.HP
		,train_value = 0
	}
}


# ##############################################################################
# base manager
# ##############################################################################


func load_from_data(data: Dictionary):
	var manager_data = data.get(manager_name,get_save_data_template())


func save_to_data(data: Dictionary) -> Dictionary:
	return data


func get_save_data_template() -> Dictionary:
	return {}


func get_save_data() -> Dictionary:
	return {}


# ##############################################################################
# funcs
# ##############################################################################


var player_unlocked_cages = {
	E_CageUID.Empty : true 
	,E_CageUID.BlankRoom : true 
	,E_CageUID.Locked : true 
	,E_CageUID.Rest : true 
}


func is_cage_unlocked(cage_uid):
	return unlocked_cdge_dict.get(cage_uid, false)


func get_normal_unlocked_cages():
	var cages = unlocked_cdge_dict.keys()
	cages.erase(E_CageUID.Locked)
	return cages


# ##############################################################################
# ENDS
# ##############################################################################
