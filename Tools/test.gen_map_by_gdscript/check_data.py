import json
import os

data_dir = r'g:\WIN11\ming.jun\godot_projects\godot-mud-demo\Tools\test.gen_map_by_gdscript\data\saves\slot_1\mods\WorldMapManager'

# 检查 wilderness 类型的数据
wilderness_files = ['map_test_Area.sav', 'map_test_Forest.sav', 'map_test_World.sav']
print('=== 检查 wilderness 数据的 final_height_level ===')
for f in wilderness_files:
    filepath = os.path.join(data_dir, f)
    data = json.load(open(filepath, 'r', encoding='utf-8'))
    
    # 检查 metadata.config.map_data.final_height_level
    meta_final = data.get('metadata', {}).get('config', {}).get('map_data', {}).get('final_height_level')
    # 检查 data.height_levels
    data_height = data.get('data', {}).get('height_levels')
    
    print(f'\n{f}:')
    print(f'  metadata.config.map_data.final_height_level: {meta_final is not None}')
    if meta_final:
        print(f'    前 2 行：{meta_final[:2]}')
    print(f'  data.height_levels: {data_height is not None}')
    if data_height:
        print(f'    前 2 行：{data_height[:2]}')

# 检查 town 类型的数据
print('\n\n=== 检查 town 数据的 total_nodes 和 blocks ===')
town_files = ['map_test_Town.sav', 'map_test_City.sav']
for f in town_files:
    filepath = os.path.join(data_dir, f)
    data = json.load(open(filepath, 'r', encoding='utf-8'))
    
    total_nodes = data.get('data', {}).get('total_nodes')
    blocks = data.get('data', {}).get('blocks')
    map_nodes = data.get('data', {}).get('map_nodes')
    
    print(f'\n{f}:')
    print(f'  total_nodes: {total_nodes is not None} (count: {len(total_nodes) if total_nodes else 0})')
    print(f'  blocks: {blocks is not None} (count: {len(blocks) if blocks else 0})')
    print(f'  map_nodes: {map_nodes is not None} (count: {len(map_nodes) if map_nodes else 0})')
    if map_nodes and len(map_nodes) > 0:
        print(f'    第一个节点：{map_nodes[0]}')
