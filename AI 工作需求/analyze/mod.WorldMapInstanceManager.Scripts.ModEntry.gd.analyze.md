# mod.WorldMapInstanceManager.Scripts.ModEntry.gd 分析文档

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
WorldMapInstanceManager

## 模块路径
res/mods/WorldMapInstanceManager/Scripts/ModEntry.gd

## 模块功能
世界地图实例管理模块，负责管理多个 location 的运行时实例。主要职责包括：
1. 管理地图实例的生命周期（创建、加载、保存）
2. 处理实体在地图上的位置信息
3. 处理地图格子的修改（破坏、建造、掉落等）
4. 响应实体创建和销毁事件
5. 维护地图实例与实体的索引关系
6. 对地图位置的实体按 render_order 排序

## 模块依赖
- WorldMapManager: 获取地图模板
- EntityInstanceManager: 创建和管理实体实例
- EntityManager: 获取实体类型的 render_order
- SaveManager: 保存/加载地图实例数据
- ModEventListenerFilter: 事件监听过滤

## 使用全局种子
GameCore.Settings.GameSettings.WorldSeed

## 数据结构

### 地图实例数据结构
```json
{
  "version": 1,
  "location_id": "file_island",
  "map_data": [
    { "x": 0, "y": 0, "tile": "grass" },
    { "x": 1, "y": 0, "tile": "tree", "breakable": true, "hp": 20 }
  ],
  "state": {
    "weather": "sunny",
    "light_level": 1.0
  }
}
```

### 地图实例运行时数据结构（细化后）
```json
{
  "data": {
    "map_instance_id": "file_island",
    "map_nodes": {
      "x,y": [
        {
          "entity_instance_id": "entity_001",
          "entity_type": "human"
        }
      ]
    },
    "map_nodes_dirty": {
      "x,y": true|false
    }
  }
}
```

### 实体位置索引
```json
{
  "map_instance_id": {
    "x_y": {
      "entity_instance_id": {}
    }
  }
}
```

## 模块用例

```gdscript
# 示例 1：生成所有地图实例
WorldMapInstanceManager.gen_all_locations()

# 示例 2：加载某个地图实例
WorldMapInstanceManager.load_location("file_island")

# 示例 3：获取当前地图实例
var current_instance = WorldMapInstanceManager.get_current_instance()

# 示例 4：创建实体
var entity_cfg = {
    "entity_template_id": "human",
    "map_instance_id": "file_island",
    "map_position": Vector2(10, 10),
    "attributes": { "level": 5, "hp": 100 }
}
var entity = WorldMapInstanceManager.create_entity(entity_cfg)

# 示例 5：设置实体位置
WorldMapInstanceManager.set_entity_position(entity.instance_id, {
    "map_instance_id": "file_island",
    "map_position": Vector2(15, 15)
})

# 示例 6：获取地图上的所有实体
var entities = WorldMapInstanceManager.get_entities_by_map("file_island")

# 示例 7：修改地图格子数据
WorldMapInstanceManager.merge_tile_data("file_island", 5, 5, { "tile": "water", "passable": false })

# 示例 8：移动实体
WorldMapInstanceManager.move_entity({
    "entity_instance_id": "entity_001",
    "new_map_instance_id": "file_island",
    "new_map_position": Vector2(20, 20)
})

# 示例 9：获取排序后的地图节点
var sorted_nodes = WorldMapInstanceManager.get_sorted_map_nodes_at_map_position({
    "map_instance_id": "file_island",
    "map_position": Vector2(10, 10)
})
```

# 成员变量

- _mud_map_instances: Dictionary
  - 存储所有地图实例
  - 数据结构：{location_id: map_instance_data}

- _current_location_id: String
  - 当前位置 ID

- _entity_positions: Dictionary
  - 维护基于 map_instance_id 的 entity 位置信息
  - 数据结构：{map_instance_id: {x_y: {entity_instance_id: {}}}}

- _entity_by_map: Dictionary
  - 以 map_instance_id 为索引的 entity 索引表
  - 数据结构：{map_instance_id: {entity_instance_id: {}}}

- _map_by_entity: Dictionary
  - 以 entity_instance_id 为索引的地图索引表
  - 数据结构：{entity_instance_id: map_instance_id}

- _rng: RandomNumberGenerator
  - 随机数生成器

# 成员方法

- _on_mod_load() -> bool
  - @return bool: 模块加载是否成功
  - functions:
    - 初始化随机数生成器，使用全局种子
    - 注册事件监听器：
      - SceneManager.SaveAllMapInstanceData: 保存所有地图实例
      - EntityInstanceManager.entity_created: 实体创建事件
      - EntityInstanceManager.entity_destroyed: 实体销毁事件

