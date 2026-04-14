## 地图生成器
## 基于 Simplex 噪声的地形生成系统
## 实现了噪声生成、地形特征、侵蚀算法、分位数映射等功能
## 所有方法均为静态方法，可直接通过 WildernessGen.方法名() 调用

## 配置、输入输出数据结构说明
## 
## 1. 全局配置结构 (CONFIG)
## {
##   "width": 512,          # 地图宽度
##   "height": 512,         # 地图高度
##   "noise_scale": 32,      # 噪声缩放因子
##   "noise_zoom": 16,       # 噪声放大倍数
##   "water_erosion_iterations": 100,  # 水流侵蚀迭代次数
##   "thermal_erosion_iterations": 100, # 热侵蚀迭代次数
##   "combined_iterations": 100,       # 混合侵蚀迭代次数
##   "quantile_bins": [0.0, 0.1, 0.2, 0.4, 0.6, 0.8, 0.9, 1.0],  # 分位数区间
##   "quantile_weights": [0.03, 0.07, 0.10, 0.60, 0.10, 0.07, 0.03],  # 分位数权重
##   "color_map": {          # 高度等级颜色映射
##     "0.0-0.1": "#00008B",  # 深蓝色 (深海)
##     "0.1-0.2": "#0000FF",  # 蓝色 (海洋)
##     "0.2-0.4": "#006400",  # 深绿色 (森林/平原)
##     "0.4-0.6": "#FFFF00",  # 黄色 (草原)
##     "0.6-0.8": "#FFA500",  # 橙色 (丘陵)
##     "0.8-0.9": "#FF0000",  # 红色 (山地)
##     "0.9-1.0": "#000000"   # 黑色 (高山/积雪)
##   }
## }
##
## 2. 输入数据结构 (input_data)
## 各函数的输入数据均为字典，包含以下字段：
## - "seed": 随机种子
## - "height_map": 高度图 (二维数组)
## - "noise_maps": 噪声图列表 (仅 generate_height_map 需要)
## - "terrain_mask": 地形掩码 (仅 regional_raise_lower 需要)
## - "heat_mask": 热度掩码 (仅 erosion 函数需要)
##
## 3. 输出数据结构
## 各函数的输出均为字典，包含以下字段：
## - "seed": 随机种子
## - "height_map": 处理后的高度图
## - "noise_maps": 生成的噪声图列表 (仅 generate_noise_maps 输出)
## - "terrain_mask": 生成的地形掩码 (仅 generate_terrain_mask 输出)
## - "heat_mask": 生成的热度掩码 (仅 generate_heat_mask 输出)
## - "height_levels": 高度等级 (仅 height_summarize_process 输出)
## - "color_map": 颜色地图 (仅 generate_color_map 输出)
##
## 4. 最终输出数据结构 (final_data)
## {
##   "metadata": {
##     "version": "1.0.0",
##     "generated_at": "2023-12-31 12:00:00",
##     "config": {
##       "seed": 123,
##       "width": 256,
##       "height": 256
##     },
##     "size": [256, 256]
##   },
##   "data": {
##     "size": [256, 256],
##     "final_height_level": [[0, 1, 2, ...], ...]  # 高度等级数组
##   }
## }

class_name WildernessGen
extends RefCounted

## 全局配置
## 包含地图生成的所有参数设置
const CONFIG = {
	"width": 512,          ## 地图宽度
	"height": 512,         ## 地图高度
	"noise_scale": 32,      ## 噪声缩放因子，控制噪声的细节程度
	"noise_zoom": 16,       ## 噪声放大倍数
	"water_erosion_iterations": 100,  ## 水流侵蚀迭代次数
	"thermal_erosion_iterations": 100, ## 热侵蚀迭代次数
	"combined_iterations": 100,       ## 混合侵蚀迭代次数
	"quantile_bins": [0.0, 0.1, 0.2, 0.4, 0.6, 0.8, 0.9, 1.0],  ## 分位数映射的区间边界
	"quantile_weights": [0.03, 0.07, 0.10, 0.60, 0.10, 0.07, 0.03],  ## 分位数映射的区间权重
	"color_map": {          ## 高度等级对应的颜色映射
		"0.0-0.1": "#00008B",  # 深蓝色
		"0.1-0.2": "#0000FF",  # 蓝色
		"0.2-0.4": "#006400",  # 深绿色
		"0.4-0.6": "#FFFF00",  # 黄色
		"0.6-0.8": "#FFA500",  # 橙色
		"0.8-0.9": "#FF0000",  # 红色
		"0.9-1.0": "#000000"   # 黑色
	}
}

