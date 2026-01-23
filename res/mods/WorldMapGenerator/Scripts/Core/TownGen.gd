# ============================================================
# TownGen.gd
# 城镇生成主模块 —— 轮廓生成完整实现版
# ============================================================

class_name TownGen
extends Object

# ------------------------------------------------------------
# 枚举与配置
# ------------------------------------------------------------

enum TownBaseShape {
	CIRCLE,
	RECTANGLE,
	IRREGULAR,
	MULTI_CORE,
}

enum TownRiverRelation {
	NONE,
	AVOID,
	ALONG,
	THROUGH,
}

enum TownCoastRelation {
	NONE,
	COAST,
	PORT,
}

class TownShapeConfig:
	var base_shape: int = TownBaseShape.IRREGULAR
	var has_terrain_slope: bool = false
	var river_relation: int = TownRiverRelation.NONE
	var coast_relation: int = TownCoastRelation.NONE


# ------------------------------------------------------------
# 主入口
# ------------------------------------------------------------
static func generate_town(width: int, height: int, seed: int = 12345) -> TownData:
	var data = TownData.new()
	data.width = width
	data.height = height
	data.init_arrays()

	var rng = RandomNumberGenerator.new()
	rng.seed = seed

	var config = TownShapeConfig.new()
	config.base_shape = rng.randi() % TownBaseShape.size()
	config.has_terrain_slope = true
	config.river_relation = rng.randi() % TownRiverRelation.size()
	config.coast_relation = rng.randi() % TownCoastRelation.size()

	_generate_town_shape(data, rng, config)
	_generate_walls(data, rng)
	_generate_poi(data, rng)
	_generate_main_roads(data, rng)
	_generate_districts(data, rng)
	_generate_lots(data, rng)

	return data


# ============================================================
# 1. 轮廓生成（专业版：适宜度场 + 区域生长 + 平滑）
# ============================================================
static func _generate_town_shape(
	data: TownData,
	rng: RandomNumberGenerator,
	config: TownShapeConfig
) -> TownData:
	var w = data.width
	var h = data.height

	# 1. 各类软掩码（几何 + 山脉 + 河流 + 海岸 + 噪声）
	var shape_mask = _shape_feature_soft(data, rng, config)
	var mountain_mask = _mountain_feature_soft(data, rng, config)
	var river_mask = _river_feature_soft(data, rng, config)
	var coast_mask = _coast_feature_soft(data, rng, config.coast_relation)
	var noise_mask = _noise_edge_feature(data, rng)

	# 2. 适宜度场（0~1）
	var suitability = _compute_suitability(
		w, h,
		shape_mask,
		mountain_mask,
		river_mask,
		coast_mask,
		noise_mask
	)

	# 3. 区域生长（Flood Fill + 面积控制）
	var target_area = int(w * h * 0.25)  # 目标城镇面积占比，可调
	var grown_mask = _grow_town_region(
		w, h,
		suitability,
		rng,
		target_area
	)

	# 4. 形态平滑（边界优化）
	var final_mask = _smooth_mask(grown_mask, 3)

	# 5. 写入 TownData
	for x in range(w):
		for y in range(h):
			data.cell_type[x][y] = "inside" if (final_mask[x][y] > 0.5) else "outside"

	return data


# ------------------------------------------------------------
# 适宜度场
# ------------------------------------------------------------
static func _compute_suitability(
	w: int, h: int,
	shape_mask: Array,
	mountain_mask: Array,
	river_mask: Array,
	coast_mask: Array,
	noise_mask: Array
) -> Array:
	var s = _new_mask(w, h)

	for x in range(w):
		for y in range(h):
			s[x][y] = \
				shape_mask[x][y] * \
				mountain_mask[x][y] * \
				river_mask[x][y] * \
				coast_mask[x][y] * \
				noise_mask[x][y]

	return s


