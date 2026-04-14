## 地图生成器 - 基于 Simplex 噪声的程序化城镇生成
## 实现了完整的管线化生成流程，支持多种配置和可视化

import random
import json
import math
import os
from datetime import datetime

## 日志输出函数
def log_message(message):
    """
    同时在控制台和output.log文件中输出日志
    """
    print(message)
    # 确保output目录存在
    if not os.path.exists("output"):
        os.makedirs("output")
    # 写入日志文件
    with open("output/output.log", "a", encoding="utf-8") as f:
        f.write(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] {message}\n")


## 节点颜色定义
NODE_COLOR = {
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

## 辅助函数：获取两点之间的所有整数坐标点
def get_points_between(start_x, start_y, end_x, end_y):
    """
    获取两点之间的所有整数坐标点（包含起点，不包含终点）
    使用 Bresenham 直线算法
    """
    points = []
    dx = abs(end_x - start_x)
    dy = abs(end_y - start_y)
    sx = 1 if start_x < end_x else -1
    sy = 1 if start_y < end_y else -1
    err = dx - dy
    
    x, y = start_x, start_y
    
    while True:
        points.append(f"{x},{y}")
        if x == end_x and y == end_y:
            break
        e2 = 2 * err
        if e2 > -dy:
            err -= dy
            x += sx
        if e2 < dx:
            err += dx
            y += sy
    
    # 移除最后一个点（终点），只保留起点到终点之间的点
    if points:
        points.pop()
    
    return points

## 辅助函数：计算点到中心的距离
def distance_to_center(x, y, center_x, center_y):
    """
    计算点到中心的距离
    """
    return math.sqrt((x - center_x) ** 2 + (y - center_y) ** 2)


# 内置的 Simplex 噪声实现
class SimplexNoise:
    def __init__(self, seed):
        self.seed = seed
        self.perm = list(range(256))
        rng = random.Random(seed)  # 使用独立的随机数生成器
        rng.shuffle(self.perm)
        self.perm += self.perm
    
    def noise2d(self, x, y, scale=0.05):
        x = x * scale
        y = y * scale
        
        # 基础 Simplex 噪声实现
        F2 = 0.5 * (math.sqrt(3.0) - 1.0)
        G2 = (3.0 - math.sqrt(3.0)) / 6.0
        
        s = (x + y) * F2
        i = int(math.floor(x + s))
        j = int(math.floor(y + s))
        t = (i + j) * G2
        X0 = i - t
        Y0 = j - t
        x0 = x - X0
        y0 = y - Y0
        
        if x0 > y0:
            i1, j1 = 1, 0
        else:
            i1, j1 = 0, 1
        
        x1 = x0 - i1 + G2
        y1 = y0 - j1 + G2
        x2 = x0 - 1.0 + 2.0 * G2
        y2 = y0 - 1.0 + 2.0 * G2
        
        i &= 255
        j &= 255
        n0 = self._grad(self.perm[i + self.perm[j]], x0, y0)
        n1 = self._grad(self.perm[i + i1 + self.perm[j + j1]], x1, y1)
        n2 = self._grad(self.perm[i + 1 + self.perm[j + 1]], x2, y2)
        
        return 70.0 * (n0 + n1 + n2)
    
    def _grad(self, hash_val, x, y):
        h = hash_val & 7
        u = y if h < 4 else x
        v = x if h < 4 else y
        return (u if (h & 1) == 0 else -u) + (v if (h & 2) == 0 else -v)

# 尝试导入噪声库，如果有则使用
try:
    from noise import snoise2
    # 覆盖 SimplexNoise 类以使用外部库
    class SimplexNoise:
        def __init__(self, seed):
            self.seed = seed
        
        def noise2d(self, x, y, scale=0.05):
            return snoise2(x * scale, y * scale, octaves=3, persistence=0.5, lacunarity=2.0, repeatx=1024, repeaty=1024, base=self.seed)
except ImportError:
    # 噪声库不可用，使用内置实现
    pass

# 生成配置
def gen_config(size=None, shape=None, seed=None):
    """
    生成地图生成器配置
    Args:
        size: 城镇尺寸 (SMALL/MEDIUM/LARGE)
        shape: 城镇形状 (CIRCLE/RECTANGLE)
        seed: 随机种子
    Returns:
        配置字典
    """
    # 使用提供的种子或生成随机种子
    if seed is None:
        seed = random.randint(0, 999999)
    
    rng = random.Random(seed)
    
    # 尺寸配置
    size_options = ["SMALL", "MEDIUM", "LARGE"]
    if size is None:
        size = rng.choice(size_options)
    
    # 形状配置
    shape_options = ["CIRCLE", "RECTANGLE"]
    if shape is None:
        shape = rng.choice(shape_options)
    
    # 根据尺寸确定宽高范围
    if size == "SMALL":
        width = rng.randint(12, 16)
        height = rng.randint(12, 16)
    elif size == "MEDIUM":
        width = rng.randint(16, 22)
        height = rng.randint(16, 22)
    else:  # LARGE
        width = rng.randint(22, 30)
        height = rng.randint(22, 30)
    
    # 生成不规则强度和长度
    irregularity_strength = rng.uniform(8, 16)
    irregularity_length = rng.uniform(4, 8)  # 控制噪声偏移的范围
    
    return {
        "size": size,
        "shape": shape,
        "seed": seed,
        "width": width,
        "height": height,
        "irregularity_strength": irregularity_strength,
        "irregularity_length": irregularity_length
    }

class MapGenerator:
    """
    地图生成器类
    """
    def __init__(self, config):
        """
        初始化地图生成器
        Args:
            config: 配置字典
        """
        self.config = config
        self.seed = config["seed"]
        self.rng = random.Random(self.seed)
        self.noise = SimplexNoise(self.seed)
        self.steps = []
        self.output_dir = "output"
        
        # 创建输出目录
        if not os.path.exists(self.output_dir):
            os.makedirs(self.output_dir)
    
    def run(self):
        """
        运行完整的生成流程
        Returns:
            最终生成数据
        """
        # 步骤 1: 生成基础轮廓
        mask_data = self.step_1_generate_mask()
        self.steps.append(mask_data)
        
        # 步骤 2: 确定城镇中心
        center_data = self.step_2_determine_center(mask_data)
        self.steps.append(center_data)
        
        # 步骤 3: 生成主干道与城门
        road_data = self.step_3_generate_roads(center_data)
        self.steps.append(road_data)
        
        # 步骤 4: edge 后处理（已在step_1_generate_mask中完成）
        
        # 步骤 4.1: 在后处理后，对mask再进行一遍edge的检查
        road_data = self.step_4_1_recheck_edges(road_data)
        
        # 步骤 4.2: 进行edge合法性校对
        self.validate_edge_connectivity(road_data)
        
        # 步骤 5: 生成城墙
        wall_data = self.step_4_generate_walls(road_data)
        self.steps.append(wall_data)
        
        # 步骤 6: 生成区块与次级道路
        block_data = self.step_5_generate_blocks(wall_data)
        self.steps.append(block_data)
        
        # 生成最终数据
        final_data = self.generate_final_data(block_data)
        
        # 保存最终数据
        self.save_final_data(final_data)
        
        return final_data
    
    def step_1_generate_mask(self):
        """
        步骤 1: 生成城镇基础轮廓
        Returns:
            包含mask和edges的字典
        """
        width = self.config["width"]
        height = self.config["height"]
        shape = self.config["shape"]
        irregularity_strength = self.config.get("irregularity_strength", 1.0)
        irregularity_length = self.config.get("irregularity_length", 2.0)  # 控制噪声偏移的范围
        
        # 为种子9强制设置更大的不规则强度和长度，用于测试
        if self.config.get("seed") == 9:
            irregularity_strength = 8.0  # 更大的噪声强度
            irregularity_length = 6.0  # 更大的噪声偏移范围
        
        # 计算噪声偏移可能需要的边界扩展
        max_noise_offset = irregularity_length
        expand_amount = int(math.ceil(max_noise_offset)) + 2  # 额外加2以确保覆盖所有可能的偏移
        
        # 计算中心坐标
        center_x = width // 2
        center_y = height // 2
        
        # 步骤1: 生成原始mask（无噪声）
        original_mask = []
        
        # 遍历原始地图范围
        for y in range(height):
            for x in range(width):
                # 基础形状判断（无噪声）
                should_be_in_mask = False
                if shape == "CIRCLE":
                    # 圆形：距离中心不超过最大半径
                    distance = math.sqrt((x - center_x) ** 2 + (y - center_y) ** 2)
                    max_radius = min(width, height) // 2
                    should_be_in_mask = distance <= max_radius
                else:  # RECTANGLE
                    # 矩形：在边界内
                    should_be_in_mask = True
                
                if should_be_in_mask:
                    original_mask.append(f"{x},{y}")
        
        # 步骤2: 对原始mask做完整的edge标记
        original_edges = []
        
        # 对原始mask中的每个点进行边缘检测
        for point_str in original_mask:
            x, y = map(int, point_str.split(","))
            
            # 检查九宫格内是否有无效节点
            has_invalid_neighbor = False
            for dx_off in [-1, 0, 1]:
                for dy_off in [-1, 0, 1]:
                    if dx_off == 0 and dy_off == 0:
                        continue
                    neighbor_x = x + dx_off
                    neighbor_y = y + dy_off
                    neighbor_point = f"{neighbor_x},{neighbor_y}"
                    
                    # 检查邻居是否在原始mask中
                    if neighbor_point not in original_mask:
                        has_invalid_neighbor = True
                        break
                if has_invalid_neighbor:
                    break
            
            # 如果九宫格内有无效节点，标记为edge
            if has_invalid_neighbor:
                original_edges.append(point_str)
        
        # 可视化原始mask和edges
        self.visualize_step(0, "original_mask", original_mask, original_edges)
        
        # 步骤3: 对原始edge应用噪声偏移
        mask = original_mask.copy()
        edge_offsets = []
        
        # 对每个原始边缘点应用噪声偏移
        for point_str in original_edges:
            x, y = map(int, point_str.split(","))
            
            # 使用多层噪声增加不规则性
            noise_value_1 = self.noise.noise2d(x, y, scale=0.05)  # 低频噪声
            noise_value_2 = self.noise.noise2d(x, y, scale=0.1)  # 中频噪声
            noise_value_3 = self.noise.noise2d(x, y, scale=0.15)   # 高频噪声
            
            # 叠加不同频率的噪声
            combined_noise = noise_value_1 * 0.5 + noise_value_2 * 0.3 + noise_value_3 * 0.2
            
            # 归一化噪声到 [-1, 1] 范围
            if abs(combined_noise) > 10:
                normalized_noise = max(-1.0, min(1.0, combined_noise / 210.0))
            else:
                normalized_noise = max(-1.0, min(1.0, combined_noise))
            
            # 映射噪声到 [-irregularity_length, irregularity_length]
            noise_offset = normalized_noise * irregularity_length
            
            # 计算偏移后的坐标
            # 对于圆形，朝径向方向偏移
            # 对于矩形，朝垂直于边缘的方向偏移
            offset_x, offset_y = x, y
            is_outward = False
            
            if shape == "CIRCLE":
                # 计算径向方向
                if x != center_x or y != center_y:
                    # 计算单位向量
                    distance = math.sqrt((x - center_x) ** 2 + (y - center_y) ** 2)
                    if distance > 0:
                        dx = (x - center_x) / distance
                        dy = (y - center_y) / distance
                        # 应用偏移
                        offset_x = round(x + dx * noise_offset)
                        offset_y = round(y + dy * noise_offset)
                
                # 检查是否向外偏移
                original_distance = math.sqrt((x - center_x) ** 2 + (y - center_y) ** 2)
                new_distance = math.sqrt((offset_x - center_x) ** 2 + (offset_y - center_y) ** 2)
                is_outward = new_distance > original_distance
            else:  # RECTANGLE
                # 计算到各边的距离
                distance_to_left = x
                distance_to_right = width - 1 - x
                distance_to_top = y
                distance_to_bottom = height - 1 - y
                min_distance = min(distance_to_left, distance_to_right, distance_to_top, distance_to_bottom)
                
                # 根据最近的边计算偏移方向
                if distance_to_left == min_distance:
                    # 朝左或右偏移
                    offset_x = round(x - noise_offset)  # 负噪声向左偏移，正噪声向右偏移
                    is_outward = offset_x < 0
                elif distance_to_right == min_distance:
                    # 朝右或左偏移
                    offset_x = round(x + noise_offset)  # 正噪声向右偏移，负噪声向左偏移
                    is_outward = offset_x > width - 1
                elif distance_to_top == min_distance:
                    # 朝上或下偏移
                    offset_y = round(y - noise_offset)  # 负噪声向上偏移，正噪声向下偏移
                    is_outward = offset_y < 0
                elif distance_to_bottom == min_distance:
                    # 朝下或上偏移
                    offset_y = round(y + noise_offset)  # 正噪声向下偏移，负噪声向上偏移
                    is_outward = offset_y > height - 1
            
            # 取消边界限制，允许偏移超出原始地图边界
            # 注：这样会实现真正的地图拓展
            
            # 存储边缘点的偏移信息
            edge_offsets.append((x, y, offset_x, offset_y, is_outward))
        
        # 创建集合便于快速查找
        mask_set = set(mask)
        
        # 存储需要移除的节点
        nodes_to_remove = set()
        # 存储需要添加的mask节点
        nodes_to_add = set()
        # 存储偏移后的边缘点
        offset_edges = []
        
        # 处理每个边缘点的偏移
        for orig_x, orig_y, offset_x, offset_y, is_outward in edge_offsets:
            # 获取原始点和偏移点之间的所有节点
            intermediate_nodes = get_points_between(orig_x, orig_y, offset_x, offset_y)
            
            # 移除中间节点
            for node in intermediate_nodes:
                nodes_to_remove.add(node)
            
            # 如果是向外偏移，添加中间节点到mask
            if is_outward:
                for node in intermediate_nodes:
                    # 取消边界检查，允许添加超出原始范围的节点
                    # 注：这样会实现真正的地图拓展
                    nodes_to_add.add(node)
            
            # 添加偏移后的边缘点
            offset_edges.append(f"{offset_x},{offset_y}")
        
        # 应用移除和添加操作
        mask_set = mask_set - nodes_to_remove
        mask_set = mask_set.union(nodes_to_add)
        
        # 转换回列表
        mask = list(mask_set)
        
        # 步骤5: 移除所有现有的edge，重新检测edge
        # 完全移除所有edge
        final_edges = []
        
        # 重新对mask进行edge检测
        for point_str in mask:
            x, y = map(int, point_str.split(","))
            
            # 检查九宫格内是否有无效节点
            has_invalid_neighbor = False
            for dx_off in [-1, 0, 1]:
                for dy_off in [-1, 0, 1]:
                    if dx_off == 0 and dy_off == 0:
                        continue
                    neighbor_x = x + dx_off
                    neighbor_y = y + dy_off
                    neighbor_point = f"{neighbor_x},{neighbor_y}"
                    
                    # 检查邻居是否在调整后的mask中
                    if neighbor_point not in mask:
                        has_invalid_neighbor = True
                        break
                if has_invalid_neighbor:
                    break
            
            # 如果九宫格内有无效节点，标记为edge
            if has_invalid_neighbor:
                final_edges.append(point_str)
        
        # 导出一份edge的图片可视化结果
        self.visualize_step(0, "5.refind_edge", mask, edges=final_edges)

        # 步骤6: 检查十字线上的邻居，移除只有一个邻居的edge节点
        edges_to_remove = set()
        
        # 使用队列来处理被移除节点的邻居
        from collections import deque
        check_queue = deque()
        checked = set()
        
        # 初始队列包含所有edge节点
        for edge_point in final_edges:
            check_queue.append(edge_point)
            checked.add(edge_point)
        
        while check_queue:
            edge_point = check_queue.popleft()
            x, y = map(int, edge_point.split(","))
            
            # 检查十字线方向的邻居（上、下、左、右）
            cross_neighbors = []
            directions = [(0, -1), (0, 1), (-1, 0), (1, 0)]  # 上、下、左、右
            
            for dx, dy in directions:
                neighbor_x = x + dx
                neighbor_y = y + dy
                neighbor_point = f"{neighbor_x},{neighbor_y}"
                
                if neighbor_point in mask and neighbor_point not in edges_to_remove:
                    cross_neighbors.append(neighbor_point)
            
            # 如果十字线上只有一个邻居，移除该edge节点
            if len(cross_neighbors) == 1:
                edges_to_remove.add(edge_point)
                
                # 将被移除节点的横竖邻居加入检查队列
                for dx, dy in directions:
                    neighbor_x = x + dx
                    neighbor_y = y + dy
                    neighbor_point = f"{neighbor_x},{neighbor_y}"
                    
                    if neighbor_point in mask and neighbor_point not in edges_to_remove:
                        check_queue.append(neighbor_point)
                        checked.add(neighbor_point)
        
        # 应用移除操作
        final_edges = [edge for edge in final_edges if edge not in edges_to_remove]
        mask = [node for node in mask if node not in edges_to_remove]
        
        # # 导出一份edge的图片可视化结果
        # self.visualize_step(0, "6.refind_edge", mask, edges=final_edges)

        # 步骤7: 对edge进行后处理，标记必要节点和移除节点
        
        # 节点状态：0=未标记，1=必要节点，2=移除节点
        node_status = {}
        for edge_point in final_edges:
            node_status[edge_point] = 0
        
        # 步骤7.1: 找到符合条件的起始节点
        start_node = None
        for edge_point in final_edges:
            x, y = map(int, edge_point.split(","))
            
            # 检查九宫格内的横邻居和竖邻居数量
            horizontal_neighbors = 0
            vertical_neighbors = 0
            
            # 水平方向（左、右）
            for dx in [-1, 1]:
                neighbor_point = f"{x+dx},{y}"
                if neighbor_point in final_edges:
                    horizontal_neighbors += 1
            
            # 垂直方向（上、下）
            for dy in [-1, 1]:
                neighbor_point = f"{x},{y+dy}"
                if neighbor_point in final_edges:
                    vertical_neighbors += 1
            
            # 条件：横邻居为2或竖邻居为2
            if horizontal_neighbors == 2 or vertical_neighbors == 2:
                start_node = edge_point
                node_status[start_node] = 1  # 标记为必要节点
                break
        
        # 步骤7.2: 广度优先遍历所有edge节点
        if start_node:
            from collections import deque
            queue = deque()
            visited = set()  # 使用visited集合跟踪处理状态
            
            queue.append(start_node)
            visited.add(start_node)  # 只有加入队列时标记为visited
            
            while queue:
                current_node = queue.popleft()
                x, y = map(int, current_node.split(","))
                
                # 检查横竖方向的邻居
                cross_neighbors = []
                directions = [(0, -1), (0, 1), (-1, 0), (1, 0)]  # 上、下、左、右
                
                for dx, dy in directions:
                    neighbor_point = f"{x+dx},{y+dy}"
                    if neighbor_point in final_edges:
                        cross_neighbors.append(neighbor_point)
                
                # 当前节点的横竖邻居数量
                neighbor_count = len(cross_neighbors)
                
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
                            visited.add(neighbor)
                        elif node_status[neighbor] == 0:
                            # 未标记的邻居，标记为必要节点
                            node_status[neighbor] = 1
                            if neighbor not in visited:
                                queue.append(neighbor)
                                visited.add(neighbor)
                
                # 将未处理的邻居加入队列
                for neighbor in cross_neighbors:
                    if neighbor not in visited:
                        queue.append(neighbor)
                        visited.add(neighbor)
        
        # 步骤7.3: 移除非必要节点
        non_essential_nodes = set()
        for edge_point, status in node_status.items():
            if status != 1:
                non_essential_nodes.add(edge_point)
        
        # 应用移除操作
        final_edges = [edge for edge in final_edges if edge not in non_essential_nodes]
        mask = [node for node in mask if node not in non_essential_nodes]
        
        # 去重
        mask = list(set(mask))
        final_edges = list(set(final_edges))
        
        # 可视化最终结果
        self.visualize_step(0, "final_mask", mask, final_edges)
        
        return {
            "mask": mask,
            "edges": final_edges,
            "width": width,
            "height": height
        }
    
    def step_2_determine_center(self, mask_data):
        """
        步骤 2: 确定城镇中心
        Args:
            mask_data: 包含mask的字典
        Returns:
            包含center的字典
        """
        mask = mask_data["mask"]
        width = mask_data["width"]
        height = mask_data["height"]
        
        # 计算几何中心
        center_x = width // 2
        center_y = height // 2
        geometric_center = f"{center_x},{center_y}"
        
        # 检查几何中心是否在mask内
        if geometric_center in mask:
            center = geometric_center
        else:
            # 找到离几何中心最近的有效点
            min_distance = float('inf')
            closest_point = None
            
            for point_str in mask:
                x, y = map(int, point_str.split(","))
                distance = math.sqrt((x - center_x) ** 2 + (y - center_y) ** 2)
                if distance < min_distance:
                    min_distance = distance
                    closest_point = point_str
            
            center = closest_point
        
        # 可视化
        self.visualize_step(1, "center", mask, mask_data["edges"], center)
        
        result = mask_data.copy()
        result["center"] = center
        return result
    
    def step_3_generate_roads(self, center_data):
        """
        步骤 3: 生成主干道与城门
        Args:
            center_data: 包含center的字典
        Returns:
            包含primary_road和gates的字典
        """
        mask = center_data["mask"]
        edges = center_data["edges"].copy()  # 复制一份，以便修改
        center = center_data["center"]
        width = center_data["width"]
        height = center_data["height"]
        

        
        center_x, center_y = map(int, center.split(","))
        primary_road = []
        gates = []
        gate_walls = []
        
        # 四个方向的主干道
        directions = [
            (0, -1, "up"),    # 上
            (0, 1, "down"),   # 下
            (-1, 0, "left"),  # 左
            (1, 0, "right")   # 右
        ]
        
        for dx, dy, direction in directions:
            x, y = center_x, center_y
            last_point = None
            
            while True:
                last_point = f"{x},{y}"
                x += dx
                y += dy
                current_point = f"{x},{y}"
                
                # 检查是否在mask内
                if current_point not in mask:
                    # 检查last_point是否是边缘，如果是则作为城门
                    if last_point in edges:
                        gates.append(last_point)
                        # 将last_point从edges中移除
                        if last_point in edges:
                            edges.remove(last_point)
                    # 同时检查last_point是否在primary_road中，如果在则移除
                    if last_point in primary_road:
                        primary_road.remove(last_point)
                    break
                
                # 检查是否到达边缘
                if current_point in edges:
                    # 检查下一个点是否在mask内（判断是否是最后一个轮廓）
                    next_x = x + dx
                    next_y = y + dy
                    next_point = f"{next_x},{next_y}"
                    is_last_contour = next_point not in mask
                    
                    if is_last_contour:
                        # 是最后一个轮廓，将current_point作为城门
                        gates.append(current_point)
                        
                        # 将current_point从edges中移除
                        if current_point in edges:
                            edges.remove(current_point)
                        
                        # 生成城门城墙（在城门垂直主干道的两个方向）
                        gate_x, gate_y = map(int, current_point.split(","))
                        # 计算垂直方向的偏移
                        if dx != 0:  # 水平方向的主干道（左右）
                            # 垂直方向（上下）生成城门城墙
                            for dy_off in [-1, 1]:
                                wall_y = gate_y + dy_off
                                wall_point = f"{gate_x},{wall_y}"
                                # 直接添加城门城墙，不检查是否在mask中
                                gate_walls.append(wall_point)
                                # 将城门城墙节点添加到mask和edges中
                                if wall_point not in mask:
                                    mask.append(wall_point)
                                if wall_point not in edges:
                                    edges.append(wall_point)
                        else:  # 垂直方向的主干道（上下）
                            # 水平方向（左右）生成城门城墙
                            for dx_off in [-1, 1]:
                                wall_x = gate_x + dx_off
                                wall_point = f"{wall_x},{gate_y}"
                                # 直接添加城门城墙，不检查是否在mask中
                                gate_walls.append(wall_point)
                                # 将城门城墙节点添加到mask和edges中
                                if wall_point not in mask:
                                    mask.append(wall_point)
                                if wall_point not in edges:
                                    edges.append(wall_point)
                        
                        # 停止检查
                        break
                    elif last_point in mask:
                        # 轮廓后方有轮廓，将current_point作为主干道
                        primary_road.append(current_point)
                        
                        # 将current_point从edges中移除
                        if current_point in edges:
                            edges.remove(current_point)
                        
                        # 将后方轮廓作为触及点继续检查
                        # 继续循环，不break
                    else:
                        # 轮廓后方没有轮廓，将current_point作为城门
                        gates.append(current_point)
                        
                        # 将current_point从edges中移除
                        if current_point in edges:
                            edges.remove(current_point)
                        
                        # 停止检查
                        break
                else:
                    # 不是边缘，继续添加到主干道
                    primary_road.append(current_point)
        
        # 可视化
        self.visualize_step(2, "roads", mask, edges, center, primary_road, gates, None, gate_walls)
        
        result = center_data.copy()
        result["primary_road"] = primary_road
        result["gates"] = gates
        result["gate_walls"] = gate_walls
        result["edges"] = edges  # 更新edges，移除了触及点
        return result
    
    def step_4_generate_walls(self, road_data):
        """
        步骤 4: 生成城墙
        Args:
            road_data: 包含edges和gates的字典
        Returns:
            包含walls的字典
        """
        mask = road_data["mask"]
        edges = road_data["edges"]
        gates = road_data.get("gates", [])
        primary_road = road_data.get("primary_road", [])
        gate_walls = road_data.get("gate_walls", [])
        
        walls = []
        
        # 将轮廓的最远边缘生成为城墙，避开城门和城门城墙
        for point_str in edges:
            # 避开城门
            if point_str in gates:
                continue
            
            # 避开城门城墙
            if point_str in gate_walls:
                continue
            
            # 避开主干道
            if point_str in primary_road:
                continue
            
            # 检查当前节点九空格内的节点是否都是有效节点
            x, y = map(int, point_str.split(","))
            all_valid = True
            # 检查九空格内的所有节点
            for dx_off in [-1, 0, 1]:
                for dy_off in [-1, 0, 1]:
                    # 跳过自身
                    if dx_off == 0 and dy_off == 0:
                        continue
                    # 计算邻接点坐标
                    neighbor_x = x + dx_off
                    neighbor_y = y + dy_off
                    neighbor_point = f"{neighbor_x},{neighbor_y}"
                    # 检查邻接点是否在mask中
                    if neighbor_point not in mask:
                        all_valid = False
                        break
                if not all_valid:
                    break
            
            # 如果九空格内的节点都是有效节点，则当前节点不作为城墙节点，并将其从边缘节点中移除
            if all_valid:
                # 将当前节点从边缘节点中移除
                if point_str in edges:
                    edges.remove(point_str)
                continue
            
            walls.append(point_str)
        
        # 生成所有城墙（包含原始城墙和所有城门城墙）
        all_walls = walls + gate_walls
        
        # 可视化
        self.visualize_step(3, "walls", mask, edges, road_data["center"], primary_road, gates, walls, gate_walls)
        
        result = road_data.copy()
        result["walls"] = walls
        result["all_walls"] = all_walls
        return result
    
    def step_5_generate_blocks(self, wall_data):
        """
        步骤 5: 生成区块与次级道路
        Args:
            wall_data: 包含walls的字典
        Returns:
            包含blocks和secondary_roads的字典
        """
        mask = wall_data["mask"]
        center = wall_data["center"]
        primary_road = wall_data.get("primary_road", [])
        gates = wall_data.get("gates", [])
        walls = wall_data.get("walls", [])
        
        center_x, center_y = map(int, center.split(","))
        blocks = {}
        secondary_roads = []
        block_id = 1
        
        # 获取城门城墙和所有城墙
        gate_walls = wall_data.get("gate_walls", [])
        all_walls = wall_data.get("all_walls", [])
        
        # 已占用的位置
        occupied = set(mask) - set(primary_road) - set(gates) - set(walls) - set(gate_walls)
        
        # 检查点是否有效（不在障碍物中）
        def is_valid_point(x, y):
            point_str = f"{x},{y}"
            return (point_str in mask and 
                    point_str not in primary_road and 
                    point_str not in gates and 
                    point_str not in walls and
                    point_str not in gate_walls and
                    point_str not in secondary_roads and
                    point_str in occupied)
        
        # 从中心向外四个方向生成区块
        directions = [(0, -1), (0, 1), (-1, 0), (1, 0)]  # 上、下、左、右
        
        # 先尝试在中心附近生成第一个5x5的区块
        first_block_generated = False
        
        # 扩大搜索范围，确保能找到合适的位置生成第一个5x5区块
        search_range = 5  # 扩大搜索范围到5格
        for y_offset in range(-search_range, search_range + 1):
            for x_offset in range(-search_range, search_range + 1):
                if first_block_generated:
                    break
                
                # 计算起始点
                x = center_x + x_offset
                y = center_y + y_offset
                
                # 尝试生成5x5的区块
                block_size = 5
                block_valid = True
                block_nodes = []
                
                # 检查区块是否在有效范围内
                for y_off in range(block_size):
                    for x_off in range(block_size):
                        block_x = x + x_off
                        block_y = y + y_off
                        block_point = f"{block_x},{block_y}"
                        
                        # 检查是否有效
                        if block_point not in occupied:
                            block_valid = False
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
                        if node in occupied:
                            occupied.remove(node)
                    
                    # 在区块周边的空闲节点生成次级道路
                    # 当区块大小为1的时候，如果横竖方向上已经有次级道路，则该区块不生成周围的次级道路
                    if block_size == 1:
                        # 检查横竖方向上是否已经有次级道路
                        has_horizontal_road = False
                        has_vertical_road = False
                        
                        # 检查水平方向（左、右）
                        for dx in [-1, 1]:
                            check_point = f"{x+dx},{y}"
                            if check_point in secondary_roads or check_point in primary_road:
                                has_horizontal_road = True
                                break
                        
                        # 检查垂直方向（上、下）
                        for dy in [-1, 1]:
                            check_point = f"{x},{y+dy}"
                            if check_point in secondary_roads or check_point in primary_road:
                                has_vertical_road = True
                                break
                        
                        # 如果横竖方向上任意方向上都有次级道路，则不生成周围的次级道路
                        if not (has_horizontal_road or has_vertical_road):
                            # 生成次级道路
                            for y_off in range(-1, block_size + 1):
                                for x_off in range(-1, block_size + 1):
                                    # 只在区块边缘生成道路
                                    if x_off == -1 or x_off == block_size or y_off == -1 or y_off == block_size:
                                        road_x = x + x_off
                                        road_y = y + y_off
                                        road_point = f"{road_x},{road_y}"
                                        
                                        # 检查道路是否有效
                                        if (road_point in mask and 
                                            road_point not in primary_road and 
                                            road_point not in gates and 
                                            road_point not in walls and
                                            road_point not in gate_walls and
                                            road_point not in secondary_roads and
                                            road_point not in [node for block in blocks.values() for node in block["nodes"]] and
                                            road_point in occupied):
                                            secondary_roads.append(road_point)
                                            # 从occupied中移除次级道路节点
                                            if road_point in occupied:
                                                occupied.remove(road_point)
                    else:
                        # 区块大小不为1，正常生成次级道路
                        for y_off in range(-1, block_size + 1):
                            for x_off in range(-1, block_size + 1):
                                # 只在区块边缘生成道路
                                if x_off == -1 or x_off == block_size or y_off == -1 or y_off == block_size:
                                    road_x = x + x_off
                                    road_y = y + y_off
                                    road_point = f"{road_x},{road_y}"
                                    
                                    # 检查道路是否有效
                                    if (road_point in mask and 
                                        road_point not in primary_road and 
                                        road_point not in gates and 
                                        road_point not in walls and
                                        road_point not in gate_walls and
                                        road_point not in secondary_roads and
                                        road_point not in [node for block in blocks.values() for node in block["nodes"]] and
                                        road_point in occupied):
                                        secondary_roads.append(road_point)
                                        # 从occupied中移除次级道路节点
                                        if road_point in occupied:
                                            occupied.remove(road_point)
                    
                    block_id += 1
                    first_block_generated = True
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
                        x = center_x + x_offset
                        y = center_y + y_offset
                        
                        # 尝试生成区块
                        block_valid = True
                        block_nodes = []
                        
                        # 检查区块是否在有效范围内
                        for y_off in range(block_size):
                            for x_off in range(block_size):
                                block_x = x + x_off
                                block_y = y + y_off
                                block_point = f"{block_x},{block_y}"
                                
                                # 检查是否有效
                                if block_point not in occupied:
                                    block_valid = False
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
                                if node in occupied:
                                    occupied.remove(node)
                            
                            # 在区块周边的空闲节点生成次级道路
                            # 当区块大小为1的时候，如果横竖方向上已经有次级道路，则该区块不生成周围的次级道路
                            if block_size == 1:
                                # 检查横竖方向上是否已经有次级道路
                                has_horizontal_road = False
                                has_vertical_road = False
                                
                                # 检查水平方向（左、右）
                                for dx in [-1, 1]:
                                    check_point = f"{x+dx},{y}"
                                    if check_point in secondary_roads or check_point in primary_road:
                                        has_horizontal_road = True
                                        break
                                
                                # 检查垂直方向（上、下）
                                for dy in [-1, 1]:
                                    check_point = f"{x},{y+dy}"
                                    if check_point in secondary_roads or check_point in primary_road:
                                        has_vertical_road = True
                                        break
                                
                                # 如果横竖方向上任意方向上都有次级道路，则不生成周围的次级道路
                                if not (has_horizontal_road or has_vertical_road):
                                    # 生成次级道路
                                    for y_off in range(-1, block_size + 1):
                                        for x_off in range(-1, block_size + 1):
                                            # 只在区块边缘生成道路
                                            if x_off == -1 or x_off == block_size or y_off == -1 or y_off == block_size:
                                                road_x = x + x_off
                                                road_y = y + y_off
                                                road_point = f"{road_x},{road_y}"
                                                
                                                # 检查道路是否有效
                                                if (road_point in mask and 
                                                    road_point not in primary_road and 
                                                    road_point not in gates and 
                                                    road_point not in walls and
                                                    road_point not in gate_walls and
                                                    road_point not in secondary_roads and
                                                    road_point not in [node for block in blocks.values() for node in block["nodes"]] and
                                                    road_point in occupied):
                                                    secondary_roads.append(road_point)
                                                    # 从occupied中移除次级道路节点
                                                    if road_point in occupied:
                                                        occupied.remove(road_point)
                            else:
                                # 区块大小不为1，正常生成次级道路
                                for y_off in range(-1, block_size + 1):
                                    for x_off in range(-1, block_size + 1):
                                        # 只在区块边缘生成道路
                                        if x_off == -1 or x_off == block_size or y_off == -1 or y_off == block_size:
                                            road_x = x + x_off
                                            road_y = y + y_off
                                            road_point = f"{road_x},{road_y}"
                                            
                                            # 检查道路是否有效
                                            if (road_point in mask and 
                                                road_point not in primary_road and 
                                                road_point not in gates and 
                                                road_point not in walls and
                                                road_point not in gate_walls and
                                                road_point not in secondary_roads and
                                                road_point not in [node for block in blocks.values() for node in block["nodes"]] and
                                                road_point in occupied):
                                                secondary_roads.append(road_point)
                                                # 从occupied中移除次级道路节点
                                                if road_point in occupied:
                                                    occupied.remove(road_point)
                            
                            block_id += 1
                            first_block_generated = True
                            break
                    if first_block_generated:
                        break
        
        # 区块生成逻辑：循环生成区块，直到没有可用点
        while occupied:
            # 收集当前所有可用点，并计算每个点作为不同大小区块起始点时的最佳距离
            best_candidates = []
            
            for point_str in occupied:
                x, y = map(int, point_str.split(","))
                
                # 尝试不同大小的区块
                for block_size in [5, 4, 3, 2, 1]:
                    # 计算区块的四个角坐标
                    block_corners = [
                        (x, y),              # 左上角
                        (x + block_size - 1, y),  # 右上角
                        (x, y + block_size - 1),  # 左下角
                        (x + block_size - 1, y + block_size - 1)  # 右下角
                    ]
                    
                    # 计算区块中心坐标
                    block_center_x = x + block_size / 2.0
                    block_center_y = y + block_size / 2.0
                    
                    # 计算区块中心到城镇中心的距离
                    min_distance = math.sqrt((block_center_x - center_x) ** 2 + (block_center_y - center_y) ** 2)
                    
                    # 找到最接近中心的角点（用于可视化）
                    closest_corner = None
                    min_corner_distance = float('inf')
                    for corner in block_corners:
                        corner_distance = math.sqrt((corner[0] - center_x) ** 2 + (corner[1] - center_y) ** 2)
                        if corner_distance < min_corner_distance:
                            min_corner_distance = corner_distance
                            closest_corner = corner
                    
                    # 检查区块是否在有效范围内
                    block_valid = True
                    block_nodes = []
                    
                    for y_offset in range(block_size):
                        for x_offset in range(block_size):
                            block_x = x + x_offset
                            block_y = y + y_offset
                            block_point = f"{block_x},{block_y}"
                            
                            # 检查是否有效
                            if block_point not in occupied:
                                block_valid = False
                                break
                            
                            block_nodes.append(block_point)
                        
                        if not block_valid:
                            break
                    
                    if block_valid:
                        # 计算与主干道的最短距离
                        min_road_distance = float('inf')
                        # 使用之前计算好的区块中心坐标（取整）
                        block_center_x_int = int(x + block_size // 2)
                        block_center_y_int = int(y + block_size // 2)
                        for road_point in primary_road:
                            road_x, road_y = map(int, road_point.split(","))
                            # 计算区块中心到主干道的距离
                            road_distance = math.sqrt((block_center_x_int - road_x) ** 2 + (block_center_y_int - road_y) ** 2)
                            if road_distance < min_road_distance:
                                min_road_distance = road_distance
                        
                        # 添加到候选列表，优先选择距离中心近、大区块、距离主干道近的区块
                        # 优先级：距离中心距离 > 区块大小 > 距离主干道距离
                        # 确保区块生成顺序是从中心向外扩散的
                        # 使用整数距离（乘以 100 取整）来提高比较精度
                        int_distance = int(min_distance * 100)
                        int_road_distance = int(min_road_distance * 100)
                        priority = (-int_distance, block_size, -int_road_distance)
                        best_candidates.append((priority, min_distance, min_road_distance, block_size, x, y, closest_corner, block_nodes))
            
            # 如果没有候选区块，停止
            if not best_candidates:
                break
            
            # 按优先级排序，选择最佳候选
            best_candidates.sort(reverse=True)
            best_priority, best_distance, best_road_distance, best_block_size, best_x, best_y, best_corner, best_nodes = best_candidates[0]
            

            
            # 生成区块
            blocks[str(block_id)] = {
                "size": [best_block_size, best_block_size],
                "position": [best_x, best_y],
                "nodes": best_nodes
            }
            
            # 从occupied中移除区块节点
            for node in best_nodes:
                if node in occupied:
                    occupied.remove(node)
            
            # 在区块周边的空闲节点生成次级道路
            # 当区块大小为1的时候，如果横竖方向上已经有次级道路，则该区块不生成周围的次级道路
            if best_block_size == 1:
                # 检查横竖方向上是否已经有次级道路
                has_horizontal_road = False
                has_vertical_road = False
                
                # 检查水平方向（左、右）
                for dx in [-1, 1]:
                    check_point = f"{best_x+dx},{best_y}"
                    if check_point in secondary_roads or check_point in primary_road:
                        has_horizontal_road = True
                        break
                
                # 检查垂直方向（上、下）
                for dy in [-1, 1]:
                    check_point = f"{best_x},{best_y+dy}"
                    if check_point in secondary_roads or check_point in primary_road:
                        has_vertical_road = True
                        break
                
                # 如果横竖方向上任意方向上都有次级道路，则不生成周围的次级道路
                if not (has_horizontal_road or has_vertical_road):
                    # 生成次级道路
                    for y_offset in range(-1, best_block_size + 1):
                        for x_offset in range(-1, best_block_size + 1):
                            # 只在区块边缘生成道路
                            if x_offset == -1 or x_offset == best_block_size or y_offset == -1 or y_offset == best_block_size:
                                road_x = best_x + x_offset
                                road_y = best_y + y_offset
                                road_point = f"{road_x},{road_y}"
                                
                                # 检查道路是否有效
                                if (road_point in mask and 
                                    road_point not in primary_road and 
                                    road_point not in gates and 
                                    road_point not in walls and
                                    road_point not in gate_walls and
                                    road_point not in secondary_roads and
                                    road_point not in [node for block in blocks.values() for node in block["nodes"]] and
                                    road_point in occupied):
                                    secondary_roads.append(road_point)
                                    # 从occupied中移除次级道路节点
                                    if road_point in occupied:
                                        occupied.remove(road_point)
            else:
                # 区块大小不为1，正常生成次级道路
                for y_offset in range(-1, best_block_size + 1):
                    for x_offset in range(-1, best_block_size + 1):
                        # 只在区块边缘生成道路
                        if x_offset == -1 or x_offset == best_block_size or y_offset == -1 or y_offset == best_block_size:
                            road_x = best_x + x_offset
                            road_y = best_y + y_offset
                            road_point = f"{road_x},{road_y}"
                            
                            # 检查道路是否有效
                            if (road_point in mask and 
                                road_point not in primary_road and 
                                road_point not in gates and 
                                road_point not in walls and
                                road_point not in gate_walls and
                                road_point not in secondary_roads and
                                road_point not in [node for block in blocks.values() for node in block["nodes"]] and
                                road_point in occupied):
                                secondary_roads.append(road_point)
                                # 从occupied中移除次级道路节点
                                if road_point in occupied:
                                    occupied.remove(road_point)
            
            block_id += 1
            
            # 限制区块数量，防止无限循环
            if block_id > 100:
                break
        
        # 后处理：检查次级道路
        secondary_roads_to_remove = []
        new_blocks = {}
        
        # 找出所有次级道路的连通组件
        secondary_roads_set = set(secondary_roads)
        visited = set()
        connected_components = []
        
        for road_point in secondary_roads:
            if road_point not in visited:
                # BFS找出连通组件
                component = []
                queue = [road_point]
                visited.add(road_point)
                
                while queue:
                    current = queue.pop(0)
                    component.append(current)
                    
                    x, y = map(int, current.split(","))
                    directions = [(0, -1), (0, 1), (-1, 0), (1, 0)]  # 上、下、左、右
                    
                    for dx, dy in directions:
                        neighbor_x = x + dx
                        neighbor_y = y + dy
                        neighbor_point = f"{neighbor_x},{neighbor_y}"
                        
                        if neighbor_point in secondary_roads_set and neighbor_point not in visited:
                            visited.add(neighbor_point)
                            queue.append(neighbor_point)
                
                connected_components.append(component)
        
        # 检查每个连通组件是否与其他道路连通
        for component in connected_components:
            is_connected = False
            
            for road_point in component:
                x, y = map(int, road_point.split(","))
                directions = [(0, -1), (0, 1), (-1, 0), (1, 0)]  # 上、下、左、右
                
                for dx, dy in directions:
                    neighbor_x = x + dx
                    neighbor_y = y + dy
                    neighbor_point = f"{neighbor_x},{neighbor_y}"
                    
                    # 检查邻居是否是道路节点（主干道）
                    if neighbor_point in primary_road:
                        is_connected = True
                        break
                
                if is_connected:
                    break
            
            # 如果不与其他道路连通，标记为移除
            if not is_connected:
                for road_point in component:
                    secondary_roads_to_remove.append(road_point)
        
        # 移除不连通的次级道路节点，并添加回 occupied 中
        for road_point in secondary_roads_to_remove:
            if road_point in secondary_roads:
                secondary_roads.remove(road_point)
                # 将移除的次级道路节点添加回 occupied 中，以便生成后处理区块
                occupied.add(road_point)
                
                # 生成大小为1的区块
                block_nodes = [road_point]
                new_blocks[str(block_id)] = {
                    "size": [1, 1],
                    "position": list(map(int, road_point.split(","))),
                    "nodes": block_nodes
                }
                # 从occupied中移除区块节点
                occupied.remove(road_point)
                block_id += 1
        
        # 合并新生成的区块
        blocks.update(new_blocks)
        
        # 可视化（在区块后处理之后）
        self.visualize_step(4, "blocks", mask, wall_data["edges"], center, primary_road, gates, walls, wall_data.get("gate_walls", []), blocks, secondary_roads)
        
        result = wall_data.copy()
        result["blocks"] = blocks
        result["secondary_roads"] = secondary_roads
        return result
    
    def visualize_step(self, step_index, step_name, mask, edges=None, center=None, primary_road=None, gates=None, walls=None, gate_walls=None, blocks=None, secondary_roads=None):
        """
        可视化步骤结果
        Args:
            step_index: 步骤索引
            step_name: 步骤名称
            mask: 轮廓点
            edges: 边缘点
            center: 中心点
            primary_road: 主干道
            gates: 城门
            walls: 城墙
            gate_walls: 城门城墙
            blocks: 区块
            secondary_roads: 次级道路
        """
        try:
            import matplotlib.pyplot as plt
            import numpy as np
            
            # 确定地图尺寸
            min_x = float('inf')
            min_y = float('inf')
            max_x = 0
            max_y = 0
            
            for point_str in mask:
                x, y = map(int, point_str.split(","))
                if x < min_x:
                    min_x = x
                if y < min_y:
                    min_y = y
                if x > max_x:
                    max_x = x
                if y > max_y:
                    max_y = y
            
            # 计算实际地图尺寸
            map_width = max_x - min_x + 1
            map_height = max_y - min_y + 1
            
            # 创建图像
            grid_size = max(map_width, map_height)
            img_size = max(512, min(1024, grid_size * 32))
            img = np.ones((img_size, img_size, 4), dtype=np.float32)  # RGBA
            
            # 计算每个格子的大小
            cell_size = img_size / grid_size
            
            # 绘制mask
            for point_str in mask:
                x, y = map(int, point_str.split(","))
                # 计算格子在图像中的位置
                grid_x = x - min_x
                grid_y = y - min_y
                
                # 计算绘制区域
                start_x = int(grid_x * cell_size)
                start_y = int(grid_y * cell_size)
                end_x = int((grid_x + 1) * cell_size)
                end_y = int((grid_y + 1) * cell_size)
                
                # 确保坐标在有效范围内
                if start_x < img.shape[1] and start_y < img.shape[0]:
                    color = NODE_COLOR["mask"]
                    r, g, b = [c / 255.0 for c in color]
                    # 填充整个格子
                    img[start_y:end_y, start_x:end_x] = [r, g, b, 1.0]
            
            # 绘制edges
            if edges:
                for point_str in edges:
                    x, y = map(int, point_str.split(","))
                    # 计算格子在图像中的位置
                    grid_x = x - min_x
                    grid_y = y - min_y
                    
                    # 计算绘制区域
                    start_x = int(grid_x * cell_size)
                    start_y = int(grid_y * cell_size)
                    end_x = int((grid_x + 1) * cell_size)
                    end_y = int((grid_y + 1) * cell_size)
                    
                    # 确保坐标在有效范围内
                    if start_x < img.shape[1] and start_y < img.shape[0]:
                        color = NODE_COLOR["edge"]
                        r, g, b = [c / 255.0 for c in color]
                        # 填充整个格子
                        img[start_y:end_y, start_x:end_x] = [r, g, b, 1.0]
            
            # 绘制center
            if center:
                x, y = map(int, center.split(","))
                # 计算格子在图像中的位置
                grid_x = x - min_x
                grid_y = y - min_y
                
                # 计算绘制区域
                start_x = int(grid_x * cell_size)
                start_y = int(grid_y * cell_size)
                end_x = int((grid_x + 1) * cell_size)
                end_y = int((grid_y + 1) * cell_size)
                
                # 确保坐标在有效范围内
                if start_x < img.shape[1] and start_y < img.shape[0]:
                    color = NODE_COLOR["center"]
                    r, g, b = [c / 255.0 for c in color]
                    # 填充整个格子
                    img[start_y:end_y, start_x:end_x] = [r, g, b, 1.0]
            
            # 绘制primary_road
            if primary_road:
                for point_str in primary_road:
                    x, y = map(int, point_str.split(","))
                    # 计算格子在图像中的位置
                    grid_x = x - min_x
                    grid_y = y - min_y
                    
                    # 计算绘制区域
                    start_x = int(grid_x * cell_size)
                    start_y = int(grid_y * cell_size)
                    end_x = int((grid_x + 1) * cell_size)
                    end_y = int((grid_y + 1) * cell_size)
                    
                    # 确保坐标在有效范围内
                    if start_x < img.shape[1] and start_y < img.shape[0]:
                        color = NODE_COLOR["primary_road"]
                        r, g, b = [c / 255.0 for c in color]
                        # 填充整个格子
                        img[start_y:end_y, start_x:end_x] = [r, g, b, 1.0]
            
            # 绘制gates
            if gates:
                for point_str in gates:
                    x, y = map(int, point_str.split(","))
                    # 计算格子在图像中的位置
                    grid_x = x - min_x
                    grid_y = y - min_y
                    
                    # 计算绘制区域
                    start_x = int(grid_x * cell_size)
                    start_y = int(grid_y * cell_size)
                    end_x = int((grid_x + 1) * cell_size)
                    end_y = int((grid_y + 1) * cell_size)
                    
                    # 确保坐标在有效范围内
                    if start_x < img.shape[1] and start_y < img.shape[0]:
                        color = NODE_COLOR["gate"]
                        r, g, b = [c / 255.0 for c in color]
                        # 填充整个格子
                        img[start_y:end_y, start_x:end_x] = [r, g, b, 1.0]
            
            # 绘制walls
            if walls:
                for point_str in walls:
                    x, y = map(int, point_str.split(","))
                    # 计算格子在图像中的位置
                    grid_x = x - min_x
                    grid_y = y - min_y
                    
                    # 计算绘制区域
                    start_x = int(grid_x * cell_size)
                    start_y = int(grid_y * cell_size)
                    end_x = int((grid_x + 1) * cell_size)
                    end_y = int((grid_y + 1) * cell_size)
                    
                    # 确保坐标在有效范围内
                    if start_x < img.shape[1] and start_y < img.shape[0]:
                        color = NODE_COLOR["wall"]
                        r, g, b = [c / 255.0 for c in color]
                        # 填充整个格子
                        img[start_y:end_y, start_x:end_x] = [r, g, b, 1.0]
            
            # 绘制gate_walls
            if gate_walls:
                for point_str in gate_walls:
                    x, y = map(int, point_str.split(","))
                    # 计算格子在图像中的位置
                    grid_x = x - min_x
                    grid_y = y - min_y
                    
                    # 计算绘制区域
                    start_x = int(grid_x * cell_size)
                    start_y = int(grid_y * cell_size)
                    end_x = int((grid_x + 1) * cell_size)
                    end_y = int((grid_y + 1) * cell_size)
                    
                    # 确保坐标在有效范围内
                    if start_x < img.shape[1] and start_y < img.shape[0]:
                        color = NODE_COLOR["gate_wall"]
                        r, g, b = [c / 255.0 for c in color]
                        # 填充整个格子
                        img[start_y:end_y, start_x:end_x] = [r, g, b, 1.0]
            
            # 绘制secondary_roads
            if secondary_roads:
                for point_str in secondary_roads:
                    x, y = map(int, point_str.split(","))
                    # 计算格子在图像中的位置
                    grid_x = x - min_x
                    grid_y = y - min_y
                    
                    # 计算绘制区域
                    start_x = int(grid_x * cell_size)
                    start_y = int(grid_y * cell_size)
                    end_x = int((grid_x + 1) * cell_size)
                    end_y = int((grid_y + 1) * cell_size)
                    
                    # 确保坐标在有效范围内
                    if start_x < img.shape[1] and start_y < img.shape[0]:
                        color = NODE_COLOR["secondary_road"]
                        r, g, b = [c / 255.0 for c in color]
                        # 填充整个格子
                        img[start_y:end_y, start_x:end_x] = [r, g, b, 1.0]
            
            # 绘制blocks
            if blocks:
                # 先修改img数组
                block_texts = []
                block_borders = []
                
                for block_id, block in blocks.items():
                    # 随机颜色
                    r = self.rng.random()
                    g = self.rng.random()
                    b = self.rng.random()
                    
                    # 计算补色（用于边框和文本）
                    # 补色计算：基于HSL颜色空间，将色相调整180度
                    def rgb_to_hsl(r, g, b):
                        max_val = max(r, g, b)
                        min_val = min(r, g, b)
                        h, s, l = 0, 0, (max_val + min_val) / 2
                        
                        if max_val != min_val:
                            d = max_val - min_val
                            s = d / (2 - max_val - min_val) if l > 0.5 else d / (max_val + min_val)
                            if max_val == r:
                                h = (g - b) / d + (6 if g < b else 0)
                            elif max_val == g:
                                h = (b - r) / d + 2
                            else:
                                h = (r - g) / d + 4
                            h /= 6
                        return h, s, l
                    
                    def hsl_to_rgb(h, s, l):
                        def hue2rgb(p, q, t):
                            if t < 0:
                                t += 1
                            if t > 1:
                                t -= 1
                            if t < 1/6:
                                return p + (q - p) * 6 * t
                            if t < 1/2:
                                return q
                            if t < 2/3:
                                return p + (q - p) * (2/3 - t) * 6
                            return p
                        
                        if s == 0:
                            return l, l, l
                        q = l * (1 + s) if l < 0.5 else l + s - l * s
                        p = 2 * l - q
                        return hue2rgb(p, q, h + 1/3), hue2rgb(p, q, h), hue2rgb(p, q, h - 1/3)
                    
                    # 将RGB转换为HSL
                    h, s, l = rgb_to_hsl(r, g, b)
                    # 调整色相180度得到补色
                    complementary_h = (h + 0.5) % 1.0
                    # 将补色HSL转换回RGB
                    border_r, border_g, border_b = hsl_to_rgb(complementary_h, s, l)
                    
                    # 绘制区块
                    for node in block["nodes"]:
                        x, y = map(int, node.split(","))
                        # 计算格子在图像中的位置
                        grid_x = x - min_x
                        grid_y = y - min_y
                        
                        # 计算绘制区域
                        start_x = int(grid_x * cell_size)
                        start_y = int(grid_y * cell_size)
                        end_x = int((grid_x + 1) * cell_size)
                        end_y = int((grid_y + 1) * cell_size)
                        
                        # 确保坐标在有效范围内
                        if start_x < img.shape[1] and start_y < img.shape[0]:
                            img[start_y:end_y, start_x:end_x] = [r, g, b, 1.0]
                    
                    # 计算区块边界（用于绘制边框）
                    block_x, block_y = block["position"]
                    block_size = block["size"][0]
                    # 计算区块在图像中的边界
                    start_grid_x = block_x - min_x
                    start_grid_y = block_y - min_y
                    end_grid_x = start_grid_x + block_size
                    end_grid_y = start_grid_y + block_size
                    
                    # 转换为图像坐标
                    border_left = int(start_grid_x * cell_size)
                    border_top = int(start_grid_y * cell_size)
                    border_right = int(end_grid_x * cell_size)
                    border_bottom = int(end_grid_y * cell_size)
                    
                    # 保存边框信息
                    block_borders.append((border_left, border_top, border_right, border_bottom, (border_r, border_g, border_b)))
                    
                    # 计算区块中心
                    center_x = block_x + block_size // 2
                    center_y = block_y + block_size // 2
                    
                    # 计算中心在图像中的位置
                    grid_x = center_x - min_x
                    grid_y = center_y - min_y
                    px = int((grid_x + 0.5) * cell_size)
                    py = int((grid_y + 0.5) * cell_size)
                    
                    # 计算字体大小：区块可视化大小的60%像素
                    block_visual_size = block_size * cell_size
                    fontsize = max(8, int(block_visual_size * 0.6))  # 最小字体大小为8
                    
                    # 保存文本信息
                    block_texts.append((px, py, block_id, (border_r, border_g, border_b), fontsize))
                
                # 然后创建图像并保存
                plt.figure(figsize=(img_size/100, img_size/100), dpi=100)
                plt.imshow(img)
                
                # 绘制所有边框（4px的反色边框，确保在区块范围内）
                for left, top, right, bottom, color in block_borders:
                    # 调整边框位置，确保在区块范围内
                    inner_left = left + 2
                    inner_top = top + 2
                    inner_right = right - 2
                    inner_bottom = bottom - 2
                    plt.plot([inner_left, inner_right, inner_right, inner_left, inner_left], [inner_top, inner_top, inner_bottom, inner_bottom, inner_top], 
                             color=color, linewidth=4)
                
                # 绘制所有文本
                for px, py, block_id, color, fontsize in block_texts:
                    plt.text(px, py, block_id, ha='center', va='center', 
                             color=color, fontsize=fontsize)
                
                # 保存图像
                plt.axis('off')
                filename = f"{self.output_dir}/{self.config['seed']}.step_{step_index}.{step_name}.png"
                plt.savefig(filename, bbox_inches='tight', pad_inches=0)
                plt.close()
                # 已经保存了图像，直接返回
                return
            
            # 保存图像（没有blocks的情况）
            filename = f"{self.output_dir}/{self.config['seed']}.step_{step_index}.{step_name}.png"
            plt.figure(figsize=(img_size/100, img_size/100), dpi=100)
            plt.imshow(img)
            plt.axis('off')
            plt.savefig(filename, bbox_inches='tight', pad_inches=0)
            plt.close()
            
        except ImportError:
            log_message(f"警告: 无法可视化步骤 {step_index}，请安装 matplotlib")
    
    def generate_final_data(self, block_data):
        """
        生成最终数据
        Args:
            block_data: 包含所有生成数据的字典
        Returns:
            最终数据字典
        """
        # 构建metadata
        metadata = {
            "version": "1.0.2",
            "generated_at": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            "config": self.config,
            "size": [self.config["width"], self.config["height"]]
        }
        
        # 构建data
        # 处理center字段，转换为数组格式
        center_str = block_data.get("center", "0,0")
        center_arr = list(map(int, center_str.split(",")))
        
        data = {
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
            "all_walls": block_data.get("all_walls", []),
            "total_nodes": {}
        }
        
        # 构建total_nodes
        # 将RGB颜色转换为十六进制格式
        def rgb_to_hex(rgb):
            r, g, b = rgb
            return f"#{r:02x}{g:02x}{b:02x}ff"
        
        for point_str in data["nodes"]:
            node_type = "mask"
            
            # 注意：data["center"]现在是数组格式，需要转换为字符串进行比较
            if point_str == f"{data['center'][0]},{data['center'][1]}":
                node_type = "center"
            elif point_str in data["primary_road"]:
                node_type = "primary_road"
            elif point_str in data["secondary_roads"]:
                node_type = "secondary_road"
            elif point_str in block_data.get("walls", []):
                node_type = "wall"
            elif point_str in block_data.get("gates", []):
                node_type = "gate"
            elif point_str in block_data.get("gate_walls", []):
                node_type = "gate_wall"
            
            data["total_nodes"][point_str] = {
                "type": node_type,
                "color": rgb_to_hex(NODE_COLOR[node_type])
            }
        
        return {
            "metadata": metadata,
            "data": data
        }
    
    def validate_edge_connectivity(self, wall_data):
        """
        步骤 4.2: 进行edge合法性校对
        检查edge是否首尾相连
        Args:
            wall_data: 包含edges的字典
        """
        edges = wall_data.get("edges", [])
        if not edges:
            return
        
        # 构建edge集合便于快速查找
        edge_set = set(edges)
        
        # 计算每个edge节点的邻居数量（十字线方向）
        node_neighbors = {}
        
        for edge_point in edges:
            x, y = map(int, edge_point.split(","))
            neighbors = []
            directions = [(0, -1), (0, 1), (-1, 0), (1, 0)]  # 上、下、左、右
            
            for dx, dy in directions:
                neighbor_x = x + dx
                neighbor_y = y + dy
                neighbor_point = f"{neighbor_x},{neighbor_y}"
                if neighbor_point in edge_set:
                    neighbors.append(neighbor_point)
            
            node_neighbors[edge_point] = neighbors
        
        # 检查是否有节点只有一个邻居（首尾节点）
        end_nodes = []
        for edge_point, neighbors in node_neighbors.items():
            if len(neighbors) == 1:
                end_nodes.append(edge_point)
        
        # 检查edge是否首尾相连，只有不合法时才打印错误信息
        if len(end_nodes) != 0 and len(end_nodes) != 2:
            # 不是闭合环也不是开放路径，说明edge不合法
            log_message(f"[ERROR] edge 合法性错误：{edges} 不是首尾相连的")
    
    def step_4_1_recheck_edges(self, road_data):
        """
        步骤 4.1: 在后处理后，对mask再进行一遍edge的检查
        检查mask节点是否应该是edge节点
        Args:
            road_data: 包含mask和edges的字典
        Returns:
            更新后的road_data字典
        """
        mask = road_data.get("mask", [])
        edges = road_data.get("edges", [])
        
        # 构建mask集合便于快速查找
        mask_set = set(mask)
        
        # 重新检测edge节点
        new_edges = []
        
        for point_str in mask:
            x, y = map(int, point_str.split(","))
            
            # 检查九宫格内是否有无效节点
            has_invalid_neighbor = False
            for dx_off in [-1, 0, 1]:
                for dy_off in [-1, 0, 1]:
                    if dx_off == 0 and dy_off == 0:
                        continue
                    neighbor_x = x + dx_off
                    neighbor_y = y + dy_off
                    neighbor_point = f"{neighbor_x},{neighbor_y}"
                    
                    # 检查邻居是否在mask中
                    if neighbor_point not in mask_set:
                        has_invalid_neighbor = True
                        break
                if has_invalid_neighbor:
                    break
            
            # 如果九宫格内有无效节点，标记为edge
            if has_invalid_neighbor:
                new_edges.append(point_str)
        
        # 更新edges
        road_data["edges"] = new_edges

        # 导出一份edge的图片可视化结果
        self.visualize_step(4, "6.final_edge", mask, edges=new_edges)
        
        return road_data
    
    def save_final_data(self, final_data):
        """
        保存最终数据
        Args:
            final_data: 最终数据字典
        """
        filename = f"{self.output_dir}/{self.config['seed']}.final.json"
        
        with open(filename, 'w', encoding='utf-8') as f:
            json.dump(final_data, f, indent=2, ensure_ascii=False)
        
        log_message(f"\n最终数据已保存到: {filename}")

# 主函数
if __name__ == "__main__":
    # 清空日志文件
    if os.path.exists("output/output.log"):
        os.remove("output/output.log")
    
    # 测试不同种子，暂时遍历0-10
    for seed in range(1):  # 遍历0-10
        log_message(f"\n=== 测试种子 {seed} ===")
        config = gen_config(seed=seed)
        generator = MapGenerator(config)
        final_data = generator.run()
        # 打印生成配置
        log_message("生成配置:")
        log_message(json.dumps(config, indent=2, ensure_ascii=False))