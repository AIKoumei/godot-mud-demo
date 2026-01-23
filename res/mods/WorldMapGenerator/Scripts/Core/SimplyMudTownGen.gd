class_name SimplyMudTownGen
extends Object

# -------------------------
# 节点类型
# -------------------------
enum NodeType {
	CENTER,
	WALL,
	DEL_WALL,
	START_WALL,
	END_WALL,
	PATCH_WALL,
	MAIN_ROAD,
	GATE,
	GATE_WALL,   # ⭐ 新增：城门两侧补墙
}

class TownNode:
	var id: int
	var type: int
	var pos: Vector2i

	func _init(_id: int, _type: int, _pos: Vector2i):
		id = _id
		type = _type
		pos = _pos


# -------------------------
# 颜色映射
# -------------------------
static var NODE_COLOR = {
	NodeType.CENTER: Color(1.0, 0.0, 0.0),
	NodeType.WALL: Color(0.2, 0.2, 0.2),
	NodeType.DEL_WALL: Color(1.0, 1.0, 1.0),
	NodeType.START_WALL: Color(0.0, 0.0, 0.0),
	NodeType.END_WALL: Color(0.5, 0.5, 0.5),
	NodeType.PATCH_WALL: Color(0.0, 1.0, 0.0),
	NodeType.MAIN_ROAD: Color(0.0, 0.4, 0.0),
	NodeType.GATE: Color(0.5, 0.0, 0.0),
	NodeType.GATE_WALL: Color(1.0, 0.6, 0.6),   # ⭐ 浅红色
}

static var noise = FastNoiseLite.new()


# -------------------------
# 配置生成
# -------------------------
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


# -------------------------
# 主入口
# -------------------------
static func generate_town(cfg: Dictionary) -> Dictionary:
	var rng = RandomNumberGenerator.new()
	rng.seed = cfg["seed"]

	noise.seed = cfg["seed"]
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = lerp(0.02, 0.08, cfg["smoothness"])

	var size: Vector2i = _pick_town_size(String(cfg["size_type"]), rng)
	var w: int = size.x
	var h: int = size.y

	# 1. 轮廓 mask
	var mask: Dictionary = _generate_contour_mask(cfg, w, h)

	# 2. center
	var final_center: Vector2i = _pick_center(mask, w, h)

	# 3. 原始墙体（基于 mask）
	var edge_points: Array = _find_edge_points(mask)

	# 4. ⭐ 主干道（使用 edge_points 判断撞墙）
	var road_data = generate_main_roads(final_center, mask, edge_points)
	var main_road_set = road_data["main_road_set"]
	var gate_set = road_data["gate_set"]

	# 5. ⭐ 大门九宫格调整（修改 mask）
	var gate_outdoor_set := {}
	var gate_wall_set := {}

	for gate_pos in gate_set.keys():
		var outdoor_pos = _adjust_gate_mask(gate_pos, main_road_set, mask, gate_wall_set)
		if outdoor_pos != null:
			gate_outdoor_set[outdoor_pos] = true

	# 6. ⭐ 修补城墙（基于修改后的 mask，避免堵门）
	var patched = patch_walls(_find_edge_points(mask), gate_outdoor_set)
	var edge_set: Dictionary = patched["edge_set"]
	var patch_set: Dictionary = patched["patch_set"]

	# 7. 回路检测 + 剪枝（DEL_WALL）
	var loop_data = find_wall_loop(edge_set, final_center)
	var loop: Array = loop_data["loop"]
	var delete_set: Dictionary = loop_data["delete_set"]

	var start_wall_pos: Vector2i = loop[0]
	var end_wall_pos: Vector2i = loop[loop.size() - 1]

	var nodes: Dictionary = {}
	var next_id: int = 0

	# center
	nodes[next_id] = TownNode.new(next_id, NodeType.CENTER, final_center)
	next_id += 1

	# 输出墙体
	for pos in edge_set.keys():
		var t = NodeType.WALL

		if delete_set.has(pos):
			t = NodeType.DEL_WALL
		elif pos == start_wall_pos:
			t = NodeType.START_WALL
		elif pos == end_wall_pos:
			t = NodeType.END_WALL
		elif gate_wall_set.has(pos):
			t = NodeType.GATE_WALL
		elif patch_set.has(pos):
			t = NodeType.PATCH_WALL
		elif gate_set.has(pos):
			t = NodeType.GATE

		nodes[next_id] = TownNode.new(next_id, t, pos)
		next_id += 1

	# 输出主干道
	for pos in main_road_set.keys():
		nodes[next_id] = TownNode.new(next_id, NodeType.MAIN_ROAD, pos)
		next_id += 1

	return nodes


