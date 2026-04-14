import json

data_file = r'g:\WIN11\ming.jun\godot_projects\godot-mud-demo\Tools\test.gen_map_by_gdscript\data\saves\slot_1\mods\WorldMapManager\map_test_Town.sav'
data = json.load(open(data_file, 'r', encoding='utf-8'))

print('=== 检查数据结构 ===')
print('Top keys:', list(data.keys()))
print('\ndata keys:', list(data.get('data', {}).keys()))
print('metadata keys:', list(data.get('metadata', {}).keys()))
print('metadata.config keys:', list(data.get('metadata', {}).get('config', {}).keys()))
print('metadata.config.map_data keys:', list(data.get('metadata', {}).get('config', {}).get('map_data', {}).keys()))

# 检查 blocks
meta_blocks = data.get('metadata', {}).get('config', {}).get('map_data', {}).get('blocks', {})
print(f'\nmetadata.config.map_data.blocks count: {len(meta_blocks)}')
print('Sample blocks:', list(meta_blocks.keys())[:5])

# 检查 total_nodes
meta_total = data.get('metadata', {}).get('config', {}).get('map_data', {}).get('total_nodes', {})
print(f'\nmetadata.config.map_data.total_nodes count: {len(meta_total)}')
print('Sample total_nodes:', list(meta_total.keys())[:5])
