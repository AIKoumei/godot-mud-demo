class_name SimplyMudTownGen
extends Object

# ============================================================
# 节点类型
# ============================================================
enum NodeType {
	CENTER,
	WALL,
	DEL_WALL,
	START_WALL,
	END_WALL,
	PATCH_WALL,
	MAIN_ROAD,
	SECONDARY_ROADS,
	GATE,
	GATE_WALL,
}

class TownNode:
	var id: int
	var type: int
	var pos: Vector2i

	func _init(_id: int, _type: int, _pos: Vector2i):
		id = _id
		type = _type
		pos = _pos


# ============================================================
# TownData：统一保存所有生成层
# ============================================================
class SimplyMudTownData:
	var nodes: Dictionary
	var center: Vector2i
	var start_wall: Vector2i
	var end_wall: Vector2i

	var mask: Dictionary
	var edge: Dictionary
	var patched_edge: Dictionary
	var delete_wall: Dictionary
	var main_road: Dictionary
	var secondary_roads: Dictionary
	var gate: Dictionary
	var gate_wall: Dictionary
	var blocks: Array

	func _init():
		nodes = {}
		mask = {}
		edge = {}
		patched_edge = {}
		delete_wall = {}
		main_road = {}
		secondary_roads = {}
		gate = {}
		gate_wall = {}
		blocks = []


# ============================================================
# 颜色映射
# ============================================================
static var NODE_COLOR = {
	NodeType.CENTER: Color(1.0, 0.0, 0.0),
	NodeType.WALL: Color(0.35, 0.35, 0.35),
	NodeType.DEL_WALL: Color(1.0, 1.0, 1.0),
	NodeType.START_WALL: Color(0.0, 0.0, 0.0),
	NodeType.END_WALL: Color(0.6, 0.6, 0.6),
	NodeType.PATCH_WALL: Color(0.0, 1.0, 0.0),
	NodeType.MAIN_ROAD: Color(0.0, 0.4, 0.0),
	NodeType.SECONDARY_ROADS: Color(0.0, 0.5, 0.2),
	NodeType.GATE: Color(1.0, 0.0, 0.0),
	NodeType.GATE_WALL: Color(1.0, 0.2, 0.2),
}

static var noise := FastNoiseLite.new()

static var dir4 = [Vector2i(-1,0),Vector2i(1,0),Vector2i(0,-1),Vector2i(0,1)]

# ============================================================
# 配置生成
# ============================================================
static func gen_config(override: Dictionary = {}) -> Dictionary:
	var rng = RandomNumberGenerator.new()
	rng.randomize()

	var cfg = {
		"size_type": ["SMALL", "MEDIUM", "LARGE"][rng.randi_range(0, 2)],
		"shape_type": ["CIRCLE", "RECT"][rng.randi_range(0, 1)],
		"irregularity": rng.randf_range(0.0, 0.6),
		"smoothness": rng.randf_range(0.0, 1.0),
		"seed": randi(),
	}

	for k in override.keys():
		cfg[k] = override[k]

	return cfg


