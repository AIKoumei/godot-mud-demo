# mod.WorldMapManager.Scripts.Core.MudMapGenerator.gd 分析文档

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
MudMapGenerator

## 模块路径
res/mods/WorldMapManager/Scripts/Core/MudMapGenerator.gd

## 模块功能
MUD 地图生成器，负责生成 MUD 风格的地图模板。主要职责包括：
1. 根据 location 配置生成地图模板
2. 支持多种地图类型（wilderness、town、dungeon 等）
3. 使用 WildernessGen 生成荒野地图
4. 使用 TownGen 生成城镇地图
5. 使用 MudMapConverter 转换地图格式
6. 生成 entity_spawns 配置

## 模块依赖
- WildernessGen: 荒野地图生成
- TownGen: 城镇地图生成
- MudMapConverter: 地图格式转换
- SimplexNoise: Simplex 噪声生成

## 配置结构
```json
{
  "location_id": "file_island",
  "map_type": "wilderness",
  "seed": 12345,
  "config": {
    "width": 256,
    "height": 256,
    "noise_scale": 32
  }
}
```

## 输出数据结构
```json
{
  "metadata": {
    "version": "1.0.0",
    "generated_at": "2023-12-31 12:00:00",
    "config": {...}
  },
  "data": {
    "map_nodes": [...],
    "entity_spawns": {...}
  }
}
```

## 模块用例

```gdscript
# 示例 1：生成 MUD 地图模板
var location_config = {
    "location_id": "file_island",
    "map_type": "wilderness",
    "seed": 12345
}
var map_template = MudMapGenerator.generate_mud_map_template(location_config)

# 示例 2：生成荒野地图
var wilderness_config = {
    "seed": 12345,
    "width": 256,
    "height": 256
}
var wilderness_map = MudMapGenerator.generate_wilderness(wilderness_config)

# 示例 3：生成城镇地图
var town_config = {
    "size": "MEDIUM",
    "shape": "CIRCLE",
    "seed": 54321
}
var town_map = MudMapGenerator.generate_town(town_config)

# 示例 4：转换地图格式
var raw_map_data = {...}
var converted_map = MudMapGenerator.convert_map(raw_map_data)
```

# 成员变量

- 无（所有方法均为静态方法）

# 成员方法

- generate_mud_map_template(location_config:Dictionary) -> Dictionary
  - @args:
    - location_config: location 配置，包含 location_id、map_type、seed 等
  - @return Dictionary: 生成的 MUD 地图模板
  - functions:
    - 根据 location_config 确定地图类型
    - 调用对应的生成函数（generate_wilderness、generate_town 等）
    - 使用 MudMapConverter 转换地图格式
    - 生成 entity_spawns 配置
    - 返回完整的地图模板

- generate_wilderness(config:Dictionary) -> Dictionary
  - @args:
    - config: 荒野地图配置，包含 seed、width、height 等
  - @return Dictionary: 生成的荒野地图数据
  - functions:
    - 调用 WildernessGen.generate_map() 生成地形
    - 根据高度等级生成 map_nodes
    - 生成 entity_spawns 配置
    - 返回荒野地图数据

- generate_town(config:Dictionary) -> Dictionary
  - @args:
    - config: 城镇配置，包含 size、shape、seed 等
  - @return Dictionary: 生成的城镇地图数据
  - functions:
    - 创建 TownGen 实例
    - 调用 TownGen.run() 生成城镇
    - 解析城镇数据，生成 map_nodes
    - 生成 entity_spawns 配置
    - 返回城镇地图数据

- convert_map(raw_map_data:Dictionary) -> Dictionary
  - @args:
    - raw_map_data: 原始地图数据
  - @return Dictionary: 转换后的地图数据
  - functions:
    - 调用 MudMapConverter.convert() 转换地图格式
    - 返回转换后的地图数据

- generate_entity_spawns(map_data:Dictionary) -> Dictionary
  - @args:
    - map_data: 地图数据
  - @return Dictionary: entity_spawns 配置
  - functions:
    - 根据地图类型和地形生成 entity_spawns
    - 为不同地形分配不同的实体生成配置
    - 返回 entity_spawns 配置

# 数据文件

- 无直接依赖的数据文件
- 使用 WildernessGen、TownGen 等生成器生成地图数据

# 模块交互

## 调用的其他模块
- WildernessGen: generate_map() 生成荒野地图
- TownGen: run() 生成城镇地图
- MudMapConverter: convert() 转换地图格式
- SimplexNoise: 噪声生成

## 被其他模块调用
- WorldMapManager: generate_mud_map_template() 生成地图模板

## 发送的事件
- 无

# 核心流程

## 地图生成流程
1. WorldMapManager 调用 MudMapGenerator.generate_mud_map_template(location_config)
2. 根据 location_config 确定地图类型（wilderness、town、dungeon 等）
3. 调用对应的生成函数
   - wilderness: generate_wilderness(config)
   - town: generate_town(config)
   - dungeon: generate_dungeon(config)
4. 使用 MudMapConverter 转换地图格式为标准格式
5. 生成 entity_spawns 配置
6. 返回完整的地图模板

## 荒野地图生成流程
1. 调用 WildernessGen.generate_map(seed, width, height)
2. WildernessGen 执行完整的地形生成流程
   - 生成 Simplex 噪声图
   - 叠加噪声图生成高度图
   - 执行侵蚀算法（水流侵蚀、热侵蚀）
   - 分位数映射调整高度分布
   - 生成高度等级
3. 根据高度等级生成 map_nodes
4. 为不同高度等级分配不同的实体类型
5. 生成 entity_spawns 配置
6. 返回荒野地图数据

## 城镇地图生成流程
1. 创建 TownGen 实例，传入配置
2. 调用 TownGen.run() 执行完整的生成流程
   - 生成基础轮廓（使用 Simplex 噪声）
   - 确定城镇中心
   - 生成主干道与城门
   - 生成城墙
   - 生成区块与次级道路
3. 解析城镇数据，生成 map_nodes
4. 为不同类型的节点（road、wall、block 等）分配实体
5. 生成 entity_spawns 配置
6. 返回城镇地图数据

## 地图格式转换流程
1. 调用 MudMapConverter.convert(raw_map_data)
2. 将原始地图数据转换为标准格式
   - 统一坐标系统
   - 标准化节点类型
   - 生成元数据
3. 返回转换后的地图数据

## 实体生成配置流程
1. 根据地图类型确定实体池
2. 为不同地形/节点类型分配实体生成权重
3. 生成 entity_spawns 配置
   - 指定实体类型
   - 指定生成数量范围
   - 指定生成位置规则
4. 返回 entity_spawns 配置

# 架构设计

## 生成器架构
- 所有方法均为静态方法，可直接调用
- 支持多种地图类型（wilderness、town、dungeon）
- 使用组合模式，调用不同的生成器完成特定任务
- 统一的输出格式，便于后续处理

## 数据流
1. 输入：location_config（包含地图类型、种子、配置等）
2. 处理：调用对应的生成器生成原始地图数据
3. 转换：使用 MudMapConverter 转换为标准格式
4. 增强：生成 entity_spawns 配置
5. 输出：完整的地图模板（包含 metadata 和 data）
