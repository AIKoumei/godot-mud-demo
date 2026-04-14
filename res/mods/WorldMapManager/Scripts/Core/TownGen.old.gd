# 城镇生成系统 - 基于 Simplex 噪声的程序化城镇生成
# 实现了完整的管线化生成流程，支持多种配置和可视化

class_name TownGen_Old
extends RefCounted

# 节点颜色定义
const NODE_COLOR = {
	"mask": [70, 70, 70],      # 基础轮廓
	"edge": [90, 90, 90],       # 边缘
	"wall": [170, 120, 100],    # 城墙
	"gate": [150, 150, 200],    # 城门
	"gate_wall": [100, 100, 150],  # 城门城墙（灰蓝色）
	"primary_road": [180, 180, 180],  # 主干道
	"secondary_road": [200, 200, 200],  # 次级道路
	"block": [120, 120, 120],   # 区块
	"center": [255, 0, 0],      # 中心
	"empty": [255, 255, 255]    # 空白
}

# 辅助函数：获取两点之间的所有整数坐标点
static func get_points_between(start_x: int, start_y: int, end_x: int, end_y: int) -> Array:
	# 获取两点之间的所有整数坐标点（包含起点，不包含终点）
	# 使用 Bresenham 直线算法
	var points = []
	var dx = abs(end_x - start_x)
	var dy = abs(end_y - start_y)
	var sx = 1 if start_x < end_x else -1
	var sy = 1 if start_y < end_y else -1
	var err = dx - dy
	
	var x = start_x
	var y = start_y
	
	while true:
		points.append(str(x) + "," + str(y))
		if x == end_x and y == end_y:
			break
		var e2 = 2 * err
		if e2 > -dy:
			err -= dy
			x += sx
		if e2 < dx:
			err += dx
			y += sy
	
	# 移除最后一个点（终点），只保留起点到终点之间的点
	if points.size() > 0:
		points.pop_back()
	
	return points

# 辅助函数：计算点到中心的距离
static func distance_to_center(x: int, y: int, center_x: int, center_y: int) -> float:
	# 计算点到中心的距离
	return sqrt(pow(x - center_x, 2) + pow(y - center_y, 2))

# 辅助函数：将RGB颜色转换为十六进制格式
static func rgb_to_hex(rgb: Array) -> String:
	# 将RGB颜色转换为十六进制格式
	var r = rgb[0]
	var g = rgb[1]
	var b = rgb[2]
	return "#" + str(r).pad_zeros(2) + str(g).pad_zeros(2) + str(b).pad_zeros(2) + "ff"

# 辅助函数：数组去重
static func deduplicate_array(array: Array) -> Array:
	# 数组去重
	var unique_array = []
	var seen = {}
	for item in array:
		if not seen.has(item):
			seen[item] = true
			unique_array.append(item)
	return unique_array

# 生成配置
static func gen_config(size = null, shape = null, seed = null) -> Dictionary:
	# 生成地图生成器配置
	# Args:
	#     size: 城镇尺寸 (SMALL/MEDIUM/LARGE)
	#     shape: 城镇形状 (CIRCLE/RECTANGLE)
	#     seed: 随机种子
	# Returns:
	#     配置字典
	# 使用提供的种子或生成随机种子
	if seed == null:
		seed = randi_range(0, 999999)
	
	var rng = RandomNumberGenerator.new()
	rng.seed = seed
	
	# 尺寸配置
	var size_options = ["SMALL", "MEDIUM", "LARGE"]
	if size == null:
		size = size_options[rng.randi_range(0, size_options.size() - 1)]
	
	# 形状配置
	var shape_options = ["CIRCLE", "RECTANGLE"]
	if shape == null:
		shape = shape_options[rng.randi_range(0, shape_options.size() - 1)]
	
	# 根据尺寸确定宽高范围
	var width
	var height
	if size == "SMALL":
		width = rng.randi_range(12, 16)
		height = rng.randi_range(12, 16)
	elif size == "MEDIUM":
		width = rng.randi_range(16, 22)
		height = rng.randi_range(16, 22)
	else:  # LARGE
		width = rng.randi_range(22, 30)
		height = rng.randi_range(22, 30)
	
	# 生成不规则强度和长度
	var irregularity_strength = rng.randf_range(8, 16)
	var irregularity_length = rng.randf_range(4, 8)  # 控制噪声偏移的范围
	
	return {
		"size": size,
		"shape": shape,
		"seed": seed,
		"width": width,
		"height": height,
		"irregularity_strength": irregularity_strength,
		"irregularity_length": irregularity_length
	}



var config: Dictionary
var seed: int
var rng: RandomNumberGenerator
var noise: SimplexNoise
var steps: Array

func _init(config: Dictionary):
	# 初始化城镇生成器
	# Args:
	#     config: 配置字典
	self.config = config
	self.seed = config["seed"]
	self.rng = RandomNumberGenerator.new()
	self.rng.seed = self.seed
	self.noise = SimplexNoise.new(self.seed)
	self.steps = []

func run() -> Dictionary:
	# 运行完整的生成流程
	# Returns:
	#     最终生成数据
	# 步骤 1: 生成基础轮廓
	var mask_data = step_1_generate_mask()
	steps.append(mask_data)
	
	# 步骤 2: 确定城镇中心
	var center_data = step_2_determine_center(mask_data)
	steps.append(center_data)
	
	# 步骤 3: 生成主干道与城门
	var road_data = step_3_generate_roads(center_data)
	steps.append(road_data)
	
	# 步骤 4.1: 在后处理后，对mask再进行一遍edge的检查
	road_data = step_4_1_recheck_edges(road_data)
	
	# 步骤 4.2: 进行edge合法性校对
	validate_edge_connectivity(road_data)
	
	# 步骤 5: 生成城墙
	var wall_data = step_4_generate_walls(road_data)
	steps.append(wall_data)
	
	# 步骤 6: 生成区块与次级道路
	var block_data = step_5_generate_blocks(wall_data)
	steps.append(block_data)
	
	# 生成最终数据
	var final_data = generate_final_data(block_data)
	
	return final_data