# ------------------------------------------------------------
# 区域生长（Flood Fill + 面积控制）
# ------------------------------------------------------------
static func _grow_town_region(
	w: int, h: int,
	suitability: Array,
	rng: RandomNumberGenerator,
	target_area: int
) -> Array:
	var mask = _new_mask(w, h, 0.0)

	# 1. 找到适宜度最高的点作为种子
	var best_pos = Vector2i(0, 0)
	var best_val = -1.0
	for x in range(w):
		for y in range(h):
			if suitability[x][y] > best_val:
				best_val = suitability[x][y]
				best_pos = Vector2i(x, y)

	if best_val <= 0.0:
		return mask

	# 2. Flood Fill 生长
	var queue: Array[Vector2i] = [best_pos]
	mask[best_pos.x][best_pos.y] = 1.0
	var area = 1

	while queue.size() > 0 and area < target_area:
		var pos = queue.pop_front()
		for dir in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
			var nx = pos.x + dir.x
			var ny = pos.y + dir.y
			if nx < 0 or nx >= w or ny < 0 or ny >= h:
				continue
			if mask[nx][ny] > 0.0:
				continue

			var p = suitability[nx][ny]
			if p <= 0.0:
				continue

			# 适宜度越高，越容易被纳入城镇
			if p > rng.randf():
				mask[nx][ny] = 1.0
				queue.append(Vector2i(nx, ny))
				area += 1

	return mask


# ------------------------------------------------------------
# 形态平滑（边界优化）
# ------------------------------------------------------------
static func _smooth_mask(mask: Array, iterations: int) -> Array:
	var w = mask.size()
	var h = mask[0].size()

	for i in range(iterations):
		var new_mask = _new_mask(w, h)
		for x in range(w):
			for y in range(h):
				var sum = 0.0
				var count = 0
				for dx in [-1, 0, 1]:
					for dy in [-1, 0, 1]:
						var nx = x + dx
						var ny = y + dy
						if nx < 0 or nx >= w or ny < 0 or ny >= h:
							continue
						sum += mask[nx][ny]
						count += 1
				new_mask[x][y] = sum / max(1, count)
		mask = new_mask

	return mask


# ============================================================
# 形状特征（圆形 / 矩形 / 不规则 / 多中心）
# ============================================================
static func _shape_feature_soft(
	data: TownData,
	rng: RandomNumberGenerator,
	config: TownShapeConfig
) -> Array:
	var w = data.width
	var h = data.height
	var mask = _new_mask(w, h)

	match config.base_shape:
		TownBaseShape.CIRCLE:
			_shape_soft_circle(mask, w, h)
		TownBaseShape.RECTANGLE:
			_shape_soft_rectangle(mask, w, h, rng)
		TownBaseShape.MULTI_CORE:
			_shape_soft_multi_core(mask, w, h, rng)
		TownBaseShape.IRREGULAR:
			_shape_soft_irregular(mask, w, h, rng)

	return mask


static func _shape_soft_circle(mask: Array, w: int, h: int) -> void:
	var cx = float(w) * 0.5
	var cy = float(h) * 0.5
	var r = min(float(w), float(h)) * 0.4

	for x in range(w):
		for y in range(h):
			var dx = float(x) - cx
			var dy = float(y) - cy
			var d = sqrt(dx * dx + dy * dy)
			mask[x][y] = clamp(1.0 - d / r, 0.0, 1.0)


static func _shape_soft_rectangle(mask: Array, w: int, h: int, rng: RandomNumberGenerator) -> void:
	var left = int(w * 0.2)
	var right = int(w * 0.8)
	var top = int(h * 0.2)
	var bottom = int(h * 0.8)
	var fade = 6.0

	for x in range(w):
		for y in range(h):
			var fx = smoothstep(left, left + fade, x) * smoothstep(right, right - fade, x)
			var fy = smoothstep(top, top + fade, y) * smoothstep(bottom, bottom - fade, y)
			mask[x][y] = fx * fy


static func _shape_soft_irregular(mask: Array, w: int, h: int, rng: RandomNumberGenerator) -> void:
	var cx = float(w) * 0.5
	var cy = float(h) * 0.5
	var rx = float(w) * 0.35
	var ry = float(h) * 0.45

	var noise = FastNoiseLite.new()
	noise.seed = rng.randi()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.08

	for x in range(w):
		for y in range(h):
			var nx = (float(x) - cx) / rx
			var ny = (float(y) - cy) / ry
			var d = nx * nx + ny * ny
			var n = noise.get_noise_2d(x, y) * 0.25
			mask[x][y] = clamp(1.0 - (d - n), 0.0, 1.0)


static func _shape_soft_multi_core(mask: Array, w: int, h: int, rng: RandomNumberGenerator) -> void:
	var centers = []
	var core_count = 2 + rng.randi_range(0, 1)

	for i in range(core_count):
		var cx = float(w) * (0.3 + 0.4 * float(i) / max(1, core_count - 1))
		var cy = float(h) * (0.4 + rng.randf_range(-0.1, 0.1))
		centers.append(Vector2(cx, cy))

	var rx = float(w) * 0.22
	var ry = float(h) * 0.32

	for x in range(w):
		for y in range(h):
			var best = 0.0
			for c in centers:
				var nx = (float(x) - c.x) / rx
				var ny = (float(y) - c.y) / ry
				var d = nx * nx + ny * ny
				best = max(best, clamp(1.0 - d, 0.0, 1.0))
			mask[x][y] = best


