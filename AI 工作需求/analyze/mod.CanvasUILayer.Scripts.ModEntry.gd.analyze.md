# CanvasUILayer.ModEntry.gd 分析文档

## 基础规则

- 禁止在函数内部创建函数（包括 lambda 函数、匿名函数）
- 禁止使用多行注释，使用#注释
- 函数注解、模块注解使用##

## 模块概述

**文件路径**: `res://mods/CanvasUILayer/Scripts/ModEntry.gd`

**模块名称**: CanvasUILayer (画布 UI 层)

**模块类型**: 功能模块

**继承**: ModInterface

**依赖模块**: 
- ModInterface (基础接口)
- GameCore (游戏核心)

**功能说明**: 
提供全局 CanvasLayer 节点管理，实现 UI 元素的分层管理。支持四层 UI 布局（Bottom/Middle/Top/Tips），并提供 UI 场景挂载接口和场景过渡功能。

**涉及模块**:
- CanvasUILayer (主模块)
- ModManager (模块管理器)
- GameCore (游戏核心)

## 配置、输入输出数据结构

### 1. 场景路径配置

```gdscript
var scene_path_CanvasUILayer: String = "res://res/mods/CanvasUILayer/Scenes/UIScenes/CanvasUILayer.tscn"
```

### 2. UI 层级结构

```
CanvasUILayer (CanvasLayer)
  ├─ BottomWindowLayer (Control)   # 底层 UI
  ├─ MiddleWindowLayer (Control)   # 中层 UI
  ├─ TopWindowLayer (Control)      # 顶层 UI
  └─ TipsWindowLayer (Control)     # 提示 UI
  └─ FadeRect (Control)            # 渐层遮罩（场景过渡）
```

### 3. 输入数据结构

#### add_ui_to_bottom_layer(ui_scene: Node)
- `ui_scene`: 要添加的 UI 场景节点

#### add_ui_to_middle_layer(ui_scene: Node)
- `ui_scene`: 要添加的 UI 场景节点

#### add_ui_to_top_layer(ui_scene: Node)
- `ui_scene`: 要添加的 UI 场景节点

#### add_ui_to_tips_layer(ui_scene: Node)
- `ui_scene`: 要添加的 UI 场景节点

### 4. 输出数据结构

#### get_ui_layer_bottom_window_layer() -> Control
- 返回：BottomWindowLayer 节点引用

#### get_ui_layer_middle_window_layer() -> Control
- 返回：MiddleWindowLayer 节点引用

#### get_ui_layer_top_window_layer() -> Control
- 返回：TopWindowLayer 节点引用

#### get_ui_layer_tips_window_layer() -> Control
- 返回：TipsWindowLayer 节点引用

#### get_fade_rect() -> Control
- 返回：FadeRect 节点引用

## 成员变量

### 实例变量

```gdscript
var scene_path_CanvasUILayer: String          # CanvasUILayer 场景路径
@export var CanvasUILayer: CanvasLayer         # 画布层根节点
@export var BottomWindowLayer: Control         # 底层 UI 容器
@export var MiddleWindowLayer: Control         # 中层 UI 容器
@export var TopWindowLayer: Control            # 顶层 UI 容器
@export var TipsWindowLayer: Control           # 提示 UI 容器
@export var FadeRect: Control                  # 渐层遮罩
```

## 成员方法

### 生命周期方法

#### _on_mod_load() -> bool

模块加载时调用。

**返回值**: 是否加载成功

**功能**:
1. 检查场景资源是否存在
2. 加载 CanvasUILayer 场景
3. 实例化场景并赋值给变量
4. 验证实例类型是否为 CanvasLayer

**示例**:
```gdscript
func _on_mod_load() -> bool:
    var is_load_succeed: bool = super._on_mod_load()
    
    if not ResourceLoader.exists(scene_path_CanvasUILayer):
        push_warning("[%s] scene resource not found: %s" % [mod_name, scene_path_CanvasUILayer])
        return false
    
    var scene_res: PackedScene = load(scene_path_CanvasUILayer)
    var instance: Node = scene_res.instantiate()
    
    if instance is CanvasLayer:
        CanvasUILayer = instance as CanvasLayer
    else:
        push_error("[%s] Loaded scene is not a CanvasLayer: %s" % [mod_name, scene_path_CanvasUILayer])
        return false
    
    return is_load_succeed
```

