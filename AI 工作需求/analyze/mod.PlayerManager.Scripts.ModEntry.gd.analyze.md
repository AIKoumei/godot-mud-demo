# 基础规则

## 基础规则
- 禁止在函数内部创建函数
- 禁止使用多行注释"""，"""注释内容"""，使用#注释
- 函数注解、模块注解使用##

## 基础代码调用用例

- 调用模块方法
   ```gdscript
   result = GameCore.ModManager.call_mod("PlayerManager", "get_money")
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
PlayerManager

## 模块路径
res://mods/PlayerManager/Scripts/ModEntry.gd

## 模块功能
玩家管理模块，处理玩家的各种功能逻辑，包括实体管理、数据管理、金钱和道具管理

## 涉及模块
- ModInterface: 基础接口
- EntityManager: 实体管理
- EntityInstanceManager: 实体实例管理
- WorldMapInstanceManager: 世界地图实例管理
- SaveManager: 存档管理

# 成员变量

- _player_data: Dictionary
   - 玩家数据字典：
   ```json
   {
      "entity_instance_id": "",
      "money": 0,
      "inventory": {"item_id": "amount"},
      "stats": {
         "level": 1,
         "exp": 0,
         "max_exp": 100,
         "health": 100,
         "max_health": 100,
         "mana": 50,
         "max_mana": 50
      }
   }
   ```

# 成员方法

- _on_mod_load() -> bool
   - @return bool: 加载是否成功
   - 功能说明：
      - 模块加载时调用
      - 注册 SavePlayerData 和 LoadPlayerData 事件监听器

- _on_mod_init() -> void
   - @return void
   - 功能说明：
      - 模块初始化时调用
      - 初始化玩家数据

- _on_mod_enable() -> void
   - @return void
   - 功能说明：
      - 模块启用时调用

- _on_mod_disable() -> void
   - @return void
   - 功能说明：
      - 模块禁用时调用
      - 保存玩家数据

- _on_mod_unload() -> void
   - @return void
   - 功能说明：
      - 模块卸载时调用
      - 保存玩家数据

- _on_mod_event(_mod_name: String, event_name: String, event_data: Dictionary) -> void
   - @param _mod_name: 发送事件的模块名
   - @param event_name: 事件名称
   - @param event_data: 事件数据
   - @return void
   - 功能说明：
      - 处理模块间事件
      - 处理 SavePlayerData 和 LoadPlayerData 事件

- _init_player_data() -> void
   - @return void
   - 功能说明：
      - 初始化玩家数据为默认值

- create_player_entity(player_id: String = "player", player_cfg: Dictionary = {}) -> String
   - @param player_id: 玩家实体模板 ID
   - @param player_cfg: 玩家配置数据
   - @return String: 玩家实体实例 ID
   - 功能说明：
      - 通过 EntityInstanceManager 创建玩家实体

- init_player_entity(instance_id: String) -> void
   - @param instance_id: 玩家实体实例 ID
   - @return void
   - 功能说明：
      - 初始化玩家实体

- load_player_entity() -> void
   - @return void
   - 功能说明：
      - 加载玩家实体

- save_player_entity() -> void
   - @return void
   - 功能说明：
      - 保存玩家实体（TODO: 未实现）

- get_player_data() -> Dictionary
   - @return Dictionary: 玩家数据字典
   - 功能说明：
      - 获取玩家数据副本

- save_player_data() -> void
   - @return void
   - 功能说明：
      - 保存玩家数据到存档

- load_player_data() -> void
   - @return void
   - 功能说明：
      - 从存档加载玩家数据

- get_money() -> int
   - @return int: 金钱数量
   - 功能说明：
      - 获取玩家金钱

- set_money(amount: int) -> void
   - @param amount: 金钱数量
   - @return void
   - 功能说明：
      - 设置玩家金钱

- add_money(amount: int) -> void
   - @param amount: 金钱数量
   - @return void
   - 功能说明：
      - 增加玩家金钱

- remove_money(amount: int) -> bool
   - @param amount: 金钱数量
   - @return bool: 是否成功减少
   - 功能说明：
      - 减少玩家金钱

- get_inventory() -> Dictionary
   - @return Dictionary: 背包字典
   - 功能说明：
      - 获取玩家背包

- get_item_amount(item_id: String) -> int
   - @param item_id: 道具 ID
   - @return int: 道具数量
   - 功能说明：
      - 获取道具数量

- add_item(item_id: String, amount: int) -> void
   - @param item_id: 道具 ID
   - @param amount: 道具数量
   - @return void
   - 功能说明：
      - 添加道具

- remove_item(item_id: String, amount: int) -> bool
   - @param item_id: 道具 ID
   - @param amount: 道具数量
   - @return bool: 是否成功移除
   - 功能说明：
      - 移除道具

- consume_item(item_id: String, amount: int) -> bool
   - @param item_id: 道具 ID
   - @param amount: 道具数量
   - @return bool: 是否成功消耗
   - 功能说明：
      - 消耗道具

- get_player_stat(stat_name: String) -> int
   - @param stat_name: 属性名称
   - @return int: 属性值
   - 功能说明：
      - 获取玩家属性

- set_player_stat(stat_name: String, value: int) -> void
   - @param stat_name: 属性名称
   - @param value: 属性值
   - @return void
   - 功能说明：
      - 设置玩家属性

- add_player_stat(stat_name: String, value: int) -> void
   - @param stat_name: 属性名称
   - @param value: 增加的值
   - @return void
   - 功能说明：
      - 增加玩家属性

- get_player_entity_instance_id() -> String
   - @return String: 玩家实体实例 ID
   - 功能说明：
      - 获取玩家实体实例 ID

- get_player_entity() -> Dictionary
   - @return Dictionary: 玩家实体数据
   - 功能说明：
      - 通过 EntityInstanceManager 获取玩家实体

- has_enough_money(amount: int) -> bool
   - @param amount: 需要的金钱数量
   - @return bool: 是否有足够的金钱
   - 功能说明：
      - 检查金钱是否足够

- has_enough_item(item_id: String, amount: int) -> bool
   - @param item_id: 道具 ID
   - @param amount: 需要的道具数量
   - @return bool: 是否有足够的道具
   - 功能说明：
      - 检查道具是否足够

# 数据文件

- ModuleConfig.json: 模块配置文件