# ============================================================
# 山脉特征（1~3 个方向包裹）
# ============================================================
static func _mountain_feature_soft(
	data: TownData,
	rng: RandomNumberGenerator,
	config: TownShapeConfig
) -> Array:
	var w = data.width
	var h = data.height
	var mask = _new_mask(w, h, 1.0)

	if not config.has_terrain_slope:
		return mask

	var ridge_count = rng.randi_range(1, 3)
	var ridges = []

	for i in range(ridge_count):
		var angle = rng.randf_range(0, TAU)
		var px = int(w * (0.5 + 0.45 * cos(angle)))
		var py = int(h * (0.5 + 0.45 * sin(angle)))
		ridges.append(Vector2(px, py))

	for x in range(w):
		for y in range(h):
			var v = 1.0
			for r in ridges:
				var dx = float(x) - r.x
				var dy = float(y) - r.y
				var d = sqrt(dx * dx + dy * dy)
				v = min(v, clamp(d / 12.0, 0.0, 1.0))
			mask[x][y] = v

	return mask


# ============================================================
# 河流特征（避开 / 贴着 / 穿城）
# ============================================================
static func _river_feature_soft(
	data: TownData,
	rng: RandomNumberGenerator,
	config: TownShapeConfig
) -> Array:
	var w = data.width
	var h = data.height
	var mask = _new_mask(w, h, 1.0)

	if config.river_relation == TownRiverRelation.NONE:
		return mask

	var river_y = float(h) * 0.5 + rng.randi_range(-5, 5)
	var half_w = 2.0

	for x in range(w):
		var offset = sin(float(x) * 0.15) * 3.0
		var cy = river_y + offset
		for y in range(h):
			var dy = abs(float(y) - cy)

			match config.river_relation:
				TownRiverRelation.AVOID:
					if dy <= half_w:
						mask[x][y] = 0.0
				TownRiverRelation.ALONG:
					mask[x][y] = clamp(1.0 - dy / 10.0, 0.0, 1.0)
				TownRiverRelation.THROUGH:
					mask[x][y] = 1.0

	return mask


# ============================================================
# 海岸特征（靠海 / 港口）
# ============================================================
static func _coast_feature_soft(
	data: TownData,
	rng: RandomNumberGenerator,
	coast_relation: int
) -> Array:
	var w = data.width
	var h = data.height
	var mask = _new_mask(w, h, 1.0)

	if coast_relation == TownCoastRelation.NONE:
		return mask

	var coast_y = int(h * 0.25)

	for x in range(w):
		for y in range(h):
			if y < coast_y:
				mask[x][y] = 0.0
			else:
				var dy = float(y - coast_y)
				mask[x][y] = clamp(1.0 - dy / 12.0, 0.0, 1.0)

	return mask


# ============================================================
# 噪声边缘（让轮廓更自然）
# ============================================================
static func _noise_edge_feature(data: TownData, rng: RandomNumberGenerator) -> Array:
	var w = data.width
	var h = data.height
	var mask = _new_mask(w, h)

	var noise = FastNoiseLite.new()
	noise.seed = rng.randi()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.06

	for x in range(w):
		for y in range(h):
			mask[x][y] = 0.85 + noise.get_noise_2d(x, y) * 0.15

	return mask


# ============================================================
# 工具函数：创建 mask
# ============================================================
static func _new_mask(w: int, h: int, value: float = 0.0) -> Array:
	var mask = []
	mask.resize(w)
	for x in range(w):
		var row = []
		row.resize(h)
		for y in range(h):
			row[y] = value
		mask[x] = row
	return mask


# ============================================================
# 2~6 层（暂时空实现）
# ============================================================
static func _generate_walls(data: TownData, rng: RandomNumberGenerator) -> TownData:
	return data

static func _generate_poi(data: TownData, rng: RandomNumberGenerator) -> TownData:
	return data

static func _generate_main_roads(data: TownData, rng: RandomNumberGenerator) -> TownData:
	return data

static func _generate_districts(data: TownData, rng: RandomNumberGenerator) -> TownData:
	return data

static func _generate_lots(data: TownData, rng: RandomNumberGenerator) -> TownData:
	return data