## 生成二维数组
static func create_2d_array(height, width, default_value = 0.0):
	var array = []
	for y in range(height):
		var row = []
		for x in range(width):
			row.append(default_value)
		array.append(row)
	return array

## 复制二维数组
static func copy_2d_array(array):
	var copy = []
	for y in range(array.size()):
		var row = []
		for x in range(array[y].size()):
			row.append(array[y][x])
		copy.append(row)
	return copy

## 生成 Simplex 噪声图
## 将均匀分布映射为正态分布
## 参数：
## - width: 噪声图宽度
## - height: 噪声图高度
## - seed_offset: 种子偏移量，用于生成不同的噪声图
## 返回值：生成的噪声图（二维数组）
static func simplex_noise(width, height, seed_offset):
	## 生成基础噪声
	var noise_map = create_2d_array(height, width, 0.0)
	var noise = FastNoiseLite.new()
	noise.seed = seed_offset       ## 设置种子
	noise.fractal_octaves = 2      ## 噪声八度，控制细节
	noise.frequency = 1.0 / CONFIG["noise_scale"]  ## 噪声频率，控制缩放
	noise.fractal_gain = 0.5       ## 噪声持久性，控制频率影响
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX  ## 设置为 Simplex 噪声类型
	
	for y in range(height):
		for x in range(width):
			## 使用 seed_offset 确保不同种子生成不同噪声
			var noise_value = noise.get_noise_2d(float(x), float(y))
			## 将 [-1, 1] 映射到 [0, 1]
			noise_map[y][x] = (noise_value + 1.0) / 2.0
	
	## 分位数变换：将均匀分布映射为正态分布
	## 1. 收集所有噪声值并排序
	var sorted_noise = []
	for y in range(height):
		for x in range(width):
			sorted_noise.append(noise_map[y][x])
	sorted_noise.sort()
	
	## 2. 对每个像素进行分位数变换
	for y in range(height):
		for x in range(width):
			## 计算当前值的分位数
			var value = noise_map[y][x]
			var quantile = 0.0
			var len = sorted_noise.size()
			for i in range(len):
				if sorted_noise[i] >= value:
					quantile = float(i) / float(len)
					break
			if quantile == 0.0 and len > 0:
				quantile = 1.0 / float(len)
			
			## 使用逆高斯函数（近似）将分位数转换为正态分布
			## 这里使用 Box-Muller 变换的近似
			var z = 0.0
			if quantile < 0.5:
				z = -sqrt(-2.0 * log(2.0 * quantile))
			else:
				z = sqrt(-2.0 * log(2.0 * (1.0 - quantile)))
			
			## 将正态分布值映射回 [0, 1]
			noise_map[y][x] = (z + 3.0) / 6.0  ## 假设 z 在 [-3, 3] 之间
	
	return noise_map

## 生成噪声图
static func generate_noise_maps(input_data):
	var seed = input_data.get("seed", 0)
	var width = input_data.get("width", CONFIG["width"])
	var height = input_data.get("height", CONFIG["height"])
	
	# 生成3张噪声图
	var noise_maps = []
	for i in range(3):
		var noise_map = simplex_noise(width, height, seed + i)
		noise_maps.append(noise_map)
	
	return {
		"seed": seed,
		"noise_maps": noise_maps
	}