# ============================================================
# 主入口：生成城镇
# ============================================================
static func generate_town(cfg: Dictionary) -> SimplyMudTownData:
	var data = SimplyMudTownData.new()

	var rng = RandomNumberGenerator.new()
	rng.seed = cfg["seed"]

	noise.seed = cfg["seed"]
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = lerp(0.02, 0.08, cfg["smoothness"])

	var size: Vector2i = _pick_town_size(String(cfg["size_type"]), rng)
	var w: int = size.x
	var h: int = size.y

	# 1. mask
	var mask: Dictionary = _generate_contour_mask(cfg, w, h)
	_scanline_connect(mask, w, h)
	data.mask = mask

	# 2. center
	var center: Vector2i = _pick_center(mask, w, h)
	data.center = center

	# 3. edge
	var edge_points: Array = _find_edge_points(mask)

	# 4. main road
	var road_data = generate_main_roads(center, mask, edge_points)
	var main_road_set: Dictionary = road_data["main_road_set"]
	var gate_set: Dictionary = road_data["gate_set"]

	data.main_road = main_road_set.duplicate()
	data.gate = gate_set.duplicate()

	# 5. gate wall
	var gate_outdoor_set := {}
	var gate_wall_set := {}

	for gate_pos in gate_set.keys():
		var outdoor_pos = _adjust_gate_mask(gate_pos, main_road_set, mask, gate_wall_set)
		if outdoor_pos != null:
			gate_outdoor_set[outdoor_pos] = true

	data.gate_wall = gate_wall_set.duplicate()

	# 6. patched edge
	var patched = patch_walls(_find_edge_points(mask), gate_outdoor_set)
	var edge_set: Dictionary = patched["edge_set"]
	var patch_set: Dictionary = patched["patch_set"]

	data.edge = edge_set.duplicate()
	data.patched_edge = patch_set.duplicate()
	mask.merge(patch_set)

	# 7. loop detection
	var loop_data = find_wall_loop(edge_set, center)
	var loop: Array = loop_data["loop"]
	var delete_set: Dictionary = loop_data["delete_set"]
	for _del in delete_set.keys():
		edge_set.erase(_del)
		# 删除外围需要 delete 的围墙
		for _d in dir4:
			var _p = _del + _d
			if not mask.has(_p):
				mask.erase(_del)
	data.mask = mask.duplicate()
	data.delete_wall = delete_set.duplicate()
	data.edge = edge_set.duplicate()

			
	if loop.size() > 0:
		data.start_wall = loop[0]
		data.end_wall = loop[loop.size() - 1]
	else:
		data.start_wall = center
		data.end_wall = center

	# 8. build nodes
	var next_id = 0

	for pos in edge_set.keys():
		var t = NodeType.WALL

		if delete_set.has(pos):
			t = NodeType.DEL_WALL
		elif pos == data.start_wall:
			t = NodeType.START_WALL
		elif pos == data.end_wall:
			t = NodeType.END_WALL
		elif gate_wall_set.has(pos):
			t = NodeType.GATE_WALL
		elif patch_set.has(pos):
			t = NodeType.PATCH_WALL
		elif gate_set.has(pos):
			t = NodeType.GATE

		data.nodes[next_id] = TownNode.new(next_id, t, pos)
		next_id += 1

	for pos in data.delete_wall.keys():
		data.nodes[next_id] = TownNode.new(next_id, NodeType.DEL_WALL, pos)
		next_id += 1

	# center node
	data.nodes[next_id] = TownNode.new(next_id, NodeType.CENTER, center)
	next_id += 1

	# main road nodes
	for pos in main_road_set.keys():
		data.nodes[next_id] = TownNode.new(next_id, NodeType.MAIN_ROAD, pos)
		next_id += 1

	# 9. blocks（智能 block）
	var ban_point_set = {}
	ban_point_set.merge(data.gate)
	ban_point_set.merge(data.gate_wall)
	ban_point_set.merge(data.main_road)
	ban_point_set.merge(data.edge)
	var block_result = gen_blocks(data.mask, data.center, ban_point_set, data.main_road, data.edge)
	data.blocks = block_result.blocks
	data.secondary_roads = block_result.secondary_roads_set

	# secondary_roads nodes
	for pos in data.secondary_roads.keys():
		data.nodes[next_id] = TownNode.new(next_id, NodeType.SECONDARY_ROADS, pos)
		next_id += 1

	return data


# ============================================================
# 轮廓大小
# ============================================================
static func _pick_town_size(size_type: String, rng: RandomNumberGenerator) -> Vector2i:
	match size_type:
		"SMALL":
			return Vector2i(rng.randi_range(12, 18), rng.randi_range(12, 18))
		"MEDIUM":
			return Vector2i(rng.randi_range(20, 30), rng.randi_range(20, 30))
		"LARGE":
			return Vector2i(rng.randi_range(32, 48), rng.randi_range(32, 48))
		_:
			return Vector2i(20, 20)


# ============================================================
# mask 生成（RECT / CIRCLE）
# ============================================================
static func _generate_contour_mask(cfg: Dictionary, w: int, h: int) -> Dictionary:
	var mask: Dictionary = {}
	for x in range(w):
		for y in range(h):
			if _is_inside_shape(x, y, cfg, w, h):
				mask[Vector2i(x, y)] = true
	return mask