- _on_mod_event(_mod_name:String, event_name:String, event_data:Dictionary) -> void
  - @args:
    - _mod_name: 触发事件的模块名称
    - event_name: 事件名称
    - event_data: 事件数据
  - functions:
    - 监听 WorldMapManager 的 after_gen_all_location_map_finished 事件
    - 监听 SaveAllMapInstanceData 事件
    - 处理 EntityInstanceManager 的实体创建/销毁事件

- create_map(location_id:String) -> bool
  - @args:
    - location_id: 地图位置 ID
  - @return bool: 是否创建成功
  - functions:
    - 从 WorldMapManager 获取地图模板
    - 创建地图实例，生成唯一 instance_id
    - 实例化地图中的实体（调用 EntityInstanceManager）
    - 存储地图实例到 _mud_map_instances

- load_location(location_id:String) -> bool
  - @args:
    - location_id: 地图位置 ID
  - @return bool: 是否加载成功
  - functions:
    - 如果地图实例已存在，直接设置为当前实例
    - 从 WorldMapManager 获取静态数据
    - 创建新的地图实例
    - 设置为当前实例

- gen_all_locations() -> void
  - functions:
    - 注册事件监听器，监听 WorldMapManager 的 after_gen_all_location_map_finished 事件
    - 调用 WorldMapManager.gen_all_locations() 生成所有地图模板

- after_gen_all_locations_finished() -> void
  - functions:
    - 调用 init_mud_maps() 初始化所有地图实例
    - 保存所有地图实例
    - 发送 after_gen_all_locations_finished 事件

- init_mud_maps() -> void
  - functions:
    - 从 WorldMapManager 获取所有地图模板
    - 遍历所有模板，创建地图实例
    - 初始化 map_nodes 和 map_nodes_dirty
    - 实例化地图中的实体
    - 发送 init_one_mud_map_entities 事件

- save_all_location_instances() -> void
  - functions:
    - 遍历 _mud_map_instances 中的所有地图数据
    - 使用 SaveManager 保存每个地图数据到存档槽位
    - 调用 EntityInstanceManager.save_entity_instances()

- get_current_instance() -> Dictionary
  - @return Dictionary: 当前地图实例数据
  - functions:
    - 从 _mud_map_instances 中获取当前实例

- get_instance(location_id:String) -> Dictionary
  - @args:
    - location_id: 地图位置 ID
  - @return Dictionary: 指定地图实例数据
  - functions:
    - 从 _mud_map_instances 中获取指定实例

- get_all_mud_map_instances() -> Dictionary
  - @return Dictionary: 所有地图实例数据
  - functions:
    - 返回 _mud_map_instances 字典

- get_map_data(location_id:String) -> Array
  - @args:
    - location_id: 地图位置 ID
  - @return Array: 地图数据数组
  - functions:
    - 从指定地图实例中获取 map_data

- get_entities_by_map(map_instance_id:String) -> Array
  - @args:
    - map_instance_id: 地图实例 ID
  - @return Array: 该地图上的所有实体实例 ID 列表
  - functions:
    - 从 _entity_by_map 中获取该地图的所有实体

- create_entity(cfg:Dictionary) -> Dictionary
  - @args:
    - cfg: 配置字典，包含 entity_template_id, map_position, attributes 等
  - @return Dictionary: 创建的实体实例数据
  - functions:
    - 提取必要参数（entity_template_id, map_instance_id, map_position）
    - 构建实体配置
    - 调用 EntityInstanceManager.create_entity() 创建实体

- set_entity_position(entity_instance_id:String, cfg:Dictionary) -> void
  - @args:
    - entity_instance_id: 实体实例 ID
    - cfg: 配置字典，包含 map_instance_id, map_position 等
  - functions:
    - 从旧位置移除实体
    - 在新位置写入实体
    - 更新两个索引表（_entity_by_map 和 _map_by_entity）

- move_entity(args:Dictionary) -> void
  - @args:
    - entity_instance_id: 实体实例 ID
    - new_map_instance_id: 新的地图实例 ID（可选）
    - new_map_position: 实体新的位置
  - functions:
    - 从 EntityInstanceManager 获取实体实例
    - 调用 add_entity 添加到新位置
    - 通知 EntityInstanceManager 更新实体位置

- remove_entity(args:Dictionary) -> void
  - @args:
    - entity_instance_id: 实体实例 ID
    - map_instance_id: 地图实例 ID（可选）
  - functions:
    - 从 EntityInstanceManager 获取实体实例
    - 从 _entity_positions 中移除
    - 从 map_nodes 中移除并设置 map_nodes_dirty
    - 从索引表中移除

- add_entity(args:Dictionary) -> void
  - @args:
    - entity_instance_id: 实体实例 ID
    - map_instance_id: 地图实例 ID
    - map_position: 实体位置
  - functions:
    - 先移除实体（如果已存在）
    - 确保地图实例存在
    - 在新位置写入实体
    - 更新两个索引表
    - 更新 map_nodes 和 map_nodes_dirty

