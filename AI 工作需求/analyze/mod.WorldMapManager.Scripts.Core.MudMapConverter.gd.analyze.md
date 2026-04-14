# mod.WorldMapManager.Scripts.Core.MudMapConverter.gd 分析文档

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
MudMapConverter

## 模块路径
res/mods/WorldMapManager/Scripts/Core/MudMapConverter.gd

## 模块功能
MUD 地图格式转换器，负责将不同来源的地图数据转换为统一的 MUD 地图格式。主要职责包括：
1. 将 WildernessGen 生成的地形数据转换为标准格式
2. 将 TownGen 生成的城镇数据转换为标准格式
3. 统一坐标系统和节点类型
4. 生成标准化的元数据
5. 生成 entity_spawns 配置

## 输入数据结构
```json
{
  "metadata": {
    "version": "1.0.0",
    "generated_at": "2023-12-31 12:00:00",
    "config": {...}
  },
  "data": {
    "final_height_level": [[0, 1, 2, ...], ...]
  }
}
```

## 输出数据结构
```json
{
  "metadata": {
    "version": "1.0.0",
    "generated_at": "2023-12-31 12:00:00",
    "config": {...},
    "size": [256, 256]
  },
  "data": {
    "map_nodes": [
      {
        "x": 0,
        "y": 0,
        "tile": "grass",
        "height_level": 2
      }
    ],
    "entity_spawns": {...}
  }
}
```

## 模块用例

```gdscript
# 示例 1：转换 WildernessGen 地图
var wilderness_data = WildernessGen.generate_map(12345)
var converted_map = MudMapConverter.convert(wilderness_data)

# 示例 2：转换 TownGen 地图
var town_data = town_gen.run()
var converted_town = MudMapConverter.convert_town(town_data)

# 示例 3：生成 entity_spawns
var entity_spawns = MudMapConverter.generate_entity_spawns(converted_map)
```

# 成员变量

- 无（所有方法均为静态方法）

# 成员方法

- convert(raw_data:Dictionary) -> Dictionary
  - @args:
    - raw_data: 原始地图数据（WildernessGen 或 TownGen 输出）
  - @return Dictionary: 转换后的标准地图数据
  - functions:
    - 检查数据类型（wilderness 或 town）
    - 调用对应的转换函数
    - 返回标准格式的地图数据

- convert_wilderness(wilderness_data:Dictionary) -> Dictionary
  - @args:
    - wilderness_data: WildernessGen 生成的地图数据
  - @return Dictionary: 转换后的标准地图数据
  - functions:
    - 解析 height_levels 数组
    - 将高度等级映射到 tile 类型
    - 生成 map_nodes 数组
    - 生成 entity_spawns 配置
    - 构建标准格式的元数据
    - 返回完整的地图数据

- convert_town(town_data:Dictionary) -> Dictionary
  - @args:
    - town_data: TownGen 生成的城镇数据
  - @return Dictionary: 转换后的标准地图数据
  - functions:
    - 解析 town_data 的 nodes、blocks、roads 等
    - 将不同类型的节点映射到 tile 类型
    - 生成 map_nodes 数组
    - 生成 entity_spawns 配置
    - 构建标准格式的元数据
    - 返回完整的地图数据

- generate_entity_spawns(map_data:Dictionary) -> Dictionary
  - @args:
    - map_data: 标准格式的地图数据
  - @return Dictionary: entity_spawns 配置
  - functions:
    - 遍历 map_nodes
    - 根据 tile 类型分配实体生成权重
    - 生成 entity_spawns 配置
    - 返回 entity_spawns

- height_level_to_tile(height_level:int) -> String
  - @args:
    - height_level: 高度等级（0-6）
  - @return String: tile 类型名称
  - functions:
    - 根据高度等级返回对应的 tile 类型
    - 0: deep_water（深海）
    - 1: water（海洋）
    - 2: forest（森林）
    - 3: grassland（草原）
    - 4: hill（丘陵）
    - 5: mountain（山地）
    - 6: snow（积雪）

- town_node_type_to_tile(node_type:String) -> String
  - @args:
    - node_type: 城镇节点类型（mask、road、wall 等）
  - @return String: tile 类型名称
  - functions:
    - 根据城镇节点类型返回对应的 tile 类型
    - mask: ground（地面）
    - primary_road: road（道路）
    - secondary_road: path（小径）
    - wall: wall（城墙）
    - gate: gate（城门）
    - block: building（建筑）
    - center: plaza（广场）

# 数据文件

- 无直接依赖的数据文件

# 模块交互

## 调用的其他模块
- 无

## 被其他模块调用
- MudMapGenerator: convert() 转换地图格式

## 发送的事件
- 无

# 核心流程

## WildernessGen 地图转换流程
1. 接收 WildernessGen 生成的地图数据
2. 解析 metadata 和 data 部分
3. 遍历 height_levels 数组
4. 对每个高度等级调用 height_level_to_tile()
5. 生成 map_nodes 数组，包含 x、y、tile、height_level
6. 根据 tile 类型生成 entity_spawns 配置
7. 构建标准格式的元数据
8. 返回完整的地图数据

## TownGen 地图转换流程
1. 接收 TownGen 生成的城镇数据
2. 解析 metadata 和 data 部分
3. 遍历 data 中的 nodes、blocks、roads、walls 等
4. 对每个节点类型调用 town_node_type_to_tile()
5. 生成 map_nodes 数组，包含 x、y、tile、node_type
6. 根据 node_type 生成 entity_spawns 配置
7. 构建标准格式的元数据
8. 返回完整的地图数据

## 实体生成配置流程
1. 遍历 map_nodes 数组
2. 统计每种 tile 类型的数量
3. 根据 tile 类型分配实体生成权重
   - deep_water/water: 鱼类生物
   - forest: 野生动物、树木
   - grassland: 食草动物
   - hill/mountain: 矿石、岩石
   - road/path: 行人、商人
   - building: NPC、商人
4. 生成 entity_spawns 配置
   - entity_type: 实体类型
   - min_count/max_count: 生成数量范围
   - weight: 生成权重
5. 返回 entity_spawns 配置

# 架构设计

## 转换器架构
- 所有方法均为静态方法，可直接调用
- 支持多种地图类型（wilderness、town、dungeon）
- 统一的输出格式，便于后续处理
- 使用映射函数将不同类型转换为标准 tile 类型

## 数据映射
- height_level_to_tile(): 高度等级到 tile 类型的映射
- town_node_type_to_tile(): 城镇节点类型到 tile 类型的映射
- generate_entity_spawns(): tile 类型到实体生成配置的映射

## 标准化输出
- 统一的 metadata 结构（version、generated_at、config、size）
- 统一的 data 结构（map_nodes、entity_spawns）
- 统一的坐标系统（x、y 坐标）
- 统一的 tile 类型命名规范
