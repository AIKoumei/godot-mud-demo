# 基础规则

## 基础规则
- 禁止在函数内部创建函数
- 禁止使用多行注释"""，"""注释内容"""，使用#注释
- 函数注解、模块注解使用##

## 基础代码调用用例

- 调用模块方法
   ```gdscript
   result = GameCore.ModManager.call_mod("PlayerDataManager", "get_money")
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
PlayerDataManager

## 模块路径
res://mods/PlayerDataManager/Scripts/ModEntry.gd

## 模块功能
玩家元数据管理模块，负责管理玩家的"元数据（Meta-Data）"，不包含玩家角色本体数据

## 涉及模块
- ModInterface: 基础接口
- SaveManager: 存档管理
- EntityInstanceManager: 实体实例管理

# 成员变量

- player_data: Dictionary
   - 玩家数据字典，包含：
   ```json
   {
      "name": "Player",
      "money": 100,
      "inventory": [],
      "quests": {},
      "settings": {},
      "location_id": "file_island_village",
      "position": {"x": 0, "y": 0},
      "start_map": "file_island_village",
      "start_spawn_point": {"x": 0, "y": 0},
      "team": ["player_hero#0001"]
   }
   ```

# 成员方法

- _on_mod_load() -> bool
   - @return bool: 加载是否成功
   - 功能说明：
      - 模块加载时调用
      - 打印加载信息

- create_default_player() -> void
   - @return void
   - 功能说明：
      - 创建默认玩家数据
      - 初始化所有字段为默认值

- create_default_team() -> Array
   - @return Array: 默认队伍 ID 数组
   - 功能说明：
      - 创建默认队伍模板 ID 列表

- set_player_team(team_instance_ids: Array) -> void
   - @param team_instance_ids: 队伍实例 ID 数组
   - @return void
   - 功能说明：
      - 设置玩家队伍

- get_player_team() -> Array
   - @return Array: 队伍实例 ID 数组
   - 功能说明：
      - 获取玩家队伍

- set_location(location_id: String) -> void
   - @param location_id: 位置 ID
   - @return void
   - 功能说明：
      - 设置玩家当前位置

- get_location() -> String
   - @return String: 位置 ID
   - 功能说明：
      - 获取玩家当前位置

- set_position(x: float, y: float) -> void
   - @param x: X 坐标
   - @param y: Y 坐标
   - @return void
   - 功能说明：
      - 设置玩家位置

- get_position() -> Dictionary
   - @return Dictionary: 位置字典 {"x": x, "y": y}
   - 功能说明：
      - 获取玩家位置

- get_start_map() -> String
   - @return String: 出生地图 ID
   - 功能说明：
      - 获取玩家出生地图

- get_start_spawn_point() -> Dictionary
   - @return Dictionary: 出生点坐标
   - 功能说明：
      - 获取玩家出生点

- add_money(amount: int) -> void
   - @param amount: 金额
   - @return void
   - 功能说明：
      - 增加金钱

- get_money() -> int
   - @return int: 金钱数量
   - 功能说明：
      - 获取金钱数量

- add_item(item_id: String) -> void
   - @param item_id: 物品 ID
   - @return void
   - 功能说明：
      - 添加物品到背包

- get_inventory() -> Array
   - @return Array: 背包物品数组
   - 功能说明：
      - 获取背包物品列表

- set_quest_state(quest_id: String, state: String) -> void
   - @param quest_id: 任务 ID
   - @param state: 任务状态
   - @return void
   - 功能说明：
      - 设置任务状态

- get_quest_state(quest_id: String) -> String
   - @param quest_id: 任务 ID
   - @return String: 任务状态
   - 功能说明：
      - 获取任务状态

# 数据文件

- ModuleConfig.json: 模块配置文件