## 生成高度地图
static func generate_height_map(input_data):
	var noise_maps = input_data["noise_maps"]
	var weights = input_data.get("weights", [0.7, 0.2, 0.1])
	
	# 叠加噪声图
	var height = noise_maps[0].size()
	var width = noise_maps[0][0].size()
	var height_map = create_2d_array(height, width, 0.0)
	
	for i in range(noise_maps.size()):
		var noise_map = noise_maps[i]
		var weight = weights[i]
		for y in range(height):
			for x in range(width):
				height_map[y][x] += noise_map[y][x] * weight
	
	return {
		"seed": input_data["seed"],
		"height_map": height_map,
		"weights": weights
	}

## 归一化高度地图
static func normalize_height_map(input_data):
	var height_map = input_data["height_map"]
	
	# 归一化到 [0, 1]
	var min_val = INF
	var max_val = -INF
	var height = height_map.size()
	var width = height_map[0].size()
	
	for y in range(height):
		for x in range(width):
			var val = height_map[y][x]
			if val < min_val:
				min_val = val
			if val > max_val:
				max_val = val
	
	var normalized_map = create_2d_array(height, width, 0.0)
	if max_val > min_val:
		for y in range(height):
			for x in range(width):
				normalized_map[y][x] = (height_map[y][x] - min_val) / (max_val - min_val)
	else:
		normalized_map = copy_2d_array(height_map)
	
	return {
		"seed": input_data["seed"],
		"height_map": normalized_map
	}

## 平滑滤波
static func smooth_filter(input_data):
	var height_map = input_data["height_map"]
	var height = height_map.size()
	var width = height_map[0].size()
	
	# 3x3 平均滤波器
	var smoothed_map = create_2d_array(height, width, 0.0)
	
	for y in range(height):
		for x in range(width):
			# 计算邻域平均值
			var sum_val = 0.0
			var count = 0
			for dy in [-1, 0, 1]:
				for dx in [-1, 0, 1]:
					var ny = y + dy
					var nx = x + dx
					if ny >= 0 and ny < height and nx >= 0 and nx < width:
						sum_val += height_map[ny][nx]
						count += 1
			smoothed_map[y][x] = sum_val / float(count)
	
	# 再次归一化到 [0, 1]
	var min_val = INF
	var max_val = -INF
	for y in range(height):
		for x in range(width):
			var val = smoothed_map[y][x]
			if val < min_val:
				min_val = val
			if val > max_val:
				max_val = val
	
	if max_val > min_val:
		for y in range(height):
			for x in range(width):
				smoothed_map[y][x] = (smoothed_map[y][x] - min_val) / (max_val - min_val)
	
	return {
		"seed": input_data["seed"],
		"height_map": smoothed_map
	}

## 非线性拉伸
static func nonlinear_stretch(input_data):
	var height_map = input_data["height_map"]
	var height = height_map.size()
	var width = height_map[0].size()
	var stretched_map = create_2d_array(height, width, 0.0)
	
	for y in range(height):
		for x in range(width):
			var val = height_map[y][x]
			if val < 0.2:
				# 低值：压缩得更低
				stretched_map[y][x] = (val / 0.2) * 0.1
			elif val < 0.7:
				# 中值：尽量拉平
				stretched_map[y][x] = 0.1 + ((val - 0.2) / 0.5) * 0.3
			else:
				# 高值：拉伸得更高
				stretched_map[y][x] = 0.4 + ((val - 0.7) / 0.3) * 0.6
	
	return {
		"seed": input_data["seed"],
		"height_map": stretched_map
	}

## 生成地形抬升掩码
static func generate_terrain_mask(input_data):
	var seed = input_data["seed"]
	var height_map = input_data["height_map"]
	var height = height_map.size()
	var width = height_map[0].size()
	
	# 生成8*8的噪声图，然后放大到实际地图大小
	var mask_small = simplex_noise(8, 8, seed + 10)
	var mask = create_2d_array(height, width, 0.0)
	
	# 放大掩码
	for y in range(height):
		for x in range(width):
			var sy = int(float(y) * 8.0 / float(height))
			var sx = int(float(x) * 8.0 / float(width))
			mask[y][x] = mask_small[sy][sx]
	
	return {
		"seed": seed,
		"height_map": input_data["height_map"],
		"terrain_mask": mask
	}

