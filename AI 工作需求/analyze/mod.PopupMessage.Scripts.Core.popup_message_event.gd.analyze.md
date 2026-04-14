# popup_message_event.gd 分析文档

## 基础规则

- 禁止在函数内部创建函数（包括 lambda 函数、匿名函数）
- 禁止使用多行注释，使用#注释
- 函数注解、模块注解使用##

## 模块概述

**文件路径**: `res://mods/PopupMessage/Scripts/Core/popup_message_event.gd`

**模块名称**: PopupMessageEvent (弹窗消息事件)

**模块类型**: 核心事件类

**继承**: MessageEvent

**依赖模块**: 
- message_event.gd (基类)

**功能说明**: 
弹窗消息事件类，继承自 MessageEvent。这是一个简单的继承类，用于标识特定类型的消息事件。可能用于弹窗消息系统中的事件标识。

**涉及模块**:
- PopupMessage (主模块)
- MessageEvent (基类)

## 配置、输入输出数据结构

### 类定义

```gdscript
class_name PopupMessageEvent
```

### 继承关系

```
Node (Godot 基类)
  └─ MessageEvent (基类)
      └─ PopupMessageEvent (当前类)
```

## 成员变量

本文件未定义额外的成员变量，继承自 MessageEvent 基类。

## 成员方法

本文件未定义额外的成员方法，继承自 MessageEvent 基类。

## 核心流程

### 类继承流程

```
1. MessageEvent 定义基础消息事件
   ├─ message_text: 消息文本
   ├─ alive_time: 存活时间
   └─ position_type: 位置类型
   ↓
2. PopupMessageEvent 继承
   └─ 用于标识弹窗消息类型
```

## 架构设计

### 继承架构

1. **基类层**: MessageEvent 定义基础消息事件
2. **派生层**: PopupMessageEvent 标识特定类型

### 设计模式

- **标记模式**: 通过类名标识事件类型
- **继承模式**: 复用基类的属性和方法

## 使用场景

### 事件标识

```gdscript
# 创建弹窗消息事件
var event = PopupMessageEvent.new()
event.message_text = "Hello, World!"
event.alive_time = 3.0
event.position_type = PopupMessageEvent.STATIC_Position_Type.CenterCenter

# 发送事件
ModManager.emit_event("popup_message", event)
```

### 事件处理

```gdscript
# 接收事件
func _on_mod_event(mod_name: String, event_name: String, event_data: Dictionary) -> void:
    if event_name == "popup_message" and event_data is PopupMessageEvent:
        _show_popup(event_data.message_text, event_data.alive_time)
```

## TODO

- [ ] 补充完整的使用示例
- [ ] 说明与 MessageEvent 的区别
- [ ] 添加更多实际应用场景

## 备注

- 这是一个简单的继承类
- 主要用于标识事件类型
- 实际功能在基类 MessageEvent 中实现
- 总代码行数：3 行（不含空行）
- 可能需要进一步扩展功能
