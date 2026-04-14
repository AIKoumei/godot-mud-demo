import json
import math

# 读取存档文件
with open('G:/WIN11/ming.jun/godot_projects/godot-mud-demo/Tools/test.gen_map_by_gdscript/data/saves/slot_1/mods/WorldMapManager/map_test_Town.sav', 'r', encoding='utf-8') as f:
    data = json.load(f)

map_data = data['metadata']['config']['map_data']
blocks = map_data['blocks']
center = map_data['center']
primary_road = map_data['primary_road']
mask = map_data['mask']

center_x, center_y = center

# 模拟生成过程，检查在生成 ID=17 后的状态
occupied = set(mask) - set(primary_road) - set(map_data.get('gates', [])) - set(map_data.get('walls', [])) - set(map_data.get('gate_walls', []))

# 按 ID 顺序处理区块，直到 ID=16
sorted_blocks = sorted(blocks.items(), key=lambda x: int(x[0]))

for block_id, block in sorted_blocks:
    bid = int(block_id)
    if bid >= 17:
        break
    
    nodes = set(block['nodes'])
    # 从 occupied 中移除区块节点
    occupied = occupied - nodes

print(f"在生成 ID=17 时，occupied 剩余点数：{len(occupied)}")

# 检查在生成 ID=17 时，(13,5) 5x5 是否是最好的候选
x, y = 13, 5
block_size = 5

# 计算 (13,5) 的距离
block_corners = [
    (x, y),
    (x + block_size - 1, y),
    (x, y + block_size - 1),
    (x + block_size - 1, y + block_size - 1)
]

if x < center_x and y > center_y:
    closest_corner = block_corners[1]
elif x > center_x and y > center_y:
    closest_corner = block_corners[0]
else:
    closest_corner = min(block_corners, key=lambda c: math.sqrt((c[0] - center_x)**2 + (c[1] - center_y)**2))

min_distance = math.sqrt((closest_corner[0] - center_x)**2 + (closest_corner[1] - center_y)**2)
print(f"\n(13,5) 5x5: 最近角点={closest_corner}, 距离={min_distance:.2f}")

# 检查这个区块是否在 occupied 中
block_valid = True
for dy in range(block_size):
    for dx in range(block_size):
        check_point = f"{x+dx},{y+dy}"
        if check_point not in occupied:
            block_valid = False
            print(f"  点 {check_point} 不在 occupied 中")
            break
    if not block_valid:
        break

if block_valid:
    print(f"  ✓ (13,5) 5x5 是有效的候选")
else:
    print(f"  ✗ (13,5) 5x5 不是有效的候选")

# 检查在生成 ID=17 时，中心附近还有哪些可用点
print(f"\n在生成 ID=17 时，中心附近的可用点:")
nearby_available = []
for x_offset in range(-10, 11):
    for y_offset in range(-10, 11):
        x = center_x + x_offset
        y = center_y + y_offset
        point = f"{x},{y}"
        if point in occupied:
            dist = math.sqrt((x - center_x)**2 + (y - center_y)**2)
            if dist <= 5:
                nearby_available.append((point, dist))

nearby_available.sort(key=lambda x: x[1])
print(f"  中心附近（距离<=5）的可用点数：{len(nearby_available)}")
if nearby_available:
    print(f"  最近的 20 个可用点:")
    for point, dist in nearby_available[:20]:
        print(f"    {point}: 距离={dist:.2f}")

# 检查这些点能否形成 5x5 区块
print(f"\n  检查这些点能否形成 5x5 区块:")
for point, dist in nearby_available[:30]:
    x, y = map(int, point.split(","))
    
    can_form_5x5 = True
    for dy in range(5):
        for dx in range(5):
            check_point = f"{x+dx},{y+dy}"
            if check_point not in occupied:
                can_form_5x5 = False
                break
        if not can_form_5x5:
            break
    
    if can_form_5x5:
        print(f"    点 {point} (距离={dist:.2f}) 可以形成 5x5 区块！")
        break
else:
    print(f"    前 30 个最近的点都无法形成 5x5 区块")

# 检查在生成 ID=17 时，(6,12) 这个点的情况
print(f"\n检查 (6,12) 这个点:")
point_6_12 = "6,12"
if point_6_12 in occupied:
    print(f"  ✓ (6,12) 在 occupied 中")
    
    # 检查能否形成 4x4 区块
    can_form_4x4 = True
    for dy in range(4):
        for dx in range(4):
            check_point = f"{6+dx},{12+dy}"
            if check_point not in occupied:
                can_form_4x4 = False
                print(f"    点 {check_point} 不在 occupied 中")
                break
        if not can_form_4x4:
            break
    
    if can_form_4x4:
        print(f"  ✓ (6,12) 可以形成 4x4 区块")
    else:
        print(f"  ✗ (6,12) 不能形成 4x4 区块")
else:
    print(f"  ✗ (6,12) 不在 occupied 中")
