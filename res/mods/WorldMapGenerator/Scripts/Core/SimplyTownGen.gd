# ============================================================
# SimplyTownGen.gd
# 节点图 + A* 路径生成 + BLOCKED + PATH + 可视化支持
# ============================================================

class_name SimplyTownGen
extends Object

# ------------------------------------------------------------
# 节点类型
# ------------------------------------------------------------
enum TownNodeType {
	EMPTY,
	CENTER,
	BUILDING,
	ROAD,
	OUTSKIRT,
	PATH,          # A* 生成的道路格子
	BLOCKED,       # 不可通行（噪声、障碍）
	OUTSKIRT_ROAD, # 郊外道路
	GATE,          # 城镇大门
}

# ------------------------------------------------------------
# 节点数据结构
# ------------------------------------------------------------
class TownNode:
	var id: int
	var node_type: int
	var name: String
	var pos: Vector2
	var neighbors: Array[int]

	func _init(_id: int, _type: int, _pos: Vector2, _name: String = ""):
		id = _id
		node_type = _type
		pos = _pos
		name = _name
		neighbors = []

# ------------------------------------------------------------
# 整个城镇的数据结构
# ------------------------------------------------------------
class SimplyTownData:
	var nodes: Array[TownNode] = []
	var center_id: int = -1

	func get_node(id: int) -> TownNode:
		for n in nodes:
			if n.id == id:
				return n
		return null

# ------------------------------------------------------------
# 渲染映射表（数值 + 颜色 + 道路评分）
# road_score 用来衡量“重要程度”，用于主干道/次干道判断
# ------------------------------------------------------------
static var NODE_RENDER_MAP = {
	"EMPTY": {
		"value": 0,
		"color": Color(0, 0, 0, 0),
		"road_score": 0,
	},

	TownNodeType.CENTER: {
		"value": 1,
		"color": Color(1.0, 0.0, 0.017, 1.0),
		"road_score": 3, # 非常重要
	},

	TownNodeType.BUILDING: {
		"value": 2,
		"color": Color(0.0, 0.167, 1.0, 1.0),
		"road_score": 2, # 一般重要建筑
	},

	TownNodeType.ROAD: {
		"value": 3,
		"color": Color(1.0, 0.6, 0.0, 1.0),
		"road_score": 1, # 普通城内道路
	},

	TownNodeType.OUTSKIRT: {
		"value": 4,
		"color": Color(0.0, 0.819, 0.994, 1.0),
		"road_score": 1, # 郊外区域
	},

	TownNodeType.PATH: {
		"value": 5,
		"color": Color(0.7, 0.7, 0.7),
		"road_score": 1, # A* 生成的普通道路
	},

	TownNodeType.BLOCKED: {
		"value": 6,
		"color": Color(0.2, 0.2, 0.2),
		"road_score": 0,
	},

	TownNodeType.OUTSKIRT_ROAD: {
		"value": 7,
		"color": Color(0.5, 0.5, 0.2, 1.0),
		"road_score": 1, # 郊外道路
	},

	TownNodeType.GATE: {
		"value": 8,
		"color": Color(1.0, 1.0, 0.3, 1.0),
		"road_score": 3, # 城镇大门，视为重要节点
	},
}

# ------------------------------------------------------------
# 城镇形状类型
# ------------------------------------------------------------
enum TownShapeType {
	CIRCLE,
	RECTANGLE,
	RADIAL_NET,
}