func step_1_generate_mask() -> Dictionary:
	# 步骤 1: 生成城镇基础轮廓
	# Returns:
	#     包含mask和edges的字典
	var width = config["width"]
	var height = config["height"]
	var shape = config["shape"]
	var irregularity_strength = config.get("irregularity_strength", 1.0)
	var irregularity_length = config.get("irregularity_length", 2.0)  # 控制噪声偏移的范围
	
	# 为种子9强制设置更大的不规则强度和长度，用于测试
	if config.get("seed") == 9:
		irregularity_strength = 8.0  # 更大的噪声强度
		irregularity_length = 6.0  # 更大的噪声偏移范围
	
	# 计算噪声偏移可能需要的边界扩展
	var max_noise_offset = irregularity_length
	var expand_amount = int(ceil(max_noise_offset)) + 2  # 额外加2以确保覆盖所有可能的偏移
	
	# 计算中心坐标
	var center_x = width / 2
	var center_y = height / 2
	
	# 步骤1: 生成原始mask（无噪声）
	var original_mask = []
	
	# 遍历原始地图范围
	for y in range(height):
		for x in range(width):
			# 基础形状判断（无噪声）
			var should_be_in_mask = false
			if shape == "CIRCLE":
				# 圆形：距离中心不超过最大半径
				var distance = sqrt(pow(x - center_x, 2) + pow(y - center_y, 2))
				var max_radius = min(width, height) / 2
				should_be_in_mask = distance <= max_radius
			else:  # RECTANGLE
				# 矩形：在边界内
				should_be_in_mask = true
			
			if should_be_in_mask:
				original_mask.append(str(x) + "," + str(y))
	
	# 步骤2: 对原始mask做完整的edge标记
	var original_edges = []
	
	# 对原始mask中的每个点进行边缘检测
	for point_str in original_mask:
		var x = int(point_str.split(",")[0])
		var y = int(point_str.split(",")[1])
		
		# 检查九宫格内是否有无效节点
		var has_invalid_neighbor = false
		for dx_off in [-1, 0, 1]:
			for dy_off in [-1, 0, 1]:
				if dx_off == 0 and dy_off == 0:
					continue
				var neighbor_x = x + dx_off
				var neighbor_y = y + dy_off
				var neighbor_point = str(neighbor_x) + "," + str(neighbor_y)
				
				# 检查邻居是否在原始mask中
				if not original_mask.has(neighbor_point):
					has_invalid_neighbor = true
					break
			if has_invalid_neighbor:
				break
		
		# 如果九宫格内有无效节点，标记为edge
		if has_invalid_neighbor:
			original_edges.append(point_str)
	
	# 步骤3: 对原始edge应用噪声偏移
	var mask = original_mask.duplicate()
	var edge_offsets = []
	
	# 对每个原始边缘点应用噪声偏移
	for point_str in original_edges:
		var x = int(point_str.split(",")[0])
		var y = int(point_str.split(",")[1])
		
		# 使用多层噪声增加不规则性
		var noise_value_1 = noise.noise2d(float(x), float(y), 0.05)  # 低频噪声
		var noise_value_2 = noise.noise2d(float(x), float(y), 0.1)  # 中频噪声
		var noise_value_3 = noise.noise2d(float(x), float(y), 0.15)   # 高频噪声
		
		# 叠加不同频率的噪声
		var combined_noise = noise_value_1 * 0.5 + noise_value_2 * 0.3 + noise_value_3 * 0.2
		
		# 归一化噪声到 [-1, 1] 范围
		var normalized_noise
		if abs(combined_noise) > 10:
			normalized_noise = clamp(combined_noise / 210.0, -1.0, 1.0)
		else:
			normalized_noise = clamp(combined_noise, -1.0, 1.0)
		
		# 映射噪声到 [-irregularity_length, irregularity_length]
		var noise_offset = normalized_noise * irregularity_length
		
		# 计算偏移后的坐标
		# 对于圆形，朝径向方向偏移
		# 对于矩形，朝垂直于边缘的方向偏移
		var offset_x = x
		var offset_y = y
		var is_outward = false
		
		if shape == "CIRCLE":
			# 计算径向方向
			if x != center_x or y != center_y:
				# 计算单位向量
				var distance = sqrt(pow(x - center_x, 2) + pow(y - center_y, 2))
				if distance > 0:
					var dx = float(x - center_x) / distance
					var dy = float(y - center_y) / distance
					# 应用偏移
					offset_x = int(round(float(x) + dx * noise_offset))
					offset_y = int(round(float(y) + dy * noise_offset))
			
			# 检查是否向外偏移
			var original_distance = sqrt(pow(x - center_x, 2) + pow(y - center_y, 2))
			var new_distance = sqrt(pow(offset_x - center_x, 2) + pow(offset_y - center_y, 2))
			is_outward = new_distance > original_distance
		else:  # RECTANGLE
			# 计算到各边的距离
			var distance_to_left = x
			var distance_to_right = width - 1 - x
			var distance_to_top = y
			var distance_to_bottom = height - 1 - y
			var min_distance = min(distance_to_left, distance_to_right, distance_to_top, distance_to_bottom)
			
			# 根据最近的边计算偏移方向
			if distance_to_left == min_distance:
				# 朝左或右偏移
				offset_x = int(round(float(x) - noise_offset))  # 负噪声向左偏移，正噪声向右偏移
				is_outward = offset_x < 0
			elif distance_to_right == min_distance:
				# 朝右或左偏移
				offset_x = int(round(float(x) + noise_offset))  # 正噪声向右偏移，负噪声向左偏移
				is_outward = offset_x > width - 1
			elif distance_to_top == min_distance:
				# 朝上或下偏移
				offset_y = int(round(float(y) - noise_offset))  # 负噪声向上偏移，正噪声向下偏移
				is_outward = offset_y < 0
			elif distance_to_bottom == min_distance:
				# 朝下或上偏移
				offset_y = int(round(float(y) + noise_offset))  # 正噪声向下偏移，负噪声向上偏移
				is_outward = offset_y > height - 1
		
		# 取消边界限制，允许偏移超出原始地图边界
		# 注：这样会实现真正的地图拓展
		
		# 存储边缘点的偏移信息
		edge_offsets.append([x, y, offset_x, offset_y, is_outward])
	
	# 创建集合便于快速查找
	var mask_set = {}  # 使用字典作为集合
	for point in mask:
		mask_set[point] = true
	
	# 存储需要移除的节点
	var nodes_to_remove = {}
	# 存储需要添加的mask节点
	var nodes_to_add = {}
	# 存储偏移后的边缘点
	var offset_edges = []
	
	# 处理每个边缘点的偏移
	for offset_info in edge_offsets:
		var orig_x = offset_info[0]
		var orig_y = offset_info[1]
		var offset_x = offset_info[2]
		var offset_y = offset_info[3]
		var is_outward = offset_info[4]
		
		# 获取原始点和偏移点之间的所有节点
		var intermediate_nodes = TownGen.get_points_between(orig_x, orig_y, offset_x, offset_y)
		
		# 移除中间节点
		for node in intermediate_nodes:
			nodes_to_remove[node] = true
		
		# 如果是向外偏移，添加中间节点到mask
		if is_outward:
			for node in intermediate_nodes:
				# 取消边界检查，允许添加超出原始范围的节点
				# 注：这样会实现真正的地图拓展
				nodes_to_add[node] = true
		
		# 添加偏移后的边缘点
		offset_edges.append(str(offset_x) + "," + str(offset_y))
	
	# 应用移除和添加操作
	for node in nodes_to_remove.keys():
		if mask_set.has(node):
			mask_set.erase(node)
	for node in nodes_to_add.keys():
		mask_set[node] = true
	
	# 转换回列表
	mask = []
	for node in mask_set.keys():
		mask.append(node)
	
	# 步骤5: 移除所有现有的edge，重新检测edge
	# 完全移除所有edge
	var final_edges = []
	
	# 重新对mask进行edge检测
	for point_str in mask:
		var x = int(point_str.split(",")[0])
		var y = int(point_str.split(",")[1])
		
		# 检查九宫格内是否有无效节点
		var has_invalid_neighbor = false
		for dx_off in [-1, 0, 1]:
			for dy_off in [-1, 0, 1]:
				if dx_off == 0 and dy_off == 0:
					continue
				var neighbor_x = x + dx_off
				var neighbor_y = y + dy_off
				var neighbor_point = str(neighbor_x) + "," + str(neighbor_y)
				
				# 检查邻居是否在调整后的mask中
				if not mask_set.has(neighbor_point):
					has_invalid_neighbor = true
					break
			if has_invalid_neighbor:
				break
		
		# 如果九宫格内有无效节点，标记为edge
		if has_invalid_neighbor:
			final_edges.append(point_str)
	
	# 步骤6: 检查十字线上的邻居，移除只有一个邻居的edge节点
	var edges_to_remove = {}
	
	# 使用队列来处理被移除节点的邻居
	var check_queue = []
	var checked = {}
	
	# 初始队列包含所有edge节点
	for edge_point in final_edges:
		check_queue.append(edge_point)
		checked[edge_point] = true
	
	while check_queue.size() > 0:
		var edge_point = check_queue.pop_front()
		var x = int(edge_point.split(",")[0])
		var y = int(edge_point.split(",")[1])
		
		# 检查十字线方向的邻居（上、下、左、右）
		var cross_neighbors = []
		var directions = [[0, -1], [0, 1], [-1, 0], [1, 0]]  # 上、下、左、右
		
		for direction in directions:
			var dx = direction[0]
			var dy = direction[1]
			var neighbor_x = x + dx
			var neighbor_y = y + dy
			var neighbor_point = str(neighbor_x) + "," + str(neighbor_y)
			
			if mask_set.has(neighbor_point) and not edges_to_remove.has(neighbor_point):
				cross_neighbors.append(neighbor_point)
		
		# 如果十字线上只有一个邻居，移除该edge节点
		if cross_neighbors.size() == 1:
			edges_to_remove[edge_point] = true
			
			# 将被移除节点的横竖邻居加入检查队列
			for direction in directions:
				var dx = direction[0]
				var dy = direction[1]
				var neighbor_x = x + dx
				var neighbor_y = y + dy
				var neighbor_point = str(neighbor_x) + "," + str(neighbor_y)
				
				if mask_set.has(neighbor_point) and not edges_to_remove.has(neighbor_point):
					check_queue.append(neighbor_point)
					checked[neighbor_point] = true
	
	# 应用移除操作
	var temp_edges = []
	for edge in final_edges:
		if not edges_to_remove.has(edge):
			temp_edges.append(edge)
	final_edges = temp_edges
	
	var temp_mask = []
	for node in mask:
		if not edges_to_remove.has(node):
			temp_mask.append(node)
	mask = temp_mask
	
	# 步骤7: 对edge进行后处理，标记必要节点和移除节点
	
	# 节点状态：0=未标记，1=必要节点，2=移除节点
	var node_status = {}
	for edge_point in final_edges:
		node_status[edge_point] = 0
	
	# 步骤7.1: 找到符合条件的起始节点
	var start_node = null
	for edge_point in final_edges:
		var x = int(edge_point.split(",")[0])
		var y = int(edge_point.split(",")[1])
		
		# 检查九宫格内的横邻居和竖邻居数量
		var horizontal_neighbors = 0
		var vertical_neighbors = 0
		
		# 水平方向（左、右）
		for dx in [-1, 1]:
			var neighbor_point = str(x + dx) + "," + str(y)
			if final_edges.has(neighbor_point):
				horizontal_neighbors += 1
		
		# 垂直方向（上、下）
		for dy in [-1, 1]:
			var neighbor_point = str(x) + "," + str(y + dy)
			if final_edges.has(neighbor_point):
				vertical_neighbors += 1
		
		# 条件：横邻居为2或竖邻居为2
		if horizontal_neighbors == 2 or vertical_neighbors == 2:
			start_node = edge_point
			node_status[start_node] = 1  # 标记为必要节点
			break
	
	# 步骤7.2: 广度优先遍历所有edge节点
	if start_node:
		var queue = []
		var visited = {}  # 使用visited字典跟踪处理状态
		
		queue.append(start_node)
		visited[start_node] = true  # 只有加入队列时标记为visited
		
		while queue.size() > 0:
			var current_node = queue.pop_front()
			var x = int(current_node.split(",")[0])
			var y = int(current_node.split(",")[1])
			
			# 检查横竖方向的邻居
			var cross_neighbors = []
			var directions = [[0, -1], [0, 1], [-1, 0], [1, 0]]  # 上、下、左、右
			
			for direction in directions:
				var dx = direction[0]
				var dy = direction[1]
				var neighbor_point = str(x + dx) + "," + str(y + dy)
				if final_edges.has(neighbor_point):
					cross_neighbors.append(neighbor_point)
			
			# 当前节点的横竖邻居数量
			var neighbor_count = cross_neighbors.size()
			
			# 处理当前节点
			if neighbor_count == 3:
				# 标记为移除节点
				if node_status[current_node] != 1:
					node_status[current_node] = 2
				# 标记邻居节点为移除节点
				for neighbor in cross_neighbors:
					if node_status[neighbor] != 1:
						node_status[neighbor] = 2
			
			elif neighbor_count == 2 and node_status[current_node] != 2:
				# 标记为必要节点
				if node_status[current_node] != 1:
					node_status[current_node] = 1
				# 标记横竖邻居为必要节点
				for neighbor in cross_neighbors:
					if node_status[neighbor] == 2:
						# 邻居被标记为移除节点，改为必要节点并重新检查
						node_status[neighbor] = 1
						queue.append(neighbor)
						visited[neighbor] = true
					elif node_status[neighbor] == 0:
						# 未标记的邻居，标记为必要节点
						node_status[neighbor] = 1
						if not visited.has(neighbor):
							queue.append(neighbor)
							visited[neighbor] = true
			
			# 将未处理的邻居加入队列
			for neighbor in cross_neighbors:
				if not visited.has(neighbor):
					queue.append(neighbor)
					visited[neighbor] = true
	
	# 步骤7.3: 移除非必要节点
	var non_essential_nodes = {}
	for edge_point in node_status.keys():
		if node_status[edge_point] != 1:
			non_essential_nodes[edge_point] = true
	
	# 应用移除操作
	var temp_edges2 = []
	for edge in final_edges:
		if not non_essential_nodes.has(edge):
			temp_edges2.append(edge)
	final_edges = temp_edges2
	
	var temp_mask2 = []
	for node in mask:
		if not non_essential_nodes.has(node):
			temp_mask2.append(node)
	mask = temp_mask2
	
	# 去重
	mask = deduplicate_array(mask)
	final_edges = deduplicate_array(final_edges)
	
	return {
		"mask": mask,
		"edges": final_edges,
		"width": width,
		"height": height
	}

