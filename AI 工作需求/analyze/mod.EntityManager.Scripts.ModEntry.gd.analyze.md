# mod.EntityManager.Scripts.ModEntry.gd 分析文档

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
EntityManager

## 模块路径
res/mods/EntityManager/Scripts/ModEntry.gd

## 模块功能
实体管理模块，负责管理游戏中的实体模板和实体类型。主要职责包括：
1. 注册实体模板和实体类型
2. 查询实体模板和实体类型
3. 从 JSON 文件加载实体配置
4. 构建和维护实体类型索引（父子关系、子孙关系）
5. 提供实体类型的渲染排序索引

## 模块依赖
- ModEventListenerFilter: 事件监听过滤
- DictionaryTools: 字典合并工具

## 配置文件
- res/mods/EntityManager/Data/Entities.json

## 模块用例

```gdscript
# 示例 1：注册单个实体模板
var entity_data = {
    "entity_type": "human",
    "attributes": {
        "description": "测试实体",
        "roles": ["test"]
    }
}
EntityManager.register_entity("MyMod", "test_entity", entity_data)

# 示例 2：批量注册实体
var packet = {
    "data": {
        "entities": {
            "entity1": { "entity_type": "human", "attributes": { "description": "实体 1" } },
            "entity2": { "entity_type": "item", "attributes": { "description": "实体 2" } }
        },
        "entity_types": {
            "test_type": { "entity_type": "test", "parent_entity_type": ["entity"] }
        }
    }
}
EntityManager.register_entity_packet("MyMod", packet)

# 示例 3：从 JSON 文件加载实体
var file_path = "res://mods/MyMod/Data/Entities.json"
EntityManager.regist_entities_from_json("MyMod", file_path)

# 示例 4：查询实体模板
var entity_template = EntityManager.get_entity_template("test_entity")
print(entity_template)

# 示例 5：查询实体类型
var entity_type = EntityManager.get_entity_type("human")
print(entity_type)

# 示例 6：获取指定类型的所有实体模板
var templates = EntityManager.get_entity_templates_by_type("human")

# 示例 7：判断实体类型是否属于某个大类
var is_animal = EntityManager.is_entity_type("dog", "animal")

# 示例 8：获取实体类型的渲染排序
var render_order = EntityManager.get_render_order("tree")
```

# 成员变量

- _entity_templates: Dictionary
  - 核心存储：{entity_id: blueprint_data}
  - 用于存储所有注册的实体模板

- _entity_types: Dictionary
  - 实体类型存储：{entity_type: type_data}
  - 用于存储所有注册的实体类型

- _indexer_entity_templates_by_type: Dictionary
  - 索引：按实体类型索引实体模板
  - 格式：{entity_type: [entity_template_id, ...]}

- _indexer_child_entity_types_by_parent_type: Dictionary
  - 索引：按父类型索引子实体类型
  - 格式：{parent_type: [child_type1, child_type2, ...]}
  - 包含所有子孙类型（递归）

- _indexer_parent_entity_types_by_child_type: Dictionary
  - 索引：按子类型索引父实体类型
  - 格式：{child_type: [parent_type1, parent_type2, ...]}
  - 包含所有父类型（递归）

# 成员方法

- _on_mod_enable() -> void
  - functions:
    - 加载 Entities.json 文件
    - 调用 regist_entities_from_json() 注册所有实体

- register_entity(source_mod:String, entity_id:String, blueprint:Dictionary) -> bool
  - @args:
    - source_mod: 提交者的 mod_name
    - entity_id: 实体的唯一标识符
    - blueprint: 实体的数据结构
  - @return bool: 是否注册成功
  - functions:
    - 检查实体 ID 是否已存在
    - 注入来源元数据_source_mod
    - 赋值 entity_id
    - 存储到_entity_templates
    - 更新实体模板按类型索引

- register_entity_packet(source_mod:String, packet:Dictionary) -> void
  - @args:
    - source_mod: 提交者的 mod_name
    - packet: 包含 metadata 和 data.entities 的字典
  - functions:
    - 检查数据包格式
    - 注册实体模板（遍历 data.entities）
    - 注册实体类型（遍历 data.entity_types）
    - 处理 parent_entity_type 和 child_entity_type
    - 构建完整的索引（调用_build_entity_types_indexes）

- regist_entities_from_json(source_mod:String, file_path:String) -> void
  - @args:
    - source_mod: 提交者的 mod_name
    - file_path: JSON 文件路径
  - functions:
    - 打开并读取 JSON 文件
    - 解析 JSON 内容
    - 调用 register_entity_packet() 注册实体

- get_entity_template(entity_id:String) -> Dictionary
  - @args:
    - entity_id: 实体模板 ID
  - @return Dictionary: 实体模板数据字典
  - functions:
    - 从_entity_templates 中获取实体模板

- has_template(entity_id:String) -> bool
  - @args:
    - entity_id: 实体模板 ID
  - @return bool: 是否存在该实体模板
  - functions:
    - 检查_entity_templates 中是否存在该实体模板

- get_entity_type(type_id:String) -> Dictionary
  - @args:
    - type_id: 实体类型 ID
  - @return Dictionary: 实体类型数据字典
  - functions:
    - 从_entity_types 中获取实体类型

- has_entity_type(type_id:String) -> bool
  - @args:
    - type_id: 实体类型 ID
  - @return bool: 是否存在该实体类型
  - functions:
    - 检查_entity_types 中是否存在该实体类型

