class_name MudEntityAction extends Resource

## 动作唯一标识符
var action_id: String = ""
## UI 显示名称
var action_label: String = ""

## 判定：source 是否能对 target 执行此动作
func can_perform(_source: Dictionary, _target: Dictionary) -> bool:
	return true

## 执行逻辑：返回包含状态和描述的字典
func execute(source: Dictionary, target: Dictionary) -> Dictionary:
	return {
		"status": "success", 
		"msg": "%s 对 %s 执行了动作。" % [source.data.name, target.data.name]
	}
