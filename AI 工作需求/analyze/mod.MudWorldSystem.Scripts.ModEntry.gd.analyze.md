# 基础规则

## 基础规则
- 禁止在函数内部创建函数
- 禁止使用多行注释"""，"""注释内容"""，使用#注释
- 函数注解、模块注解使用##

## 基础代码调用用例

- 调用模块方法
   ```gdscript
   GameCore.ModManager.call_mod("MudWorldSystem", "init_mud_world")
   GameCore.ModManager.call_mod("MudWorldSystem", "enter_location", location_data)
   GameCore.ModManager.call_mod("MudWorldSystem", "request_interaction", req)
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
MudWorldSystem

## 模块路径
res://mods/MudWorldSystem/Scripts/ModEntry.gd

## 模块功能
Mud 世界系统模块，协调世界加载流、调度交互流程并维护数据同步，提供对外的业务入口

## 涉及模块
- ModInterface: 基础接口
- WorldMapInstanceManager: 世界地图实例管理
- WorldMapManager: 世界地图管理
- MudEntityInteractionSystem: 实体交互系统
- UnitManager: 单位管理
- MudUIManager: UI 管理

# 成员变量

无特殊成员变量

# 成员方法

- init_mud_world() -> void
   - @return void
   - 功能说明：
      - 初始化 Mud 世界
      - 从配置中生成地图实例
      - 调用 WorldMapInstanceManager.gen_all_locations

- enter_location(location_data: Dictionary) -> void
   - @param location_data: 位置数据
   - @return void
   - 功能说明：
      - 进入新地点
      - 获取解析后的地图数据
      - 初始化物理/逻辑房间实例
      - 生成地点内的 Entity

- _populate_location_entities(map_data: Dictionary) -> void
   - @param map_data: 地图数据
   - @return void
   - 功能说明：
      - 从房间数据中提取需要生成的 NPC 或道具
      - 示例调用工厂并注册到 UnitManager
      - TODO: 未完全实现

- request_interaction(req: Dictionary) -> void
   - @param req: 交互请求 {action_id, source_id, target_id}
   - @return void
   - 功能说明：
      - 发起交互请求
      - 通过 UnitManager 获取实体数据
      - 调用交互系统模块执行
      - 数据同步
      - 反馈交互结果给玩家

- _handle_result_output(result: Dictionary) -> void
   - @param result: 交互结果
   - @return void
   - 功能说明：
      - 处理结果输出
      - 调用 UI 模块显示文本

# 数据文件

- ModuleConfig.json: 模块配置文件

## 交互请求数据结构

```json
{
    "action_id": "String",
    "source_id": "String",
    "target_id": "String"
}
```

## 交互结果数据结构

```json
{
    "status": "success|ok|error|blocked",
    "msg": "String"
}
```
