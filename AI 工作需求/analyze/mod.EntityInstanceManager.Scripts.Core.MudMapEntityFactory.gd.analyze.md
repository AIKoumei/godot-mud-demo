# mod.EntityInstanceManager.Scripts.Core.MudMapEntityFactory.gd 分析文档

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
MudMapEntityFactory

## 模块路径
res/mods/EntityInstanceManager/Scripts/Core/MudMapEntityFactory.gd

## 模块功能
实体工厂模块，负责创建和管理实体实例。主要职责包括：
1. 生成基础实体结构
2. 创建各种类型的实体实例（玩家、NPC、物品、建筑等）
3. 批量创建实体实例
4. 管理实体实例的生命周期（获取、注册、销毁）

## 模块依赖
- EntityManager: 获取实体模板
- EntityInstanceManager: 创建和管理实体实例
- DictionaryTools: 字典合并工具
- GameCore.Settings.GameSettings.WorldSeed: 全局种子

## 实体数据结构
```json
{
  "metadata": {
    "version": "1.0",
    "generate_at": 1234567890
  },
  "data": {
    "name": "实体名称",
    "entity_type": "entity_type",
    "attributes": {
      "actions": {},
      "tags": {}
    }
  }
}
```

## 模块用例

```gdscript
# 示例 1：创建基础实体结构
var base_entity = MudMapEntityFactory.create_base_entity("测试实体", "test")

# 示例 2：创建带重写逻辑的 NPC
var special_npc = MudMapEntityFactory.create_special_npc("商人", "fast_open")

# 示例 3：创建玩家实体
var player = MudMapEntityFactory.create_player("玩家 1", {"level": 1, "hp": 100})

# 示例 4：创建 NPC 实体
var npc = MudMapEntityFactory.create_npc("村民", "human", {"level": 5, "hp": 50})

# 示例 5：创建物品实体
var item = MudMapEntityFactory.create_item("药水", "health_potion", {"effect": "heal", "value": 50})

# 示例 6：创建建筑实体
var building = MudMapEntityFactory.create_building("商店", "building_block", {"description": "道具商店"})

# 示例 7：批量创建实体
var entities_cfg = [
    {"entity_id": "human", "name": "村民 1"},
    {"entity_id": "human", "name": "村民 2"}
]
var entities = MudMapEntityFactory.create_entity_instances(entities_cfg)

# 示例 8：获取实体实例
var entity = MudMapEntityFactory.get_entity_instance("1001")

# 示例 9：获取所有实体实例
var all_entities = MudMapEntityFactory.get_all_entity_instances()

# 示例 10：销毁实体实例
MudMapEntityFactory.destroy_entity_instance("1001")

# 示例 11：注册实体实例
var entity_data = {"instance_id": "1002", "entity_id": "human", "name": "村民 3"}
MudMapEntityFactory.register_entity_instance(entity_data)
```

# 成员变量

- _rng: RandomNumberGenerator (static)
  - 随机数生成器，使用全局种子初始化

# 成员方法

- _init_rng() -> void
  - functions:
    - 初始化随机数生成器
    - 使用 GameCore.Settings.GameSettings.WorldSeed 作为种子

- create_base_entity(name:String, entity_type:String) -> Dictionary
  - @args:
    - name: 实体名称
    - entity_type: 实体类型
  - @return Dictionary: 基础实体字典结构
  - functions:
    - 初始化随机数生成器
    - 创建基础实体结构，包含 metadata 和 data
    - metadata 包含 version 和 generate_at
    - data 包含 name、entity_type、attributes
    - attributes 包含 actions 和 tags

- create_special_npc(name:String, override_action:String) -> Dictionary
  - @args:
    - name: NPC 名称
    - override_action: 重写的动作
  - @return Dictionary: 带重写逻辑的 NPC 实体
  - functions:
    - 调用 create_base_entity() 创建基础 NPC
    - 如果 override_action 不为空，设置 action_overrides
    - 返回 NPC 实体

- create_entity_instance(entity_cfg:Dictionary) -> Dictionary
  - @args:
    - entity_cfg: 包含 entity_id, map_instance_id, map_position 的配置字典
  - @return Dictionary: 创建的实体实例数据
  - functions:
    - 初始化随机数生成器
    - 检查 entity_cfg 是否包含 entity_id
    - 通过 EntityManager 获取实体模板
    - 使用 DictionaryTools.merge() 合并模板和配置
    - 返回实体实例

- create_entity(entity_cfg:Dictionary) -> Dictionary
  - @args:
    - entity_cfg: 包含 entity_id 等配置的字典
  - @return Dictionary: 实体实例的基础数据
  - functions:
    - 初始化随机数生成器
    - 检查 entity_cfg 是否包含 entity_id
    - 通过 EntityManager 获取实体模板
    - 使用 DictionaryTools.merge() 合并模板和配置
    - 返回实体实例（不包含实例 ID）

