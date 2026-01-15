extends Node
class_name BaseComponent


@export_category("Debug")
@export var verbose: bool = GlobalEnv.Debug.verbose


# ##############################################################################
# funcs
# ##############################################################################

# no used
func _on_init():
	get_root_node().on_component_init_once(self)


# ##############################################################################
# funcs
# ##############################################################################


func get_root_node():
	var root = get_parent()
	if root.name == "Components":
		root = root.get_parent()
	return root

func get_root_entity():
	var root = get_parent()
	if root.name == "Components":
		root = root.get_parent()
	return root.entity

func has_component(node, component_name):
	return NodeUtil.has_component(node, component_name)
