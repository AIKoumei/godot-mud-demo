extends BaseManager


@export var RecylePool = {}
enum E_PoolObjType {
	MapObj_Poop
	,MapObj_Food
	,MapObj_Medicine
	,MapObj_Cake
	,Scene_CommonPopupMessageWindowScene
	,CageEditScene_LockedCage
}
#var STATIC_PoolObjType_Name = {
	#E_PoolObjType.MapObj_Poop : "MapObj_Poop"
	#,E_PoolObjType.MapObj_Food : "MapObj_Food"
	#,E_PoolObjType.MapObj_Medicine : "MapObj_Medicine"
	#,E_PoolObjType.MapObj_Cake : "MapObj_Cake"
	#,E_PoolObjType.Scene_CommonPopupMessageWindowScene : "Scene_CommonPopupMessageWindowScene"
#}


var _manager_inited = false
var node_trush = Node.new()
func _init() -> void:
	if _manager_inited: return
	_manager_inited = true
	self.add_child(node_trush)
	node_trush.name = "Trush"



# ##############################################################################
# funcs
# ##############################################################################


func drop_to_trush(node: Node, pool_obj_type: E_PoolObjType):
	if "empty" in node: node.empty()
	NodeUtil.deactive_node(node)
	NodeUtil.hide_node(node)
	if not pool_obj_type in RecylePool:
		RecylePool[pool_obj_type] = []
	RecylePool[pool_obj_type].append(node)
	node.get_parent().remove_child(node)
	node_trush.add_child(node)

func get_recyle_item(pool_obj_type: E_PoolObjType):
	if pool_obj_type in RecylePool and RecylePool[pool_obj_type].size() > 0:
		var node = RecylePool[pool_obj_type].pop_front()
		node_trush.remove_child(node)
		if "reactive" in node: node.reactive()
		return node


# ##############################################################################
# ENDS
# ##############################################################################
