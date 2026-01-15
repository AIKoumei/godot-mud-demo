extends BaseUtil


var STATIC_ComponentNames = {
	AttackableComponent = "AttackableComponent"
}


# ##############################################################################
# funcs
# ##############################################################################


func get_component(node:Node, component_name:String):
	return node.get_node("./Components/"+component_name)


func has_component(node:Node, component_name:String):
	return node.has_node("./Components/"+component_name)


func active_node(node):
	node.process_mode = Node.PROCESS_MODE_INHERIT

func deactive_node(node):
	node.process_mode = Node.PROCESS_MODE_DISABLED


func show_node(node):
	node.visible = true

func hide_node(node):
	node.visible = false
