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

print(f"中心点：{center}")
print(f"总区块数：{len(blocks)}")
print(f"总 mask 点数：{len(mask)}")
print(f"总次级道路数：{len(secondary_roads)}")
print(f"总主干道点数：{len(primary_road)}")

# 分析 ID=23 的区块
block_23 = blocks['23']
pos_23 = block_23['position']
size_23 = block_23['size'][0]
print(f"\nID=23 区块：pos={pos_23}, size={size_23}x{size_23}")

# 计算 ID=23 到中心的距离
center_x, center_y = center
# 找到最近的角点
corners = [
    (pos_23[0], pos_23[1]),
    (pos_23[0] + size_23 - 1, pos_23[1]),
    (pos_23[0], pos_23[1] + size_23 - 1),
    (pos_23[0] + size_23 - 1, pos_23[1] + size_23 - 1)
]
closest_corner = min(corners, key=lambda c: math.sqrt((c[0] - center_x)**2 + (c[1] - center_y)**2))
dist_23 = math.sqrt((closest_corner[0] - center_x)**2 + (closest_corner[1] - center_y)**2)
print(f"最近角点：{closest_corner}, 距离={dist_23:.2f}")

# 找出所有比 ID=23 距离更近但 ID 更大的区块
print("\n\n分析比 ID=23 距离更近但 ID 更大的区块:")
print("-" * 80)

closer_blocks = []
for block_id, block in blocks.items():
    if int(block_id) > 23:
        pos = block['position']
        size = block['size'][0]
        corners = [
            (pos[0], pos[1]),
            (pos[0] + size - 1, pos[1]),
            (pos[0], pos[1] + size - 1),
            (pos[0] + size - 1, pos[1] + size - 1)
        ]
        closest = min(corners, key=lambda c: math.sqrt((c[0] - center_x)**2 + (c[1] - center_y)**2))
        dist = math.sqrt((closest[0] - center_x)**2 + (closest[1] - center_y)**2)
        
        if dist < dist_23:
            closer_blocks.append((int(block_id), dist, pos, size, closest))

closer_blocks.sort(key=lambda x: x[1])
print(f"发现 {len(closer_blocks)} 个区块比 ID=23 距离更近但 ID 更大:")
for b_id, dist, pos, size, closest in closer_blocks[:20]:
    print(f"  ID={b_id:2d}: pos={pos}, size={size}, 最近角点={closest}, 距离={dist:.2f}")

# 模拟生成过程，检查在生成 ID=23 时，哪些点被占用了
print("\n\n模拟生成过程，检查在生成 ID=23 时的状态:")
print("-" * 80)

# 按 ID 顺序处理区块
sorted_blocks = sorted(blocks.items(), key=lambda x: int(x[0]))

# 初始 occupied 集合
occupied = set(mask) - set(primary_road) - set(map_data.get('gates', [])) - set(map_data.get('walls', [])) - set(map_data.get('gate_walls', []))

# 按顺序处理每个区块
for block_id, block in sorted_blocks:
    bid = int(block_id)
    pos = block['position']
    size = block['size'][0]
    nodes = set(block['nodes'])
    
    # 检查这个区块是否在 occupied 中
    if not nodes.issubset(occupied):
        print(f"ID={bid}: 区块不在 occupied 中（可能已被占用）")
    
    # 如果是 ID=23，打印当前状态
    if bid == 23:
        print(f"\n在生成 ID=23 时:")
        print(f"  occupied 剩余点数：{len(occupied)}")
        
        # 检查中心附近的点是否可用
        nearby_available = []
        for x in range(center_x - 10, center_x + 11):
            for y in range(center_y - 10, center_y + 11):
                point = f"{x},{y}"
                if point in occupied:
                    dist = math.sqrt((x - center_x)**2 + (y - center_y)**2)
                    if dist <= 5:
                        nearby_available.append((point, dist))
        
        nearby_available.sort(key=lambda x: x[1])
        print(f"  中心附近（距离<=5）的可用点数：{len(nearby_available)}")
        if nearby_available:
            print(f"  最近的 10 个可用点:")
            for point, dist in nearby_available[:10]:
                print(f"    {point}: 距离={dist:.2f}")
        
        # 检查这些点能否形成区块
        print(f"\n  检查这些点能否形成>=4x4 的区块:")
        checked = set()
        for point, dist in nearby_available[:50]:
            if point in checked:
                continue
            x, y = map(int, point.split(","))
            
            # 尝试不同大小的区块
            for block_size in [5, 4, 3, 2, 1]:
                can_form = True
                block_nodes = []
                for dy in range(block_size):
                    for dx in range(block_size):
                        check_point = f"{x+dx},{y+dy}"
                        if check_point not in occupied:
                            can_form = False
                            break
                        block_nodes.append(check_point)
                    if not can_form:
                        break
                
                if can_form and block_size >= 4:
                    print(f"    点 {point} (距离={dist:.2f}) 可以形成 {block_size}x{block_size} 区块！")
                    checked.add(point)
                    break
                elif can_form:
                    checked.add(point)
        
        break
    
    # 从 occupied 中移除区块节点
    occupied = occupied - nodes
    
    # 如果是 ID=1，还要移除次级道路（模拟生成次级道路）
    if bid == 1:
        # 生成区块 1 周围的次级道路
        block_1_nodes = set(block['nodes'])
        for node in list(occupied):
            x, y = map(int, node.split(","))
            # 检查是否在区块 1 的周围
            for dx in [-1, 0, 1]:
                for dy in [-1, 0, 1]:
                    check_x = x + dx
                    check_y = y + dy
                    if f"{check_x},{check_y}" in block_1_nodes:
                        if node in occupied:
                            occupied.remove(node)
                            break
