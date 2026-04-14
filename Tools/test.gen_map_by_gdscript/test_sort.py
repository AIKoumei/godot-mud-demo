"""
测试排序逻辑是否正确
"""

# 模拟一些候选数据
candidates = [
    # (priority, min_distance, min_road_distance, block_size, x, y, closest_corner, block_nodes)
    # priority = [-min_distance, block_size, -min_road_distance]
    ([-1.41, 5, -10], 1.41, 10, 5, 7, 6, (9, 9), ["7,6"]),  # ID=1 的位置，距离 1.41，5x5
    ([-11.40, 2, -5], 11.40, 5, 2, 4, 1, (4, 1), ["4,1"]),  # ID=2 的位置，距离 11.40，2x2
    ([-10.20, 1, -8], 10.20, 8, 1, 10, 1, (10, 1), ["10,1"]),  # ID=3，距离 10.20，1x1
    ([-3.16, 4, -6], 3.16, 6, 4, 6, 12, (9, 12), ["6,12"]),  # ID=23 的位置，距离 3.16，4x4
    ([-1.41, 1, -7], 1.41, 7, 1, 11, 12, (11, 12), ["11,12"]),  # ID=24，距离 1.41，1x1
    ([-1.41, 5, -9], 1.41, 9, 5, 13, 12, (13, 12), ["13,12"]),  # ID=25，距离 1.41，5x5
]

# Python 的排序（升序）
print("Python 排序结果（升序，从小到大）:")
sorted_candidates = sorted(candidates, key=lambda x: x[0])
for i, c in enumerate(sorted_candidates, 1):
    priority, min_distance, _, block_size, x, y, _, _ = c
    print(f"{i:2d}. priority={priority}, distance={min_distance:.2f}, size={block_size}, pos=({x},{y})")

print("\nPython 排序结果（降序，从大到小）:")
sorted_candidates_desc = sorted(candidates, key=lambda x: x[0], reverse=True)
for i, c in enumerate(sorted_candidates_desc, 1):
    priority, min_distance, _, block_size, x, y, _, _ = c
    print(f"{i:2d}. priority={priority}, distance={min_distance:.2f}, size={block_size}, pos=({x},{y})")

print("\n\n分析:")
print("-" * 80)
print("priority = [-min_distance, block_size, -min_road_distance]")
print("我们希望：距离近的优先 > 区块大的优先 > 距离主干道近的优先")
print()
print("对于 [-min_distance, ...]:")
print("  - min_distance 越小（距离近），-min_distance 越大（负得少）")
print("  - 例如：距离 1.41 -> -1.41，距离 11.40 -> -11.40")
print("  - -1.41 > -11.40，所以距离近的排在前面（降序时）")
print()
print("结论：应该使用降序排序（reverse=True），这样：")
print("  1. -min_distance 大的（距离近的）排前面")
print("  2. block_size 大的排前面")
print("  3. -min_road_distance 大的（距离主干道近的）排前面")
