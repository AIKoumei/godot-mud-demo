## res://mods/MudEntityInteractionSystem/MudMapEntityFactory.gd
class_name MudMapEntityFactory

## 生成最基础的 Entity 字典结构
static func create_base_entity(name: String, type: String) -> Dictionary:
	return {
		"metadata": {
			"type": type,
			"version": "1.0",
			"created_at": Time.get_unix_time_from_system()
		},
		"data": {
			"name": name,
			"entity_type": "entity",
			"attributes": {
				"actions": {}, # 存放 action_id: bool
				"tags": {}     # 存放业务标签
			}
		}
	}

## 示例：生成一个带重写逻辑的角色
static func create_special_npc(name: String, override_action: String = "") -> Dictionary:
	var npc = create_base_entity(name, "character")
	if override_action != "":
		# 设置重写：当该 NPC 尝试 "open" 时，实际调用 "fast_open"
		npc.data.attributes["action_overrides"] = {"open": override_action}
	return npc