static func _is_inside_shape(x: int, y: int, cfg: Dictionary, w: int, h: int) -> bool:
	var irr: float = float(cfg["irregularity"])
	var shape: String = String(cfg["shape_type"])

	var n: float = (noise.get_noise_2d(x, y) + 1.0) * 0.5
	var deform: float = 1.0 - irr * n

	if shape == "RECT":
		var margin_x: int = int(w * 0.2 * deform)
		var margin_y: int = int(h * 0.2 * deform)
		return x >= margin_x and x < w - margin_x and y >= margin_y and y < h - margin_y

	var cx: float = w / 2.0
	var cy: float = h / 2.0
	var dx: float = float(x) - cx
	var dy: float = float(y) - cy
	var base_r: float = float(min(w, h)) * 0.5
	var r: float = base_r * deform

	return dx * dx + dy * dy <= r * r


# ============================================================
# center 选择
# ============================================================
static func _pick_center(mask: Dictionary, w: int, h: int) -> Vector2i:
	var cx: int = w / 2
	var cy: int = h / 2
	var center_pos: Vector2i = Vector2i(cx, cy)

	if mask.has(center_pos):
		return center_pos

	var best: Vector2i = center_pos
	var best_dist: float = INF

	for pos in mask.keys():
		var d: float = float(pos.distance_to(center_pos))
		if d < best_dist:
			best = pos
			best_dist = d

	return best


# ============================================================
# 扫描线闭合补丁
# ============================================================
static func _scanline_connect(mask: Dictionary, w: int, h: int) -> void:
	var prev_left = null
	var prev_right = null

	for y in range(h):
		var row_points: Array = []
		for x in range(w):
			var p = Vector2i(x, y)
			if mask.has(p):
				row_points.append(p)

		if row_points.size() < 1:
			continue

		var left = row_points[0]
		var right = row_points[row_points.size() - 1]

		if prev_left != null:
			if not _is_connected(mask, left, prev_left, [prev_right, right]):
				_fill_line(mask, left, prev_left)

			if not _is_connected(mask, right, prev_right, [prev_left, left]):
				_fill_line(mask, right, prev_right)

		if left != right:
			prev_left = left
			prev_right = right


static func _is_connected(mask: Dictionary, start: Vector2i, goal: Vector2i, forbidden_points: Array) -> bool:
	var queue: Array = [start]
	var visited := {}

	while queue.size() > 0:
		var p: Vector2i = queue.pop_front()
		if p == goal:
			return true

		if visited.has(p):
			continue
		visited[p] = true

		if p in forbidden_points:
			continue

		for d in [
			Vector2i(-1,-1), Vector2i(0,-1), Vector2i(1,-1),
			Vector2i(-1,0),  Vector2i(0,0),  Vector2i(1,0),
			Vector2i(-1,1),  Vector2i(0,1),  Vector2i(1,1)
		]:
			var np = p + d
			if mask.has(np) and not visited.has(np):
				queue.append(np)

	return false


static func _fill_line(mask: Dictionary, a: Vector2i, b: Vector2i) -> void:
	var dx = b.x - a.x
	var dy = b.y - a.y
	var steps = max(abs(dx), abs(dy))
	if steps == 0:
		mask[a] = true
		return

	for i in range(steps + 1):
		var t = float(i) / float(steps)
		var x = int(round(lerp(a.x, b.x, t)))
		var y = int(round(lerp(a.y, b.y, t)))
		mask[Vector2i(x, y)] = true


# ============================================================
# edge 查找
# ============================================================
static func _find_edge_points(mask: Dictionary) -> Array:
	var edges: Array = []
	var dirs: Array = [
		Vector2i(1,0), Vector2i(-1,0),
		Vector2i(0,1), Vector2i(0,-1)
	]

	for pos in mask.keys():
		for d in dirs:
			if not mask.has(pos + d):
				edges.append(pos)
				break

	return edges