- create_player(player_name:String, player_attributes:Dictionary) -> Dictionary
  - @args:
    - player_name: 玩家名称
    - player_attributes: 玩家属性
  - @return Dictionary: 玩家实体实例
  - functions:
    - 构建玩家配置（entity_id="player", roles=["player"]）
    - 调用 create_entity_instance() 创建玩家

- create_npc(npc_name:String, npc_type:String, npc_attributes:Dictionary) -> Dictionary
  - @args:
    - npc_name: NPC 名称
    - npc_type: NPC 类型
    - npc_attributes: NPC 属性
  - @return Dictionary: NPC 实体实例
  - functions:
    - 构建 NPC 配置（entity_id=npc_type, roles=["npc", npc_type]）
    - 调用 create_entity_instance() 创建 NPC

- create_item(item_name:String, item_type:String, item_attributes:Dictionary) -> Dictionary
  - @args:
    - item_name: 物品名称
    - item_type: 物品类型
    - item_attributes: 物品属性
  - @return Dictionary: 物品实体实例
  - functions:
    - 构建物品配置（entity_id=item_type, roles=["item", item_type]）
    - 调用 create_entity_instance() 创建物品

- create_building(building_name:String, building_type:String, building_attributes:Dictionary) -> Dictionary
  - @args:
    - building_name: 建筑名称
    - building_type: 建筑类型
    - building_attributes: 建筑属性
  - @return Dictionary: 建筑实体实例
  - functions:
    - 构建建筑配置（entity_id=building_type, roles=["building", building_type]）
    - 调用 create_entity_instance() 创建建筑

- create_entity_instances(entities_cfg:Array) -> Array
  - @args:
    - entities_cfg: 实体配置数组
  - @return Array: 创建的实体实例数组
  - functions:
    - 遍历 entities_cfg
    - 对每个配置调用 create_entity_instance()
    - 收集并返回所有创建的实体

- get_entity_instance(instance_id:String) -> Dictionary
  - @args:
    - instance_id: 实体实例 ID
  - @return Dictionary: 实体实例数据
  - functions:
    - 调用 EntityInstanceManager.get_entity() 获取实体

- get_all_entity_instances() -> Array
  - @return Array: 实体实例数组
  - functions:
    - 调用 EntityInstanceManager.get_all_entities() 获取所有实体

- destroy_entity_instance(instance_id:String) -> void
  - @args:
    - instance_id: 实体实例 ID
  - functions:
    - 调用 EntityInstanceManager.delete_entity() 销毁实体

- register_entity_instance(entity_data:Dictionary) -> bool
  - @args:
    - entity_data: 实体实例数据
  - @return bool: 是否注册成功
  - functions:
    - 调用 EntityInstanceManager.register_entity_instance() 注册实体

# 数据文件

- 无直接依赖的数据文件

# 模块交互

## 调用的其他模块
- EntityManager: get_entity_template() 获取实体模板
- EntityInstanceManager: get_entity(), get_all_entities(), delete_entity(), register_entity_instance()
- DictionaryTools: merge() 合并字典
- GameCore.Settings.GameSettings.WorldSeed: 全局种子

## 被其他模块调用
- WorldMapInstanceManager: 调用 create_entity_instance() 创建地图实体
- WorldSceneManager: 调用 create_player() 创建玩家
- MudEntityInteractionSystem: 调用 create_npc(), create_item() 创建交互实体

## 发送的事件
- 无

# 核心流程

## 实体创建流程
1. 调用对应的创建方法（create_player, create_npc, create_item 等）
2. 构建实体配置（包含 entity_id, name, attributes, roles）
3. 调用 create_entity_instance() 或 create_entity()
4. 通过 EntityManager 获取实体模板
5. 使用 DictionaryTools.merge() 合并模板和配置
6. 返回实体实例

## 随机数生成器初始化流程
1. 检查_rng 是否为 null
2. 如果为 null，创建新的 RandomNumberGenerator
3. 使用 GameCore.Settings.GameSettings.WorldSeed 设置种子
4. 确保所有实体创建操作使用相同的随机种子

## 批量创建实体流程
1. 遍历实体配置数组
2. 对每个配置调用 create_entity_instance()
3. 检查创建结果是否有效
4. 收集所有有效的实体实例
5. 返回实体实例数组

# 架构设计

## 工厂模式
- 所有方法均为静态方法，可直接调用
- 提供多种实体类型的创建方法
- 统一的实体创建接口
- 支持批量创建

## 数据结构设计
- metadata: 版本和生成时间
- data: 实体核心数据（name, entity_type, attributes）
- attributes: 动作、标签、重写等
- roles: 实体角色标识（player, npc, item, building）

## 扩展性设计
- 支持 action_overrides: 动作重写
- 支持 tags: 业务标签
- 支持 actions: 动作权限
- 易于添加新的实体类型