#### _on_mod_init() -> void

模块初始化时调用。

**功能**:
- 将 CanvasUILayer 添加到场景树
- 初始化各层 UI 容器

#### _on_mod_enable() -> void

模块启用时调用。

**功能**:
- 显示 CanvasUILayer
- 启用各层 UI 容器

### UI 层获取方法

#### get_ui_layer_bottom_window_layer() -> Control

获取底层 UI 容器。

**返回值**: BottomWindowLayer 节点引用

**用途**: 添加底层 UI 元素（如背景、装饰等）

#### get_ui_layer_middle_window_layer() -> Control

获取中层 UI 容器。

**返回值**: MiddleWindowLayer 节点引用

**用途**: 添加中层 UI 元素（如对话框、菜单等）

#### get_ui_layer_top_window_layer() -> Control

获取顶层 UI 容器。

**返回值**: TopWindowLayer 节点引用

**用途**: 添加顶层 UI 元素（如弹窗、警告等）

#### get_ui_layer_tips_window_layer() -> Control

获取提示 UI 容器。

**返回值**: TipsWindowLayer 节点引用

**用途**: 添加提示 UI 元素（如提示信息、教程等）

#### get_fade_rect() -> Control

获取渐层遮罩。

**返回值**: FadeRect 节点引用

**用途**: 场景过渡、淡入淡出效果

### UI 添加方法

#### add_ui_to_bottom_layer(ui_scene: Node) -> void

添加 UI 场景到底层。

**参数**:
- `ui_scene`: 要添加的 UI 场景节点

**功能**:
1. 将 ui_scene 添加为 BottomWindowLayer 的子节点
2. 自动管理 UI 的生命周期

**示例**:
```gdscript
var my_ui = load("res://mods/MyMod/Scenes/MyUI.tscn").instantiate()
CanvasUILayer.add_ui_to_bottom_layer(my_ui)
```

#### add_ui_to_middle_layer(ui_scene: Node) -> void

添加 UI 场景到中层。

**参数**:
- `ui_scene`: 要添加的 UI 场景节点

**功能**:
1. 将 ui_scene 添加为 MiddleWindowLayer 的子节点

**示例**:
```gdscript
var dialog = load("res://mods/MyMod/Scenes/Dialog.tscn").instantiate()
CanvasUILayer.add_ui_to_middle_layer(dialog)
```

#### add_ui_to_top_layer(ui_scene: Node) -> void

添加 UI 场景到顶层。

**参数**:
- `ui_scene`: 要添加的 UI 场景节点

**功能**:
1. 将 ui_scene 添加为 TopWindowLayer 的子节点

**示例**:
```gdscript
var popup = load("res://mods/MyMod/Scenes/Popup.tscn").instantiate()
CanvasUILayer.add_ui_to_top_layer(popup)
```

#### add_ui_to_tips_layer(ui_scene: Node) -> void

添加 UI 场景到提示层。

**参数**:
- `ui_scene`: 要添加的 UI 场景节点

**功能**:
1. 将 ui_scene 添加为 TipsWindowLayer 的子节点

**示例**:
```gdscript
var tip = load("res://mods/MyMod/Scenes/Tip.tscn").instantiate()
CanvasUILayer.add_ui_to_tips_layer(tip)
```

## 核心流程

### 模块加载流程

```
1. ModManager.load_mod("CanvasUILayer")
   ↓
2. _on_mod_load()
   ├─ 检查场景资源
   ├─ 加载场景
   ├─ 实例化节点
   └─ 验证类型
   ↓
3. _on_mod_init()
   ├─ 添加到场景树
   └─ 初始化容器
   ↓
4. _on_mod_enable()
   ├─ 显示 CanvasLayer
   └─ 启用容器
```

