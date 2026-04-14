# mod.EntityInstanceManager.Scripts.ModEntry.gd 分析文档

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
EntityInstanceManager

## 模块路径
res/mods/EntityInstanceManager/Scripts/ModEntry.gd

## 模块功能
实体实例管理模块，负责管理游戏中的实体实例。主要职责包括：
1. 创建逻辑实体实例
2. 销毁逻辑实体实例
3. 查询实体实例
4. 注册实体实例
5. 更新实体实例数据
6. 保存和加载实体实例数据

## 模块依赖
- MudMapEntityFactory: 通过工厂创建实体实例
- DictionaryTools: 字典合并工具
- SaveManager: 保存/加载实体实例数据
- ModEventListenerFilter: 事件监听过滤

## 使用全局种子
GameCore.Settings.GameSettings.WorldSeed

## 实体实例数据结构
```json
{
  "instance_id": "entity_instance_id",
  "entity_id": "entity_template_id",
  "name": "name",
  "entity_type": "entity_type",
  "map_instance_id": "map_instance_id",
  "map_position": "map_position",
  "attributes": "attributes"
}
```

## 模块用例

```gdscript
# 示例 1：创建实体实例
var entity_cfg = {
    "entity_id": "test_entity",
    "attributes": {
        "description": "测试实体",
        "roles": ["test"]
    }
}
var entity = EntityInstanceManager.create_entity(entity_cfg)

# 示例 2：销毁实体实例
EntityInstanceManager.delete_entity(entity.instance_id)

# 示例 3：查询实体实例
var entity = EntityInstanceManager.get_entity(instance_id)

# 示例 4：获取所有实体实例
var entities = EntityInstanceManager.get_all_entities()

# 示例 5：创建并放置到地图的实体实例
var map_entity_cfg = {
    "entity_id": "test_entity",
    "map_instance_id": "map_1",
    "map_position": Vector2(10, 10)
}
var map_entity = EntityInstanceManager.create_entity(map_entity_cfg)

# 示例 6：更新实体实例
var update_cfg = {
    "name": "更新后的测试实体",
    "attributes": {
        "description": "更新后的测试实体描述"
    }
}
EntityInstanceManager.update_entity(entity.instance_id, update_cfg)

# 示例 7：快捷注册实体实例
var entity_data = {
    "instance_id": "1001",
    "entity_id": "test_entity",
    "name": "测试实体",
    "entity_type": "human",
    "map_instance_id": "map_1",
    "map_position": Vector2(10, 10),
    "attributes": {}
}
EntityInstanceManager.register_entity_instance(entity_data)

# 示例 8：根据实体类型获取实体实例
var entities = EntityInstanceManager.get_entities_by_type("human")

# 示例 9：根据地图实例 ID 获取实体实例
var entities = EntityInstanceManager.get_entities_by_map("map_1")
```

# 成员变量

- _entities: Dictionary
  - 存储所有逻辑实体实例
  - 数据结构：{instance_id: EntityObject}

- _next_id: int
  - 自增 ID 种子，初始值为 1000

- _rng: RandomNumberGenerator
  - 随机数生成器，使用全局种子

# 成员方法

- _on_mod_enable() -> void
  - functions:
    - 初始化随机数生成器，使用全局种子
    - 注册事件监听器，监听 SceneManager.SaveAllMapInstanceData 事件

- create_entity(entity_cfg:Dictionary) -> Dictionary
  - @args:
    - entity_cfg: 实体配置数据，包含 entity_id、attributes_data、map_instance_id、map_position 等
  - @return Dictionary: 创建的逻辑实体数据对象
  - functions:
    - 检查 entity_cfg 是否包含 entity_id
    - 通过 MudMapEntityFactory.create_entity() 创建实体实例
    - 确保实例 ID 存在（生成或使用已有 ID）
    - 确保实体类型存在
    - 记录并维护到_entities 字典
    - 发送 entity_created 事件，通知可视化模块渲染

- delete_entity(entity_instance_id:String) -> void
  - @args:
    - entity_instance_id: 实体实例 ID
  - functions:
    - 从_entities 中移除实体
    - 发送 entity_destroyed 事件，通知可视化模块移除渲染

- get_entity(instance_id:String) -> Dictionary
  - @args:
    - instance_id: 实体实例 ID
  - @return Dictionary: 实体实例数据字典
  - functions:
    - 从_entities 中获取实体实例

- get_all_entities() -> Array
  - @return Array: 实体实例数据数组
  - functions:
    - 返回_entities 的所有值

