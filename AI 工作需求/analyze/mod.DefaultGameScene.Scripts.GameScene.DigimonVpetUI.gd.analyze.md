# DigimonVpetUI.gd 分析文档

## 基础规则

- 禁止在函数内部创建函数（包括 lambda 函数、匿名函数）
- 禁止使用多行注释，使用#注释
- 函数注解、模块注解使用##

## 模块概述

**文件路径**: `res://mods/DefaultGameScene/Scripts/GameScene/DigimonVpetUI.gd`

**模块名称**: DigimonVpetUI (数码兽虚拟宠物 UI)

**模块类型**: 游戏场景 UI 组件

**继承**: Control

**依赖模块**: 
- GameCore (游戏核心)
- ModManager (模块管理器)

**功能说明**: 
数码兽虚拟宠物 UI 控制器，负责管理游戏中的数码兽显示界面。作为 Control 节点，用于在 UI 中展示数码兽的虚拟宠物形象。

**涉及模块**:
- DefaultGameScene (主模块)
- GameCore (游戏核心)

## 配置、输入输出数据结构

### 1. 节点结构

```
DigimonVpetUI (Control)
  ├─ MarginRoot (MarginContainer)
  │   └─ VBoxRoot (VBoxContainer)
  │       └─ MainRow (HBoxContainer)
  │           └─ FieldPanel (Panel)
  │               └─ FieldMargin (MarginContainer)
  │                   └─ FieldView (Control)
  │                       └─ SubViewportContainer
  │                           └─ SubViewport
```

### 2. 输入数据结构

_ui_scene_event 事件数据：
```json
{
  "event_name": "after_scene_ready.DigimonVpetUI",
  "event_data": {}  # 无特殊数据
}
```

### 3. 输出数据结构

get_game_scene_subviewport() 返回值：
```
SubViewport 节点引用
```

## 成员变量

本文件未定义额外的成员变量，使用 Godot Control 基类的属性。

## 成员方法

### 实例方法

#### _ready() -> void

节点进入场景树时调用。

**功能**:
- 发送 UI 场景准备就绪事件
- 通知其他模块 DigimonVpetUI 已加载

**示例**:
```gdscript
func _ready() -> void:
    GameCore.mod_manager.emit_ui_scene_event("after_scene_ready.DigimonVpetUI")
```

#### _process(delta: float) -> void

每帧处理（当前为空实现）。

**参数**:
- `delta`: 距离上一帧的时间

**功能**: 预留的帧更新逻辑

#### get_game_scene_subviewport() -> SubViewport

获取游戏场景的子视口。

**返回值**: SubViewport 节点引用

**功能**: 用于在其他 UI 中嵌入游戏场景的渲染

**示例**:
```gdscript
var viewport = get_game_scene_subviewport()
# 可用于在其他地方显示游戏场景
```

#### _on_mod_event(_mod_name: String, event_name: String, event_data: Dictionary) -> void

接收模块事件。

**参数**:
- `_mod_name`: 发送事件的模块名称
- `event_name`: 事件名称
- `event_data`: 事件数据字典

**功能**:
- 打印接收到的事件信息
- 预留的事件处理逻辑

**示例**:
```gdscript
func _on_mod_event(_mod_name: String, event_name: String, event_data: Dictionary) -> void:
    prints("[DigimonVpetUI] 收到事件：", _mod_name, event_name)
```

#### _on_sub_viewport_container_gui_input(event: InputEvent) -> void

处理子视口容器的 GUI 输入事件。

**参数**:
- `event`: 输入事件对象

**功能**:
- 捕获 SubViewportContainer 的输入事件
- 打印输入事件信息
- 预留的输入处理逻辑

**示例**:
```gdscript
func _on_sub_viewport_container_gui_input(event: InputEvent) -> void:
    prints("_on_sub_viewport_container_gui_input", event)
```

## 核心流程

### UI 初始化流程

```
1. 场景加载
   ↓
2. _ready() 调用
   ↓
3. 发送事件 "after_scene_ready.DigimonVpetUI"
   ↓
4. 其他模块接收事件
   ↓
5. UI 准备就绪
```

### 事件监听流程

```
1. 其他模块发送事件
   ↓
2. _on_mod_event() 接收
   ↓
3. 打印事件信息
   ↓
4. 预留处理逻辑
```

### 输入处理流程

```
1. 用户在 SubViewportContainer 上操作
   ↓
2. _on_sub_viewport_container_gui_input() 捕获
   ↓
3. 打印输入事件
   ↓
4. 预留处理逻辑
```

## 架构设计

### UI 分层架构

1. **根节点层**: Control (DigimonVpetUI)
2. **布局层**: MarginContainer + VBoxContainer + HBoxContainer
3. **面板层**: Panel (FieldPanel)
4. **视图层**: SubViewport + SubViewportContainer

### 事件驱动设计

- 使用 `GameCore.mod_manager.emit_ui_scene_event()` 发送 UI 场景事件
- 使用 `_on_mod_event()` 接收模块间事件
- 支持输入事件捕获和处理

### 子视口设计

```
SubViewportContainer
  └─ SubViewport
      └─ [游戏场景内容]
```

- SubViewport 用于渲染游戏场景
- 可以在 UI 中嵌入 3D/2D 场景
- 支持在其他地方引用这个视口

## 使用场景

### 数码兽 UI 显示

```gdscript
# 在场景中自动加载
# DigimonVpetUI.tscn 被实例化到游戏场景中
# _ready() 自动发送准备就绪事件
```

### 获取游戏场景视口

```gdscript
# 在其他 UI 中引用游戏场景
var ui_node = get_node("DigimonVpetUI")
var viewport = ui_node.get_game_scene_subviewport()

# 可以将 viewport 添加到其他 UI 容器中
```

### 事件监听

```gdscript
# 在其他模块中监听 DigimonVpetUI 准备就绪
func _on_mod_event(mod_name: String, event_name: String, event_data: Dictionary) -> void:
    if event_name == "after_scene_ready.DigimonVpetUI":
        # DigimonVpetUI 已准备就绪
        _setup_digimon_ui()
```

## TODO

- [ ] 补充数码兽显示的具体实现
- [ ] 说明 SubViewport 的用途和渲染内容
- [ ] 添加数码兽动画播放逻辑
- [ ] 说明 UI 与其他系统的交互方式

## 备注

- 这是一个 UI 控制器脚本
- 当前实现较为基础，主要是框架性代码
- 预留了事件处理和输入处理的接口
- 使用 SubViewport 嵌入游戏场景
- 总代码行数：23 行
- 需要进一步扩展数码兽显示功能