### UI 添加流程

```
1. 其他模块调用
   ↓
2. add_ui_to_xxx_layer(ui_scene)
   ↓
3. 将 ui_scene 添加到对应容器
   ↓
4. UI 自动显示和管理
```

### 场景过渡流程

```
1. 获取 FadeRect
   ↓
2. 设置 FadeRect 的透明度动画
   ↓
3. 淡出当前场景
   ↓
4. 切换场景
   ↓
5. 淡入新场景
```

## 架构设计

### 分层架构

1. **CanvasLayer 层**: 最顶层，确保 UI 在所有 3D/2D 场景之上
2. **容器层**: 4 个 Control 容器，分别管理不同层级的 UI
3. **功能层**: 提供统一的 UI 添加接口

### UI 层级设计

```
CanvasLayer (最高层级)
  │
  ├─ BottomWindowLayer   (layer = 0)
  │   └─ 背景、装饰等
  │
  ├─ MiddleWindowLayer   (layer = 1)
  │   └─ 对话框、菜单等
  │
  ├─ TopWindowLayer      (layer = 2)
  │   └─ 弹窗、警告等
  │
  ├─ TipsWindowLayer     (layer = 3)
  │   └─ 提示信息、教程等
  │
  └─ FadeRect           (layer = 4)
      └─ 渐层遮罩、过渡效果
```

### 模块化设计

- 通过 ModManager 统一管理
- 其他模块通过 call_mod() 调用
- 支持动态添加/移除 UI

## 使用场景

### 添加 UI 到不同层级

```gdscript
# 底层 UI（背景）
var bg = load("res://mods/MyMod/Scenes/Background.tscn").instantiate()
GameCore.mod_manager.call_mod("CanvasUILayer", "add_ui_to_bottom_layer", bg)

# 中层 UI（对话框）
var dialog = load("res://mods/MyMod/Scenes/Dialog.tscn").instantiate()
GameCore.mod_manager.call_mod("CanvasUILayer", "add_ui_to_middle_layer", dialog)

# 顶层 UI（弹窗）
var popup = load("res://mods/MyMod/Scenes/Popup.tscn").instantiate()
GameCore.mod_manager.call_mod("CanvasUILayer", "add_ui_to_top_layer", popup)

# 提示 UI（教程）
var tip = load("res://mods/MyMod/Scenes/Tutorial.tscn").instantiate()
GameCore.mod_manager.call_mod("CanvasUILayer", "add_ui_to_tips_layer", tip)
```

### 获取 UI 容器

```gdscript
# 获取顶层容器
var top_layer = GameCore.mod_manager.call_mod("CanvasUILayer", "get_ui_layer_top_window_layer")

# 手动添加 UI
var my_ui = load("res://mods/MyMod/Scenes/MyUI.tscn").instantiate()
top_layer.add_child(my_ui)
```

### 场景过渡

```gdscript
# 获取 FadeRect
var fade_rect = GameCore.mod_manager.call_mod("CanvasUILayer", "get_fade_rect")

# 执行淡出动画
var tween = create_tween()
tween.tween_property(fade_rect, "modulate:a", 1.0, 0.5)

# 切换场景
await get_tree().create_timer(0.5).timeout
SceneManager.change_scene("res://scenes/NewScene.tscn")

# 执行淡入动画
tween = create_tween()
tween.tween_property(fade_rect, "modulate:a", 0.0, 0.5)
```

## TODO

- [ ] 补充 FadeRect 的具体实现细节
- [ ] 说明 UI 层的层级设置（layer 属性）
- [ ] 添加 UI 移除方法的说明
- [ ] 说明如何处理 UI 的生命周期

## 备注

- 这是一个全局 UI 管理模块
- 提供四层 UI 布局，支持复杂的 UI 层级管理
- 使用 CanvasLayer 确保 UI 在所有场景之上
- 支持场景过渡的渐层遮罩功能
- 通过 ModManager 提供统一的调用接口
- 总代码行数：约 100+ 行（完整文件）