- get_entities_by_type(entity_type:String) -> Array
  - @args:
    - entity_type: 实体类型
  - @return Array: 实体实例数据数组
  - functions:
    - 遍历_entities，筛选出指定 entity_type 的实体

- get_entities_by_map(map_instance_id:String) -> Array
  - @args:
    - map_instance_id: 地图实例 ID
  - @return Array: 实体实例数据数组
  - functions:
    - 遍历_entities，筛选出指定 map_instance_id 的实体

- register_entity_instance(entity_data:Dictionary) -> bool
  - @args:
    - entity_data: 实体实例数据
  - @return bool: 是否注册成功
  - functions:
    - 检查 entity_data 是否为空
    - 检查 instance_id 是否存在
    - 确保 entity_instance_id 和 instance_id 保持一致
    - 存储到_entities 字典

- update_entity(entity_instance_id:String, entity_cfg:Dictionary) -> Dictionary
  - @args:
    - entity_instance_id: 实体实例 ID
    - entity_cfg: 要更新的实体数据
  - @return Dictionary: 更新后的实体实例数据
  - functions:
    - 检查实体是否存在
    - 使用 DictionaryTools.merge() 合并数据
    - 确保 entity_instance_id 和 instance_id 保持一致
    - 更新到_entities 字典
    - 发送 entity_updated 事件，通知可视化模块更新渲染

- _generate_unique_id() -> String
  - @return String: 唯一 ID 字符串
  - functions:
    - 使用随机数生成器确保可重复生成
    - 自增_next_id
    - 返回唯一 ID

- _on_mod_event(_mod_name:String, event_name:String, event_data:Dictionary) -> void
  - @args:
    - _mod_name: 触发事件的模块名称
    - event_name: 事件名称
    - event_data: 事件数据
  - functions:
    - 监听 SaveAllMapInstanceData 事件
    - 调用 save_entity_instances() 保存所有实体实例

- save_entity_instances() -> void
  - functions:
    - 遍历_entities 中的所有实体实例
    - 为每个实体生成唯一的文件名
    - 使用 SaveManager 保存到存档槽位

# 数据文件

- 无直接依赖的数据文件
- 使用 SaveManager 保存/加载实体实例数据到存档槽位
- 存档文件名格式：mods/EntityInstanceManager/entity_{instance_id}.sav

# 模块交互

## 调用的其他模块
- MudMapEntityFactory: create_entity() 创建实体实例
- DictionaryTools: merge() 合并字典
- SaveManager: save_mod_slot_data(), load_mod_slot_data(), has_mod_slot_file()
- ModEventListenerFilter: 事件监听过滤

## 被其他模块调用
- WorldMapInstanceManager: 调用 create_entity(), get_entity(), update_entity_position()
- WorldSceneManager: 调用 get_entity() 获取玩家实例数据
- MudEntityInteractionSystem: 调用 create_entity(), delete_entity(), get_entity()

## 发送的事件
- entity_created: 实体创建完成
- entity_destroyed: 实体销毁完成
- entity_updated: 实体更新完成

# 核心流程

## 实体创建流程
1. 调用 create_entity(entity_cfg)
2. 检查 entity_cfg 是否包含 entity_id
3. 调用 MudMapEntityFactory.create_entity() 创建实体实例
4. 确保实例 ID 存在（生成或使用已有 ID）
5. 确保实体类型存在
6. 存储到_entities 字典
7. 发送 entity_created 事件，通知可视化模块渲染

## 实体更新流程
1. 调用 update_entity(entity_instance_id, entity_cfg)
2. 检查实体是否存在
3. 使用 DictionaryTools.merge() 合并数据
4. 确保 entity_instance_id 和 instance_id 保持一致
5. 更新到_entities 字典
6. 发送 entity_updated 事件，通知可视化模块更新渲染

## 实体销毁流程
1. 调用 delete_entity(entity_instance_id)
2. 从_entities 中移除实体
3. 发送 entity_destroyed 事件，通知可视化模块移除渲染

## 实体保存流程
1. 监听到 SaveAllMapInstanceData 事件
2. 调用 save_entity_instances()
3. 遍历_entities 中的所有实体实例
4. 为每个实体生成唯一的文件名（entity_{instance_id}.sav）
5. 使用 SaveManager 保存到存档槽位
6. 如果调试模式下已存在存档文件，则跳过保存

## 唯一 ID 生成流程
1. 使用全局种子初始化随机数生成器
2. 自增_next_id（初始值为 1000）
3. 返回唯一 ID 字符串
4. 确保可重复生成相同的 ID 序列