- sort_map_nodes(args:Dictionary) -> void
  - @args:
    - map_instance_id: 地图实例 ID
    - map_position: 地图位置
  - functions:
    - 检查 map_nodes_dirty 标记
    - 对 nodes 按 render_order 排序（使用冒泡排序）
    - 清除 map_nodes_dirty 标记

- get_sorted_map_nodes_at_map_position(args:Dictionary) -> Array
  - @args:
    - map_instance_id: 地图实例 ID
    - map_position: 地图位置
  - @return Array: 排序后的实体实例列表
  - functions:
    - 检查 map_nodes_dirty 标记
    - 如果需要排序，调用 sort_map_nodes()
    - 返回排序后的实体列表

- merge_tile_data(location_id:String, x:int, y:int, data:Dictionary) -> void
  - @args:
    - location_id: 地图位置 ID
    - x: 格子 x 坐标
    - y: 格子 y 坐标
    - data: 要合并的数据
  - functions:
    - 查找指定坐标的格子
    - 合并数据到格子
    - 如果没有找到，创建新格子

- update(delta:float) -> void
  - @args:
    - delta: 时间增量
  - functions:
    - 更新所有地图实例（TODO: 天气变化、单位 AI 等）

- _remove_entity_from_all_positions(entity_instance_id:String) -> void
  - @args:
    - entity_instance_id: 实体实例 ID
  - functions:
    - 从所有地图实例的 _entity_positions 中移除
    - 从所有地图实例的 map_nodes 中移除
    - 从两个索引表中移除

- _remove_entity_from_all_indices(entity_instance_id:String) -> void
  - @args:
    - entity_instance_id: 实体实例 ID
  - functions:
    - 从 _entity_by_map 中移除
    - 从 _map_by_entity 中移除

- _remove_entity_from_old_position(entity_instance_id:String, map_instance_id:String) -> void
  - @args:
    - entity_instance_id: 实体实例 ID
    - map_instance_id: 地图实例 ID
  - functions:
    - 从 _entity_positions 的旧位置移除实体

- _update_instance(location_id:String, delta:float) -> void
  - @args:
    - location_id: 地图位置 ID
    - delta: 时间增量
  - functions:
    - 更新单个地图实例（TODO: 天气变化、单位 AI 等）

# 数据文件

- 无直接依赖的数据文件
- 使用 SaveManager 保存/加载地图实例数据到存档槽位
- 存档文件名格式：mods/WorldMapInstanceManager/map_{map_name}.sav

# 模块交互

## 调用的其他模块
- WorldMapManager: get_location_static(), get_all_mud_map_templates()
- EntityInstanceManager: create_entity(), get_entity(), update_entity_position(), save_entity_instances()
- EntityManager: get_render_order()
- SaveManager: save_mod_slot_data(), load_mod_slot_data(), has_mod_slot_file()
- ModEventListenerFilter: 事件监听过滤

## 被其他模块调用
- WorldSceneManager: 调用 get_instance(), get_entities_by_map()
- MudEntityInteractionSystem: 调用 move_entity(), add_entity(), remove_entity()
- DefaultGameScene: 调用 get_current_instance(), get_sorted_map_nodes_at_map_position()

## 发送的事件
- after_gen_all_locations_finished: 所有地图实例生成完成
- init_one_mud_map_entities: 单个地图实例的实体初始化完成

# 核心流程

## 地图实例生成流程
1. GameManager 调用 WorldMapInstanceManager.gen_all_locations()
2. WorldMapInstanceManager 注册事件监听器
3. WorldMapManager 生成所有地图模板后发送事件
4. WorldMapInstanceManager 接收到事件后，调用 after_gen_all_locations_finished()
5. 调用 init_mud_maps() 初始化所有地图实例
6. 遍历所有地图模板，创建地图实例
7. 为每个地图实例化实体（调用 EntityInstanceManager）
8. 每初始化一个地图，发送 init_one_mud_map_entities 事件
9. 所有地图初始化完成后，保存所有地图实例
10. 发送 after_gen_all_locations_finished 事件

## 实体位置管理流程
1. 实体创建时，EntityInstanceManager 发送 entity_created 事件
2. WorldMapInstanceManager 监听到事件后，调用 set_entity_position()
3. set_entity_position() 从旧位置移除实体，在新位置写入
4. 更新 _entity_by_map 和 _map_by_entity 索引表
5. 更新 map_nodes 和 map_nodes_dirty

## 地图节点排序流程
1. 渲染地图节点前，检查 map_nodes_dirty 标记
2. 如果 dirty=true，调用 sort_map_nodes()
3. sort_map_nodes() 使用冒泡排序，按 render_order 排序
4. 排序后清除 map_nodes_dirty 标记
5. 返回排序后的实体列表用于渲染

## 线程安全
- 使用全局种子确保随机数可重复生成
- 地图实例数据使用 duplicate_deep() 避免引用问题
- 实体位置索引使用互斥操作
