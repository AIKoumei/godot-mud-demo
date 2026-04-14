import json
import math

# 读取存档文件
with open('G:/WIN11/ming.jun/godot_projects/godot-mud-demo/Tools/test.gen_map_by_gdscript/data/saves/slot_1/mods/WorldMapManager/map_test_Town.sav', 'r', encoding='utf-8') as f:
    data = json.load(f)

map_data = data['metadata']['config']['map_data']
blocks = map_data['blocks']
center = map_data['center']
primary_road = map_data['primary_road']
secondary_roads = map_data.get('secondary_roads', [])
mask = map_data['mask']

center_x, center_y = center

# 模拟生成过程，重建在生成 ID=23 时的 occupied 状态
occupied = set(mask) - set(primary_road) - set(map_data.get('gates', [])) - set(map_data.get('walls', [])) - set(map_data.get('gate_walls', []))

# 按 ID 顺序处理区块，直到 ID=22
sorted_blocks = sorted(blocks.items(), key=lambda x: int(x[0]))

for block_id, block in sorted_blocks:
    bid = int(block_id)
    if bid >= 23:
        break
    
    nodes = set(block['nodes'])
    # 从 occupied 中移除区块节点
    occupied = occupied - nodes

print(f"在生成 ID=23 时，occupied 剩余点数：{len(occupied)}")

# 现在模拟生成 ID=23 时的候选列表
best_candidates = []

for point_str in occupied:
    x = int(point_str.split(",")[0])
    y = int(point_str.split(",")[1])
    
    # 尝试不同大小的区块
    for block_size in [5, 4, 3, 2, 1]:
        # 计算区块的四个角坐标
        block_corners = [
            (x, y),
            (x + block_size - 1, y),
            (x, y + block_size - 1),
            (x + block_size - 1, y + block_size - 1)
        ]
        
        # 根据区块位置选择计算距离的角点
        if x < center_x and y > center_y:
            # 左下角区块，使用右上角坐标
            closest_corner = block_corners[1]
            min_distance = math.sqrt((closest_corner[0] - center_x)**2 + (closest_corner[1] - center_y)**2)
        elif x > center_x and y > center_y:
            # 右下角区块，使用左上角坐标
            closest_corner = block_corners[0]
            min_distance = math.sqrt((closest_corner[0] - center_x)**2 + (closest_corner[1] - center_y)**2)
        else:
            # 其他区块，找到最接近中心的角
            min_distance = float('inf')
            closest_corner = None
            for corner in block_corners:
                corner_distance = math.sqrt((corner[0] - center_x)**2 + (corner[1] - center_y)**2)
                if corner_distance < min_distance:
                    min_distance = corner_distance
                    closest_corner = corner
        
        # 检查区块是否在有效范围内
        block_valid = True
        block_nodes = []
        
        for y_offset in range(block_size):
            for x_offset in range(block_size):
                block_x = x + x_offset
                block_y = y + y_offset
                block_point = f"{block_x},{block_y}"
                
                if block_point not in occupied:
                    block_valid = False
                    break
                
                block_nodes.append(block_point)
            
            if not block_valid:
                break
        
        if block_valid:
            # 计算与主干道的最短距离
            min_road_distance = float('inf')
            for road_point in primary_road:
                road_x, road_y = map(int, road_point.split(","))
                block_center_x = x + block_size / 2
                block_center_y = y + block_size / 2
                road_distance = math.sqrt((block_center_x - road_x)**2 + (block_center_y - road_y)**2)
                if road_distance < min_road_distance:
                    min_road_distance = road_distance
            
            # 计算优先级（使用整数距离）
            int_distance = int(min_distance * 100)
            int_road_distance = int(min_road_distance * 100)
            priority = (-int_distance, block_size, -int_road_distance)
            
            best_candidates.append({
                'priority': priority,
                'min_distance': min_distance,
                'min_road_distance': min_road_distance,
                'block_size': block_size,
                'x': x,
                'y': y,
                'closest_corner': closest_corner,
                'block_nodes': block_nodes
            })

print(f"生成的候选数量：{len(best_candidates)}")

# 按优先级排序（降序）
best_candidates.sort(key=lambda x: x['priority'], reverse=True)

# 显示前 30 个候选
print("\n\n前 30 个候选（按优先级降序排序）:")
print("-" * 80)
print(f"{'排名':<4} {'优先级':<25} {'距离':<8} {'大小':<4} {'位置':<15} {'最近角点':<15}")
print("-" * 80)

for i, cand in enumerate(best_candidates[:30], 1):
    priority_str = str(cand['priority'])
    print(f"{i:<4} {priority_str:<25} {cand['min_distance']:<8.2f} {cand['block_size']:<4} ({cand['x']},{cand['y']})        {str(cand['closest_corner']):<15}")

# 检查 ID=23 的实际位置在候选列表中的排名
print("\n\n检查 ID=23 的实际位置 (6,12) 在候选列表中的排名:")
print("-" * 80)
for i, cand in enumerate(best_candidates, 1):
    if cand['x'] == 6 and cand['y'] == 12 and cand['block_size'] == 4:
        print(f"ID=23 的实际位置 (6,12) 4x4 排名第 {i} 位")
        print(f"  优先级：{cand['priority']}")
        print(f"  距离：{cand['min_distance']:.2f}")
        break

# 检查 (13,12) 5x5 在候选列表中的排名
print("\n检查 (13,12) 5x5 在候选列表中的排名:")
print("-" * 80)
for i, cand in enumerate(best_candidates, 1):
    if cand['x'] == 13 and cand['y'] == 12 and cand['block_size'] == 5:
        print(f"(13,12) 5x5 排名第 {i} 位")
        print(f"  优先级：{cand['priority']}")
        print(f"  距离：{cand['min_distance']:.2f}")
        break
