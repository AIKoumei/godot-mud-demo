# ============================================================
# WorldGen.gd
# 世界生成工具类（强类型 + 细胞算法平滑）
# ============================================================

class_name WorldGen
extends Object

static func generate_world(width: int, height: int, seed: int = 12345) -> WorldData:
	var data: WorldData = WorldData.new()
	data.width = width
	data.height = height
	data.init_arrays()

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed

	_generate_continent(data, rng)
	_generate_height(data, rng)
	_generate_climate(data, rng)

	_thermal_erosion(data, rng)
	_hydraulic_erosion(data, rng)
	_wind_erosion(data, rng)

	_generate_rivers(data, rng)
	_generate_biome(data, rng)

	# 生物群系细胞平滑
	_smooth_biome(data, 2)

	_generate_voronoi_regions(data, rng)

	return data


# ============================================================
# 分步生成：给线程用的步骤列表
# ============================================================
static func generate_world_steps(width: int, height: int, seed: int) -> Array:
	var data: WorldData = WorldData.new()
	data.width = width
	data.height = height
	data.init_arrays()

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed

	var steps: Array = []

	steps.append(func() -> Dictionary:
		_generate_continent(data, rng)
		return {"step": "continent", "world": data}
	)

	steps.append(func() -> Dictionary:
		_generate_height(data, rng)
		return {"step": "height", "world": data}
	)

	steps.append(func() -> Dictionary:
		_generate_climate(data, rng)
		return {"step": "climate", "world": data}
	)

	steps.append(func() -> Dictionary:
		_thermal_erosion(data, rng)
		return {"step": "thermal", "world": data}
	)

	steps.append(func() -> Dictionary:
		_hydraulic_erosion(data, rng)
		return {"step": "hydraulic", "world": data}
	)

	steps.append(func() -> Dictionary:
		_wind_erosion(data, rng)
		return {"step": "wind", "world": data}
	)

	steps.append(func() -> Dictionary:
		_generate_rivers_advanced(data, rng)
		return {"step": "river", "world": data}
	)

	steps.append(func() -> Dictionary:
		_generate_biome(data, rng)
		_smooth_biome(data, 2)
		return {"step": "biome", "world": data}
	)

	steps.append(func() -> Dictionary:
		_generate_voronoi_regions(data, rng)
		return {"step": "region", "world": data}
	)

	return steps


# ============================================================
# 1. 大陆形状
# ============================================================
static func _generate_continent(data: WorldData, rng: RandomNumberGenerator) -> void:
	var noise: FastNoiseLite = FastNoiseLite.new()
	noise.seed = rng.randi()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 0.01

	for x: int in range(data.width):
		for y: int in range(data.height):
			var n: float = noise.get_noise_2d(float(x), float(y))
			n = (n + 1.0) * 0.5

			var dx: float = float(x) / float(data.width) - 0.5
			var dy: float = float(y) / float(data.height) - 0.5
			var dist: float = sqrt(dx * dx + dy * dy) * 1.4
			var mask: float = clamp(1.0 - dist, 0.0, 1.0)

			var h: float = n * mask
			if h < 0.3:
				h *= 0.5

			data.heightmap[x][y] = h


# ============================================================
# 2. 高度细节（FBM）
# ============================================================
static func _generate_height(data: WorldData, rng: RandomNumberGenerator) -> void:
	var noise: FastNoiseLite = FastNoiseLite.new()
	noise.seed = rng.randi()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 0.02

	var octaves: int = 4

	for x: int in range(data.width):
		for y: int in range(data.height):
			var base_h: float = data.heightmap[x][y]

			var h: float = 0.0
			var amp: float = 1.0
			var freq: float = 1.0

			for i: int in range(octaves):
				var nx: float = float(x) * freq
				var ny: float = float(y) * freq
				h += noise.get_noise_2d(nx, ny) * amp
				amp *= 0.5
				freq *= 2.0

			h = (h + 1.0) * 0.5

			if base_h < 0.3:
				data.heightmap[x][y] = base_h * 0.8 + h * 0.2
			else:
				data.heightmap[x][y] = base_h * 0.6 + h * 0.4


# ============================================================
# 3. 气候（温度 + 湿度）
# ============================================================
static func _generate_climate(data: WorldData, rng: RandomNumberGenerator) -> void:
	var humid_noise: FastNoiseLite = FastNoiseLite.new()
	humid_noise.seed = rng.randi()
	humid_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	humid_noise.frequency = 0.03

	for x: int in range(data.width):
		for y: int in range(data.height):
			var h: float = data.heightmap[x][y]

			var latitude: float = abs(float(y) / float(data.height) - 0.5) * 2.0
			var temp: float = 1.0 - latitude
			temp -= h * 0.4
			temp = clamp(temp, 0.0, 1.0)
			data.temperature[x][y] = temp

			var w: float = humid_noise.get_noise_2d(float(x), float(y))
			w = (w + 1.0) * 0.5
			if h < 0.3:
				w = min(w + 0.2, 1.0)
			data.humidity[x][y] = w


