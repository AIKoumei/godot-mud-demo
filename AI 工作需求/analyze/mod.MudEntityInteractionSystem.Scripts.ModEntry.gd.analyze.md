# 基础规则

## 基础规则
- 禁止在函数内部创建函数
- 禁止使用多行注释"""，"""注释内容"""，使用#注释
- 函数注解、模块注解使用##

## 基础代码调用用例

- 执行动作
   ```gdscript
   var result = GameCore.ModManager.call_mod("MudEntityInteractionSystem", "execute", {
       "action_id": "stealth_move",
       "source": source_entity,
       "target": target_entity
   })
   ```

- 获取可用动作
   ```gdscript
   var actions = GameCore.ModManager.call_mod("MudEntityInteractionSystem", "get_available_actions", {
       "source": source_entity,
       "target": target_entity
   })
   ```

- 挂载动作组
   ```gdscript
   GameCore.ModManager.call_mod("MudEntityInteractionSystem", "mount_group", {
       "entity": entity,
       "group_id": "thief_set"
   })
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
MudEntityInteractionSystem

## 模块路径
res://mods/MudEntityInteractionSystem/Scripts/ModEntry.gd

## 模块功能
基于 Dictionary 实体的动作权限管理与执行引擎，支持 Action Overriding 和 Middleware Pipeline

## 涉及模块
- ModInterface: 基础接口
- MudEntityAction: 动作基类

# 成员变量

- _registered_actions: Dictionary
   - 已注册的动作：{action_id: MudEntityAction}

- _action_groups: Dictionary
   - 动作组：{group_id: [action_id, ...]}

- _middlewares: Array
   - 中间件数组：[Callable]

# 成员方法

- call_mod(func_name: String, data: Dictionary) -> Variant
   - @param func_name: 功能名称
   - @param data: 数据字典
   - @return Variant: 返回值
   - 功能说明：
      - 模块通信入口
      - 支持 execute, get_available_actions, add_middleware
      - 支持 register_mod_actions, mount_action, unmount_action
      - 支持 mount_group, unmount_group

- execute_action(action_id: String, source: Dictionary, target: Dictionary) -> Dictionary
   - @param action_id: 动作 ID
   - @param source: 源实体
   - @param target: 目标实体
   - @return Dictionary: 执行结果
   - 功能说明：
      - 执行一个动作
      - 处理 Action Overriding
      - 查找动作实现
      - 进入管道并执行

- get_available_actions(source: Dictionary, target: Dictionary) -> Array
   - @param source: 源实体
   - @param target: 目标实体
   - @return Array: 可用动作列表
   - 功能说明：
      - 获取实体当前对目标可用的动作列表
      - 检查权限和注册状态
      - 调用 can_perform 检查

- _run_pipeline(action: MudEntityAction, source: Dictionary, target: Dictionary) -> Dictionary
   - @param action: 动作实例
   - @param source: 源实体
   - @param target: 目标实体
   - @return Dictionary: 执行结果
   - 功能说明：
      - 执行中间件管道
      - 遍历所有中间件
      - 如果中间件返回 false 则拦截

- _get_attr(entity: Dictionary, key: String, default = null) -> Variant
   - @param entity: 实体
   - @param key: 属性键
   - @param default: 默认值
   - @return Variant: 属性值
   - 功能说明：
      - 安全获取实体属性

- mount_action(entity: Dictionary, action_id: String) -> bool
   - @param entity: 实体
   - @param action_id: 动作 ID
   - @return bool: 是否成功
   - 功能说明：
      - 挂载单个动作权限
      - 确保嵌套字典结构路径存在

- unmount_action(entity: Dictionary, action_id: String) -> bool
   - @param entity: 实体
   - @param action_id: 动作 ID
   - @return bool: 是否成功
   - 功能说明：
      - 卸载单个动作权限

- mount_action_group(entity: Dictionary, group_id: String) -> void
   - @param entity: 实体
   - @param group_id: 动作组 ID
   - @return void
   - 功能说明：
      - 批量挂载动作权限

- unmount_action_group(entity: Dictionary, group_id: String) -> void
   - @param entity: 实体
   - @param group_id: 动作组 ID
   - @return void
   - 功能说明：
      - 批量卸载动作权限

- scan_and_register_mod(dir_path: String, mod_id: String) -> bool
   - @param dir_path: 目录路径
   - @param mod_id: 模块 ID
   - @return bool: 是否成功
   - 功能说明：
      - 扫描目录并根据 config.json 注册动作
      - 注册 Actions 和 Groups

- _load_action_resource(aid: String, info: Dictionary, dir_path: String) -> void
   - @param aid: 动作 ID
   - @param info: 动作信息
   - @param dir_path: 目录路径
   - @return void
   - 功能说明：
      - 加载脚本资源并实例化
      - 设置 action_id 和 action_label
      - 存储 Overriding 元数据

# 数据文件

- ModuleConfig.json: 模块配置文件
- config.json: 动作资源配置

## config.json 结构

```json
{
    "metadata": {
        "name": "潜行包",
        "version": "1.0.0"
    },
    "data": {
        "actions": {
            "stealth_move": {
                "script_path": "stealth_move.gd",
                "name": "潜行",
                "action_overrides": "open"
            }
        },
        "action_groups": {
            "thief_set": {
                "stealth_move": true,
                "fast_open": true
            }
        }
    }
}
```

## 实体数据结构

```json
{
    "data": {
        "attributes": {
            "actions": {
                "action_id": true
            },
            "action_overrides": {
                "original_action": "override_action"
            }
        }
    }
}
```
