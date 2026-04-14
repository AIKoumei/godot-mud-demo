import json

data_file = r'g:\WIN11\ming.jun\godot_projects\godot-mud-demo\Tools\test.gen_map_by_gdscript\data\saves\slot_1\mods\WorldMapManager\map_test_Town.sav'
data = json.load(open(data_file, 'r', encoding='utf-8'))

map_nodes = data.get('data', {}).get('map_nodes', [])
print(f'Total map_nodes: {len(map_nodes)}')

# 检查第一个节点的完整结构
print('\n第一个节点的完整结构：')
print(json.dumps(map_nodes[0], indent=2, ensure_ascii=False))

# 检查所有节点的 attributes.map_position
print('\n检查 attributes.map_position:')
for i, node in enumerate(map_nodes[:5]):
    attrs = node.get('attributes', {})
    map_pos = attrs.get('map_position', 'N/A')
    print(f'{i}: attributes.map_position={map_pos}')
