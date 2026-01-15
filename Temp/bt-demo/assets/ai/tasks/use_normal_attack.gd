@tool
extends BTAction
## Empty description. [br]
## Returns [code]SUCCESS[/code].

func _tick(_delta: float) -> Status:
	var component = NodeUtil.get_component(agent, NodeUtil.STATIC_ComponentNames.AttackableComponent) as AttackableComponent
	if not component:
		return FAILURE
	component.use_normal_attack()
	return SUCCESS
