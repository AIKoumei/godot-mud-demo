# 基础规则

## 基础规则
- 禁止在函数内部创建函数
- 禁止使用多行注释"""，"""注释内容"""，使用#注释
- 函数注解、模块注解使用##

## 基础代码调用用例

无（自动注册地点数据）

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
DefaultLocations

## 模块路径
res://mods/DefaultLocations/Scripts/ModEntry.gd

## 模块功能
基础地点数据模块，提供游戏初始地点数据（数码世界与现实世界），从 JSON 文件批量加载地点数据

## 涉及模块
- ModInterface: 基础接口
- LocationManager: 地点管理

# 成员变量

- _locations_data: Dictionary
   - 存储解析后的地点数据

- _relationships_data: Dictionary
   - 存储解析后的关系数据

# 成员方法

- _on_mod_load() -> bool
   - @return bool: 加载是否成功
   - 功能说明：
      - 模块加载时调用
      - 加载基础地点数据
      - 读取 Locations.json 文件

- _on_mod_enable() -> void
   - @return void
   - 功能说明：
      - 模块启用时调用
      - 注册地点数据
      - 调用 LocationManager 的批量注册函数

- get_mod_path() -> String
   - @return String: 模块路径
   - 功能说明：
      - 获取当前 mod 的根目录

# 数据文件

- ModuleConfig.json: 模块配置文件
- Data/Locations.json: 地点数据文件

## 地点数据格式

```json
{
    "name": "地点名称",
    "Kanji/Kana": {"content": "日文名称", "url": "链接"},
    "inhabitants": {"居民 1": [{"text": "居民详情", "url": "链接"}]},
    "url": "参考链接",
    "introduce": "简介",
    "description": "详细描述",
    "type": {"content": "类型", "url": "链接"},
    "location level type": "层级类型",
    "version": "1.0.0"
}
```

## 地点关系数据格式

```json
{
    "relationships": {
        "父地点 ID": ["子地点 ID1", "子地点 ID2", ...]
    }
}
```
