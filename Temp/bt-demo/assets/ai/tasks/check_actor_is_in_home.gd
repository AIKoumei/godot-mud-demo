@tool
extends BTAction
## Empty description. [br]
## Returns [code]SUCCESS[/code].


func _tick(_delta: float) -> Status:
	if not agent is BaseDigimon: return FAILURE
	agent = agent as BaseDigimon
	if agent.scene_position_type == BaseDigimon.E_ScenePositionType.Home:
		return SUCCESS
	return FAILURE