# ============================================================
# 4. 热侵蚀
# ============================================================
static func _thermal_erosion(data: WorldData, rng: RandomNumberGenerator) -> void:
	var iterations: int = 3
	var talus: float = 0.03
	var factor: float = 0.5

	for iter: int in range(iterations):
		var new_h: Array = []
		new_h.resize(data.width)

		for x: int in range(data.width):
			var row: Array = []
			row.resize(data.height)
			for y: int in range(data.height):
				row[y] = data.heightmap[x][y]
			new_h[x] = row

		for x: int in range(data.width):
			for y: int in range(data.height):
				var h: float = data.heightmap[x][y]
				if h < 0.3:
					continue

				for dx: int in range(-1, 2):
					for dy: int in range(-1, 2):
						if dx == 0 and dy == 0:
							continue

						var nx: int = x + dx
						var ny: int = y + dy
						if nx < 0 or ny < 0 or nx >= data.width or ny >= data.height:
							continue

						var nh: float = data.heightmap[nx][ny]
						var diff: float = h - nh
						if diff > talus:
							var move: float = (diff - talus) * factor
							new_h[x][y] = float(new_h[x][y]) - move
							new_h[nx][ny] = float(new_h[nx][ny]) + move

		data.heightmap = new_h


# ============================================================
# 5. 水侵蚀
# ============================================================
static func _hydraulic_erosion(data: WorldData, rng: RandomNumberGenerator) -> void:
	var iterations: int = 30
	var rain: float = 0.01
	var erosion_rate: float = 0.02
	var deposition_rate: float = 0.01
	var evaporation: float = 0.02

	for iter: int in range(iterations):
		for x: int in range(data.width):
			for y: int in range(data.height):
				if data.heightmap[x][y] >= 0.3:
					data.water_amount[x][y] = float(data.water_amount[x][y]) + rain

		var new_h: Array = []
		var new_w: Array = []
		new_h.resize(data.width)
		new_w.resize(data.width)

		for x: int in range(data.width):
			var row_h: Array = []
			var row_w: Array = []
			row_h.resize(data.height)
			row_w.resize(data.height)
			for y: int in range(data.height):
				row_h[y] = data.heightmap[x][y]
				row_w[y] = 0.0
			new_h[x] = row_h
			new_w[x] = row_w

		for x: int in range(data.width):
			for y: int in range(data.height):
				var h: float = data.heightmap[x][y]
				var w: float = data.water_amount[x][y]
				if w <= 0.0:
					continue

				var best: Vector2i = Vector2i(x, y)
				var best_h: float = h + w

				for dx: int in range(-1, 2):
					for dy: int in range(-1, 2):
						var nx: int = x + dx
						var ny: int = y + dy
						if nx < 0 or ny < 0 or nx >= data.width or ny >= data.height:
							continue
						var nh: float = data.heightmap[nx][ny] + data.water_amount[nx][ny]
						if nh < best_h:
							best_h = nh
							best = Vector2i(nx, ny)

				if best.x == x and best.y == y:
					new_w[x][y] = float(new_w[x][y]) + w * (1.0 - evaporation)
					continue

				var tx: int = best.x
				var ty: int = best.y

				var erode: float = erosion_rate * w
				new_h[x][y] = float(new_h[x][y]) - erode

				var deposit: float = deposition_rate * w
				new_h[tx][ty] = float(new_h[tx][ty]) + deposit

				new_w[tx][ty] = float(new_w[tx][ty]) + w * (1.0 - evaporation)

		data.heightmap = new_h
		data.water_amount = new_w


# ============================================================
# 6. 风蚀
# ============================================================
static func _wind_erosion(data: WorldData, rng: RandomNumberGenerator) -> void:
	var iterations: int = 2
	var rate: float = 0.01

	for iter: int in range(iterations):
		var new_h: Array = []
		new_h.resize(data.width)

		for x: int in range(data.width):
			var row: Array = []
			row.resize(data.height)
			for y: int in range(data.height):
				row[y] = data.heightmap[x][y]
			new_h[x] = row

		for x: int in range(data.width):
			for y: int in range(data.height):
				var h: float = data.heightmap[x][y]
				var w: float = data.humidity[x][y]
				if w > 0.4 or h < 0.3:
					continue

				var nx: int = x + 1
				if nx >= data.width:
					continue

				new_h[x][y] = float(new_h[x][y]) - rate
				new_h[nx][y] = float(new_h[nx][y]) + rate

		data.heightmap = new_h


