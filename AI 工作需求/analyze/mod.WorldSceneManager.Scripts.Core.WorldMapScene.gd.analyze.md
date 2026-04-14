# mod.WorldSceneManager.Scripts.Core.WorldMapScene.gd 分析文档

## 基础规则

### 基础规则
- 禁止在函数内部创建函数
- 禁止使用多行注释"""，"""注释内容"""，使用#注释
- 函数注解、模块注解使用##

### 基础代码调用用例

- 数组去重
   ```gdscript
   new_array = GameCore.ArrayTools.deduplicate(array)
   ```

- 字典合并
   ```gdscript
   new_dict = GameCore.DictionaryTools.merge(dict_1, dict_2)
   ```

- 时间获取
   ```gdscript
   time_string =  Time.get_datetime_string_from_system()
   ```

- 调用其他模块
   ```gdscript
   result = GameCore.ModManager.call_mod(mod_name:String, method_name:String, ...args)
   ```

### 代码注释

- 为文件适当添加注释
   - 给出配置
   - 给出输入输出的数据结构
   - 说明模块的功能
   - 给出模块的用例
   - 给出涉及模块的名称

- 在文件头给出模块的主要功能以及对应方法

- 给出功能的用例

### 模块交互

- 通过 GameCore.mod_manager.call_mod(mod_name, method_name, args) 调用其他模块的方法
- 不需要判断 Engine.has_meta(mod_name)
- 因为 GameCore.mod_manager.call_mod 已经判断了，如果模块不存在，不会调用空模块，所以不会报错。

# 模块概述

## 模块名称
WorldMapScene

## 模块路径
res/mods/WorldSceneManager/Scripts/Core/WorldMapScene.gd

## 模块功能
世界地图场景类，负责渲染和管理世界地图的可视化。主要职责包括:
1. 渲染地图实例 (TileMap 层)
2. 管理实体节点 (MapMudCell)
3. 摄像机跟随玩家
4. 处理输入事件 (选择、移动)
5. 管理建筑类型和实体类型映射

## 模块依赖
- WorldMapInstanceManager: 获取地图实例数据
- PlayerManager: 获取玩家实体 ID
- EntityInstanceManager: 获取实体数据
- CachePoolManager: 缓存 MapMudCell
- EntityManager: 获取实体类型父类型
- ModEventListenerFilter: 事件监听过滤

## 场景结构
```
WorldMapScene (Node2D)
├── MapLayer (Node2D)
│   ├── PathLayer (TileMapLayer) - 路径层
│   ├── GroundLayer (TileMapLayer) - 地面层
│   ├── EntityLayer (Node2D) - 实体层
│   └── SelectedPathLayer (Node2D)
│       └── Selected (TextureRect) - 选择指示器
└── CameraRoot (Node2D)
    └── Camera2D - 摄像机
```

## 建筑类型定义
```gdscript
BUILDING_TYPES = {
  "item_shop": {
    "name": "道具商店",
    "required": {
      "entity_type": { "shopkeeper": {}, "vending_machine": {} },
      "entity": {}
    }
  },
  "equipment_shop": { "name": "装备商店", ... },
  "quest_center": { "name": "任务中心", ... },
  "training_center": { "name": "训练中心", ... },
  "home_shop": { "name": "家园商店", ... },
  "home": { "name": "家园", ... },
  "union_room": { "name": "联盟大厅", ... }
}
```

## 模块用例

```gdscript
# 示例 1：渲染地图
var world_map_scene = WorldMapScene.new()
world_map_scene.render_from_instance("file_island")

# 示例 2：设置 mod 根目录
world_map_scene.set_mod_root("res://mods/MyMod")

# 示例 3：移动实体到指定位置
world_map_scene.move_entity_to_map_position({
    "map_position": Vector2i(10, 10),
    "entity_instance_id": "player_001"
})

# 示例 4：播放移动动画
world_map_scene.play_move_animation({
    "map_position": Vector2i(15, 15),
    "entity_instance_id": "player_001"
})

# 示例 5：获取实体类型的 tile ID
var tile_id = world_map_scene._get_tile_id_by_entity_type("human")
```

# 成员变量

## 节点引用
- @onready var PathLayer: TileMapLayer
  - 路径层，用于渲染道路连接

- @onready var GroundLayer: TileMapLayer
  - 地面层，用于渲染地形和实体

- @onready var EntityLayer: Node2D
  - 实体层，用于挂载 MapMudCell 节点

- @onready var camera_root: Node2D
  - 摄像机根节点

- @onready var camera: Camera2D
  - 摄像机

- @onready var selected_img: TextureRect
  - 选择指示器图像

## 状态变量
- var cur_map_instance_id: String
  - 当前地图实例 ID

- var entity_node_player: Node
  - 玩家实体节点

- var entity_instance_id_to_map_node: Dictionary
  - 实体实例 ID 到 MapNode 节点的映射

- var _cells: Dictionary
  - 存储 pos -> MapMudCell 的映射

- var mod_root_path: String
  - mod 根路径

- var MudCellScene: PackedScene
  - MapMudCell 场景资源

## 配置
- var camera_settings: Dictionary
  - 摄像机设置
  - 包含 target, target_position, is_moving

- var entity_type_to_tile_id: Dictionary
  - 实体类型到 tile ID 的映射
  - 例如：{"map_cell": 27, "wall": 230, "gate": 237, ...}

- var connection_to_tile_id_pos: Dictionary
  - 路径连接到 tile ID 和位置的映射
  - 例如：{1: Vector2i(0,1), 2: Vector2i(1,0), ...}

# 成员方法

## 生命周期方法

- _ready() -> void
  - functions:
    - 连接父节点的 on_input_event 信号
    - 为 BUILDING_TYPES 中的每个类型设置 tile ID
    - 加载 MapMudCell 场景

- _process(delta: float) -> void
  - @args:
    - delta: 时间增量
  - functions:
    - 平滑移动摄像机到目标位置
    - 使用 lerp 插值，速度 5.0
    - 检查 target 是否存在
    - 更新 target_position
    - 到达目标位置后清空标记

## 场景加载方法

- _load_mud_cell_scene() -> void
  - functions:
    - 加载 MapMudCell.tscn 场景
    - 路径：res://res/mods/WorldSceneManager/Scenes/GameScenes/MapMudCell.tscn
    - 检查资源是否存在
    - 加载并保存到 MudCellScene

- set_mod_root(path: String) -> void
  - @args:
    - path: mod 根路径
  - functions:
    - 设置 mod_root_path
    - 用于加载图标资源

## 渲染方法

- render_from_instance(location_id: String) -> void
  - @args:
    - location_id: 地图位置 ID
  - functions:
    - 1. 设置 cur_map_instance_id
    - 2. 调用 WorldMapInstanceManager.get_instance() 获取地图实例
    - 3. 遍历 map_nodes 渲染实体:
       - 对每个位置，调用 get_sorted_map_nodes_at_map_position()
       - 获取实体类型，调用 _get_tile_id_by_entity_type()
       - 使用 GroundLayer.set_cell() 渲染
    - 4. 渲染玩家:
       - 调用 PlayerManager.get_player_entity_instance_id()
       - 调用 EntityInstanceManager.get_entity() 获取数据
       - 从 CachePoolManager 获取或创建 MapMudCell
       - 设置位置，添加到 EntityLayer
       - 设置摄像机 target
    - 5. 打印渲染信息

- _render_path_and_ground(map_data: Array) -> void
  - @args:
    - map_data: 地图数据数组
  - functions:
    - 清空 PathLayer
    - 遍历 map_data
    - 对每个 cell:
      - 获取位置
      - 调用 _get_ground_tile_id() 获取地面 tile ID
      - 调用 _get_path_tile_id() 获取路径 tile ID
      - 设置对应的 TileMapLayer

- _render_info_cells(map_data: Array, entity_instances: Array) -> void
  - @args:
    - map_data: 地图数据
    - entity_instances: 实体实例数组
  - functions:
    - 遍历 map_data
    - 对包含 entity 或 flag 的 cell:
      - 实例化 MapMudCell
      - 调用 _render_entity() 或 _render_flag()
      - 添加到 EntityLayer
    - 遍历 entity_instances
    - 对每个实体:
      - 检查位置是否已有单元格
      - 没有则创建新的 MapMudCell
      - 调用 _render_entity() 渲染

- _render_entity(mud_cell: MapMudCell, entity_data: Dictionary) -> void
  - @args:
    - mud_cell: MapMudCell 节点
    - entity_data: 实体数据
  - functions:
    - 获取 entity_type
    - 构建图标路径：{mod_root_path}/Sprites/WorldMap/Icon/{entity_type}.png
    - 调用 mud_cell.set_entity_icon()

- _render_flag(mud_cell: MapMudCell, flag_data: Dictionary, pos: Vector2i) -> void
  - @args:
    - mud_cell: MapMudCell 节点
    - flag_data: 旗帜数据
    - pos: 位置
  - functions:
    - 获取 flag_type
    - 构建图标路径
    - 计算偏移量
    - 调用 mud_cell.set_flag_icon()

## 工具方法

- _get_ground_tile_id(tile_type: String) -> int
  - @args:
    - tile_type: 地面类型
  - @return int: tile ID
  - functions:
    - match tile_type:
      - "water": 0
      - "deep_water": 1
      - "sand": 2
      - "lava": 3
      - "volcano_road": 4
      - "grass": 5
      - 其他：-1

- _get_path_tile_id(path_info: Dictionary) -> int
  - @args:
    - path_info: 路径信息
  - @return int: tile ID
  - functions:
    - 获取 dir
    - match dir:
      - "N": 0
      - "S": 1
      - "E": 2
      - "W": 3
      - 其他：-1

- _get_tile_id_by_entity_type(entity_type: String) -> int
  - @args:
    - entity_type: 实体类型
  - @return int: tile ID
  - functions:
    - 检查 entity_type_to_tile_id 是否有当前类型
    - 有则返回
    - 没有则调用 EntityManager.get_parent_entity_type_by_child_type()
    - 递归查找父类型的 tile ID
    - 找到则返回，否则返回 0

- _clear_all() -> void
  - functions:
    - 清空 EntityLayer 的所有子节点
    - 清空 _cells 字典

## 输入处理方法

- _input(event: InputEvent) -> void
  - @args:
    - event: 输入事件
  - functions:
    - 检查 InputEventMouseButton
    - 左键:
      - 获取鼠标位置
      - 转换为地图位置
      - 如果未选择或选择不同位置:
        - 设置 selected_position
        - 显示选择指示器
      - 如果已选择相同位置:
        - 取消选择
    - 右键:
      - 取消选择

## 实体移动方法

- move_entity_to_map_position(args: Dictionary) -> void
  - @args:
    - args: 包含 map_position, entity_instance_id
  - functions:
    - 检查 map_position 和 entity_instance_id
    - TODO: 检查地图位置是否可通行
    - TODO: 播放移动动画
    - TODO: 等待动画完成后更新实体位置
    - TODO: 检查地图格子遭遇
    - 打印 TODO 提示

- play_move_animation(args: Dictionary) -> void
  - @args:
    - args: 包含 map_position, entity_instance_id
  - functions:
    - 检查 map_position 和 entity_instance_id
    - TODO: 播放移动动画
    - TODO: 更新玩家实体位置
    - TODO: 更新渲染位置
    - TODO: 动画完成后调用后续操作
    - 打印 TODO 提示

- _on_input_event(event: InputEvent) -> void
  - @args:
    - event: 输入事件
  - functions:
    - 打印输入事件信息

# 数据文件

- MapMudCell.tscn
  - 路径：res://res/mods/WorldSceneManager/Scenes/GameScenes/MapMudCell.tscn
  - 用于显示实体图标和旗帜

# 模块交互

## 调用的其他模块
- WorldMapInstanceManager: get_instance(), get_sorted_map_nodes_at_map_position()
- PlayerManager: get_player_entity_instance_id()
- EntityInstanceManager: get_entity()
- CachePoolManager: get_cached()
- EntityManager: get_parent_entity_type_by_child_type()

## 被其他模块调用
- WorldSceneManager: render_from_instance()
- GameManager: 渲染游戏场景

## 发送的事件
- 无

# 核心流程

## 地图渲染流程
```
1. 接收 location_id
2. 调用 WorldMapInstanceManager.get_instance(location_id)
3. 如果地图实例存在:
   a. 遍历 map_nodes:
      - 对每个位置 pos_key:
        * 解析坐标 pos_vec
        * 调用 get_sorted_map_nodes_at_map_position()
        * 对每个 node:
          · 获取 entity_type
          · 调用 _get_tile_id_by_entity_type()
          · GroundLayer.set_cell(pos_vec, tile_id)
   b. 渲染玩家:
      - 获取玩家实体 ID
      - 获取玩家实体数据
      - 获取地图位置
      - 从 CachePoolManager 获取 MapMudCell
      - 设置位置，添加到 EntityLayer
      - 设置摄像机 target
4. 打印渲染信息
```

## 摄像机跟随流程
```
每帧执行 (_process):
1. 检查 target 是否存在
2. 如果存在:
   a. 获取 target 的全局位置
   b. 调整偏移 (32, 32)
   c. 检查位置是否变化
   d. 如果变化:
      - 更新 target_position
      - 使用 lerp 平滑移动 camera_root
      - 速度：5.0 * delta
3. 如果不存在但有 target_position:
   a. 检查 is_moving 是否为 false
   b. 平滑移动到 target_position
   c. 检查是否到达 (距离 < 1.0)
   d. 到达后清空 target_position
```

## 输入处理流程
```
鼠标左键点击:
1. 获取鼠标地面位置
2. 转换为地图位置
3. 如果未选择或选择不同:
   - 设置 selected_position
   - 显示选择指示器
   - 设置指示器位置
4. 如果已选择相同位置:
   - 取消选择
   - 隐藏指示器

鼠标右键点击:
1. 取消选择
2. 隐藏指示器
```

## 实体移动流程 (TODO)
```
1. 接收 map_position 和 entity_instance_id
2. 检查参数有效性
3. TODO: 调用 WorldMapInstanceManager.check_map_node_passable_by_entity_instance_id_list()
4. TODO: 如果不可通行，返回
5. TODO: 播放移动动画 play_move_animation()
6. TODO: 等待动画完成
7. TODO: 调用 WorldMapInstanceManager.modify_entity_position()
8. TODO: 调用 mud_world_system.check_map_node_encounter()
```

# 架构设计

## 分层渲染架构
- PathLayer: 路径层 (TileMapLayer)
  - 渲染道路连接
- GroundLayer: 地面层 (TileMapLayer)
  - 渲染地形和实体
- EntityLayer: 实体层 (Node2D)
  - 挂载 MapMudCell 节点
  - 动态实体

## 摄像机系统
- CameraRoot: 摄像机根节点
  - 平滑移动的目标
- Camera2D: 实际摄像机
  - 跟随 CameraRoot

## 实体映射系统
- entity_type_to_tile_id: 实体类型到 tile ID
- 支持递归查找父类型
- 便于扩展新实体类型

## 缓存系统
- 使用 CachePoolManager 缓存 MapMudCell
- 避免重复实例化
- 提高性能

## 输入处理
- _input(): 处理全局输入
- _on_input_event(): 处理特定事件
- 支持选择和移动操作

# TODO

- [ ] 实现完整的移动功能
  - [ ] 检查地图位置可通行性
  - [ ] 播放移动动画
  - [ ] 更新实体位置
  - [ ] 检查遭遇事件

- [ ] 优化渲染性能
  - [ ] 只渲染可见区域
  - [ ] 使用 MultiMeshInstance2D

- [ ] 添加更多交互功能
  - [ ] 实体选择
  - [ ] 信息显示
  - [ ] 上下文菜单

- [ ] 改进摄像机控制
  - [ ] 边界限制
  - [ ] 缩放功能
  - [ ] 拖拽移动
