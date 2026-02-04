## res://mods/WorldMapManager/Scripts/Core/MudMapGenerator.gd
## --------------------------------------------------------------------------
## MudMapGenerator
## --------------------------------------------------------------------------
extends RefCounted
class_name MudMapGenerator

# --------------------------------------------------------------------------
# I. 静态定义 (Static Definitions)
# --------------------------------------------------------------------------

const BUILDING_TYPES = {
	"item_shop": {
		"name": "道具商店",
		"required": {
			"entity_type": { "shopkeeper": {}, "vending_machine": {} },
			"entity": {} 
		}
	},
	"equipment_shop": {
		"name": "装备商店",
		"required": {
			"entity_type": { "blacksmith": {} },
			"entity": {}
		}
	},
	"quest_center": {
		"name": "任务中心",
		"required": {
			"entity_type": { "quest_master": {} },
			"entity": {}
		}
	},
	"training_center": {
		"name": "训练中心",
		"required": {
			"entity_type": { "trainer": {} },
			"entity": {}
		}
	},
	"home_shop": {
		"name": "家园商店",
		"required": {
			"entity_type": { "interior_designer": {} },
			"entity": {}
		}
	},
	"home": {
		"name": "家园",
		"required": { "entity_type": {}, "entity": {} }
	},
	"union_room": {
		"name": "联盟大厅",
		"required": { "entity_type": {}, "entity": {} }
	}
}

const ENTITY_DEFINITIONS = {
	"entity": {"desc": "默认对象类型"},
	"building": {"desc": "静态建筑结构"},
	"item": {"desc": "可交互物品"},
	"character": {"desc": "生物/人类实体"},
	
	"player": {"desc": "玩家", "type": "character"},
	"npc": {"desc": "NPC", "type": "character"},
	"shopkeeper": {"name": "店主", "type": "character"},
	"quest_master": {"name": "任务大师", "type": "character"},
	"blacksmith": {"name": "铁匠", "type": "character"},
	"trainer": {"name": "教官", "type": "character"},
	"vending_machine": {"name": "自动售货机", "type": "item"},
	"interior_designer": {"name": "家园设计师", "type": "character"}
}

const TYPE_BELONGS_TO = {
	"player": {"character": true},
	"npc": {"character": true},
	"shopkeeper": {"character": true},
	"quest_master": {"character": true},
	"blacksmith": {"character": true},
	"trainer": {"character": true},
	"vending_machine": {"item": true},
	"interior_designer": {"character": true}
}

# --------------------------------------------------------------------------
# II. 核心查询接口
# --------------------------------------------------------------------------

static func is_entity_type(target_type: String, category_type: String) -> bool:
	if target_type == category_type: return true
	var current = target_type
	while TYPE_BELONGS_TO.has(current):
		var parents = TYPE_BELONGS_TO[current]
		if parents.has(category_type): return true
		current = parents.keys()[0]
	return false

# --------------------------------------------------------------------------
# III. 主生成流
# --------------------------------------------------------------------------

static func generate_refined_map(map_data: Dictionary, world_seed: int = -1) -> Dictionary:
	var final_seed = world_seed if world_seed != -1 else _get_default_seed()
	var map_id = map_data.get("metadata", {}).get("map_id", "unknown_map")
	var refined = map_data.duplicate(true)
	var data = refined.get("data", {})
	
	_process_blocks_layer(data, final_seed, map_id)
	_process_rooms_layer(data, final_seed, map_id)
	
	return refined

# --------------------------------------------------------------------------
# IV. 填充逻辑实现
# --------------------------------------------------------------------------

static func _process_blocks_layer(data: Dictionary, seed_val: int, map_id: String) -> void:
	for block_id in data.get("blocks", {}):
		var block_node = data.blocks[block_id]
		# block.entities 现在存储的是 {"x,y": [pending_data, ...]}
		if not block_node.has("entities"): block_node["entities"] = {}
		var rng = _prepare_rng(seed_val, map_id, block_id)
		_populate_block_logic(block_id, block_node, rng, data)