- get_entity_templates_by_type(entity_type:String) -> Dictionary
  - @args:
    - entity_type: 实体类型
  - @return Dictionary: 实体模板字典
  - functions:
    - 优先查询索引
    - 如果索引不存在，查询_entity_templates 并更新索引

- is_entity_type(entity_type:String, target_type:String) -> bool
  - @args:
    - entity_type: 实体类型
    - target_type: 目标类型
  - @return bool: 是否属于该大类
  - functions:
    - 优先查询_parent_entity_types_by_child_type 索引
    - 如果索引不存在，构建索引后再查询

- is_sub_entity_type(child_type:String, parent_type:String) -> bool
  - @args:
    - child_type: 子实体类型
    - parent_type: 父实体类型
  - @return bool: 是否是子类型
  - functions:
    - 优先查询_child_entity_types_by_parent_type 索引
    - 如果索引不存在，构建索引后再查询

- get_entity_templates_with_parent_by_type(entity_type:String) -> Dictionary
  - @args:
    - entity_type: 实体类型
  - @return Dictionary: 实体模板字典（包括父类型的实体）
  - functions:
    - 获取所有父类型（包括自身）
    - 对于每个类型，获取该类型的所有实体模板
    - 合并到结果字典

- get_entity_templates_with_child_by_type(entity_type:String) -> Dictionary
  - @args:
    - entity_type: 实体类型
  - @return Dictionary: 实体模板字典（包括子类型的实体）
  - functions:
    - 获取所有子类型（包括自身）
    - 对于每个类型，获取该类型的所有实体模板
    - 合并到结果字典

- _build_all_indexes() -> void
  - functions:
    - 构建实体模板按类型索引
    - 构建实体类型索引

- _build_entity_templates_by_type_index() -> void
  - functions:
    - 遍历所有实体模板
    - 按 entity_type 分组存储到索引

- _build_entity_types_indexes() -> void
  - functions:
    - 初始化每个类型的索引，添加自身
    - 构建直接的父子关系（处理 parent_entity_type 和 child_entity_type）
    - 使用迭代方式构建完整的子孙类型索引（直到没有新的类型可以添加）
    - 使用迭代方式构建完整的父类型索引（直到没有新的类型可以添加）

- _get_all_child_entity_types(entity_type:String) -> Array
  - @args:
    - entity_type: 实体类型
  - @return Array: 所有子类型列表（包括自身）
  - functions:
    - 优先查询索引
    - 如果索引不存在，构建索引后再返回

- get_parent_entity_type_by_child_type(entity_type:String) -> Array
  - @args:
    - entity_type: 实体类型
  - @return Array: 父类型列表
  - functions:
    - 检查实体类型是否存在
    - 获取实体类型数据
    - 返回 parent_entity_type

- get_render_order(entity_type:String) -> int
  - @args:
    - entity_type: 实体类型
  - @return int: 渲染排序索引
  - functions:
    - 检查当前类型是否有 render_sort_index
    - 如果没有，递归查找父类型的 render_sort_index
    - 如果都没有找到，返回 0

- _get_all_parent_entity_types(entity_type:String) -> Array
  - @args:
    - entity_type: 实体类型
  - @return Array: 所有父类型列表（包括自身）
  - functions:
    - 优先查询索引
    - 如果索引不存在，构建索引后再返回

# 数据文件

- res/mods/EntityManager/Data/Entities.json
  - 实体配置文件
  - 包含 entities 和 entity_types 两个部分
  - 支持 parent_entity_type 和 child_entity_type 定义类型关系

# 模块交互

## 调用的其他模块
- DictionaryTools: merge() 合并字典
- ModEventListenerFilter: 事件监听过滤

## 被其他模块调用
- EntityInstanceManager: 调用 get_entity_template() 创建实体实例
- WorldMapInstanceManager: 调用 get_render_order() 对地图节点排序
- MudEntityInteractionSystem: 调用 get_entity_type() 判断实体类型

# 核心流程

## 实体注册流程
1. 模块启用时，自动加载 Entities.json 文件
2. 解析 JSON 文件，获取 entities 和 entity_types
3. 遍历 entities，调用 register_entity() 注册每个实体模板
4. 遍历 entity_types，注册每个实体类型
5. 处理 parent_entity_type 和 child_entity_type 关系
6. 构建完整的索引（包含所有子孙和父类型）

## 索引构建流程
1. 初始化每个类型的索引，添加自身
2. 遍历所有实体类型，处理 parent_entity_type 字段
3. 对于每个父类型，添加到索引中
4. 遍历所有实体类型，处理 child_entity_type 字段
5. 对于每个子类型，添加到索引中
6. 使用迭代方式构建完整的子孙类型索引（递归直到没有新的类型）
7. 使用迭代方式构建完整的父类型索引（递归直到没有新的类型）

## 渲染排序查询流程
1. 查询当前实体类型的 render_sort_index
2. 如果当前类型没有，获取父类型列表
3. 遍历父类型，递归查找 render_sort_index
4. 找到第一个非 0 的 render_sort_index 并返回
5. 如果都没有找到，返回 0

## 类型继承判断流程
1. is_entity_type(): 判断实体类型是否属于某个大类
   - 查询_parent_entity_types_by_child_type 索引
   - 检查 target_type 是否在父类型列表中
2. is_sub_entity_type(): 判断是否是子类型
   - 查询_child_entity_types_by_parent_type 索引
   - 检查 child_type 是否在子类型列表中
