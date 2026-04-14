extends RefCounted
class_name MudMapConverter

## 方向常量定义
const DIRECTIONS = {
	"north": Vector2i(0, -1),
	"south": Vector2i(0, 1),
	"east": Vector2i(1, 0),
	"west": Vector2i(-1, 0)
}

const OPPOSITE = {
	"north": "south",
	"south": "north",
	"east": "west",
	"west": "east"
}

## 主转换入口
## @param raw_dict: 传入的原始地图字典
## 主转换入口
static func convert(raw_dict: Dictionary) -> Dictionary:
	var map_info = raw_dict.get("map_data", {})
	var rooms = {}
	var blocks_map = {} # 改为字典形式存储
	
	# 1. 基础节点初始化
	var mask = map_info.get("mask", {})
	for coords_str in mask:
		rooms[coords_str] = _create_base_node(coords_str, map_info)
	
	# 2. 建立道路内部连通
	_connect_main_roads(rooms, map_info)
	
	# 3. 处理建筑块逻辑 (返回整理后的 blocks 字典)
	blocks_map = _process_all_blocks(rooms, map_info)
	
	# 4. 处理特殊功能节点
	_process_special_points(rooms, map_info)

	# 5. 生成最终数据包
	return {
		"metadata": {
			"version": "1.1",
			"map_id": raw_dict.get("name", "unknown").to_snake_case(),
			"map_name": raw_dict.get("name", "Unknown Map"),
			"generated_at": Time.get_datetime_string_from_system(),
			"grid_bounds": _calculate_bounds(mask)
		},
		"data": {
			"rooms": rooms,
			"blocks": blocks_map # 现在是 { "block_0": {...}, "block_1": {...} }
		}
	}


# ---------------------------------------------------------
# 内部处理核心逻辑
# ---------------------------------------------------------

## 初始化节点基础数据
static func _create_base_node(id: String, map_info: Dictionary) -> Dictionary:
	var type = "ground"
	var desc = "这里是一片普通的平地。"
	
	if map_info.main_road.has(id):
		type = "road"
		desc = "这是一条平整的主干道，通向城镇各处。"
	elif map_info.get("secondary_roads",{}).has(id):
		type = "secondary_road"
		desc = "这是一条次要道路，连接着城镇的各个区域。"
	elif map_info.edge.has(id):
		type = "wall"
		desc = "一堵高耸的金属墙壁挡住了去路。"
	
	return {
		"type": type,
		"title": "未命名区域",
		"description": desc,
		"exits": {},
		"attributes": {
			#"color": "#ffffff",
			#"is_safe_zone": false,
			#"terrain_cost": 1.0
		}
	}

## 建立道路的全连通网络
static func _connect_main_roads(rooms: Dictionary, map_info: Dictionary):
	# 处理主干道
	var main_roads = map_info.main_road
	
	var center = map_info.get("center", {})
	var c_id = "%d,%d" % [int(center.get("x",0)), int(center.get("y",0))]
	
	for r_id in main_roads:
		if not rooms.has(r_id): continue
		var pos = _str_to_vec(r_id)
		
		for dir in DIRECTIONS:
			var target_pos = pos + DIRECTIONS[dir]
			var target_id = "%d,%d" % [target_pos.x, target_pos.y]
			
			# 主干道与相邻的主干道或次要道路连通
			if (main_roads.has(target_id) or (map_info.has("secondary_roads") and map_info.secondary_roads.has(target_id)) or target_id == c_id) and rooms.has(target_id):
				rooms[r_id].exits[dir] = target_id
	
	# 处理次要道路
	if map_info.has("secondary_roads"):
		var secondary_roads = map_info.secondary_roads
		for r_id in secondary_roads:
			if not rooms.has(r_id): continue
			var pos = _str_to_vec(r_id)
			
			for dir in DIRECTIONS:
				var target_pos = pos + DIRECTIONS[dir]
				var target_id = "%d,%d" % [target_pos.x, target_pos.y]
				
				# 次要道路与相邻的主干道或次要道路连通
				if (main_roads.has(target_id) or secondary_roads.has(target_id)) and rooms.has(target_id):
					rooms[r_id].exits[dir] = target_id

# ---------------------------------------------------------
# 内部处理核心逻辑
# ---------------------------------------------------------

## 处理所有建筑块
# ---------------------------------------------------------
# 内部处理核心逻辑
# ---------------------------------------------------------

## 处理所有建筑块
static func _process_all_blocks(rooms: Dictionary, map_info: Dictionary) -> Dictionary:
	var blocks_cfg = map_info.get("blocks", [])
	var processed_blocks = {}
	
	for i in range(blocks_cfg.size()):
		var b = blocks_cfg[i]
		var b_id = "block_%d" % i
		var rect = Rect2i(int(b.x), int(b.y), int(b.w), int(b.h))
		
		# 1. 记录该 block 包含的所有合法坐标
		var block_nodes = {}
		
		# A. 建筑内部格子处理
		for lx in range(rect.size.x):
			for ly in range(rect.size.y):
				var curr_pos = rect.position + Vector2i(lx, ly)
				var curr_id = "%d,%d" % [curr_pos.x, curr_pos.y]
				
				if not rooms.has(curr_id): continue
				
				block_nodes[curr_id] = true
				rooms[curr_id].type = "block"
				rooms[curr_id].attributes["parent_block_id"] = b_id
				rooms[curr_id].attributes["color"] = _color_to_hex(b.color)
				
				# 内部连通逻辑
				for dir in DIRECTIONS:
					var next_pos = curr_pos + DIRECTIONS[dir]
					if rect.has_point(next_pos):
						var next_id = "%d,%d" % [next_pos.x, next_pos.y]
						if rooms.has(next_id):
							rooms[curr_id].exits[dir] = next_id

		# B. 执行开口算法 (保持原有的 rooms 连通修改)
		_generate_block_exits(rect, rooms, map_info)
		
		# C. 以 ID 为键存入字典
		processed_blocks[b_id] = {
			"w": b.w,
			"h": b.h,
			"pos": {"x": b.x, "y": b.y},
			"nodes": block_nodes # {"x,y": true, ...}
		}
		
	return processed_blocks