## 区域性抬升/降低
static func regional_raise_lower(input_data):
	var height_map = input_data["height_map"]
	var terrain_mask = input_data["terrain_mask"]
	var height = height_map.size()
	var width = height_map[0].size()
	
	var adjusted_map = create_2d_array(height, width, 0.0)
	for y in range(height):
		for x in range(width):
			var val = height_map[y][x]
			var mask_val = terrain_mask[y][x]
			
			if val > 0.7:
				# 山脉带：抬升
				var new_val = val * 2.0 * mask_val
				adjusted_map[y][x] = max(new_val, 0.7)
			elif val < 0.2:
				# 海洋带：降低
				var new_val = val * 0.3 * mask_val
				adjusted_map[y][x] = min(new_val, 0.2)
			else:
				# 平原带：保留
				adjusted_map[y][x] = val
	
	# 归一化到 [0, 1]
	var min_val = INF
	var max_val = -INF
	for y in range(height):
		for x in range(width):
			var val = adjusted_map[y][x]
			if val < min_val:
				min_val = val
			if val > max_val:
				max_val = val
	
	if max_val > min_val:
		for y in range(height):
			for x in range(width):
				adjusted_map[y][x] = (adjusted_map[y][x] - min_val) / (max_val - min_val)
	
	return {
		"seed": input_data["seed"],
		"height_map": adjusted_map
	}

## 生成热度图掩码
static func generate_heat_mask(input_data):
	var seed = input_data["seed"]
	var height_map = input_data["height_map"]
	var height = height_map.size()
	var width = height_map[0].size()
	
	# 生成4*4的噪声图，然后放大到实际地图大小
	var mask_small = simplex_noise(4, 4, seed + 20)
	var mask = create_2d_array(height, width, 0.0)
	
	# 放大掩码
	for y in range(height):
		for x in range(width):
			var sy = int(float(y) * 4.0 / float(height))
			var sx = int(float(x) * 4.0 / float(width))
			mask[y][x] = mask_small[sy][sx]
	
	return {
		"seed": seed,
		"height_map": input_data["height_map"],
		"heat_mask": mask
	}

## 水流侵蚀
## 模拟雨水侵蚀地形形成山谷和河道的过程
## 参数：
## - input_data: 包含高度图和热度图的数据字典
## 返回值：侵蚀后的高度图和热度图
static func water_erosion(input_data):
	## 复制高度图以避免修改原始数据
	var height_map = copy_2d_array(input_data["height_map"])
	var heat_mask = input_data["heat_mask"]
	var iterations = CONFIG["water_erosion_iterations"]
	
	var height = height_map.size()
	var width = height_map[0].size()
	var erosion_rate = 0.001       ## 侵蚀速率
	var deposition_rate = 0.0005    ## 沉积速率
	var min_slope = 0.005           ## 最小坡度阈值
	var rng = RandomNumberGenerator.new()
	rng.seed = input_data["seed"]  ## 设置随机数种子
	
	for _k in range(iterations):
		## 1. 随机选择非边缘格子（避免边界问题）
		var y = rng.randi_range(1, height - 2)
		var x = rng.randi_range(1, width - 2)
		
		## 2. 检查热度图，只在湿润区域执行侵蚀
		if heat_mask[y][x] < 0.5:
			continue
		
		## 3. 找最陡下坡方向（水流方向）
		var max_slope = 0.0
		var best_dir = null
		var current_height = height_map[y][x]
		
		for dy in [-1, 0, 1]:
			for dx in [-1, 0, 1]:
				if dy == 0 and dx == 0:
					continue
				var ny = y + dy
				var nx = x + dx
				var neighbor_height = height_map[ny][nx]
				var slope = current_height - neighbor_height
				if slope > max_slope and slope > min_slope:
					max_slope = slope
					best_dir = [dy, dx]
		
		if best_dir != null:
			## 4. 侵蚀当前点（水流源头）
			var erosion_amount = max_slope * erosion_rate * heat_mask[y][x]
			height_map[y][x] = max(0.0, height_map[y][x] - erosion_amount)
			
			## 5. 沉积到下游（水流终点）
			var dy = best_dir[0]
			var dx = best_dir[1]
			var ny = y + dy
			var nx = x + dx
			var deposition_amount = erosion_amount * deposition_rate
			height_map[ny][nx] = min(1.0, height_map[ny][nx] + deposition_amount)
	
	return {
		"seed": input_data["seed"],
		"height_map": height_map,
		"heat_mask": heat_mask
	}

