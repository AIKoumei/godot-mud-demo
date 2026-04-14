# 基础规则

## 基础规则
    禁止在函数内部创建函数
    禁止使用多行注释"""，"""注释内容"""，使用#注释
    函数注解、模块注解使用##

## 基础代码调用用例
    数组去重
        new_array = GameCore.ArrayTools.deduplicate(array)
    字典合并
        new_dict = GameCore.DictionaryTools.merge(dict_1, dict_2)
    时间获取
        time_string =  Time.get_datetime_string_from_system()
    调用其他模块
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
    WorldMapScene.gd.txt

## 提供功能
    - 渲染地图路径和地面
    - 渲染玩家和其他实体
    - 摄像机跟踪目标对象
    - 处理地图输入事件

# 成员变量
- PathLayer: TileMapLayer = $MapLayer/PathLayer
- GroundLayer: TileMapLayer = $MapLayer/GroundLayer
- EntityLayer: Node2D = $MapLayer/EntityLayer
- cur_map_instance_id: String = ""
- entity_node_player = null
- entity_instance_id_to_map_node: Dictionary = {}
    - 储存实体实例 ID 对应的 MapNode 节点
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
- entity_type_to_tile_id: Dictionary = {
	"map_entity":27,
	"cneter":239,
	"wall":230,
	"gate":237,
	"road":242,
	"secondary_road":242,
	"building":232,
	"building_entrance":234,
}
- selected_position = null
- selected_img = $MapLayer/SelectedPathLayer/Selected

# 成员方法
- _ready() -> void: 初始化场景，加载必要资源
- _load_mud_cell_scene() -> void: 加载 MapMudCell 场景资源
- set_mod_root(path: String) -> void: 设置 mod 根目录路径
- render_from_instance(location_id: String) -> void: 从地图实例渲染地图
    - cur_map_instance_id = location_id
    从 WorldMapInstanceManager 中获取地图数据
        # 通过 WorldMapInstanceManager.get_instance 获取目标地图实例
        var map_instance = GameCore.mod_manager.call_mod(
            "WorldMapInstanceManager",
            "get_instance",
            location_id
        ) as Dictionary
    遍历 map_instance.data.map_nodes:{
        "x,y":[
            {
                entity_instance_id:entity_instance_id,
                entity_type:entity_type,
            },
            ...
        ]
    }.keys()
        - 获取 map_position:[x,y]
        - 通过 GameCore.mod_manager.call_mod("WorldMapInstanceManager", "get_sorted_map_nodes_at_map_position", {
            "map_instance_id": map_instance_id,
            "map_position": map_position
        }) 获取 map_position 对应的实体实例列表
        - 通过 _get_tile_id_by_entity_type 获取实体类型对应的 tile_id
        - 渲染 node 中的 entity 实体
			- GroundLayer.set_cell(entity_instance.map_position, tile_id, Vector2i.ZERO)
    - 渲染 player
    - 通过 PlayerManager 获取玩家实体实例
    var player_instance_id = GameCore.mod_manager.call_mod("PlayerManager", "get_player_entity_instance_id")
    if player_instance_id != "":
        # 获取玩家实体数据
        var player_entity = GameCore.mod_manager.call_mod("EntityInstanceManager", "get_entity", player_instance_id)
        if player_entity and not player_entity.is_empty():
            # 获取地图位置
            var pos = player_entity.get("map_position", Vector2i(0, 0))
            var pos_vec = Vector2i(pos.x, pos.y)
            
            # 通过 CachePoolManager 获取或创建 MapMudCell
            var map_mud_cell_path = "res://res/mods/WorldSceneManager/Scenes/GameScenes/MapMudCell.tscn"
            var map_mud_cell = GameCore.mod_manager.call_mod("CachePoolManager", "get_cached", map_mud_cell_path)
            
            # 如果缓存中没有，创建新的
            if map_mud_cell == null:
                if MudCellScene != null:
                    map_mud_cell = MudCellScene.instantiate()
                else:
                    # 作为后备，直接加载
                    var scene = load(map_mud_cell_path)
                    if scene != null:
                        map_mud_cell = scene.instantiate()
            
            if map_mud_cell != null:
                # 设置节点位置
                prints(pos_vec, tilemap.map_to_local(pos_vec))
                map_mud_cell.position = tilemap.map_to_local(pos_vec)
                # 挂到 EntityLayer 下
                EntityLayer.add_child(map_mud_cell)
                ## 缓存 MapMudCell
                #GameCore.mod_manager.call_mod("CachePoolManager", "cache", map_mud_cell_path, map_mud_cell)
                
                entity_node_player = map_mud_cell
                camera_settings.target = entity_node_player
- _render_path_and_ground(map_data: Array) -> void: 渲染路径和地面
- _get_ground_tile_id(tile_type: String) -> int: 获取地面 tile ID
- _get_path_tile_id(path_info: Dictionary) -> int: 获取路径 tile ID

- [ ] render_entity_node(args:Dictionary) -> void: 添加实体节点
    - @param args : Dictionary 添加实体节点参数
        - map_position : Vector2i 地图位置
        - map_instance_id : String 地图实例 ID
        - entity_instance_id : String 实体实例 ID
    - @return void
    - @function :
        - if map_instance_id != null and cur_map_instance_id != cur_map_instance_id:
            return
        - if entity_instance_id not in entity_instance_id_to_map_node:
            create_entity_node(args)
        - 存储 entity_instance_id 对应的 MapNode 节点，放置于 entity_instance_id_to_map_node 中，键为 entity_instance_id
        - 添加实体节点到 EntityLayer 中，根据 map_position 定位节点位置
- [ ] TODO: create_entity_node(args:Dictionary)

- _clear_all() -> void: 清理所有资源
- _process(delta: float) -> void: 处理摄像机跟踪
- _on_input_event(event: InputEvent) -> void: 处理输入事件
- _input(event: InputEvent) -> void: 处理输入事件
	if event is InputEventMouseButton:
		#prints("_input : InputEventMouseButton", event)
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
                var ground_position = GroundLayer.get_local_mouse_position()
                var map_position = GroundLayer.local_to_map(ground_position)
                prints("map_position", map_position, GameCore.BaseTools.veci_to_pos_str(map_position))
				if not selected_position or not selected_position == map_position:
					prints("_input : InputEventMouseButton", event)
					#var mouse_position = event.global_position
					#var ground_position = GroundLayer.to_local(mouse_position)
                    selected_position = map_position
					selected_img.visible = true
					selected_img.global_position = GroundLayer.to_global(GroundLayer.map_to_local(map_position)-Vector2(32,32))
                elif selected_position == map_position:
                    # move player
                    ## play move animation
                    # cancel selection
                    selected_position = null
                    selected_img.visible = false
        elif event.button_index == MOUSE_BUTTON_RIGHT:
            # cancel selection
            selected_position = null
            selected_img.visible = false
- _get_tile_id_by_entity_type(entity_type:String) -> int: 获取实体类型的 tile ID
    - @return tile_id : int 实体类型的 tile ID
    - 如果不存在 tile ID
        - 通过 GameCore.mod_manager.call_mod("EntityManager", "get_parent_entity_type_by_child_type", entity_type) 获取实体类型的父类型列表
            - 遍历父类型列表，获取每个父类型的 tile ID
            - 如果任意父类型存在 tile ID，则返回 tile ID
            - 如果所有父类型不存在 tile ID，则继续通过 GameCore.mod_manager.call_mod("EntityManager", "get_parent_entity_type_by_child_type", entity_type) 获取实体类型的父类型列表，重复以上步骤
- [ ] move_entity_to_map_position(args:Dictionary) -> void: 移动实体到指定地图位置
    - @param args : Dictionary 移动参数
        - map_position : Vector2i 目标地图位置
    - @return void
    - 移动实体到指定地图位置
    - @note 移动实体时，需要检查地图位置是否可通行
    - @note 移动实体时，需要更新实体的位置
    - @note 移动实体时，需要更新实体的渲染位置
    - function:
        - if not map_position:
            - return
        - [ ] TODO: if not GameCore.mod_manager.call_mod("WorldMapInstanceManager", "check_map_node_passable_by_entity_instance_id_list", {
            map_instance_id: map_instance_id,
            map_position: map_position,
            entity_instance_id_list:[entity_instance_id]
        }):
            - return
        - [ ] TODO: play_move_animation({
            map_position: map_position,
            entity_instance_id: entity_instance_id,
        })
        - after move animation finished
            - [ ] TODO: GameCore.mod_manager.call_mod("WorldMapInstanceManager", "modify_entity_position", {
                map_instance_id: map_instance_id,
                map_position: map_position,
                entity_instance_id: entity_instance_id,
            })
            - [ ] TODO: mud world system.check map node encounter
- [ ] play_move_animation(args:Dictionary) -> void: 播放移动动画
    - @param args : Dictionary 移动动画参数
        - map_position : Vector2i 目标地图位置
        - entity_instance_id : String 实体实例 ID
    - @return void
    - 播放移动动画
    - @note 播放移动动画时，需要更新玩家实体的位置
    - @note 播放移动动画时，需要更新玩家实体的渲染位置
    - function:
        - if not map_position:
            - map_position = selected_position
        - if not map_position:
            - return
        - play move animation
        - after move animation finished
            - world map instance manager.modify player position({
                player_entity_instance: player_entity_instance,
                map_position: target map node position,
            })
            - mud world system.check map node encounter


# 数据文件
- MapMudCell.tscn: 用于显示地图单元格和实体的场景文件
