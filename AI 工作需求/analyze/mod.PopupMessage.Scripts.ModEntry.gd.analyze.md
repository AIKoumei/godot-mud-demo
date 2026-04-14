# 基础规则

## 基础规则
- 禁止在函数内部创建函数
- 禁止使用多行注释"""，"""注释内容"""，使用#注释
- 函数注解、模块注解使用##

## 基础代码调用用例

- 显示弹窗消息
   ```gdscript
   GameCore.ModManager.call_mod("PopupMessage", "PopupMessage", "消息内容")
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
PopupMessage

## 模块路径
res://mods/PopupMessage/Scripts/ModEntry.gd

## 模块功能
弹窗消息模块，提供统一的弹窗消息接口，支持多种弹窗位置和样式，消息分层管理

## 涉及模块
- ModInterface: 基础接口
- CanvasUILayer: UI 层管理
- PopupMessageEvent: 弹窗消息事件

# 成员变量

- MessageLayer: Dictionary
   - 消息层字典，包含 9 个位置层：
      - LeftTopLayer
      - LeftCenterLayer
      - LeftBottomLayer
      - CenterTopLayer
      - CenterCenterLayer
      - CenterBottomLayer
      - RightTopLayer
      - RightCenterLayer
      - RightBottomLayer

- STATIC_Popup_MSG_Position_To_Layer_Name: Dictionary
   - 弹窗位置到层名称的映射

# 成员方法

- _on_mod_init() -> void
   - @return void
   - 功能说明：
      - 模块初始化时调用

- _on_mod_enable() -> void
   - @return void
   - 功能说明：
      - 模块启用时调用

- _on_mod_disable() -> void
   - @return void
   - 功能说明：
      - 模块禁用时调用
      - 清理 UI、暂停逻辑等

- _on_mod_unload() -> void
   - @return void
   - 功能说明：
      - 模块卸载时调用
      - 清理资源、断开信号、保存数据等

- _on_mod_load() -> bool
   - @return bool: 加载是否成功
   - 功能说明：
      - 模块加载时调用

- _on_mod_event(_mod_name: String, event_name: String, event_data: Dictionary) -> void
   - @param _mod_name: 发送事件的模块名
   - @param event_name: 事件名称
   - @param event_data: 事件数据
   - @return void
   - 功能说明：
      - 处理模块间通信

- init_message_layer() -> void
   - @return void
   - 功能说明：
      - 初始化消息层
      - 获取 9 个位置的 UI 层节点

- _HandlePopupMessageEvent(event: PopupMessageEvent) -> void
   - @param event: 弹窗消息事件
   - @return void
   - 功能说明：
      - 处理弹窗消息事件
      - TODO: 未完全实现

- PopupMessage(message_text: String) -> void
   - @param message_text: 消息文本
   - @return void
   - 功能说明：
      - 显示弹窗消息
      - TODO: 未完全实现

# 数据文件

- ModuleConfig.json: 模块配置文件

## 弹窗位置类型

```json
{
    "LeftTop": 0,
    "LeftCenter": 1,
    "LeftBottom": 2,
    "CenterTop": 3,
    "CenterCenter": 4,
    "CenterBottom": 5,
    "RightTop": 6,
    "RightCenter": 7,
    "RightBottom": 8
}
```

## 消息层结构

```
MainScene
└── UILayer
    └── MessageLayer
        ├── LeftTopLayer
        ├── LeftCenterLayer
        ├── LeftBottomLayer
        ├── CenterTopLayer
        ├── CenterCenterLayer
        ├── CenterBottomLayer
        ├── RightTopLayer
        ├── RightCenterLayer
        └── RightBottomLayer
```