# ------------------------------------------------------------
# 主入口：生成城镇
# ------------------------------------------------------------
static func generate_town(
	shape_type,
	building_count: int = 8,
	branch_count: int = 3,
	seed: int = 12345
) -> SimplyTownData:
	var rng = RandomNumberGenerator.new()
	rng.seed = seed

	if not shape_type is int:
		shape_type = rng.randi() % TownShapeType.size()
	if branch_count < 2:
		branch_count = 2

	var data = SimplyTownData.new()

	# 1. 创建中心节点
	var center = TownNode.new(0, TownNodeType.CENTER, Vector2(0, 0), "TownCore")
	data.nodes.append(center)
	data.center_id = center.id
	var next_id = 1

	# 2. 根据形状生成城镇内部结构
	match shape_type:
		TownShapeType.CIRCLE:
			next_id = _generate_circle_town(data, rng, next_id, building_count)

		TownShapeType.RECTANGLE:
			next_id = _generate_rectangle_town(data, rng, next_id, building_count)

		TownShapeType.RADIAL_NET:
			next_id = _generate_radial_net_town(data, rng, next_id, building_count, branch_count)

	# 3. 生成郊外节点 + 大门 + 郊外道路
	_generate_outskirts(data, rng, next_id)

	return data

# ============================================================
# 圆形城镇
# ============================================================
static func _generate_circle_town(data, rng, start_id, building_count):
	var center = data.get_node(data.center_id)
	var radius = 10.0
	var road_radius = 5.0
	var id = start_id

	for i in range(building_count):
		var t = TAU * float(i) / float(max(1, building_count))

		var bx = cos(t) * radius
		var by = sin(t) * radius
		var rx = cos(t) * road_radius
		var ry = sin(t) * road_radius

		var road = TownNode.new(id, TownNodeType.ROAD, Vector2(rx, ry), "Road_%d" % id)
		data.nodes.append(road)
		var road_id = id
		id += 1

		var building = TownNode.new(id, TownNodeType.BUILDING, Vector2(bx, by), "Building_%d" % id)
		data.nodes.append(building)
		var building_id = id
		id += 1

		_connect_nodes(data, center.id, road_id)
		_connect_nodes(data, road_id, building_id)

	return id

# ============================================================
# 矩形城镇
# ============================================================
static func _generate_rectangle_town(data, rng, start_id, building_count):
	var center = data.get_node(data.center_id)
	var cols = int(ceil(sqrt(building_count)))
	var rows = int(ceil(float(building_count) / float(cols)))
	var spacing = 6.0
	var id = start_id

	var index = 0
	for y in range(rows):
		for x in range(cols):
			if index >= building_count:
				break
			index += 1

			var bx = (x - cols * 0.5 + 0.5) * spacing
			var by = (y - rows * 0.5 + 0.5) * spacing

			var road_pos = Vector2(bx, by).lerp(center.pos, 0.4)
			var road = TownNode.new(id, TownNodeType.ROAD, road_pos, "Road_%d" % id)
			data.nodes.append(road)
			var road_id = id
			id += 1

			var building = TownNode.new(id, TownNodeType.BUILDING, Vector2(bx, by), "Building_%d" % id)
			data.nodes.append(building)
			var building_id = id
			id += 1

			_connect_nodes(data, center.id, road_id)
			_connect_nodes(data, road_id, building_id)

	return id

# ============================================================
# 发散网状城镇
# ============================================================
static func _generate_radial_net_town(data, rng, start_id, building_count, branch_count):
	var center = data.get_node(data.center_id)
	var id = start_id

	branch_count = max(2, branch_count)
	var buildings_per_branch = max(1, building_count / branch_count)

	for b in range(branch_count):
		var angle = TAU * float(b) / float(branch_count)
		var branch_len = 12.0 + rng.randf_range(-2.0, 4.0)

		var prev_node_id = center.id

		for i in range(buildings_per_branch):
			var t = float(i + 1) / float(buildings_per_branch + 1)
			var dist = branch_len * t

			var rx = cos(angle) * dist
			var ry = sin(angle) * dist
			var road = TownNode.new(id, TownNodeType.ROAD, Vector2(rx, ry), "Road_%d" % id)
			data.nodes.append(road)
			var road_id = id
			id += 1

			var offset_angle = angle + rng.randf_range(-0.4, 0.4)
			var offset_dist = rng.randf_range(2.0, 4.0)
			var bx = rx + cos(offset_angle) * offset_dist
			var by = ry + sin(offset_angle) * offset_dist
			var building = TownNode.new(id, TownNodeType.BUILDING, Vector2(bx, by), "Building_%d" % id)
			data.nodes.append(building)
			var building_id = id
			id += 1

			_connect_nodes(data, prev_node_id, road_id)
			_connect_nodes(data, road_id, building_id)

			prev_node_id = road_id

	return id

