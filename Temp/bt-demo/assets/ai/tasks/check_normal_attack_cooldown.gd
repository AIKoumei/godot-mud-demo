@tool
extends BTAction
## Empty description. [br]
## Returns [code]SUCCESS[/code].



func _tick(_delta: float) -> Status:
	#if not agent.is_components_inited():
		#return FAILURE
	if not NodeUtil.has_component(agent, "ActorComponent"):
		return FAILURE
		
	if agent.entity.cooldown_normal_attack > 0:
		#agent.entity.cooldown_normal_attack -= _delta
		#print(agent.name + " " + str(agent.entity.cooldown_normal_attack))
		return FAILURE
	return SUCCESS
