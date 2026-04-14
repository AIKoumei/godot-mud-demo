import json

data_file = r'g:\WIN11\ming.jun\godot_projects\godot-mud-demo\Tools\test.gen_map_by_gdscript\data\saves\slot_1\mods\WorldMapManager\map_test_Town.sav'
data = json.load(open(data_file, 'r', encoding='utf-8'))

map_nodes = data.get('data', {}).get('map_nodes', [])
print(f'Total map_nodes: {len(map_nodes)}')

# 检查前 5 个节点的坐标
print('\n前 5 个节点的坐标：')
for i, node in enumerate(map_nodes[:5]):
    pos = node.get('map_position', [])
    print(f'{i}: map_position={pos}, type={type(pos)}, len={len(pos) if isinstance(pos, list) else "N/A"}')

# 统计所有不同的坐标格式
print('\n坐标格式统计：')
pos_formats = {}
for node in map_nodes:
    pos = node.get('map_position', [])
    format_key = f'{type(pos).__name__}'
    if isinstance(pos, list):
        format_key += f'_len{len(pos)}'
    pos_formats[format_key] = pos_formats.get(format_key, 0) + 1

for fmt, count in pos_formats.items():
    print(f'  {fmt}: {count}')

# 检查是否有节点的 map_position 不是列表
print('\n非列表坐标示例：')
for node in map_nodes[:10]:
    pos = node.get('map_position', [])
    if not isinstance(pos, list):
        print(f'  map_position={pos}, type={type(pos)}')
