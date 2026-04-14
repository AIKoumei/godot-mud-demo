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

# 模拟生成过程，检查在生成 ID=17 之前的所有区块和次级道路
occupied = set(mask) - set(primary_road) - set(map_data.get('gates', [])) - set(map_data.get('walls', [])) - set(map_data.get('gate_walls', []))

# 按 ID 顺序处理区块，直到 ID=16
sorted_blocks = sorted(blocks.items(), key=lambda x: int(x[0]))

print("在生成 ID=17 之前，已经生成的区块:")
print("-" * 80)

for block_id, block in sorted_blocks:
    bid = int(block_id)
    if bid >= 17:
        break
    
    nodes = set(block['nodes'])
    pos = block['position']
    size = block['size'][0]
    
    # 检查这个区块覆盖了哪些点
    covered_13_12 = False
    for node in nodes:
        x, y = map(int, node.split(","))
        if x == 13 and y == 12:
            covered_13_12 = True
            break
    
    if covered_13_12:
        print(f"  ID={bid}: pos={pos}, size={size} - 覆盖了 (13,12)")
    
    # 从 occupied 中移除区块节点
    occupied = occupied - nodes

# 检查 (13,12) 是否在 occupied 中
point_13_12 = "13,12"
print(f"\n检查 (13,12):")
if point_13_12 in occupied:
    print(f"  ✓ (13,12) 在 occupied 中（可用）")
    
    # 检查能否形成 5x5 区块
    can_form_5x5 = True
    for dy in range(5):
        for dx in range(5):
            check_point = f"{13+dx},{12+dy}"
            if check_point not in occupied:
                can_form_5x5 = False
                print(f"    点 {check_point} 不在 occupied 中")
                break
        if not can_form_5x5:
            break
    
    if can_form_5x5:
        print(f"  ✓ (13,12) 可以形成 5x5 区块")
    else:
        print(f"  ✗ (13,12) 不能形成 5x5 区块")
else:
    print(f"  ✗ (13,12) 不在 occupied 中（已被占用）")
    
    # 检查是被哪个区块占用的
    for block_id, block in sorted_blocks:
        bid = int(block_id)
        if bid >= 17:
            break
        
        nodes = set(block['nodes'])
        if point_13_12 in nodes:
            pos = block['position']
            size = block['size'][0]
            print(f"  被 ID={bid} 区块占用：pos={pos}, size={size}")
            break
    
    # 检查是否被次级道路占用
    if point_13_12 in secondary_roads:
        print(f"  被次级道路占用")

# 检查在生成 ID=17 时，所有可用的 5x5 候选
print(f"\n\n在生成 ID=17 时，所有可用的 5x5 候选:")
print("-" * 80)

candidates_5x5 = []
for point_str in occupied:
    x, y = map(int, point_str.split(","))
    
    # 尝试 5x5 区块
    can_form_5x5 = True
    block_nodes = []
    for dy in range(5):
        for dx in range(5):
            check_point = f"{x+dx},{y+dy}"
            if check_point not in occupied:
                can_form_5x5 = False
                break
            block_nodes.append(check_point)
        if not can_form_5x5:
            break
    
    if can_form_5x5:
        # 计算距离
        block_corners = [
            (x, y),
            (x + 4, y),
            (x, y + 4),
            (x + 4, y + 4)
        ]
        closest_corner = min(block_corners, key=lambda c: math.sqrt((c[0] - center_x)**2 + (c[1] - center_y)**2))
        distance = math.sqrt((closest_corner[0] - center_x)**2 + (closest_corner[1] - center_y)**2)
        
        candidates_5x5.append((x, y, distance, closest_corner))

# 按距离排序
candidates_5x5.sort(key=lambda x: x[2])

print(f"找到 {len(candidates_5x5)} 个 5x5 候选:")
for i, (x, y, dist, corner) in enumerate(candidates_5x5[:20], 1):
    print(f"{i:2d}. ({x},{y}): 距离={dist:.2f}, 最近角点={corner}")