# ============================================================
# 郊外生成：Road → Gate → Outskirt（郊外道路）
# ============================================================
static func _generate_outskirts(data, rng, start_id):
	var id = start_id
	var road_ids = []

	for n in data.nodes:
		if n.node_type == TownNodeType.ROAD:
			road_ids.append(n.id)

	if road_ids.is_empty():
		return

	var exit_count = max(2, road_ids.size() / 3)
	road_ids.shuffle()

	for i in range(exit_count):
		var road_id = road_ids[i]
		var road = data.get_node(road_id)
		if road == null:
			continue

		var center = data.get_node(data.center_id)
		var dir = (road.pos - center.pos).normalized()
		var out_pos = road.pos + dir * 8.0

		# 1. 创建郊外节点
		var out_node = TownNode.new(id, TownNodeType.OUTSKIRT, out_pos, "Outskirt_%d" % id)
		data.nodes.append(out_node)
		var out_id = id
		id += 1

		# 2. 在 road 和 outskirt 中间创建大门节点
		var gate_pos = road.pos.lerp(out_pos, 0.5)
		var gate = TownNode.new(id, TownNodeType.GATE, gate_pos, "Gate_%d" % id)
		data.nodes.append(gate)
		var gate_id = id
		id += 1

		# 3. 连接：road ↔ gate ↔ outskirt
		_connect_nodes(data, road_id, gate_id)
		_connect_nodes(data, gate_id, out_id)

# ============================================================
# 道路评分 & 道路等级判定
# ============================================================
static func _road_score_for_node(n: TownNode) -> int:
	if NODE_RENDER_MAP.has(n.node_type):
		return NODE_RENDER_MAP[n.node_type].get("road_score", 0)
	return 0

static func _classify_road_between(a: TownNode, b: TownNode) -> String:
	# OUTSKIRT 相关的边视为郊外道路
	if (a.node_type == TownNodeType.GATE and b.node_type == TownNodeType.OUTSKIRT) \
	or (b.node_type == TownNodeType.GATE and a.node_type == TownNodeType.OUTSKIRT):
		return "OUTSKIRT"

	var sa = _road_score_for_node(a)
	var sb = _road_score_for_node(b)

	var important_a = sa >= 2
	var important_b = sb >= 2

	if important_a and important_b:
		return "MAIN"      # 主干道
	elif important_a != important_b:
		return "SECONDARY" # 次干道
	else:
		return "LOCAL"     # 普通道路

static func _path_width_for_road_type(road_type: String) -> int:
	match road_type:
		"MAIN":
			return 5
		"SECONDARY":
			return 3
		"OUTSKIRT":
			return 3
		"LOCAL":
			return 2
		_:
			return 2

# ------------------------------------------------------------
# 工具：连接两个节点（返回道路等级）
# ------------------------------------------------------------
static func _connect_nodes(data, a_id, b_id) -> String:
	if a_id == b_id:
		return "LOCAL"

	var a = data.get_node(a_id)
	var b = data.get_node(b_id)
	if a == null or b == null:
		return "LOCAL"

	var road_type = _classify_road_between(a, b)

	if not a.neighbors.has(b_id):
		a.neighbors.append(b_id)
	if not b.neighbors.has(a_id):
		b.neighbors.append(a_id)

	return road_type