# ============================================================
# 7. 河流
# ============================================================
static func _generate_rivers(data: WorldData, rng: RandomNumberGenerator) -> void:
	var flow: Array = []
	flow.resize(data.width)

	for x: int in range(data.width):
		var row: Array = []
		row.resize(data.height)
		for y: int in range(data.height):
			row[y] = 1.0
		flow[x] = row

	var iterations: int = 50

	for iter: int in range(iterations):
		var new_flow: Array = []
		new_flow.resize(data.width)

		for x: int in range(data.width):
			var row2: Array = []
			row2.resize(data.height)
			for y: int in range(data.height):
				row2[y] = 0.0
			new_flow[x] = row2

		for x: int in range(data.width):
			for y: int in range(data.height):
				var h: float = data.heightmap[x][y]
				if h < 0.3:
					continue

				var best: Vector2i = Vector2i(x, y)
				var best_h: float = h

				for dx: int in range(-1, 2):
					for dy: int in range(-1, 2):
						var nx: int = x + dx
						var ny: int = y + dy
						if nx < 0 or ny < 0 or nx >= data.width or ny >= data.height:
							continue
						var nh: float = data.heightmap[nx][ny]
						if nh < best_h:
							best_h = nh
							best = Vector2i(nx, ny)

				if best.x == x and best.y == y:
					new_flow[x][y] = float(new_flow[x][y]) + float(flow[x][y])
				else:
					new_flow[best.x][best.y] = float(new_flow[best.x][best.y]) + float(flow[x][y])

		flow = new_flow

	var threshold: float = 5.0
	for x: int in range(data.width):
		for y: int in range(data.height):
			if float(flow[x][y]) > threshold and data.heightmap[x][y] >= 0.3:
				data.river[x][y] = true


static func _generate_rivers_advanced(data: WorldData, rng: RandomNumberGenerator) -> void:
	_fill_basins(data)
	var flow_dir := _compute_flow_direction_dinf(data)
	var flow_acc := _compute_flow_accumulation(data, flow_dir)
	_carve_rivers(data, flow_acc)
	_mark_rivers(data, flow_acc)
	_spread_wetlands(data)


static func _fill_basins(data: WorldData) -> void:
	var w := data.width
	var h := data.height

	var filled := true
	while filled:
		filled = false
		for x in range(w):
			for y in range(h):
				var cur = data.heightmap[x][y]
				var lowest_neighbor = cur

				for dx in range(-1, 2):
					for dy in range(-1, 2):
						if dx == 0 and dy == 0:
							continue
						var nx := x + dx
						var ny := y + dy
						if nx < 0 or ny < 0 or nx >= w or ny >= h:
							continue
						lowest_neighbor = min(lowest_neighbor, data.heightmap[nx][ny])

				if lowest_neighbor > cur:
					data.heightmap[x][y] = lowest_neighbor
					filled = true


static func _compute_flow_direction_dinf(data: WorldData) -> Array:
	var w := data.width
	var h := data.height

	var dir := []
	dir.resize(w)
	for x in range(w):
		var row := []
		row.resize(h)
		dir[x] = row

	for x in range(w):
		for y in range(h):
			var best_slope := 0.0
			var best_dir := Vector2.ZERO

			var h0 = data.heightmap[x][y]

			for dx in range(-1, 2):
				for dy in range(-1, 2):
					if dx == 0 and dy == 0:
						continue
					var nx := x + dx
					var ny := y + dy
					if nx < 0 or ny < 0 or nx >= w or ny >= h:
						continue

					var h1 = data.heightmap[nx][ny]
					var dh = h0 - h1
					if dh <= 0.0:
						continue

					var dist := sqrt(float(dx * dx + dy * dy))
					var slope = dh / dist

					if slope > best_slope:
						best_slope = slope
						best_dir = Vector2(dx, dy)

			dir[x][y] = best_dir

	return dir


static func _compute_flow_accumulation(data: WorldData, dir: Array) -> Array:
	var w := data.width
	var h := data.height

	var flow := []
	flow.resize(w)
	for x in range(w):
		var row := []
		row.resize(h)
		for y in range(h):
			row[y] = 1.0
		flow[x] = row

	var order := []
	for x in range(w):
		for y in range(h):
			order.append(Vector2i(x, y))

	order.sort_custom(func(a, b):
		return data.heightmap[a.x][a.y] > data.heightmap[b.x][b.y]
	)

	for pos in order:
		var x = pos.x
		var y = pos.y
		var d: Vector2 = dir[x][y]
		if d == Vector2.ZERO:
			continue

		var nx = x + int(d.x)
		var ny = y + int(d.y)
		if nx < 0 or ny < 0 or nx >= w or ny >= h:
			continue

		flow[nx][ny] = float(flow[nx][ny]) + float(flow[x][y])

	return flow