func step_2_determine_center(mask_data: Dictionary) -> Dictionary:
	# 步骤 2: 确定城镇中心
	# Args:
	#     mask_data: 包含mask的字典
	# Returns:
	#     包含center的字典
	var mask = mask_data["mask"]
	var width = mask_data["width"]
	var height = mask_data["height"]
	
	# 计算几何中心
	var center_x = width / 2
	var center_y = height / 2
	var geometric_center = str(center_x) + "," + str(center_y)
	
	# 检查几何中心是否在mask内
	var center
	if mask.has(geometric_center):
		center = geometric_center
	else:
		# 找到离几何中心最近的有效点
		var min_distance = INF
		var closest_point = null
		
		for point_str in mask:
			var x = int(point_str.split(",")[0])
			var y = int(point_str.split(",")[1])
			var distance = sqrt(pow(x - center_x, 2) + pow(y - center_y, 2))
			if distance < min_distance:
				min_distance = distance
				closest_point = point_str
		
		center = closest_point
	
	var result = mask_data.duplicate()
	result["center"] = center
	return result

func step_3_generate_roads(center_data: Dictionary) -> Dictionary:
	# 步骤 3: 生成主干道与城门
	# Args:
	#     center_data: 包含center的字典
	# Returns:
	#     包含primary_road和gates的字典
	var mask = center_data["mask"]
	var edges = center_data["edges"].duplicate()  # 复制一份，以便修改
	var center = center_data["center"]
	var width = center_data["width"]
	var height = center_data["height"]
	
	var center_x = int(center.split(",")[0])
	var center_y = int(center.split(",")[1])
	var primary_road = [center]
	var gates = []
	var gate_walls = []
	
	# 四个方向的主干道
	var directions = [
		[0, -1, "up"],    # 上
		[0, 1, "down"],   # 下
		[-1, 0, "left"],  # 左
		[1, 0, "right"]   # 右
	]
	
	for direction in directions:
		var dx = direction[0]
		var dy = direction[1]
		var dir_name = direction[2]
		var x = center_x
		var y = center_y
		var last_point = null
		
		while true:
			last_point = str(x) + "," + str(y)
			x += dx
			y += dy
			var current_point = str(x) + "," + str(y)
			
			# 检查是否在mask内
			if not mask.has(current_point):
				# 检查last_point是否是边缘，如果是则作为城门
				if edges.has(last_point):
					gates.append(last_point)
					# 将last_point从edges中移除
					if edges.has(last_point):
						edges.erase(last_point)
				# 同时检查last_point是否在primary_road中，如果在则移除
				if primary_road.has(last_point):
					primary_road.erase(last_point)
				break
			
			# 检查是否到达边缘
			if edges.has(current_point):
				# 检查下一个点是否在mask内（判断是否是最后一个轮廓）
				var next_x = x + dx
				var next_y = y + dy
				var next_point = str(next_x) + "," + str(next_y)
				var is_last_contour = not mask.has(next_point)
				
				if is_last_contour:
					# 是最后一个轮廓，将current_point作为城门
					gates.append(current_point)
					
					# 将current_point从edges中移除
					if edges.has(current_point):
						edges.erase(current_point)
					
					# 生成城门城墙（在城门垂直主干道的两个方向）
					var gate_x = x
					var gate_y = y
					# 计算垂直方向的偏移
					if dx != 0:  # 水平方向的主干道（左右）
						# 垂直方向（上下）生成城门城墙
						for dy_off in [-1, 1]:
							var wall_y = gate_y + dy_off
							var wall_point = str(gate_x) + "," + str(wall_y)
							# 直接添加城门城墙，不检查是否在mask中
							gate_walls.append(wall_point)
							# 将城门城墙节点添加到mask和edges中
							if not mask.has(wall_point):
								mask.append(wall_point)
							if not edges.has(wall_point):
								edges.append(wall_point)
					else:  # 垂直方向的主干道（上下）
						# 水平方向（左右）生成城门城墙
						for dx_off in [-1, 1]:
							var wall_x = gate_x + dx_off
							var wall_point = str(wall_x) + "," + str(gate_y)
							# 直接添加城门城墙，不检查是否在mask中
							gate_walls.append(wall_point)
							# 将城门城墙节点添加到mask和edges中
							if not mask.has(wall_point):
								mask.append(wall_point)
							if not edges.has(wall_point):
								edges.append(wall_point)
					
					# 停止检查
					break
				elif mask.has(last_point):
					# 轮廓后方有轮廓，将current_point作为主干道
					primary_road.append(current_point)
					
					# 将current_point从edges中移除
					if edges.has(current_point):
						edges.erase(current_point)
					
					# 将后方轮廓作为触及点继续检查
					# 继续循环，不break
				else:
					# 轮廓后方没有轮廓，将current_point作为城门
					gates.append(current_point)
					
					# 将current_point从edges中移除
					if edges.has(current_point):
						edges.erase(current_point)
					
					# 停止检查
					break
			else:
				# 不是边缘，继续添加到主干道
				primary_road.append(current_point)
	
	var result = center_data.duplicate()
	result["primary_road"] = primary_road
	result["gates"] = gates
	result["gate_walls"] = gate_walls
	result["edges"] = edges  # 更新edges，移除了触及点
	return result