# ============================================================
# 转换为二维数组（节点）
# ============================================================
static func to_grid(data: SimplyTownData, cell_size: float = 1.0) -> Array:
	if data.nodes.is_empty():
		return []

	var min_x = _min_x(data)
	var max_x = _max_x(data)
	var min_y = _min_y(data)
	var max_y = _max_y(data)

	var w = int(ceil((max_x - min_x) / cell_size)) + 3
	var h = int(ceil((max_y - min_y) / cell_size)) + 3

	var grid = []
	grid.resize(w)
	for x in range(w):
		grid[x] = []
		grid[x].resize(h)
		for y in range(h):
			grid[x][y] = NODE_RENDER_MAP["EMPTY"]["value"]

	for n in data.nodes:
		var gx = int((n.pos.x - min_x) / cell_size) + 1
		var gy = int((n.pos.y - min_y) / cell_size) + 1

		if gx >= 0 and gx < w and gy >= 0 and gy < h:
			grid[gx][gy] = NODE_RENDER_MAP[n.node_type]["value"]

	return grid

# ============================================================
# A* 路径生成
# ============================================================
static func in_bounds(w, h, p: Vector2i) -> bool:
	return p.x >= 0 and p.x < w and p.y >= 0 and p.y < h

static func is_walkable(walkable, p: Vector2i) -> bool:
	return walkable[p.x][p.y]

static func _astar(start: Vector2i, goal: Vector2i, walkable: Array) -> Array:
	var w = walkable.size()
	var h = walkable[0].size()

	var open = {}
	var closed = {}
	var came_from = {}

	var g = {}
	var f = {}

	open[start] = true
	g[start] = 0
	f[start] = start.distance_to(goal)

	while open.size() > 0:
		var current = null
		var best_f = INF

		for p in open.keys():
			var fs = f.get(p, INF)
			if fs < best_f:
				best_f = fs
				current = p

		if current == goal:
			var path = []
			var c = current
			while came_from.has(c):
				path.append(c)
				c = came_from[c]
			path.append(start)
			path.reverse()
			return path

		open.erase(current)
		closed[current] = true

		for dir in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
			var nb = current + dir

			if not in_bounds(w, h, nb):
				continue
			if not is_walkable(walkable, nb):
				continue
			if closed.has(nb):
				continue

			var tentative = g[current] + 1

			if not open.has(nb) or tentative < g.get(nb, INF):
				came_from[nb] = current
				g[nb] = tentative
				f[nb] = tentative + nb.distance_to(goal)
				open[nb] = true

	return []

# ============================================================
# 写入带宽度的 PATH
# ============================================================
static func _write_path_with_width(grid, path: Array, width: int):
	if path.is_empty():
		return

	var w = grid.size()
	var h = grid[0].size()
	var r = int(width / 2)

	for p in path:
		for dx in range(-r, r + 1):
			for dy in range(-r, r + 1):
				var px = p.x + dx
				var py = p.y + dy
				if px >= 0 and px < w and py >= 0 and py < h:
					if grid[px][py] == NODE_RENDER_MAP["EMPTY"]["value"]:
						grid[px][py] = NODE_RENDER_MAP[TownNodeType.PATH]["value"]

