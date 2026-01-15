extends BaseComponent
class_name TeamComponent

@export var team : GlobalEnv.Teams = GlobalEnv.Teams.Enemy

func _on_ready() -> void:
	var root = get_root_node()
	if not "entity" in root:
		return
	root.entity.team = self.team
	
	if "collision_layer" in root:
		#root.set_collision_layer_value(self.team, true)
		for _team in GlobalEnv.TeamTableForEachAsEnemy[root.entity.team]:
			root.set_collision_mask_value(_team, true)
		if not "no_collision_layer" in root.entity or not root.entity.no_collision_layer:
			root.set_collision_layer_value(root.entity.team, true)

func _on_body_entered(body):
	var root = get_root_node()
	if self.verbose:
		print(body.name + " enter " + root.name)