func step_4_generate_walls(road_data: Dictionary) -> Dictionary:
	# 步骤 4: 生成城墙
	# Args:
	#     road_data: 包含edges和gates的字典
	# Returns:
	#     包含walls的字典
	var mask = road_data["mask"]
	var edges = road_data["edges"]
	var gates = road_data.get("gates", [])
	var primary_road = road_data.get("primary_road", [])
	var gate_walls = road_data.get("gate_walls", [])
	
	var walls = []
	
	# 将轮廓的最远边缘生成为城墙，避开城门和城门城墙
	for point_str in edges:
		# 避开城门
		if gates.has(point_str):
			continue
		
		# 避开城门城墙
		if gate_walls.has(point_str):
			continue
		
		# 避开主干道
		if primary_road.has(point_str):
			continue
		
		# 检查当前节点九空格内的节点是否都是有效节点
		var x = int(point_str.split(",")[0])
		var y = int(point_str.split(",")[1])
		var all_valid = true
		# 检查九空格内的所有节点
		for dx_off in [-1, 0, 1]:
			for dy_off in [-1, 0, 1]:
				# 跳过自身
				if dx_off == 0 and dy_off == 0:
					continue
				# 计算邻接点坐标
				var neighbor_x = x + dx_off
				var neighbor_y = y + dy_off
				var neighbor_point = str(neighbor_x) + "," + str(neighbor_y)
				# 检查邻接点是否在mask中
				if not mask.has(neighbor_point):
					all_valid = false
					break
			if not all_valid:
				break
		
		# 如果九空格内的节点都是有效节点，则当前节点不作为城墙节点，并将其从边缘节点中移除
		if all_valid:
			# 将当前节点从边缘节点中移除
			if edges.has(point_str):
				edges.erase(point_str)
			continue
		
		walls.append(point_str)
	
	# 生成所有城墙（包含原始城墙和所有城门城墙）
	var all_walls = walls.duplicate()
	all_walls += gate_walls
	
	var result = road_data.duplicate()
	result["walls"] = walls
	result["all_walls"] = all_walls
	return result

