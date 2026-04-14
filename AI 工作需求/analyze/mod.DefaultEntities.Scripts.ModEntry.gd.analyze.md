# 基础规则

## 基础规则
- 禁止在函数内部创建函数
- 禁止使用多行注释"""，"""注释内容"""，使用#注释
- 函数注解、模块注解使用##

## 基础代码调用用例

无（自动注册实体数据）

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
DefaultEntities

## 模块路径
res://mods/DefaultEntities/Scripts/ModEntry.gd

## 模块功能
默认实体数据模块，提供游戏初始实体数据，从 JSON 文件加载并向 EntityManager 注册

## 涉及模块
- ModInterface: 基础接口
- EntityManager: 实体管理

# 成员变量

无

# 成员方法

- _on_mod_enable() -> void
   - @return void
   - 功能说明：
      - 模块启用时调用
      - 加载本地 JSON 文件
      - 主动向 EntityManager 注册实体数据包

- get_mod_path() -> String
   - @return String: 模块路径
   - 功能说明：
      - 获取当前 mod 的根目录

# 数据文件

- ModuleConfig.json: 模块配置文件
- Data/Entities.json: 实体数据文件

## 实体数据格式

```json
{
    "metadata": {
        "name": "默认实体包",
        "version": "1.0.0"
    },
    "data": {
        "entities": {
            "entity_id": {
                "entity_type": "human",
                "attributes": {
                    "description": "实体描述",
                    "roles": ["role1", "role2"]
                }
            }
        },
        "entity_types": {
            "type_id": {
                "entity_type": "type",
                "parent_entity_type": ["parent_type"]
            }
        }
    }
}
```
