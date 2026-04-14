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

print(f"中心点：{center}")
print(f"总区块数：{len(blocks)}")
print(f"\n区块生成顺序分析:")
print("=" * 80)

# 计算每个区块到中心的距离
block_distances = []
for block_id, block in blocks.items():
    position = block['position']
    size = block['size'][0]
    
    # 计算区块最接近中心的角点距离
    if position[0] < center[0] and position[1] > center[1]:
        # 左下角区块，使用右上角坐标
        closest_x = position[0] + size - 1
        closest_y = position[1]
    elif position[0] > center[0] and position[1] > center[1]:
        # 右下角区块，使用左上角坐标
        closest_x = position[0]
        closest_y = position[1]
    else:
        # 其他区块，找到最接近中心的角
        corners = [
            (position[0], position[1]),
            (position[0] + size - 1, position[1]),
            (position[0], position[1] + size - 1),
            (position[0] + size - 1, position[1] + size - 1)
        ]
        closest_x, closest_y = min(corners, key=lambda c: math.sqrt((c[0] - center[0])**2 + (c[1] - center[1])**2))
    
    distance = math.sqrt((closest_x - center[0])**2 + (closest_y - center[1])**2)
    block_distances.append((int(block_id), distance, position, size))

# 按 ID 排序显示
print("\n按生成顺序 (ID) 排列:")
print("-" * 80)
for block_id, distance, position, size in sorted(block_distances, key=lambda x: x[0]):
    print(f"ID={block_id:2d}: pos={position}, size={size}x{size}, 距离中心={distance:.2f}")

# 按距离排序
print("\n\n按距离中心由近到远排序:")
print("-" * 80)
sorted_by_distance = sorted(block_distances, key=lambda x: x[1])
for i, (block_id, distance, position, size) in enumerate(sorted_by_distance[:30], 1):
    print(f"排名={i:2d}: ID={block_id:2d}, pos={position}, size={size}x{size}, 距离={distance:.2f}")

# 检查是否有顺序错误
print("\n\n顺序错误检测:")
print("-" * 80)
errors = []
for i in range(1, len(sorted_by_distance)):
    prev_id, prev_dist, _, _ = sorted_by_distance[i-1]
    curr_id, curr_dist, _, _ = sorted_by_distance[i]
    
    # 如果距离相近但 ID 差距很大，可能有问题
    if abs(curr_dist - prev_dist) < 1.0 and curr_id > prev_id + 5:
        errors.append((prev_id, curr_id, prev_dist, curr_dist))

if errors:
    print(f"发现 {len(errors)} 个可能的顺序问题:")
    for prev_id, curr_id, prev_dist, curr_dist in errors[:10]:
        print(f"  ID={prev_id} (距离{prev_dist:.2f}) 和 ID={curr_id} (距离{curr_dist:.2f}) 顺序可能不合理")
else:
    print("未发现明显的顺序问题")

# 特别检查 ID=23 的区块
print("\n\nID=23 区块详细分析:")
print("-" * 80)
block_23 = blocks.get('23')
if block_23:
    pos = block_23['position']
    size = block_23['size'][0]
    
    # 计算到中心的距离
    corners = [
        (pos[0], pos[1]),
        (pos[0] + size - 1, pos[1]),
        (pos[0], pos[1] + size - 1),
        (pos[0] + size - 1, pos[1] + size - 1)
    ]
    closest_corner = min(corners, key=lambda c: math.sqrt((c[0] - center[0])**2 + (c[1] - center[1])**2))
    distance = math.sqrt((closest_corner[0] - center[0])**2 + (closest_corner[1] - center[1])**2)
    
    print(f"位置：{pos}")
    print(f"大小：{size}x{size}")
    print(f"最近角点：{closest_corner}")
    print(f"到中心距离：{distance:.2f}")
    
    # 找出所有比 ID=23 更早生成的区块中，距离更远的
    farther_blocks = []
    for block_id, block in blocks.items():
        if int(block_id) < 23:
            b_pos = block['position']
            b_size = block['size'][0]
            b_corners = [
                (b_pos[0], b_pos[1]),
                (b_pos[0] + b_size - 1, b_pos[1]),
                (b_pos[0], b_pos[1] + b_size - 1),
                (b_pos[0] + b_size - 1, b_pos[1] + b_size - 1)
            ]
            b_closest = min(b_corners, key=lambda c: math.sqrt((c[0] - center[0])**2 + (c[1] - center[1])**2))
            b_distance = math.sqrt((b_closest[0] - center[0])**2 + (b_closest[1] - center[1])**2)
            
            if b_distance > distance:
                farther_blocks.append((int(block_id), b_distance, b_pos, b_size))
    
    if farther_blocks:
        print(f"\n在 ID=23 之前生成的、但距离更远的区块有 {len(farther_blocks)} 个:")
        farther_blocks.sort(key=lambda x: x[0])
        for b_id, b_dist, b_pos, b_size in farther_blocks[:20]:
            print(f"  ID={b_id}: 距离={b_dist:.2f}, pos={b_pos}, size={b_size}")
