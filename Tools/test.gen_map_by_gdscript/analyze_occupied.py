import json
import math

# 读取存档文件
with open('G:/WIN11/ming.jun/godot_projects/godot-mud-demo/Tools/test.gen_map_by_gdscript/data/saves/slot_1/mods/WorldMapManager/map_test_Town.sav', 'r', encoding='utf-8') as f:
    data = json.load(f)

metadata = data['metadata']
map_data = metadata['config']['map_data']
blocks = map_data['blocks']
center = map_data['center']
primary_road = map_data['primary_road']
secondary_roads = map_data.get('secondary_roads', [])

print(f"中心点：{center}")
print(f"总区块数：{len(blocks)}")
print(f"总次级道路数：{len(secondary_roads)}")

# 检查 ID=1 区块覆盖的范围
block_1 = blocks['1']
pos_1 = block_1['position']
size_1 = block_1['size'][0]
print(f"\nID=1 区块：pos={pos_1}, size={size_1}x{size_1}")
print(f"覆盖范围：x=[{pos_1[0]}, {pos_1[0]+size_1-1}], y=[{pos_1[1]}, {pos_1[1]+size_1-1}]")

# 计算中心附近（距离<=5）的点有多少被次级道路占用
center_x, center_y = center
nearby_points = []
occupied_by_secondary = []

for x in range(center_x - 10, center_x + 11):
    for y in range(center_y - 10, center_y + 11):
        point = f"{x},{y}"
        distance = math.sqrt((x - center_x)**2 + (y - center_y)**2)
        if distance <= 5:
            nearby_points.append(point)
            if point in secondary_roads:
                occupied_by_secondary.append((point, distance))

print(f"\n中心附近（距离<=5）的点数：{len(nearby_points)}")
print(f"被次级道路占用的点数：{len(occupied_by_secondary)}")
if occupied_by_secondary:
    print("被占用的点（按距离排序）:")
    occupied_by_secondary.sort(key=lambda x: x[1])
    for point, dist in occupied_by_secondary[:20]:
        print(f"  {point}: 距离={dist:.2f}")

# 检查在 ID=1 生成后，距离中心最近的可用点
print("\n\n检查在 ID=1 和次级道路生成后，距离中心最近的可用点:")
print("-" * 80)

# 模拟 occupied 集合（排除 ID=1 区块和次级道路）
all_nodes = set(map_data['mask'])
occupied_by_block_1 = set(block_1['nodes'])
occupied_by_secondary_set = set(secondary_roads)

# 可用的点（排除 ID=1 区块、次级道路、主干道、城门、城墙等）
available = all_nodes - occupied_by_block_1 - occupied_by_secondary_set - set(primary_road) - set(map_data.get('gates', [])) - set(map_data.get('walls', []))

# 计算每个可用点到中心的距离
available_with_distance = []
for point in available:
    x, y = map(int, point.split(","))
    distance = math.sqrt((x - center_x)**2 + (y - center_y)**2)
    available_with_distance.append((point, distance))

# 按距离排序
available_with_distance.sort(key=lambda x: x[1])

print(f"可用点总数：{len(available)}")
print(f"\n距离中心最近的 20 个可用点:")
for i, (point, dist) in enumerate(available_with_distance[:20], 1):
    x, y = map(int, point.split(","))
    print(f"{i:2d}. {point}: 距离={dist:.2f}")

# 检查这些点是否能形成有效区块
print("\n\n检查这些点能否形成 5x5 区块:")
for i, (point, dist) in enumerate(available_with_distance[:30], 1):
    x, y = map(int, point.split(","))
    
    # 尝试 5x5 区块
    can_form_5x5 = True
    for dy in range(5):
        for dx in range(5):
            check_point = f"{x+dx},{y+dy}"
            if check_point not in available:
                can_form_5x5 = False
                break
        if not can_form_5x5:
            break
    
    if can_form_5x5:
        print(f"  距离第{i}近的点 {point} (距离={dist:.2f}) 可以形成 5x5 区块！")
        break
else:
    print("  前 30 个最近的点都无法形成 5x5 区块")