# ============================================================
# 修补斜向墙体
# ============================================================
static func patch_walls(edge_points: Array, forbidden: Dictionary = {}) -> Dictionary:
	var edge_set := {}
	for p in edge_points:
		edge_set[p] = true

	var patch_set := {}

	var diag_dirs = [
		Vector2i(1,1), Vector2i(1,-1),
		Vector2i(-1,1), Vector2i(-1,-1)
	]

	for p in edge_points:
		for d in diag_dirs:
			var q = p + d
			if not edge_set.has(q):
				continue
			
			var need_patch = true
			for d4 in [Vector2i(d.x,0), Vector2i(0,d.y)]:
				need_patch = need_patch and not edge_set.has(p + d4)
			
			if not need_patch :
				continue

			var filler1 = Vector2i(p.x + d.x, p.y)
			var filler2 = Vector2i(p.x, p.y + d.y)

			if not forbidden.has(filler1):
				if not edge_set.has(filler1) and not patch_set.has(filler1):
					edge_set[filler1] = true
					patch_set[filler1] = true
			elif not forbidden.has(filler2):
				if not edge_set.has(filler2) and not patch_set.has(filler2):
					edge_set[filler2] = true
					patch_set[filler2] = true

	return {
		"edge_set": edge_set,
		"patch_set": patch_set
	}


# ============================================================
# 主干道生成
# ============================================================
static func generate_main_roads(center: Vector2i, mask: Dictionary, edge_points: Array) -> Dictionary:
	var main_road_set := {}
	var gate_set := {}

	var edge_raw := {}
	for p in edge_points:
		edge_raw[p] = true

	var dirs = [
		Vector2i(1,0),
		Vector2i(-1,0),
		Vector2i(0,1),
		Vector2i(0,-1),
	]

	for d in dirs:
		var p = center + d

		while true:
			if not mask.has(p):
				break

			if edge_raw.has(p):
				gate_set[p] = true
				break

			main_road_set[p] = true
			p += d

	for g in gate_set.keys():
		main_road_set.erase(g)

	return {
		"main_road_set": main_road_set,
		"gate_set": gate_set
	}


# ============================================================
# 城门九宫格 mask 调整
# ============================================================
static func _adjust_gate_mask(gate_pos: Vector2i, main_road_set: Dictionary, mask: Dictionary, gate_wall_set: Dictionary) -> Variant:
	var dirs_4 = [
		Vector2i(0,-1),
		Vector2i(-1, 0), Vector2i(1, 0),
		Vector2i(0, 1)
	]

	var outdoor_pos: Variant = null

	for d in dirs_4:
		var pos = gate_pos + d
		if main_road_set.has(pos):
			var road_dir = gate_pos - pos
			outdoor_pos = gate_pos + road_dir

			var perp1 = Vector2i(-road_dir.y, road_dir.x)
			var perp2 = Vector2i( road_dir.y,-road_dir.x)

			var gw1 = gate_pos + perp1
			var gw2 = gate_pos + perp2

			mask[gw1] = true
			mask[gw2] = true

			gate_wall_set[gw1] = true
			gate_wall_set[gw2] = true

			mask.erase(outdoor_pos)
			break

	return outdoor_pos


# ============================================================
# 回路检测 + 剪枝
# ============================================================
static func find_wall_loop(edge_set: Dictionary, center: Vector2i) -> Dictionary:
	var dirs = [
		Vector2i(1,0), Vector2i(-1,0),
		Vector2i(0,1), Vector2i(0,-1)
	]

	var visited := {}
	var parent := {}
	var loops: Array = []

	for start in edge_set.keys():
		if visited.has(start):
			continue

		var stack: Array = [start]
		parent[start] = null

		while stack.size() > 0:
			var pos: Vector2i = stack.pop_back()
			visited[pos] = true

			for d in dirs:
				var np = pos + d
				if not edge_set.has(np):
					continue

				if not visited.has(np):
					parent[np] = pos
					stack.append(np)
				elif parent[pos] != np:
					var loop: Array = []
					var cur: Variant = pos
					while cur != null and cur != np:
						loop.append(cur)
						cur = parent[cur]
					loop.append(np)
					loop.reverse()
					loops.append(loop)

	if loops.size() == 0:
		return {"loop": [], "delete_set": {}}

	var chosen: Array = loops[0]
	for loop in loops:
		if _point_in_polygon(center, loop):
			chosen = loop
			break

	var loop_set := {}
	for p in chosen:
		loop_set[p] = true

	var delete_set := {}
	for p in edge_set.keys():
		if not loop_set.has(p):
			delete_set[p] = true

	return {
		"loop": chosen,
		"delete_set": delete_set
	}


