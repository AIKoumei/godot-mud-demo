#  测试数据
    路径：
        G:\WIN11\ming.jun\godot_projects\godot-mud-demo\Tools\test.gen_map_by_gdscript\data\saves\slot_1\mods\WorldMapManager\map_test_Town.sav
        G:\WIN11\ming.jun\godot_projects\godot-mud-demo\Tools\test.gen_map_by_gdscript\data\saves\slot_1\mods\WorldMapManager\map_*.sav
#  输出
    路径：
        G:\WIN11\ming.jun\godot_projects\godot-mud-demo\Tools\test.gen_map_by_gdscript\output\map_*.jpg
#  功能逻辑
    - 读取测试数据
    - 生成可视化地图
        - 根据 data.map_type 区分 town 类型和 wilderness 类型地图
        - town 类型，参考 G:\WIN11\ming.jun\godot_projects\godot-mud-demo\Tools\test_map_generator.simple\map_generator.py
            - 将 metadata.config.map_data.total_nodes 和 metadata.config.map_data.blocks 转换为可视化地图
                - block 要在内边框画上随机高饱和度的颜色
                - block 要画上 id
        - wilderness 类型，参考 G:\WIN11\ming.jun\godot_projects\godot-mud-demo\Tools\test_map_generator.town.full\map_generator.py
            - 将 metadata.config.map_data.final_height_level 转换为可视化地图
                - 高度格子按 G:\WIN11\ming.jun\godot_projects\godot-mud-demo\Tools\test_map_generator.simple\README.md 中的颜色方案
                - 高度格子画上高度
    - 保存可视化地图
        - 保存为 jpg 格式