## 随机开口算法：先抽边，再抽格子
static func _generate_block_exits(rect: Rect2i, rooms: Dictionary, map_info: Dictionary):
	var street_facing_sides: Dictionary = {} # 存放临街的边
	var all_valid_neighbors: Array = []      # 存放所有合法的邻居（用于脱孤）
	
	for dir_name in DIRECTIONS:
		var offset = DIRECTIONS[dir_name]
		var candidates_on_side: Array = []
		
		# 遍历该方向边缘的所有格子
		for i in range(rect.size.x if offset.y != 0 else rect.size.y):
			var cell_pos: Vector2i
			if offset.y != 0:
				cell_pos = rect.position + Vector2i(i, 0 if offset.y < 0 else rect.size.y - 1)
			else:
				cell_pos = rect.position + Vector2i(0 if offset.x < 0 else rect.size.x - 1, i)
			
			var from_id = "%d,%d" % [cell_pos.x, cell_pos.y]
			var target_pos = cell_pos + offset
			var to_id = "%d,%d" % [target_pos.x, target_pos.y]
			
			# 核心：确保起始点和目标点都在合法坐标内 (mask内)
			if rooms.has(from_id) and rooms.has(to_id):
				var pair = {"from": from_id, "to": to_id, "dir": dir_name}
				all_valid_neighbors.append(pair)
				
				# 记录临街边（包括主干道和次要道路）
				if map_info.main_road.has(to_id) or map_info.get("secondary_roads",{}).has(to_id):
					if not street_facing_sides.has(dir_name):
						street_facing_sides[dir_name] = []
					street_facing_sides[dir_name].append(pair)

	# 决策：
	# 2. 决策阶段：处理临街的边
	if not street_facing_sides.is_empty():
		var side_names = street_facing_sides.keys()
		side_names.shuffle()
		
		# --- 核心修改点：决定开几扇门 ---
		# 方案：随机选择 1 到 N 条边，N 为临街边的总数
		# 如果你想让多门概率低一点，可以使用 randf() 判定
		var max_doors = side_names.size()
		var num_to_open = 1 # 默认至少开一扇
		
		# 示例逻辑：30% 的概率尝试多开一扇门
		if max_doors > 1 and randf() < 0.3:
			num_to_open = 2
		
		# 确保不会超过实际拥有的临街边数量
		num_to_open = min(num_to_open, max_doors)
		
		# 依次处理选中的每一条边
		for i in range(num_to_open):
			var current_side = side_names[i]
			var candidates = street_facing_sides[current_side]
			var final_pair = candidates.pick_random()
			_apply_connection(final_pair, rooms, "block_entrance")
		
		return
	elif not all_valid_neighbors.is_empty():
		# 2. 孤岛保底：随机找个邻居建立“暗道”
		var forced_pair = all_valid_neighbors.pick_random()
		_apply_connection(forced_pair, rooms, "block_entrance")
		rooms[forced_pair.from].description += " 这里有一处极其隐蔽的窄门。"

## 特殊节点处理
static func _process_special_points(rooms: Dictionary, map_info: Dictionary):
	var center = map_info.get("center", {})
	var c_id = "%d,%d" % [int(center.get("x",0)), int(center.get("y",0))]
	if rooms.has(c_id):
		rooms[c_id].type = "center"
		rooms[c_id].title = "城镇中心"
		rooms[c_id].attributes["is_safe_zone"] = true
			
		var pos = _str_to_vec(c_id)
		
		for dir in DIRECTIONS:
			var target_pos = pos + DIRECTIONS[dir]
			var target_id = "%d,%d" % [target_pos.x, target_pos.y]
			
			# 次要道路与相邻的主干道或次要道路连通
			if (map_info.get("main_road", {}).has(target_id) or map_info.get("secondary_roads", {}).has(target_id)) and rooms.has(target_id):
				rooms[c_id].exits[dir] = target_id
	
	for g_id in map_info.get("gate", {}):
		if rooms.has(g_id):
			rooms[g_id].type = "gate"
			rooms[g_id].title = "城门"
			rooms[g_id].attributes["is_safe_zone"] = true

# ---------------------------------------------------------
# 工具方法
# ---------------------------------------------------------

static func _apply_connection(data: Dictionary, rooms: Dictionary, type_override: String):
	rooms[data.from].type = type_override
	rooms[data.from].exits[data.dir] = data.to
	rooms[data.to].exits[OPPOSITE[data.dir]] = data.from

static func _str_to_vec(s: String) -> Vector2i:
	var p = s.split(",")
	return Vector2i(int(p[0]), int(p[1]))

static func _color_to_hex(c: Dictionary) -> String:
	return Color(c.get("r",1), c.get("g",1), c.get("b",1), c.get("a",1)).to_html()

static func _calculate_bounds(mask: Dictionary) -> Dictionary:
	if mask.is_empty(): return {"min_x":0, "max_x":0, "min_y":0, "max_y":0}
	var xs = []; var ys = []
	for k in mask:
		var v = _str_to_vec(k)
		xs.append(v.x); ys.append(v.y)
	return {"min_x":xs.min(), "max_x":xs.max(), "min_y":ys.min(), "max_y":ys.max()}