static func _carve_rivers(data: WorldData, flow: Array) -> void:
	var w := data.width
	var h := data.height

	var carve_strength := 0.0008

	for x in range(w):
		for y in range(h):
			var f := float(flow[x][y])
			if f > 5.0:
				data.heightmap[x][y] -= carve_strength * f


static func _mark_rivers(data: WorldData, flow: Array) -> void:
	var w := data.width
	var h := data.height

	for x in range(w):
		for y in range(h):
			data.river[x][y] = float(flow[x][y]) > 8.0


static func _spread_wetlands(data: WorldData) -> void:
	var w := data.width
	var h := data.height

	for x in range(w):
		for y in range(h):
			if data.river[x][y]:
				for dx in range(-1, 2):
					for dy in range(-1, 2):
						var nx := x + dx
						var ny := y + dy
						if nx < 0 or ny < 0 or nx >= w or ny >= h:
							continue
						data.humidity[nx][ny] = min(1.0, data.humidity[nx][ny] + 0.25)


# ============================================================
# 8. 生物群系
# ============================================================
static func _generate_biome(data: WorldData, rng: RandomNumberGenerator) -> void:
	for x: int in range(data.width):
		for y: int in range(data.height):
			var h: float = data.heightmap[x][y]
			var t: float = data.temperature[x][y]
			var w: float = data.humidity[x][y]

			if data.river[x][y]:
				data.biome[x][y] = "river"
				continue

			if h < 0.20:
				data.biome[x][y] = "ocean_deep"
				continue
			elif h < 0.30:
				data.biome[x][y] = "ocean_shallow"
				continue
			elif h < 0.35:
				data.biome[x][y] = "coast"
				continue

			if h > 0.90 and t < 0.3:
				data.biome[x][y] = "snow_mountain"
				continue
			elif h > 0.85:
				data.biome[x][y] = "mountain"
				continue

			if h > 0.8 and t > 0.7 and rng.randf() < 0.02:
				data.biome[x][y] = "volcano"
				continue

			if t < 0.2 and h > 0.35 and h < 0.7:
				data.biome[x][y] = "snowfield"
				continue

			if h < 0.45 and w > 0.7:
				data.biome[x][y] = "swamp"
				continue

			if t > 0.7 and w < 0.3:
				data.biome[x][y] = "desert"
				continue

			if t > 0.7 and w > 0.6:
				data.biome[x][y] = "jungle"
				continue

			if w > 0.6:
				data.biome[x][y] = "forest"
			elif w > 0.4:
				data.biome[x][y] = "woodland"
			else:
				data.biome[x][y] = "grassland"


# ============================================================
# 8.1 生物群系细胞平滑
# ============================================================
static func _smooth_biome(data: WorldData, iterations: int) -> void:
	for iter: int in range(iterations):
		var new_biome: Array = []
		new_biome.resize(data.width)

		for x: int in range(data.width):
			var row: Array = []
			row.resize(data.height)
			new_biome[x] = row

		for x: int in range(data.width):
			for y: int in range(data.height):
				var counts: Dictionary = {}
				for dx: int in range(-1, 2):
					for dy: int in range(-1, 2):
						var nx: int = x + dx
						var ny: int = y + dy
						if nx < 0 or ny < 0 or nx >= data.width or ny >= data.height:
							continue
						var b: String = data.biome[nx][ny]
						var old: int = 0
						if counts.has(b):
							old = counts[b]
						counts[b] = old + 1

				var best_biome: String = data.biome[x][y]
				var best_count: int = 0
				for biome_key in counts.keys():
					var biome_name: String = biome_key
					var c: int = counts[biome_name]
					if c > best_count:
						best_count = c
						best_biome = biome_name

				new_biome[x][y] = best_biome

		data.biome = new_biome


# ============================================================
# 9. 区域划分（Voronoi）
# ============================================================
static func _generate_voronoi_regions(data: WorldData, rng: RandomNumberGenerator) -> void:
	var num_sites: int = 20
	var sites: Array = []

	while sites.size() < num_sites:
		var sx: int = rng.randi_range(0, data.width - 1)
		var sy: int = rng.randi_range(0, data.height - 1)
		if data.heightmap[sx][sy] >= 0.35:
			sites.append(Vector2i(sx, sy))

	for x: int in range(data.width):
		for y: int in range(data.height):
			if data.heightmap[x][y] < 0.35:
				data.region_id[x][y] = -1
				continue

			var best: int = -1
			var best_d: float = 999999.0

			for i: int in range(sites.size()):
				var s: Vector2i = sites[i]
				var dx: float = float(x - s.x)
				var dy: float = float(y - s.y)
				var d2: float = dx * dx + dy * dy
				if d2 < best_d:
					best_d = d2
					best = i

			data.region_id[x][y] = best