func step_5_generate_blocks(wall_data: Dictionary) -> Dictionary:
	# 步骤 5: 生成区块与次级道路
	# Args:
	#     wall_data: 包含walls的字典
	# Returns:
	#     包含blocks和secondary_roads的字典
	var mask = wall_data["mask"]
	var center = wall_data["center"]
	var primary_road = wall_data.get("primary_road", [])
	var gates = wall_data.get("gates", [])
	var walls = wall_data.get("walls", [])
	
	var center_x = int(center.split(",")[0])
	var center_y = int(center.split(",")[1])
	var blocks = {}
	var secondary_roads = []
	var block_id = 1
	
	# 获取城门城墙和所有城墙
	var gate_walls = wall_data.get("gate_walls", [])
	var all_walls = wall_data.get("all_walls", [])
	
	# 已占用的位置
	var occupied = {}
	for point in mask:
		if not primary_road.has(point) and not gates.has(point) and not walls.has(point) and not gate_walls.has(point):
			occupied[point] = true
	
	# 从中心向外四个方向生成区块
	var directions = [[0, -1], [0, 1], [-1, 0], [1, 0]]  # 上、下、左、右
	
	# 先尝试在中心附近生成第一个5x5的区块
	var first_block_generated = false
	
	# 扩大搜索范围，确保能找到合适的位置生成第一个5x5区块
	var search_range = 5  # 扩大搜索范围到5格
	for y_offset in range(-search_range, search_range + 1):
		for x_offset in range(-search_range, search_range + 1):
			if first_block_generated:
				break
			
			# 计算起始点
			var x = center_x + x_offset
			var y = center_y + y_offset
			
			# 尝试生成5x5的区块
			var block_size = 5
			var block_valid = true
			var block_nodes = []
			
			# 检查区块是否在有效范围内
			for y_off in range(block_size):
				for x_off in range(block_size):
					var block_x = x + x_off
					var block_y = y + y_off
					var block_point = str(block_x) + "," + str(block_y)
					
					# 检查是否有效
					if not occupied.has(block_point):
						block_valid = false
						break
					
					block_nodes.append(block_point)
				
				if not block_valid:
					break
			
			if block_valid:
				# 生成第一个区块
				blocks[str(block_id)] = {
					"size": [block_size, block_size],
					"position": [x, y],
					"nodes": block_nodes
				}
				
				# 从occupied中移除区块节点
				for node in block_nodes:
					if occupied.has(node):
						occupied.erase(node)
				
				# 在区块周边的空闲节点生成次级道路
				# 当区块大小为1的时候，如果横竖方向上已经有次级道路，则该区块不生成周围的次级道路
				if block_size == 1:
					# 检查横竖方向上是否已经有次级道路
					var has_horizontal_road = false
					var has_vertical_road = false
					
					# 检查水平方向（左、右）
					for dx in [-1, 1]:
						var check_point = str(x + dx) + "," + str(y)
						if secondary_roads.has(check_point) or primary_road.has(check_point):
							has_horizontal_road = true
							break
					
					# 检查垂直方向（上、下）
					for dy in [-1, 1]:
						var check_point = str(x) + "," + str(y + dy)
						if secondary_roads.has(check_point) or primary_road.has(check_point):
							has_vertical_road = true
							break
					
					# 如果横竖方向上任意方向上都有次级道路，则不生成周围的次级道路
					if not (has_horizontal_road or has_vertical_road):
						# 生成次级道路
						for y_off in range(-1, block_size + 1):
							for x_off in range(-1, block_size + 1):
								# 只在区块边缘生成道路
								if x_off == -1 or x_off == block_size or y_off == -1 or y_off == block_size:
									var road_x = x + x_off
									var road_y = y + y_off
									var road_point = str(road_x) + "," + str(road_y)
									
									# 检查道路是否有效
									var is_valid = true
									is_valid = is_valid and mask.has(road_point)
									is_valid = is_valid and not primary_road.has(road_point)
									is_valid = is_valid and not gates.has(road_point)
									is_valid = is_valid and not walls.has(road_point)
									is_valid = is_valid and not gate_walls.has(road_point)
									is_valid = is_valid and not secondary_roads.has(road_point)
									
									# 检查是否在已生成的区块中
									var in_block = false
									for block in blocks.values():
										if block["nodes"].has(road_point):
											in_block = true
											break
									is_valid = is_valid and not in_block
									
									is_valid = is_valid and occupied.has(road_point)
									
									if is_valid:
										secondary_roads.append(road_point)
										# 从occupied中移除次级道路节点
										if occupied.has(road_point):
											occupied.erase(road_point)
				else:
					# 区块大小不为1，正常生成次级道路
					for y_off in range(-1, block_size + 1):
						for x_off in range(-1, block_size + 1):
							# 只在区块边缘生成道路
							if x_off == -1 or x_off == block_size or y_off == -1 or y_off == block_size:
								var road_x = x + x_off
								var road_y = y + y_off
								var road_point = str(road_x) + "," + str(road_y)
								
								# 检查道路是否有效
								var is_valid = true
								is_valid = is_valid and mask.has(road_point)
								is_valid = is_valid and not primary_road.has(road_point)
								is_valid = is_valid and not gates.has(road_point)
								is_valid = is_valid and not walls.has(road_point)
								is_valid = is_valid and not gate_walls.has(road_point)
								is_valid = is_valid and not secondary_roads.has(road_point)
								
								# 检查是否在已生成的区块中
								var in_block = false
								for block in blocks.values():
									if block["nodes"].has(road_point):
										in_block = true
										break
								is_valid = is_valid and not in_block
								
								is_valid = is_valid and occupied.has(road_point)
								
								if is_valid:
									secondary_roads.append(road_point)
									# 从occupied中移除次级道路节点
									if occupied.has(road_point):
										occupied.erase(road_point)
				
				block_id += 1
				first_block_generated = true
				break
		if first_block_generated:
			break
	
	# 如果没有找到合适的位置生成5x5区块，尝试生成4x4或3x3的区块
	if not first_block_generated:
		for block_size in [4, 3]:
			for y_offset in range(-search_range, search_range + 1):
				for x_offset in range(-search_range, search_range + 1):
					if first_block_generated:
						break
					
					# 计算起始点
					var x = center_x + x_offset
					var y = center_y + y_offset
					
					# 尝试生成区块
					var block_valid = true
					var block_nodes = []
					
					# 检查区块是否在有效范围内
					for y_off in range(block_size):
						for x_off in range(block_size):
							var block_x = x + x_off
							var block_y = y + y_off
							var block_point = str(block_x) + "," + str(block_y)
							
							# 检查是否有效
							if not occupied.has(block_point):
								block_valid = false
								break
							
							block_nodes.append(block_point)
						
						if not block_valid:
							break
					
					if block_valid:
						# 生成第一个区块
						blocks[str(block_id)] = {
							"size": [block_size, block_size],
							"position": [x, y],
							"nodes": block_nodes
						}
						
						# 从occupied中移除区块节点
						for node in block_nodes:
							if occupied.has(node):
								occupied.erase(node)
						
						# 在区块周边的空闲节点生成次级道路
						# 当区块大小为1的时候，如果横竖方向上已经有次级道路，则该区块不生成周围的次级道路
						if block_size == 1:
							# 检查横竖方向上是否已经有次级道路
							var has_horizontal_road = false
							var has_vertical_road = false
							
							# 检查水平方向（左、右）
							for dx in [-1, 1]:
								var check_point = str(x + dx) + "," + str(y)
								if secondary_roads.has(check_point) or primary_road.has(check_point):
									has_horizontal_road = true
									break
							
							# 检查垂直方向（上、下）
							for dy in [-1, 1]:
								var check_point = str(x) + "," + str(y + dy)
								if secondary_roads.has(check_point) or primary_road.has(check_point):
									has_vertical_road = true
									break
							
							# 如果横竖方向上任意方向上都有次级道路，则不生成周围的次级道路
							if not (has_horizontal_road or has_vertical_road):
								# 生成次级道路
								for y_off in range(-1, block_size + 1):
									for x_off in range(-1, block_size + 1):
										# 只在区块边缘生成道路
										if x_off == -1 or x_off == block_size or y_off == -1 or y_off == block_size:
											var road_x = x + x_off
											var road_y = y + y_off
											var road_point = str(road_x) + "," + str(road_y)
											
											# 检查道路是否有效
											var is_valid = true
											is_valid = is_valid and mask.has(road_point)
											is_valid = is_valid and not primary_road.has(road_point)
											is_valid = is_valid and not gates.has(road_point)
											is_valid = is_valid and not walls.has(road_point)
											is_valid = is_valid and not gate_walls.has(road_point)
											is_valid = is_valid and not secondary_roads.has(road_point)
											
											# 检查是否在已生成的区块中
											var in_block = false
											for block in blocks.values():
												if block["nodes"].has(road_point):
													in_block = true
													break
											is_valid = is_valid and not in_block
											
											is_valid = is_valid and occupied.has(road_point)
											
											if is_valid:
												secondary_roads.append(road_point)
												# 从occupied中移除次级道路节点
												if occupied.has(road_point):
													occupied.erase(road_point)
						else:
							# 区块大小不为1，正常生成次级道路
							for y_off in range(-1, block_size + 1):
								for x_off in range(-1, block_size + 1):
									# 只在区块边缘生成道路
									if x_off == -1 or x_off == block_size or y_off == -1 or y_off == block_size:
										var road_x = x + x_off
										var road_y = y + y_off
										var road_point = str(road_x) + "," + str(road_y)
										
										# 检查道路是否有效
										var is_valid = true
										is_valid = is_valid and mask.has(road_point)
										is_valid = is_valid and not primary_road.has(road_point)
										is_valid = is_valid and not gates.has(road_point)
										is_valid = is_valid and not walls.has(road_point)
										is_valid = is_valid and not gate_walls.has(road_point)
										is_valid = is_valid and not secondary_roads.has(road_point)
										
										# 检查是否在已生成的区块中
										var in_block = false
										for block in blocks.values():
											if block["nodes"].has(road_point):
												in_block = true
												break
										is_valid = is_valid and not in_block
										
										is_valid = is_valid and occupied.has(road_point)
										
										if is_valid:
											secondary_roads.append(road_point)
											# 从occupied中移除次级道路节点
											if occupied.has(road_point):
												occupied.erase(road_point)
						
						block_id += 1
						first_block_generated = true
						break
				if first_block_generated:
					break
	
	# 区块生成逻辑：循环生成区块，直到没有可用点
	while occupied.size() > 0:
		# 收集当前所有可用点，并计算每个点作为不同大小区块起始点时的最佳距离
		var best_candidates = []
		
		for point_str in occupied.keys():
			var x = int(point_str.split(",")[0])
			var y = int(point_str.split(",")[1])
			
			# 尝试不同大小的区块
			for block_size in [5, 4, 3, 2, 1]:
				# 计算区块的四个角坐标
				var block_corners = [
					[x, y],              # 左上角
					[x + block_size - 1, y],  # 右上角
					[x, y + block_size - 1],  # 左下角
					[x + block_size - 1, y + block_size - 1]  # 右下角
				]
				
				# 计算区块中心坐标
				var block_center_x = x + block_size / 2.0
				var block_center_y = y + block_size / 2.0
				
				# 计算区块中心到城镇中心的距离
				var min_distance = sqrt(pow(block_center_x - center_x, 2) + pow(block_center_y - center_y, 2))
				
				# 找到最接近中心的角点（用于可视化）
				var closest_corner = null
				var min_corner_distance = INF
				for corner in block_corners:
					var corner_distance = sqrt(pow(corner[0] - center_x, 2) + pow(corner[1] - center_y, 2))
					if corner_distance < min_corner_distance:
						min_corner_distance = corner_distance
						closest_corner = corner
				
				# 检查区块是否在有效范围内
				var block_valid = true
				var block_nodes = []
				
				for y_offset in range(block_size):
					for x_offset in range(block_size):
						var block_x = x + x_offset
						var block_y = y + y_offset
						var block_point = str(block_x) + "," + str(block_y)
						
						# 检查是否有效
						if not occupied.has(block_point):
							block_valid = false
							break
						
						block_nodes.append(block_point)
					
					if not block_valid:
						break
				
				if block_valid:
					# 计算与主干道的最短距离
					var min_road_distance = INF
					# 使用之前计算好的区块中心坐标
					var road_center_x = block_center_x
					var road_center_y = block_center_y
					for road_point in primary_road:
						var road_x = int(road_point.split(",")[0])
						var road_y = int(road_point.split(",")[1])
						# 计算区块中心到主干道的距离
						var road_distance = sqrt(pow(road_center_x - road_x, 2) + pow(road_center_y - road_y, 2))
						if road_distance < min_road_distance:
							min_road_distance = road_distance
					
					# 添加到候选列表，优先选择距离中心近、大区块、距离主干道近的区块
					# 优先级：距离中心距离 > 区块大小 > 距离主干道距离
					# 确保区块生成顺序是从中心向外扩散的
					# 使用整数距离（乘以 100 取整）来提高比较精度
					var int_distance = int(min_distance * 100)
					var int_road_distance = int(min_road_distance * 100)
					var priority = [-int_distance, block_size, -int_road_distance]
					best_candidates.append([priority, min_distance, min_road_distance, block_size, x, y, closest_corner, block_nodes])
		
		# 如果没有候选区块，停止
		if best_candidates.size() == 0:
			break
		
		# 按优先级排序，选择最佳候选
		best_candidates.sort_custom(func(a, b):
			var a_priority = a[0]
			var b_priority = b[0]
			for i in range(3):
				if a_priority[i] > b_priority[i]:
					return -1
				elif a_priority[i] < b_priority[i]:
					return 1
			return 0
		)
		var best_candidate = best_candidates[0]
		var best_priority = best_candidate[0]
		var best_distance = best_candidate[1]
		var best_road_distance = best_candidate[2]
		var best_block_size = best_candidate[3]
		var best_x = best_candidate[4]
		var best_y = best_candidate[5]
		var best_corner = best_candidate[6]
		var best_nodes = best_candidate[7]
		
		# 生成区块
		blocks[str(block_id)] = {
			"size": [best_block_size, best_block_size],
			"position": [best_x, best_y],
			"nodes": best_nodes
		}
		
		# 从occupied中移除区块节点
		for node in best_nodes:
			if occupied.has(node):
				occupied.erase(node)
		
		# 在区块周边的空闲节点生成次级道路
		# 当区块大小为1的时候，如果横竖方向上已经有次级道路，则该区块不生成周围的次级道路
		if best_block_size == 1:
			# 检查横竖方向上是否已经有次级道路
			var has_horizontal_road = false
			var has_vertical_road = false
			
			# 检查水平方向（左、右）
			for dx in [-1, 1]:
				var check_point = str(best_x + dx) + "," + str(best_y)
				if secondary_roads.has(check_point) or primary_road.has(check_point):
					has_horizontal_road = true
					break
			
			# 检查垂直方向（上、下）
			for dy in [-1, 1]:
				var check_point = str(best_x) + "," + str(best_y + dy)
				if secondary_roads.has(check_point) or primary_road.has(check_point):
					has_vertical_road = true
					break
			
			# 如果横竖方向上任意方向上都有次级道路，则不生成周围的次级道路
			if not (has_horizontal_road or has_vertical_road):
				# 生成次级道路
				for y_offset in range(-1, best_block_size + 1):
					for x_offset in range(-1, best_block_size + 1):
						# 只在区块边缘生成道路
						if x_offset == -1 or x_offset == best_block_size or y_offset == -1 or y_offset == best_block_size:
							var road_x = best_x + x_offset
							var road_y = best_y + y_offset
							var road_point = str(road_x) + "," + str(road_y)
							
							# 检查道路是否有效
							var is_valid = true
							is_valid = is_valid and mask.has(road_point)
							is_valid = is_valid and not primary_road.has(road_point)
							is_valid = is_valid and not gates.has(road_point)
							is_valid = is_valid and not walls.has(road_point)
							is_valid = is_valid and not gate_walls.has(road_point)
							is_valid = is_valid and not secondary_roads.has(road_point)
							
							# 检查是否在已生成的区块中
							var in_block = false
							for block in blocks.values():
								if block["nodes"].has(road_point):
									in_block = true
									break
							is_valid = is_valid and not in_block
							
							is_valid = is_valid and occupied.has(road_point)
							
							if is_valid:
								secondary_roads.append(road_point)
								# 从occupied中移除次级道路节点
								if occupied.has(road_point):
									occupied.erase(road_point)
		else:
			# 区块大小不为1，正常生成次级道路
			for y_offset in range(-1, best_block_size + 1):
				for x_offset in range(-1, best_block_size + 1):
					# 只在区块边缘生成道路
					if x_offset == -1 or x_offset == best_block_size or y_offset == -1 or y_offset == best_block_size:
						var road_x = best_x + x_offset
						var road_y = best_y + y_offset
						var road_point = str(road_x) + "," + str(road_y)
						
						# 检查道路是否有效
						var is_valid = true
						is_valid = is_valid and mask.has(road_point)
						is_valid = is_valid and not primary_road.has(road_point)
						is_valid = is_valid and not gates.has(road_point)
						is_valid = is_valid and not walls.has(road_point)
						is_valid = is_valid and not gate_walls.has(road_point)
						is_valid = is_valid and not secondary_roads.has(road_point)
						
						# 检查是否在已生成的区块中
						var in_block = false
						for block in blocks.values():
							if block["nodes"].has(road_point):
								in_block = true
								break
						is_valid = is_valid and not in_block
						
						is_valid = is_valid and occupied.has(road_point)
						
						if is_valid:
							secondary_roads.append(road_point)
							# 从occupied中移除次级道路节点
							if occupied.has(road_point):
								occupied.erase(road_point)
		
		block_id += 1
		
		# 限制区块数量，防止无限循环
		if block_id > 100:
			break
	
	# 后处理：检查次级道路
	var secondary_roads_to_remove = []
	var new_blocks = {}
	
	# 找出所有次级道路的连通组件
	var secondary_roads_set = {}
	for road_point in secondary_roads:
		secondary_roads_set[road_point] = true
	var visited = {}
	var connected_components = []
	
	for road_point in secondary_roads:
		if not visited.has(road_point):
			# BFS找出连通组件
			var component = []
			var queue = []
			queue.append(road_point)
			visited[road_point] = true
			
			while queue.size() > 0:
				var current = queue.pop_front()
				component.append(current)
				
				var x = int(current.split(",")[0])
				var y = int(current.split(",")[1])
				
				for direction in directions:
					var dx = direction[0]
					var dy = direction[1]
					var neighbor_x = x + dx
					var neighbor_y = y + dy
					var neighbor_point = str(neighbor_x) + "," + str(neighbor_y)
					
					if secondary_roads_set.has(neighbor_point) and not visited.has(neighbor_point):
						visited[neighbor_point] = true
						queue.append(neighbor_point)
			
			connected_components.append(component)
	
	# 检查每个连通组件是否与其他道路连通
	for component in connected_components:
		var is_connected = false
		
		for road_point in component:
			var x = int(road_point.split(",")[0])
			var y = int(road_point.split(",")[1])
			
			for direction in directions:
				var dx = direction[0]
				var dy = direction[1]
				var neighbor_x = x + dx
				var neighbor_y = y + dy
				var neighbor_point = str(neighbor_x) + "," + str(neighbor_y)
				
				# 检查邻居是否是道路节点（主干道）
				if primary_road.has(neighbor_point):
					is_connected = true
					break
			
			if is_connected:
				break
		
		# 如果不与其他道路连通，标记为移除
		if not is_connected:
			for road_point in component:
				secondary_roads_to_remove.append(road_point)
	
	# 移除不连通的次级道路节点，并添加回 occupied 中
	for road_point in secondary_roads_to_remove:
		if secondary_roads.has(road_point):
			secondary_roads.erase(road_point)
			# 将移除的次级道路节点添加回 occupied 中，以便生成后处理区块
			occupied[road_point] = true
			
			# 生成大小为1的区块
			var block_nodes = [road_point]
			new_blocks[str(block_id)] = {
				"size": [1, 1],
				"position": [int(road_point.split(",")[0]), int(road_point.split(",")[1])],
				"nodes": block_nodes
			}
			# 从occupied中移除区块节点
			if occupied.has(road_point):
				occupied.erase(road_point)
			block_id += 1
	
	# 合并新生成的区块
	for block_id_str in new_blocks.keys():
		blocks[block_id_str] = new_blocks[block_id_str]
	
	var result = wall_data.duplicate()
	result["blocks"] = blocks
	result["secondary_roads"] = secondary_roads
	return result

