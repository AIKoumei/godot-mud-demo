# 基础规则

## 基础规则
- 禁止在函数内部创建函数
- 禁止使用多行注释"""，"""注释内容"""，使用#注释
- 函数注解、模块注解使用##

## 基础代码调用用例

- 注册地点
   ```gdscript
   var location_data = {
       "id": "test_location",
       "name": "测试地点",
       "type": "Location"
   }
   GameCore.ModManager.call_mod("LocationManager", "register_location", location_data)
   ```

- 查询地点
   ```gdscript
   var location = GameCore.ModManager.call_mod("LocationManager", "get_location", "test_location")
   ```

## 代码注释

- 为文件适当添加注释
   - 给出配置
   - 给出输入输出的数据结构
   - 说明模块的功能
   - 给出模块的用例
   - 给出涉及模块的名称

- 在文件头给出模块的主要功能以及对应方法

- 给出功能的用例

## 模块交互

- 通过 GameCore.mod_manager.call_mod(mod_name, method_name, args) 调用其他模块的方法
- 不需要判断 Engine.has_meta(mod_name)
- 因为 GameCore.mod_manager.call_mod 已经判断了，如果模块不存在，不会调用空模块，所以不会报错。

# 模块概述

## 模块名称
LocationManager

## 模块路径
res://mods/LocationManager/Scripts/ModEntry.gd

## 模块功能
分级地点数据管理模块，维护全局地点数据库，支持地点注册、查询、关系管理等功能

## 涉及模块
- ModInterface: 基础接口
- DefaultLocations: 默认地点数据

# 成员变量

- VERSION: String
   - 版本号 "1.0.0"

- locations: Dictionary
   - 全部地点：{id: data}

- locations_by_type: Dictionary
   - 按类型分类：{type: [id, ...]}

- locations_by_level_type: Dictionary
   - 按层级类型分类：{level_type: [id, ...]}

- children_map: Dictionary
   - 父子关系：{parent_id: [child_id, ...]}

- locations_by_inhabitant: Dictionary
   - 按居民分类：{inhabitant: [id, ...]}

# 成员方法

- _on_mod_init() -> void
   - @return void
   - 功能说明：
      - 模块初始化时调用
      - 初始化类型桶

- _on_mod_enable() -> void
   - @return void
   - 功能说明：
      - 模块启用时调用
      - 加载 Locations.json 文件

- register_location(data: Dictionary) -> void
   - @param data: 地点数据
   - @return void
   - 功能说明：
      - 注册单个地点
      - 按类型、层级、居民分类

- register_locations_from_json(json_path: String) -> bool
   - @param json_path: JSON 文件路径
   - @return bool: 是否成功
   - 功能说明：
      - 从 JSON 文件批量注册地点

- regist_relationships_from_json(json_path: String) -> bool
   - @param json_path: JSON 文件路径
   - @return bool: 是否成功
   - 功能说明：
      - 从 JSON 文件注册地点关系

- regist_from_json(json_path: String) -> bool
   - @param json_path: JSON 文件路径
   - @return bool: 是否成功
   - 功能说明：
      - 注册地点配置和关系配置

- get_location(location_id: String) -> Dictionary
   - @param location_id: 地点 ID
   - @return Dictionary: 地点数据
   - 功能说明：
      - 获取地点数据

- has_location(location_id: String) -> bool
   - @param location_id: 地点 ID
   - @return bool: 是否存在
   - 功能说明：
      - 检查地点是否存在

- get_location_children(location_id: String) -> Array
   - @param location_id: 地点 ID
   - @return Array: 子地点 ID 列表
   - 功能说明：
      - 获取地点的所有子地点

- get_location_parent(location_id: String) -> String
   - @param location_id: 地点 ID
   - @return String: 父地点 ID
   - 功能说明：
      - 获取地点的父地点

- get_locations_by_type(type_name: String) -> Array
   - @param type_name: 类型名称
   - @return Array: 地点 ID 列表
   - 功能说明：
      - 按类型获取地点

- get_locations_by_level_type(level_type: String) -> Array
   - @param level_type: 层级类型
   - @return Array: 地点 ID 列表
   - 功能说明：
      - 按层级类型获取地点

- get_locations_by_inhabitant(inhabitant_name: String) -> Array
   - @param inhabitant_name: 居民名称
   - @return Array: 地点 ID 列表
   - 功能说明：
      - 按居民获取地点

- get_locations_by_level_hierarchy(level_type: String) -> Array
   - @param level_type: 层级类型
   - @return Array: 地点 ID 列表
   - 功能说明：
      - 获取层级层次中的地点

- get_all_locations() -> Array
   - @return Array: 地点 ID 列表
   - 功能说明：
      - 获取所有地点 ID

- get_all_locations_size() -> int
   - @return int: 地点数量
   - 功能说明：
      - 获取地点总数

- get_root_locations() -> Array
   - @return Array: 根地点 ID 列表
   - 功能说明：
      - 获取所有根地点

- get_locations_count() -> int
   - @return int: 地点数量
   - 功能说明：
      - 获取地点总数

- get_location_by_name(name: String) -> Array
   - @param name: 地点名称
   - @return Array: 地点 ID 列表
   - 功能说明：
      - 按名称查找地点

- remove_location(location_id: String) -> bool
   - @param location_id: 地点 ID
   - @return bool: 是否成功
   - 功能说明：
      - 删除指定地点

- update_location(location_id: String, new_data: Dictionary) -> bool
   - @param location_id: 地点 ID
   - @param new_data: 新地点数据
   - @return bool: 是否成功
   - 功能说明：
      - 更新指定地点

- add_relationship(parent_id: String, child_id: String) -> bool
   - @param parent_id: 父地点 ID
   - @param child_id: 子地点 ID
   - @return bool: 是否成功
   - 功能说明：
      - 添加父子关系

- remove_relationship(parent_id: String, child_id: String) -> bool
   - @param parent_id: 父地点 ID
   - @param child_id: 子地点 ID
   - @return bool: 是否成功
   - 功能说明：
      - 删除父子关系

- update_relationship(old_parent_id: String, child_id: String, new_parent_id: String) -> bool
   - @param old_parent_id: 旧父地点 ID
   - @param child_id: 子地点 ID
   - @param new_parent_id: 新父地点 ID
   - @return bool: 是否成功
   - 功能说明：
      - 修改子地点的父地点

- get_relationship(parent_id: String) -> Array
   - @param parent_id: 父地点 ID
   - @return Array: 子地点 ID 列表
   - 功能说明：
      - 获取父地点的所有子地点

- has_relationship(parent_id: String, child_id: String) -> bool
   - @param parent_id: 父地点 ID
   - @param child_id: 子地点 ID
   - @return bool: 是否存在关系
   - 功能说明：
      - 检查是否存在父子关系

- get_all_relationships() -> Dictionary
   - @return Dictionary: 所有关系数据
   - 功能说明：
      - 获取所有关系数据

- clear_all_locations() -> void
   - @return void
   - 功能说明：
      - 清空所有地点数据

# 数据文件

- ModuleConfig.json: 模块配置文件
- Data/Locations.json: 地点数据文件

## 地点数据结构

```json
{
    "id": "location_id",
    "name": "地点名称",
    "type": {"content": "类型", "url": "链接"},
    "location_level_type": "层级类型",
    "inhabitants": {"居民 1": [{"text": "居民详情", "url": "链接"}]},
    "url": "参考链接",
    "introduce": "简介",
    "description": "详细描述",
    "version": "1.0.0"
}
```

## 层级类型

- World: 世界层级
- Continent: 大陆层级
- Region: 区域层级
- Area: 地区层级
- Location: 地点层级