static func _populate_block_logic(_id: String, block_node: Dictionary, rng: RandomNumberGenerator, _data: Dictionary) -> void:
	var types = BUILDING_TYPES.keys()
	var type_key = types[rng.randi() % types.size()]
	var type_info = BUILDING_TYPES[type_key]
	
	block_node["building_type"] = type_key
	block_node["building_name"] = type_info.get("name", "未知建筑")
	block_node["required"] = type_info.get("required", {}).duplicate(true)
	
	_distribute_requirements_to_rooms(block_node, block_node["required"], rng)

static func _distribute_requirements_to_rooms(block_node: Dictionary, reqs: Dictionary, rng: RandomNumberGenerator) -> void:
	var nodes = block_node.nodes.keys()
	if nodes.is_empty(): return
	
	var type_reqs = reqs.get("entity_type", {})
	for ent_type_id in type_reqs:
		_assign_pending_entity(block_node, nodes.pick_random(), ent_type_id, type_reqs[ent_type_id], true)
		
	var inst_reqs = reqs.get("entity", {})
	for ent_inst_id in inst_reqs:
		_assign_pending_entity(block_node, nodes.pick_random(), ent_inst_id, inst_reqs[ent_inst_id], false)

## 辅助方法：向 block.entities 写入待处理任务
static func _assign_pending_entity(block_node: Dictionary, room_id: String, id: String, extra_data: Dictionary, is_type: bool) -> void:
	# 初始化该格子的任务列表
	if not block_node.entities.has(room_id):
		block_node.entities[room_id] = []
	
	# 追溯 category 仅作为辅助参考，不覆盖原本的 entity_type (即参数 id)
	var category = "unknown"
	if is_type:
		category = ENTITY_DEFINITIONS.get(id, {}).get("type", "unknown")
	
	# 推送任务到该格子的任务数组中
	block_node.entities[room_id].append({
		"id": id,
		"category": category,
		"data": extra_data,
		"is_template_type": is_type
	})

static func _process_rooms_layer(data: Dictionary, seed_val: int, map_id: String) -> void:
	for room_id in data.get("rooms", {}):
		var room_node = data.rooms[room_id]
		# room.entities 结构：{"entity_instance_id": { ... }}
		if not room_node.has("entities"): room_node["entities"] = {}
		var rng = _prepare_rng(seed_val, map_id, room_id)
		_populate_room_logic(room_id, room_node, rng, data)

static func _populate_room_logic(room_id: String, room_node: Dictionary, rng: RandomNumberGenerator, data: Dictionary) -> void:
	var attrs = room_node.get("attributes", {})
	var parent_id = attrs.get("parent_block_id", "")
	if parent_id == "" or not data.blocks.has(parent_id): return
	
	var parent_block = data.blocks[parent_id]
	# 检查该坐标是否有待处理的实体任务列表
	if parent_block.entities.has(room_id):
		var pending_list = parent_block.entities[room_id]
		
		# 遍历列表，将所有任务实例化到 room.entities 中
		for pending in pending_list:
			# 使用复合 key (entity_type + instance_id) 确保格子内唯一性
			var instance_id = "ent_%d_%d" % [rng.randi() % 10000, hash(room_id) % 10000]
			
			room_node.entities[instance_id] = {
				"entity_type": pending.id, # 保持原始 entity_type，如 shopkeeper
				"category": pending.category, # 追溯的大类信息
				"data": pending.data,
				"id": instance_id, # 实例化的 ID
				"display_name": ENTITY_DEFINITIONS.get(pending.id, {}).get("name", pending.id),
				"is_template_type": pending.is_template_type
			}

# --------------------------------------------------------------------------
# V. 工具方法
# --------------------------------------------------------------------------

static func _prepare_rng(base_seed: int, map_id: String, identifier: String) -> RandomNumberGenerator:
	var rng = RandomNumberGenerator.new()
	rng.seed = base_seed ^ (hash(map_id) + hash(identifier))
	return rng

static func _get_default_seed() -> int:
	if Engine.has_meta("GameCore"):
		var core = Engine.get_meta("GameCore")
		if core.has("Settings"):
			return core.Settings.GameSettings.WorldSeed
	return 12345
