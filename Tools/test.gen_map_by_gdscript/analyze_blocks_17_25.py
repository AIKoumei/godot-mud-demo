import json
import math

# 读取存档文件
with open('G:/WIN11/ming.jun/godot_projects/godot-mud-demo/Tools/test.gen_map_by_gdscript/data/saves/slot_1/mods/WorldMapManager/map_test_Town.sav', 'r', encoding='utf-8') as f:
    data = json.load(f)

map_data = data['metadata']['config']['map_data']
blocks = map_data['blocks']
center = map_data['center']

center_x, center_y = center

print("分析 ID=17-25 的区块:")
print("-" * 80)

for bid in range(17, 26):
    block_id = str(bid)
    if block_id in blocks:
        block = blocks[block_id]
        pos = block['position']
        size = block['size'][0]
        
        # 计算距离
        corners = [
            (pos[0], pos[1]),
            (pos[0] + size - 1, pos[1]),
            (pos[0], pos[1] + size - 1),
            (pos[0] + size - 1, pos[1] + size - 1)
        ]
        closest_corner = min(corners, key=lambda c: math.sqrt((c[0] - center_x)**2 + (c[1] - center_y)**2))
        dist = math.sqrt((closest_corner[0] - center_x)**2 + (closest_corner[1] - center_y)**2)
        
        print(f"ID={bid:2d}: pos={pos}, size={size}, 最近角点={closest_corner}, 距离={dist:.2f}")

# 检查这些区块之间的位置关系
print("\n\n可视化这些区块的位置（简化的网格图）:")
print("-" * 80)

# 创建一个简单的网格
grid = {}
for block_id, block in blocks.items():
    bid = int(block_id)
    if 17 <= bid <= 25:
        pos = block['position']
        size = block['size'][0]
        for dy in range(size):
            for dx in range(size):
                grid[(pos[0] + dx, pos[1] + dy)] = bid

# 打印网格（只显示相关区域）
min_x = min(pos[0] for block in blocks.values() if 17 <= int(list(blocks.keys())[list(blocks.values()).index(block)]) <= 25 for pos in [block['position']])
max_x = max(pos[0] + block['size'][0] for block in blocks.values() if 17 <= int(list(blocks.keys())[list(blocks.values()).index(block)]) <= 25 for pos in [block['position']])
min_y = min(pos[1] for block in blocks.values() if 17 <= int(list(blocks.keys())[list(blocks.values()).index(block)]) <= 25 for pos in [block['position']])
max_y = max(pos[1] + block['size'][1] for block in blocks.values() if 17 <= int(list(blocks.keys())[list(blocks.values()).index(block)]) <= 25 for pos in [block['position']])

# 简化：只显示中心附近的区域
print(f"中心点：{center}")
print("\nY 轴")
print("↓")
for y in range(0, 25):
    row = ""
    for x in range(0, 25):
        if (x, y) in grid:
            bid = grid[(x, y)]
            if bid == int(list(grid.values())[0]):  # 只显示一次 ID
                row += f"{bid:2d} "
            else:
                row += "·  "
        elif x == center_x and y == center_y:
            row += "C  "
        else:
            row += "   "
    if row.strip():
        print(f"{y:2d}: {row}")

print("\nC = 中心点")