# ============================================================
# 转换为二维数组（包含 PATH）
# ============================================================
static func to_grid_with_paths(data: SimplyTownData, cell_size: float = 1.0) -> Array:
	var grid = to_grid(data, cell_size)

	var w = grid.size()
	var h = grid[0].size()

	# 1. walkable_mask（BUILDING 和 BLOCKED 不可通行）
	var walkable_mask = []
	walkable_mask.resize(w)
	for x in range(w):
		walkable_mask[x] = []
		walkable_mask[x].resize(h)
		for y in range(h):
			var val = grid[x][y]

			walkable_mask[x][y] = (
				val != NODE_RENDER_MAP[TownNodeType.BUILDING]["value"]
				and val != NODE_RENDER_MAP[TownNodeType.BLOCKED]["value"]
			)

	# 2. 节点坐标映射
	var min_x = _min_x(data)
	var min_y = _min_y(data)

	var node_pos = {}
	for n in data.nodes:
		var gx = int((n.pos.x - min_x) / cell_size) + 1
		var gy = int((n.pos.y - min_y) / cell_size) + 1
		node_pos[n.id] = Vector2i(gx, gy)

	# 3. A* 生成路径 + 按道路等级写入不同宽度的 PATH
	for n in data.nodes:
		for nb_id in n.neighbors:
			var other = data.get_node(nb_id)
			if other == null:
				continue

			var road_type = _classify_road_between(n, other)
			var width = _path_width_for_road_type(road_type)

			var a = node_pos[n.id]
			var b = node_pos[nb_id]

			var path = _astar(a, b, walkable_mask)
			_write_path_with_width(grid, path, width)

	# 4. 自动填补道路：如果一个空格子上下左右都是道路/路径，则也变成道路
	for x in range(1, w - 1):
		for y in range(1, h - 1):
			var val = grid[x][y]
			if val != NODE_RENDER_MAP["EMPTY"]["value"]:
				continue

			var up    = grid[x][y - 1]
			var down  = grid[x][y + 1]
			var left  = grid[x - 1][y]
			var right = grid[x + 1][y]

			var is_road_up    = up    == NODE_RENDER_MAP[TownNodeType.ROAD]["value"] or up    == NODE_RENDER_MAP[TownNodeType.PATH]["value"]
			var is_road_down  = down  == NODE_RENDER_MAP[TownNodeType.ROAD]["value"] or down  == NODE_RENDER_MAP[TownNodeType.PATH]["value"]
			var is_road_left  = left  == NODE_RENDER_MAP[TownNodeType.ROAD]["value"] or left  == NODE_RENDER_MAP[TownNodeType.PATH]["value"]
			var is_road_right = right == NODE_RENDER_MAP[TownNodeType.ROAD]["value"] or right == NODE_RENDER_MAP[TownNodeType.PATH]["value"]

			if is_road_up and is_road_down and is_road_left and is_road_right:
				grid[x][y] = NODE_RENDER_MAP[TownNodeType.ROAD]["value"]

	return grid

# ============================================================
# 转换为颜色二维数组（包含 PATH）
# ============================================================
static func to_color_grid_with_paths(data: SimplyTownData, cell_size: float = 1.0) -> Array:
	var grid = to_grid_with_paths(data, cell_size)
	var w = grid.size()
	var h = grid[0].size()

	var color_grid = []
	color_grid.resize(w)

	for x in range(w):
		color_grid[x] = []
		color_grid[x].resize(h)

		for y in range(h):
			var val = grid[x][y]
			var node_type = _value_to_node_type(val)
			color_grid[x][y] = NODE_RENDER_MAP[node_type]["color"]

	return color_grid

# ============================================================
# 转换为颜色二维数组（不含 PATH，纯节点）
# ============================================================
static func to_color_grid(data: SimplyTownData, cell_size: float = 1.0) -> Array:
	var grid = to_grid(data, cell_size)
	var w = grid.size()
	var h = grid[0].size()

	var color_grid = []
	color_grid.resize(w)

	for x in range(w):
		color_grid[x] = []
		color_grid[x].resize(h)

		for y in range(h):
			var val = grid[x][y]
			var node_type = _value_to_node_type(val)
			color_grid[x][y] = NODE_RENDER_MAP[node_type]["color"]

	return color_grid

# ============================================================
# 辅助函数
# ============================================================
static func _value_to_node_type(val: int):
	for key in NODE_RENDER_MAP.keys():
		if NODE_RENDER_MAP[key]["value"] == val:
			return key
	return "EMPTY"

static func _min_x(data):
	var v = INF
	for n in data.nodes:
		v = min(v, n.pos.x)
	return v

static func _max_x(data):
	var v = -INF
	for n in data.nodes:
		v = max(v, n.pos.x)
	return v

static func _min_y(data):
	var v = INF
	for n in data.nodes:
		v = min(v, n.pos.y)
	return v

static func _max_y(data):
	var v = -INF
	for n in data.nodes:
		v = max(v, n.pos.y)
	return v
