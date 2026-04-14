import json
from map_visualizer import parse_map_data, visualize_town_map
import os

# 确保 output 目录存在
os.makedirs('output', exist_ok=True)

# 清空日志文件
with open('output/output.log', 'w', encoding='utf-8') as f:
    f.write('')

data_file = r'data\saves\slot_1\mods\WorldMapManager\map_test_Town.sav'
data = json.load(open(data_file, 'r', encoding='utf-8'))

# 解析数据
map_data = parse_map_data(data)

print('=== 解析结果 ===')
print(f'map_type: {map_data.get("map_type")}')
print(f'total_nodes: {len(map_data.get("total_nodes", {}))}')
print(f'blocks: {len(map_data.get("blocks", {}))}')

# 可视化
visualize_town_map(map_data, 'output/test_town_with_blocks.jpg')

print('\n可视化完成！')
print(f'blocks 数量：{len(map_data.get("blocks", {}))}')
