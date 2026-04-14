# ModEntry.gd 分析文档 (mod_template)

## 基础规则

- 禁止在函数内部创建函数（包括 lambda 函数、匿名函数）
- 禁止使用多行注释，使用#注释
- 函数注解、模块注解使用##

## 模块概述

**文件路径**: `res://mods/mod_template/Scripts/ModEntry.gd`

**模块名称**: mod_template (Mod 模板)

**模块类型**: 功能模块模板

**依赖模块**: 
- ModInterface (基础接口)

**功能说明**: 
作为创建新 mod 的标准化模板，包含 mod 所需的完整生命周期方法和标准化的 mod 结构示例。遵循 Godot 4 最佳实践（强类型 + 无隐式类型）。

**涉及模块**:
- ModManager (模块管理器)
- ModInterface (模块接口)

## 配置、输入输出数据结构

### 1. 生命周期方法

```gdscript
# 模块加载时调用（进入场景树前）
func _on_mod_load() -> bool

# 模块初始化时调用（进入场景树，_ready）
func _on_mod_init() -> void

# 模块启用时调用
func _on_mod_enable() -> void

# 模块禁用时调用（未来支持）
func _on_mod_disable() -> void

# 模块卸载时调用
func _on_mod_unload() -> void

# 接收其他 mod 发送的事件
func _on_mod_event(_mod_name, event_name, event_data) -> void
```

### 2. ModuleConfig.json 配置

```json
{
  "mod_name": "mod_template",
  "mod_version": "1.0.0",
  "mod_author": "Author Name",
  "mod_description": "Mod template for creating new mods",
  "mod_dependencies": [],
  "mod_entry_scene": "res://mods/mod_template/Scenes/ModEntry.tscn"
}
```

## 成员变量

本模板文件未定义额外的成员变量，所有功能通过生命周期方法实现。

## 成员方法

### 生命周期方法

#### _on_mod_load() -> bool

模块加载时调用（进入场景树前）。

**返回值**: 是否加载成功

**调用时机**: ModManager 加载 mod 时

**功能**:
- 执行模块加载前的准备工作
- 返回是否加载成功
- 子类需要实现具体逻辑

**示例**:
```gdscript
func _on_mod_load() -> bool:
    var is_load_succeed = super._on_mod_load()
    # 子类实现：读取配置、初始化数据等
    return is_load_succeed
```

#### _on_mod_init() -> void

模块初始化时调用（进入场景树，_ready）。

**调用时机**: 模块进入场景树后

**功能**:
- 初始化模块数据
- 注册事件监听
- 设置 UI 界面
- 子类需要实现具体逻辑

**示例**:
```gdscript
func _on_mod_init() -> void:
    super._on_mod_init()
    # 子类实现：读取配置、初始化数据、注册事件等
```

#### _on_mod_enable() -> void

模块启用时调用。

**调用时机**: 模块被启用时

**功能**:
- 启动模块逻辑
- 显示 UI 界面
- 连接信号
- 子类需要实现具体逻辑

**示例**:
```gdscript
func _on_mod_enable() -> void:
    super._on_mod_enable()
    # 子类实现：入口场景已经实例化，可以开始逻辑
```

#### _on_mod_disable() -> void

模块禁用时调用（未来支持）。

**调用时机**: 模块被禁用时

**功能**:
- 清理 UI
- 暂停逻辑
- 断开信号
- 子类需要实现具体逻辑

**示例**:
```gdscript
func _on_mod_disable() -> void:
    super._on_mod_disable()
    # 子类实现：清理 UI、暂停逻辑等
```

#### _on_mod_unload() -> void

模块卸载时调用。

**调用时机**: 模块被卸载时

**功能**:
- 清理资源
- 断开信号
- 保存数据
- 子类需要实现具体逻辑

**示例**:
```gdscript
func _on_mod_unload() -> void:
    super._on_mod_unload()
    # 子类实现：清理资源、断开信号、保存数据等
```