## 热侵蚀
## 模拟热力作用导致的地形坍塌和悬崖形成
## 参数：
## - input_data: 包含高度图和热度图的数据字典
## 返回值：侵蚀后的高度图和热度图
static func thermal_erosion(input_data):
	## 复制高度图以避免修改原始数据
	var height_map = copy_2d_array(input_data["height_map"])
	var heat_mask = input_data["heat_mask"]
	var iterations = CONFIG["thermal_erosion_iterations"]
	
	var height = height_map.size()
	var width = height_map[0].size()
	var critical_slope = 0.15  ## 临界坡度，超过此值会发生坍塌
	var small_slope = 0.02     ## 小坡度阈值，低于此值会放大差值
	var erosion_amount = 0.05   ## 坍塌时的高度调整量
	
	for _k in range(iterations):
		for y in range(1, height - 1):
			for x in range(1, width - 1):
				## 检查热度图，只在温暖区域执行侵蚀
				if heat_mask[y][x] < 0.5:
					continue
				
				var current_height = height_map[y][x]
				for dy in [-1, 0, 1]:
					for dx in [-1, 0, 1]:
						if dy == 0 and dx == 0:
							continue
						var ny = y + dy
						var nx = x + dx
						var neighbor_height = height_map[ny][nx]
						var height_diff = current_height - neighbor_height
						
						if height_diff > critical_slope:
							## 坍塌：高处降，低处升
							height_map[y][x] -= erosion_amount
							height_map[ny][nx] += erosion_amount
						elif abs(height_diff) < small_slope:
							## 放大差值，增强地形对比度
							height_map[y][x] += 0.01
							height_map[ny][nx] -= 0.01
	
	## 确保值在 [0, 1] 范围内
	for y in range(height):
		for x in range(width):
			height_map[y][x] = clamp(height_map[y][x], 0.0, 1.0)
	
	return {
		"seed": input_data["seed"],
		"height_map": height_map,
		"heat_mask": heat_mask
	}

## 混合处理
## 结合热侵蚀和水流侵蚀，形成更真实的地形
## 参数：
## - input_data: 包含高度图、热度图和种子的数据字典
## 返回值：混合侵蚀后的高度图
static func mix_processing(input_data):
	var height_map = input_data["height_map"]
	var heat_mask = input_data["heat_mask"]
	var seed = input_data["seed"]
	
	## 大循环执行多次侵蚀，先执行热侵蚀，再执行水流侵蚀
	## 这样可以先形成陡峭的悬崖，再让水流在悬崖上雕刻出山谷
	for _k in range(CONFIG["combined_iterations"]):
		## 1. 执行热侵蚀，形成陡峭地形
		var thermal_input = {"seed": seed, "height_map": height_map, "heat_mask": heat_mask}
		var thermal_result = thermal_erosion(thermal_input)
		height_map = thermal_result["height_map"]
		
		## 2. 执行水流侵蚀，雕刻山谷和河道
		var water_input = {"seed": seed, "height_map": height_map, "heat_mask": heat_mask}
		var water_result = water_erosion(water_input)
		height_map = water_result["height_map"]
	
	return {
		"seed": seed,
		"height_map": height_map
	}

