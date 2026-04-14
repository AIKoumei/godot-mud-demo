# message_event.gd 分析文档

## 基础规则

- 禁止在函数内部创建函数（包括 lambda 函数、匿名函数）
- 禁止使用多行注释，使用#注释
- 函数注解、模块注解使用##

## 模块概述

**文件路径**: `res://mods/PopupMessage/Scripts/Core/message_event.gd`

**模块名称**: MessageEvent (消息事件)

**模块类型**: 核心事件基类

**继承**: Node

**依赖模块**: 
- Godot Engine Node 基类

**功能说明**: 
消息事件基类，定义所有消息事件的通用属性。用于弹窗消息系统，提供消息文本、存活时间和显示位置的配置。

**涉及模块**:
- PopupMessage (主模块)
- PopupMessageEvent (派生类)

## 配置、输入输出数据结构

### 1. 位置类型枚举

```gdscript
enum STATIC_Position_Type {
    LeftTop,      # 左上角
    LeftCenter,   # 左中
    LeftBottom,   # 左下角
    CenterTop,    # 中上
    CenterCenter, # 正中央
    CenterBottom, # 中下
    RightTop,     # 右上角
    RightCenter,  # 右中
    RightBottom   # 右下角
}
```

### 2. 消息事件数据结构

```json
{
  "message_text": "Hello, World!",  # 消息文本
  "alive_time": 2.0,                # 存活时间（秒）
  "position_type": 4                # 位置类型（STATIC_Position_Type）
}
```

## 成员变量

### 实例变量

```gdscript
@export var message_text: String = ""           # 消息文本
@export var alive_time: float = 2.0             # 存活时间（秒）
@export var position_type: STATIC_Position_Type # 显示位置
```

### 静态常量

```gdscript
enum STATIC_Position_Type {
    LeftTop,      # 0
    LeftCenter,   # 1
    LeftBottom,   # 2
    CenterTop,    # 3
    CenterCenter, # 4
    CenterBottom, # 5
    RightTop,     # 6
    RightCenter,  # 7
    RightBottom   # 8
}
```

## 成员方法

本文件未定义额外的成员方法，使用 Godot Node 基类的方法。

## 核心流程

### 消息事件创建流程

```
1. 创建 MessageEvent 实例
   ↓
2. 设置消息文本
   ↓
3. 设置存活时间
   ↓
4. 设置显示位置
   ↓
5. 发送事件
```

### 消息显示流程

```
1. 接收消息事件
   ↓
2. 解析 message_text
   ↓
3. 根据 position_type 确定显示位置
   ↓
4. 显示消息 UI
   ↓
5. 等待 alive_time 秒
   ↓
6. 隐藏/销毁消息 UI
```

## 架构设计

### 继承架构

```
Node (Godot 基类)
  └─ MessageEvent (消息事件基类)
      ├─ message_text: 消息文本
      ├─ alive_time: 存活时间
      └─ position_type: 显示位置
      ↓
      └─ PopupMessageEvent (弹窗消息事件)
```

### 数据设计

1. **消息内容**: message_text 存储要显示的文本
2. **生命周期**: alive_time 控制消息显示时长
3. **显示位置**: position_type 定义 9 个标准位置

### 位置网格

```
LeftTop(0)    CenterTop(3)    RightTop(6)
LeftCenter(1) CenterCenter(4) RightCenter(7)
LeftBottom(2) CenterBottom(5) RightBottom(8)
```

## 使用场景

### 基础消息显示

```gdscript
# 创建消息事件
var message = MessageEvent.new()
message.message_text = "任务完成！"
message.alive_time = 3.0
message.position_type = MessageEvent.STATIC_Position_Type.CenterCenter

# 发送事件
ModManager.emit_event("show_message", message)
```

### 不同位置的消息

```gdscript
# 左上角提示
var tip = MessageEvent.new()
tip.message_text = "提示：按 E 交互"
tip.alive_time = 5.0
tip.position_type = MessageEvent.STATIC_Position_Type.LeftBottom

# 中央重要消息
var important = MessageEvent.new()
important.message_text = "警告：前方危险！"
important.alive_time = 2.0
important.position_type = MessageEvent.STATIC_Position_Type.CenterCenter
```

### 继承使用

```gdscript
# 使用派生类
var popup = PopupMessageEvent.new()
popup.message_text = "弹窗消息"
popup.alive_time = 3.0
popup.position_type = PopupMessageEvent.STATIC_Position_Type.RightTop

# 类型判断
if event is PopupMessageEvent:
    _show_popup(event)
elif event is MessageEvent:
    _show_message(event)
```

## TODO

- [ ] 补充消息 UI 显示的实现细节
- [ ] 说明消息队列管理逻辑
- [ ] 添加消息动画效果的说明
- [ ] 说明消息优先级处理

## 备注

- 这是弹窗消息系统的基类
- 定义了消息的基本属性
- 支持 9 个标准显示位置
- 可控制消息显示时长
- 通过继承扩展不同类型的消息
- 总代码行数：21 行
- 使用@export 变量便于在编辑器中配置