#### _on_mod_event(_mod_name, event_name, event_data) -> void

接收其他 mod 发送的事件。

**参数**:
- `_mod_name`: 发送事件的 mod 名称
- `event_name`: 事件名称
- `event_data`: 事件数据字典

**调用时机**: 其他 mod 发送事件时

**功能**:
- 处理模块间通信
- 响应其他模块的事件
- 子类需要实现具体逻辑

**示例**:
```gdscript
func _on_mod_event(_mod_name: String, event_name: String, event_data: Dictionary) -> void:
    super._on_mod_event(_mod_name, event_name, event_data)
    # 子类实现：处理特定事件
    if event_name == "some_event":
        _handle_some_event(event_data)
```

## 核心流程

### 模块生命周期流程

```
1. ModManager.load_mod()
   ↓
2. _on_mod_load()          # 加载模块
   ↓
3. ModManager.init_mod()
   ↓
4. _on_mod_init()          # 初始化模块
   ↓
5. ModManager.enable_mod()
   ↓
6. _on_mod_enable()        # 启用模块
   ↓
7. 模块运行中...
   ├─ _on_mod_event()      # 接收事件
   ↓
8. ModManager.disable_mod()
   ↓
9. _on_mod_disable()       # 禁用模块（未来）
   ↓
10. ModManager.unload_mod()
    ↓
11. _on_mod_unload()       # 卸载模块
```

### 模块间通信流程

```
Mod A                          ModManager                        Mod B
  |                               |                                 |
  |-- emit_event(event) --------> |                                 |
  |                               |-- forward_event() ------------> |
  |                               |                                 |
  |                               |                                 |-- _on_mod_event()
  |                               |                                 |
```

## 架构设计

### 分层架构

1. **接口层**: ModInterface 定义标准接口
2. **实现层**: ModEntry 实现具体逻辑
3. **配置层**: ModuleConfig.json 定义模块配置
4. **资源层**: Scenes/Scripts/Resources 存放模块资源

### 生命周期管理

```
加载 → 初始化 → 启用 → 运行 → 禁用 → 卸载
  ↓        ↓        ↓      ↓      ↓      ↓
load    init   enable  run  disable unload
```

### 事件驱动设计

- 使用事件系统进行模块间通信
- 支持自定义事件名称和数据
- 通过 _on_mod_event() 接收事件
- 通过 ModManager.emit_event() 发送事件

## 使用场景

### 创建新 Mod

```bash
# 1. 复制 mod_template 目录
cp -r res://mods/mod_template res://mods/my_new_mod

# 2. 重命名目录
# 已在上一步完成

# 3. 修改 ModuleConfig.json
# 修改 mod_name, mod_description 等

# 4. 实现 ModEntry.gd
# 在 Scripts/ModEntry.gd 中实现逻辑

# 5. 添加资源文件
# 添加所需的场景、脚本、资源
```

### 实现自定义逻辑

```gdscript
extends ModInterface

# 初始化
func _on_mod_init() -> void:
    super._on_mod_init()
    # 读取配置
    var config = _load_config()
    # 注册事件
    ModManager.register_event("my_event", _on_my_event)

# 启用
func _on_mod_enable() -> void:
    super._on_mod_enable()
    # 显示 UI
    $MyUI.show()

# 事件处理
func _on_mod_event(mod_name: String, event_name: String, event_data: Dictionary) -> void:
    super._on_mod_event(mod_name, event_name, event_data)
    if event_name == "game_started":
        _start_game()
    elif event_name == "game_ended":
        _end_game()
```

## TODO

- [ ] 添加更多使用示例
- [ ] 说明 ModuleConfig.json 的详细配置
- [ ] 添加模块间通信的最佳实践
- [ ] 说明如何处理模块依赖

## 备注

- 这是创建新 mod 的标准模板
- 遵循 Godot 4 最佳实践
- 使用强类型声明
- 避免隐式类型
- 包含完整的生命周期方法
- 支持模块间通信
- 总代码行数：约 70 行