## 分位数映射处理
## 控制地形高度的分布，使地形更加真实（更多平原，更少极端地形）
## 参数：
## - input_data: 包含高度图的数据字典
## 返回值：分位数映射后的高度图
static func quantile_mapping_process(input_data):
	var height_map = input_data["height_map"]
	var height = height_map.size()
	var width = height_map[0].size()
	
	## 1. 收集所有高度值并排序，用于计算分位数
	var sorted_values = []
	for y in range(height):
		for x in range(width):
			sorted_values.append(height_map[y][x])
	sorted_values.sort()
	
	var mapped_map = create_2d_array(height, width, 0.0)
	var bins = CONFIG["quantile_bins"]       ## 高度区间边界
	var weights = CONFIG["quantile_weights"]  ## 每个区间的目标权重
	
	## 2. 计算累积权重，用于分位数映射
	var cum_weights = [0.0]
	for w in weights:
		cum_weights.append(cum_weights[cum_weights.size() - 1] + w)
	
	## 3. 对每个像素进行分位数映射
	for y in range(height):
		for x in range(width):
			var val = height_map[y][x]
			## 计算当前值的分位数
			var quantile = 0.0
			var len = sorted_values.size()
			for i in range(len):
				if sorted_values[i] >= val:
					quantile = float(i) / float(len)
					break
			if quantile == 0.0 and len > 0:
				quantile = 1.0 / float(len)
			
			## 映射到目标分布
			## 根据当前分位数，找到对应的目标区间并计算映射值
			for i in range(cum_weights.size() - 1):
				if cum_weights[i] <= quantile and quantile < cum_weights[i + 1]:
					mapped_map[y][x] = bins[i] + (quantile - cum_weights[i]) / weights[i] * (bins[i + 1] - bins[i])
					break
	
	return {
		"seed": input_data["seed"],
		"height_map": mapped_map
	}

## 高度概括处理
## 将高分辨率地形数据概括为低分辨率高度等级，便于后续使用
## 参数：
## - input_data: 包含高度图的数据字典
## 返回值：概括后的高度图和高度等级
static func height_summarize_process(input_data):
	var height_map = input_data["height_map"]
	var height = height_map.size()
	var width = height_map[0].size()
	
	## 1. 2*2 格子取平均值，降低分辨率
	var summary_height = height / 2
	var summary_width = width / 2
	var summarized_map = create_2d_array(summary_height, summary_width, 0.0)
	
	for y in range(summary_height):
		for x in range(summary_width):
			## 计算 2*2 区域的平均值
			var sum_val = 0.0
			var count = 0
			for dy in [0, 1]:
				for dx in [0, 1]:
					var ny = y * 2 + dy
					var nx = x * 2 + dx
					if ny < height and nx < width:
						sum_val += height_map[ny][nx]
						count += 1
			summarized_map[y][x] = sum_val / float(count)
	
	## 2. 生成高度等级，将连续高度值转换为离散等级
	var height_levels = create_2d_array(summary_height, summary_width, 0)
	var bins = CONFIG["quantile_bins"]
	
	for y in range(summarized_map.size()):
		for x in range(summarized_map[y].size()):
			var val = summarized_map[y][x]
			## 根据分位数区间确定高度等级
			for i in range(bins.size() - 1):
				if bins[i] <= val and val < bins[i + 1]:
					height_levels[y][x] = i
					break
	
	return {
		"seed": input_data["seed"],
		"height_map": summarized_map,
		"height_levels": height_levels
	}