func step_4_1_recheck_edges(road_data: Dictionary) -> Dictionary:
	# 步骤 4.1: 在后处理后，对mask再进行一遍edge的检查
	# 检查mask节点是否应该是edge节点
	# 
	# 检查逻辑：
	# 1. 构建mask集合便于快速查找
	# 2. 重新检测edge节点
	# 3. 对每个mask节点，检查其九宫格内是否有无效节点
	# 4. 如果有无效节点，标记为edge节点
	# 5. 更新edges列表
	# 
	# Args:
	#     road_data: 包含mask和edges的字典
	#     - mask: 城镇区域的节点列表
	#     - edges: 城镇边缘的节点列表
	# 
	# Returns:
	#     更新后的road_data字典
	#     - edges: 更新后的边缘节点列表
	var mask = road_data.get("mask", [])
	var edges = road_data.get("edges", [])
	
	# 构建mask集合便于快速查找
	var mask_set = {}
	for node in mask:
		mask_set[node] = true
	
	# 重新检测edge节点
	var new_edges = []
	
	for point_str in mask:
		var parts = point_str.split(",")
		var x = int(parts[0])
		var y = int(parts[1])
		
		# 检查九宫格内是否有无效节点
		var has_invalid_neighbor = false
		for dx_off in [-1, 0, 1]:
			for dy_off in [-1, 0, 1]:
				if dx_off == 0 and dy_off == 0:
					continue
				var neighbor_x = x + dx_off
				var neighbor_y = y + dy_off
				var neighbor_point = str(neighbor_x) + "," + str(neighbor_y)
				
				# 检查邻居是否在mask中
				if not mask_set.has(neighbor_point):
					has_invalid_neighbor = true
					break
				if has_invalid_neighbor:
					break
			if has_invalid_neighbor:
				break
		
		# 如果九宫格内有无效节点，标记为edge
		if has_invalid_neighbor:
			new_edges.append(point_str)
	
	# 更新edges
	road_data["edges"] = new_edges

	return road_data