static func _point_in_polygon(pt: Vector2i, poly: Array) -> bool:
	var inside = false
	var j = poly.size() - 1
	for i in range(poly.size()):
		var pi: Vector2i = poly[i]
		var pj: Vector2i = poly[j]
		if ((pi.y > pt.y) != (pj.y > pt.y)) and \
			(pt.x < (pj.x - pi.x) * (pt.y - pi.y) / float(pj.y - pi.y) + pi.x):
			inside = not inside
		j = i
	return inside


# ============================================================
# 智能 block 生成
# ============================================================
static func gen_blocks(mask: Dictionary, center: Vector2i, ban_point_set: Dictionary, main_road_set: Dictionary, wall_set: Dictionary) -> Dictionary:
	var rects: Array = []
	var delay_pos_arr: Array = []
	var visited := {}
	
	var secondary_roads_set = {}

	# 计算每个格子到 center 的距离，用于排序（从近到远）
	var dist_center_map := {}
	for pos in mask.keys():
		if pos == center:
			continue
		if ban_point_set.has(pos):
			continue
		dist_center_map[pos] = pos.distance_to(center)

	var cells: Array = dist_center_map.keys()
	cells.sort_custom(func(a, b):
		return dist_center_map[a] < dist_center_map[b]
	)

	var rng = RandomNumberGenerator.new()
	rng.randomize()

	for pos in cells:
		if visited.has(pos):
			continue
		if pos == center:
			continue
		if ban_point_set.has(pos):
			continue

		var x = pos.x
		var y = pos.y

		# 从 center 指向当前点的方向向量（归一到 -1/0/1）
		var dir = pos - center
		var dir_x = 0 if dir.x == 0 else (1 if dir.x > 0 else -1)
		var dir_y = 0 if dir.y == 0 else (1 if dir.y > 0 else -1)

		# 根据距离 center 的远近决定最大尺寸（越近越大）
		var d_center = dist_center_map[pos]
		var max_d = 1.0
		for v in dist_center_map.values():
			max_d = max(max_d, float(v))
		var t = d_center / max_d
		var max_size = int(lerp(8.0, 2.0, t))
		max_size = max(2, max_size)

		var w = 1
		var h = 1

		for step in range(1, max_size):
			var xx = x + dir_x * step
			var yy = y + dir_y * step
			var block_pass = true
			if dir_x<0 and dir_y < 0:
				pass
			for _xx in range(x, xx+dir_x, dir_x):
				var p = Vector2i(_xx, yy)
				if not mask.has(p) or visited.has(p) or ban_point_set.has(p):
					block_pass = false
					break
			if not block_pass:
				break
			for _yy in range(y, yy+dir_y, dir_y):
				var p = Vector2i(xx, _yy)
				if not mask.has(p) or visited.has(p) or ban_point_set.has(p):
					block_pass = false
					break
			if not block_pass:
				break
			w += 1
			h += 1
			if dir_x<0 and dir_y < 0:
				pass
	
	
		if w > 1 and h > 1:
			# 标记 visited
			var x_min = x
			var y_min = y
			if dir_x < 0:
				x_min = x - (w - 1)
			if dir_y < 0:
				y_min = y - (h - 1)

			for xx in range(x_min, x_min + w):
				for yy in range(y_min, y_min + h):
					var p = Vector2i(xx, yy)
					if mask.has(p):
						visited[p] = true

			var color = Color(rng.randf_range(0.4,1), rng.randf_range(0.4,1), rng.randf_range(0.4,1))
			rects.append({
				"x": x_min,
				"y": y_min,
				"w": w,
				"h": h,
				"color": color,
			})
		
			# mark secondary road
			var _xx_end = x+w*dir_x
			var _yy_end = y+h*dir_y
			for _xx in range(x-dir_x, _xx_end+dir_x, dir_x):
				var p = Vector2i(_xx, _yy_end)
				if center == p:
					continue
				var nearby_road_count = 0
				var nearby_wall = false
				for _d in dir4:
					var _p = p + _d
					if wall_set.has(_p):
						nearby_wall = true
					if main_road_set.has(_p) or secondary_roads_set.has(_p):
						nearby_road_count += 1
				if nearby_wall and nearby_road_count > 1 or wall_set.has(p) or ban_point_set.has(p):
					continue
				visited[p] = true
				secondary_roads_set[p] = true
			for _xx in range(x-dir_x, _xx_end+dir_x, dir_x):
				var p = Vector2i(_xx, y-dir_y)
				if center == p:
					continue
				var nearby_road_count = 0
				var nearby_wall = false
				for _d in dir4:
					var _p = p + _d
					if wall_set.has(_p):
						nearby_wall = true
					if main_road_set.has(_p) or secondary_roads_set.has(_p):
						nearby_road_count += 1
				if nearby_wall and nearby_road_count > 1 or wall_set.has(p) or ban_point_set.has(p):
					continue
				visited[p] = true
				secondary_roads_set[p] = true
			for _yy in range(y-dir_y, _yy_end+dir_y, dir_y):
				var p = Vector2i(_xx_end, _yy)
				if center == p:
					continue
				var nearby_road_count = 0
				var nearby_wall = false
				for _d in dir4:
					var _p = p + _d
					if wall_set.has(_p):
						nearby_wall = true
					if main_road_set.has(_p) or secondary_roads_set.has(_p):
						nearby_road_count += 1
				if nearby_wall and nearby_road_count > 1 or wall_set.has(p) or ban_point_set.has(p):
					continue
				visited[p] = true
				secondary_roads_set[p] = true
			for _yy in range(y-dir_y, _yy_end+dir_y, dir_y):
				var p = Vector2i(x-dir_x, _yy)
				if center == p:
					continue
				var nearby_road_count = 0
				var nearby_wall = false
				for _d in dir4:
					var _p = p + _d
					if wall_set.has(_p):
						nearby_wall = true
					if main_road_set.has(_p) or secondary_roads_set.has(_p):
						nearby_road_count += 1
				if nearby_wall and nearby_road_count > 1 or wall_set.has(p) or ban_point_set.has(p):
					continue
				visited[p] = true
				secondary_roads_set[p] = true
		else:
			delay_pos_arr.append(pos)


	for pos in delay_pos_arr:
		if visited.has(pos):
			continue
		if pos == center:
			continue
		if ban_point_set.has(pos):
			continue

		var x = pos.x
		var y = pos.y

		# 从 center 指向当前点的方向向量（归一到 -1/0/1）
		var dir = pos - center
		var dir_x = 0 if dir.x == 0 else (1 if dir.x > 0 else -1)
		var dir_y = 0 if dir.y == 0 else (1 if dir.y > 0 else -1)

		# 根据距离 center 的远近决定最大尺寸（越近越大）
		var d_center = dist_center_map[pos]
		var max_d = 1.0
		for v in dist_center_map.values():
			max_d = max(max_d, float(v))
		var t = d_center / max_d
		var max_size = int(lerp(8.0, 2.0, t))
		max_size = max(2, max_size)

		var w = 1
		var h = 1

		for step in range(1, max_size):
			var xx = x + dir_x * step
			var yy = y + dir_y * step
			var block_pass = true
			if dir_x<0 and dir_y < 0:
				pass
			for _xx in range(x, xx+dir_x, dir_x):
				var p = Vector2i(_xx, yy)
				if not mask.has(p) or visited.has(p) or ban_point_set.has(p):
					block_pass = false
					break
			if not block_pass:
				break
			for _yy in range(y, yy+dir_y, dir_y):
				var p = Vector2i(xx, _yy)
				if not mask.has(p) or visited.has(p) or ban_point_set.has(p):
					block_pass = false
					break
			if not block_pass:
				break
			w += 1
			h += 1
			if dir_x<0 and dir_y < 0:
				pass
	
		# 标记 visited
		var x_min = x
		var y_min = y
		if dir_x < 0:
			x_min = x - (w - 1)
		if dir_y < 0:
			y_min = y - (h - 1)

		for xx in range(x_min, x_min + w):
			for yy in range(y_min, y_min + h):
				var p = Vector2i(xx, yy)
				if mask.has(p):
					visited[p] = true

		var color = Color(rng.randf_range(0.4,1), rng.randf_range(0.4,1), rng.randf_range(0.4,1))
		rects.append({
			"x": x_min,
			"y": y_min,
			"w": w,
			"h": h,
			"color": color,
		})

	return {
		"blocks":rects,
		"secondary_roads_set":secondary_roads_set
	}
