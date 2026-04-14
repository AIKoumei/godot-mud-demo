# 基础规则

## 基础规则

1. 禁止在函数内部创建函数
2. 禁止使用多行注释"""，"""注释内容"""，使用#注释
3. 函数注解、模块注解使用##

## 基础代码调用用例

1. 数组去重
    new_array = GameCore.ArrayTools.deduplicate(array)
2. 字典合并
    new_dict = GameCore.DictionaryTools.merge(dict_1, dict_2)
3. 时间获取
    time_string =  Time.get_datetime_string_from_system()
4. 调用其他模块
    result = GameCore.ModManager.call_mod(mod_name:String, method_name:String, ...args)

## 代码注释

1. 为文件适当添加注释
    给出配置
    给出输入输出的数据结构
    说明模块的功能
    给出模块的用例
    给出涉及模块的名称
2. 在文件头给出模块的主要功能以及对应方法
3. 给出功能的用例

## 模块交互

    通过 GameCore.mod_manager.call_mod(mod_name, method_name, args) 调用其他模块的方法
        不需要判断 Engine.has_meta(mod_name)
        因为 GameCore.mod_manager.call_mod 已经判断了，如果模块不存在，不会调用空模块，所以不会报错。

# 基础逻辑/基础功能

## 声明全局种子，GameCore.Settings.GameSettings.WorldSeed，所有方法的随机数都基于这个种子，每个步骤的随机数都基于全局种子，确保可重复生成相同结果。

## 基础代码内容：
    WorldMapScene 是一个用于渲染和管理游戏世界地图的场景脚本，主要负责渲染地图路径、地面和实体，管理地图单元格，实现摄像机跟踪功能，处理地图输入事件。

## 提供功能
    - 渲染地图路径和地面
    - 渲染玩家和其他实体
    - 摄像机跟踪目标对象
    - 处理地图输入事件

# 成员变量

- PathLayer: TileMapLayer = $MapLayer/PathLayer
- GroundLayer: TileMapLayer = $MapLayer/GroundLayer
- EntityLayer: Node2D = $MapLayer/EntityLayer
- entity_node_player = null
- tilemap: TileMapLayer = GroundLayer
- camera_root: Node2D = $CameraRoot
- camera: Camera2D = $CameraRoot/Camera2D
- camera_settings = {"target": null, "target_position": null, "is_moving": false}
- MudCellScene: PackedScene = null
- _cells: Dictionary = {}
- mod_root_path: String = ""
- BUILDING_TYPES: Dictionary = {"item_shop": {...}, "equipment_shop": {...}, ...}
- connection_to_tile_id_pos: Dictionary = {
	1:Vector2i(0,1),#北
	2:Vector2i(1,0),#西
	4:Vector2i(1,1),#南
	8:Vector2i(0,0),#东
	5:Vector2i(2,1),#北南
	10:Vector2i(2,0),#东西
}
- room_type_to_tile_id: Dictionary = {
	"cneter":239,
	"road":242,
	"secondary_road":242,
	"building":232,
	"building_entrance":234,
	"wall":230,
	"gate":237,
}
- selected_position = null
- selected_img = $MapLayer/SelectedPathLayer/Selected

# 成员方法

- _ready() -> void: 初始化场景，加载必要资源
- _load_mud_cell_scene() -> void: 加载 MapMudCell 场景资源
- set_mod_root(path: String) -> void: 设置 mod 根目录路径
- render_from_instance(location_id: String) -> void: 从地图实例渲染地图
    读取 map instance 数据
    遍历 map_instance.data.map_nodes
        根据 node.entity_instance_id 从 EntityInstanceManager 中获取实体实例数据
        如果 node.type 为 map_cell
            EntityManager
            
- _render_path_and_ground(map_data: Array) -> void: 渲染路径和地面
- _get_ground_tile_id(tile_type: String) -> int: 获取地面 tile ID
- _get_path_tile_id(path_info: Dictionary) -> int: 获取路径 tile ID
- _render_info_cells(map_data: Array, entity_instances: Array = []) -> void: 渲染信息单元格
- _render_entity(mud_cell: MapMudCell, entity_data: Dictionary) -> void: 渲染实体
- _render_flag(mud_cell: MapMudCell, flag_data: Dictionary, pos: Vector2i) -> void: 渲染标记
- _clear_all() -> void: 清理所有资源
- _process(delta: float) -> void: 处理摄像机跟踪
- _on_input_event(event: InputEvent) -> void: 处理输入事件
- _input(event: InputEvent) -> void: 处理输入事件

# 数据文件

- MapMudCell.tscn: 用于显示地图单元格和实体的场景文件