func validate_edge_connectivity(wall_data: Dictionary) -> void:
	# 步骤 4.2: 进行edge合法性校对
	# 检查edge是否首尾相连
	# 
	# 验证逻辑：
	# 1. 构建edge集合便于快速查找
	# 2. 计算每个edge节点的邻居数量（十字线方向）
	# 3. 检查是否有节点只有一个邻居（首尾节点）
	# 4. 如果首尾节点数量不是0或2，说明edge不合法
	# 
	# Args:
	#     wall_data: 包含edges的字典
	#     - edges: 城镇边缘的节点列表
	# 
	# Returns:
	#     无返回值，仅在不合法时打印错误信息
	var edges = wall_data.get("edges", [])
	if edges.size() == 0:
		return
	
	# 构建edge集合便于快速查找
	var edge_set = {}
	for node in edges:
		edge_set[node] = true
	
	# 计算每个edge节点的邻居数量（十字线方向）
	var node_neighbors = {}
	
	for edge_point in edges:
		var edge_parts = edge_point.split(",")
		var x = int(edge_parts[0])
		var y = int(edge_parts[1])
		var neighbors = []
		var directions = [[0, -1], [0, 1], [-1, 0], [1, 0]] # 上、下、左、右
		
		for dir in directions:
			var dx = dir[0]
			var dy = dir[1]
			var neighbor_x = x + dx
			var neighbor_y = y + dy
			var neighbor_point = str(neighbor_x) + "," + str(neighbor_y)
			if edge_set.has(neighbor_point):
				neighbors.append(neighbor_point)
		
		node_neighbors[edge_point] = neighbors
	
	# 检查是否有节点只有一个邻居（首尾节点）
	var end_nodes = []
	for edge_point in node_neighbors.keys():
		if node_neighbors[edge_point].size() == 1:
			end_nodes.append(edge_point)
	
	# 检查edge是否首尾相连，只有不合法时才打印错误信息
	if end_nodes.size() != 0 and end_nodes.size() != 2:
		# 不是闭合环也不是开放路径，说明edge不合法
		print("[ERROR] edge 合法性错误：不是首尾相连的")