## 生成颜色地图
static func generate_color_map(input_data):
	var height_levels = input_data["height_levels"]
	var height = height_levels.size()
	var width = height_levels[0].size()
	
	# 创建颜色映射
	var colors = [
		"#00008B",  # 深蓝色
		"#0000FF",  # 蓝色
		"#006400",  # 深绿色
		"#FFFF00",  # 黄色
		"#FFA500",  # 橙色
		"#FF0000",  # 红色
		"#000000"   # 黑色
	]
	
	# 生成颜色地图
	var color_map = create_2d_array(height, width, Color(0, 0, 0))
	for y in range(height):
		for x in range(width):
			var level = height_levels[y][x]
			# 将 hex 颜色转换为 RGB
			var hex_color = colors[level]
			var r = int(hex_color.substr(1, 2).hex_to_int())
			var g = int(hex_color.substr(3, 2).hex_to_int())
			var b = int(hex_color.substr(5, 2).hex_to_int())
			color_map[y][x] = Color(r / 255.0, g / 255.0, b / 255.0)
	
	return {
		"seed": input_data["seed"],
		"height_levels": height_levels,
		"color_map": color_map
	}

## 保存图片
static func save_image(data, filename):
	# 注意：Godot 中保存图片需要使用 Image 类
	# 这里简化处理，实际项目中可能需要更复杂的实现
	pass

## 生成地图
## 完整的地形生成流程，从噪声生成到最终输出
## 参数：
## - seed: 随机种子，用于生成不同的地图
## - width: 地图宽度，默认为512
## - height: 地图高度，默认为512
## 返回值：生成的地图数据，包含高度等级和元数据
static func generate_map(seed, width=512, height=512):
	## 初始化生成数据
	var data = {"seed": seed, "width": width, "height": height}

	## 地形生成流程
	## 1. 生成噪声图：创建3张不同的噪声图作为基础
	data = generate_noise_maps(data)
	## 2. 生成高度地图：将3张噪声图按权重叠加
	data = generate_height_map(data)
	## 3. 归一化：将高度值映射到 [0, 1] 区间
	data = normalize_height_map(data)
	## 4. 平滑滤波：使用3x3平均滤波器平滑地形
	data = smooth_filter(data)
	## 5. 非线性拉伸：增强地形特征（深海、平原、山脉）
	data = nonlinear_stretch(data)
	## 6. 生成地形掩码：创建8*8的抬升掩码
	data = generate_terrain_mask(data)
	## 7. 区域性抬升/降低：根据掩码调整地形高度
	data = regional_raise_lower(data)
	## 8. 生成热度掩码：创建4*4的热度图
	data = generate_heat_mask(data)
	## 9. 混合侵蚀处理：结合热侵蚀和水流侵蚀
	data = mix_processing(data)
	## 10. 分位数映射：控制高度分布，使地形更真实
	data = quantile_mapping_process(data)
	## 11. 高度概括：将高分辨率数据概括为低分辨率高度等级
	data = height_summarize_process(data)
	## 12. 生成颜色地图：根据高度等级生成可视化地图
	data = generate_color_map(data)

	## 生成最终 JSON 数据
	var final_data = {
		"metadata": {
			"version": "1.0.0",
			"generated_at": get_current_time(),
			"config": {
				"seed": seed,
				"width": data["height_levels"][0].size(),
				"height": data["height_levels"].size()
			},
			"size": [data["height_levels"][0].size(), data["height_levels"].size()]
		},
		"data": {
			"size": [data["height_levels"][0].size(), data["height_levels"].size()],
			"final_height_level": data["height_levels"]
		}
	}

	return final_data

## 获取当前时间
static func get_current_time():
	var dt = Time.get_datetime_dict_from_system()
	var year = str(dt["year"]).pad_zeros(4)
	var month = str(dt["month"]).pad_zeros(2)
	var day = str(dt["day"]).pad_zeros(2)
	var hour = str(dt["hour"]).pad_zeros(2)
	var minute = str(dt["minute"]).pad_zeros(2)
	var second = str(dt["second"]).pad_zeros(2)
	return "%s-%s-%s %s:%s:%s" % [year, month, day, hour, minute, second]

## 主函数
static func _ready():
	# 遍历种子 0-9
	for seed in range(10):
		print("Generating map for seed " + str(seed) + "...")
		var result = generate_map(seed)
		print("Map generated for seed " + str(seed) + " with size " + str(result["metadata"]["size"]))
	print("All maps generated successfully!")