# -------------------------
# 轮廓大小
# -------------------------
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


# -------------------------
# 轮廓 mask
# -------------------------
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


# -------------------------
# 找边缘点
# -------------------------
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


# -------------------------
# 修补斜向墙体（补一边即可），避免堵住门外格子
# -------------------------
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

			var filler1 = Vector2i(p.x + d.x, p.y)
			var filler2 = Vector2i(p.x, p.y + d.y)

			# ⭐ 优先补 filler1（如果不 forbidden）
			if not forbidden.has(filler1):
				# filler2 已经存在 → 不需要补
				if edge_set.has(filler2) or patch_set.has(filler2):
					continue

				# filler1 也不能重复
				if not edge_set.has(filler1) and not patch_set.has(filler1):
					edge_set[filler1] = true
					patch_set[filler1] = true

			# ⭐ 否则尝试补 filler2
			elif not forbidden.has(filler2):
				if edge_set.has(filler1) or patch_set.has(filler1):
					continue

				if not edge_set.has(filler2) and not patch_set.has(filler2):
					edge_set[filler2] = true
					patch_set[filler2] = true

			# ⭐ 两边都 forbidden → 不补
			else:
				continue

	return {
		"edge_set": edge_set,
		"patch_set": patch_set
	}


# -------------------------
# ⭐ 主干道生成（使用 edge_points 判断撞墙）
# -------------------------
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


# -------------------------
# ⭐ 城门九宫格 mask 调整（生成 gate_wall_set）
# -------------------------
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

			# ⭐ 记录 gate_wall_set
			gate_wall_set[gw1] = true
			gate_wall_set[gw2] = true

			mask.erase(outdoor_pos)
			break

	return outdoor_pos


# -------------------------
# 回路检测 + 剪枝（DEL_WALL）
# -------------------------
static func find_wall_loop(edge_set: Dictionary, center: Vector2i) -> Dictionary:
	var start := center
	var best_dist := INF
	for p in edge_set.keys():
		var d = p.distance_to(center)
		if d < best_dist:
			best_dist = d
			start = p

	var dirs = [
		Vector2i(1,0), Vector2i(-1,0),
		Vector2i(0,1), Vector2i(0,-1)
	]

	var visited := {}
	var stack: Array = []

	var root_node = {
		"pos": start,
		"parent": null,
		"depth": 0,
	}
	stack.append(root_node)

	var found_cycle_node = null

	while stack.size() > 0:
		var node = stack.pop_back()
		var pos: Vector2i = node["pos"]
		var depth: int = node["depth"]

		if visited.has(pos):
			continue
		visited[pos] = true

		for d in dirs:
			var np = pos + d

			if depth > 2 and np == start:
				found_cycle_node = node
				stack.clear()
				break

			if edge_set.has(np) and not visited.has(np):
				stack.append({
					"pos": np,
					"parent": node,
					"depth": depth + 1,
				})

	if found_cycle_node == null:
		return {
			"loop": [start],
			"delete_set": {}
		}

	var raw_cycle: Array = []
	var cur = found_cycle_node
	while cur != null:
		raw_cycle.append(cur["pos"])
		cur = cur["parent"]
	raw_cycle.append(start)
	raw_cycle.reverse()

	var raw_cycle_set := {}
	for p in raw_cycle:
		raw_cycle_set[p] = true

	var delete_set := {}
	for p in edge_set.keys():
		if not raw_cycle_set.has(p):
			delete_set[p] = true

	return {
		"loop": raw_cycle,
		"delete_set": delete_set
	}


# -------------------------
# center 选择
# -------------------------
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