func generate_final_data(block_data: Dictionary) -> Dictionary:
	# 生成最终数据
	# Args:
	#     block_data: 包含所有生成数据的字典
	# Returns:
	#     最终数据字典
	# 构建metadata
	var metadata = {
		"version": "1.0.2",
		"generated_at": Time.get_datetime_string_from_system(),
		"config": config,
		"size": [config["width"], config["height"]]
	}
	
	# 构建data
	# 处理center字段，转换为数组格式
	var center_str = block_data.get("center", "0,0")
	var center_parts = center_str.split(",")
	var center_arr = []
	for part in center_parts:
		center_arr.append(int(part))
	
	var data = {
		"mask": block_data.get("mask", []),
		"edges": block_data.get("edges", []),
		"center": center_arr,
		"nodes": block_data.get("mask", []),
		"blocks": block_data.get("blocks", {}),
		"primary_road": block_data.get("primary_road", []),
		"secondary_roads": block_data.get("secondary_roads", []),
		"walls": block_data.get("walls", []),
		"gates": block_data.get("gates", []),
		"gate_walls": block_data.get("gate_walls", []),
		"all_walls": block_data.get("all_walls", [])
	}
	
	# 构建total_nodes，映射每个节点的类型
	var total_nodes = {}
	
	# 标记mask节点
	for node in block_data.get("mask", []):
		total_nodes[node] = {"type": "mask"}
	
	# 标记center节点
	if block_data.has("center"):
		total_nodes[block_data["center"]] = {"type": "center"}
	
	# 标记primary_road节点
	for node in block_data.get("primary_road", []):
		total_nodes[node] = {"type": "primary_road"}
	
	# 标记secondary_roads节点
	for node in block_data.get("secondary_roads", []):
		total_nodes[node] = {"type": "secondary_road"}
	
	# 标记walls节点
	for node in block_data.get("walls", []):
		total_nodes[node] = {"type": "wall"}
	
	# 标记gates节点
	for node in block_data.get("gates", []):
		total_nodes[node] = {"type": "gate"}
	
	# 标记gate_walls节点
	for node in block_data.get("gate_walls", []):
		total_nodes[node] = {"type": "gate_wall"}
	
	# 添加total_nodes到data
	data["total_nodes"] = total_nodes
	
	return {
		"metadata": metadata,
		"data": data
	}
