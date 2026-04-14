import json
from map_visualizer import parse_map_data

data_file = r'g:\WIN11\ming.jun\godot_projects\godot-mud-demo\Tools\test.gen_map_by_gdscript\data\saves\slot_1\mods\WorldMapManager\map_test_Town.sav'
data = json.load(open(data_file, 'r', encoding='utf-8'))

# 使用 parse_map_data 解析
map_data = parse_map_data(data)

print('=== 解析后的 map_data ===')
print('blocks count:', len(map_data.get('blocks', {})))
print('total_nodes count:', len(map_data.get('total_nodes', {})))
print('map_type:', map_data.get('map_type'))

# 检查前 5 个 blocks
print('\n前 5 个 blocks:')
blocks = map_data.get('blocks', {})
for i, (block_id, block_data) in enumerate(list(blocks.items())[:5]):
    print(f'  Block {block_id}:')
    print(f'    size: {block_data.get("size")}')
    print(f'    position: {block_data.get("position")}')
    print(f'    nodes count: {len(block_data.get("nodes", []))}')
