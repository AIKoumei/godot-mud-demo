# sprout_lands_tilemap.gd 分析文档

## 基础规则

- 禁止在函数内部创建函数（包括 lambda 函数、匿名函数）
- 禁止使用多行注释，使用#注释
- 函数注解、模块注解使用##

## 模块概述

**文件路径**: `res://mods/WorldSceneManager/Sprites/Scene/Tileset/sprout_lands_tilemap/sprout_lands_tilemap.gd`

**模块名称**: Sprout Lands TileMap Plugin

**模块类型**: Editor 插件

**继承**: EditorPlugin

**依赖模块**: 
- Godot Editor API
- DirAccess, FileAccess (文件操作)
- ResourceSaver (资源保存)

**功能说明**: 
这是一个 Godot Editor 插件，用于 Sprout Lands TileMap 资源包的安装和管理。提供复制示例文件、更新项目设置、处理资源文件等功能。**注意：这是编辑器工具，不是游戏运行时逻辑。**

**涉及模块**:
- Godot Editor (编辑器环境)
- WorldSceneManager (使用该资源包的模块)

## 配置、输入输出数据结构

### 1. 常量配置

```gdscript
const PLUGIN_NAME = "Sprout Lands TileMap"
const PROJECT_SETTINGS_PATH = "sprout_lands_tilemap/"
const EXAMPLES_RELATIVE_PATH = "examples/"
const UID_PREG_MATCH = r'uid="uid:\/\/[0-9a-z]+" '
const RESAVING_DELAY = 0.5
const REIMPORT_FILE_DELAY = 0.2
const OPEN_EDITOR_DELAY = 0.1
```

### 2. 输入数据结构

#### _copy_to_directory(target_path: String)
- `target_path`: 目标目录路径

#### _copy_file_path(file_path, destination_path, target_path, raw_copy_file_extensions)
- `file_path`: 源文件路径
- `destination_path`: 目标文件路径
- `target_path`: 目标目录路径
- `raw_copy_file_extensions`: 直接复制的文件扩展名列表

### 3. 输出数据结构

各函数返回 Error 类型：
- OK (0): 成功
- ERR_FILE_UNRECOGNIZED: 文件无法识别
- 其他错误码

## 成员变量

### 常量

```gdscript
const PLUGIN_NAME: String                    # 插件名称
const PROJECT_SETTINGS_PATH: String          # 项目设置路径
const EXAMPLES_RELATIVE_PATH: String         # 示例相对路径
const UID_PREG_MATCH: String                 # UID 正则匹配
const RESAVING_DELAY: float                  # 重新保存延迟
const REIMPORT_FILE_DELAY: float             # 重新导入延迟
const OPEN_EDITOR_DELAY: float               # 打开编辑器延迟
```

## 成员方法

### 插件生命周期方法

#### _enter_tree() -> void

插件进入编辑器树时调用。

**功能**:
1. 添加工具菜单项 "Copy Sprout Lands TileMap Examples..."
2. 显示插件对话框（首次使用时）

**示例**:
```gdscript
func _enter_tree():
    add_tool_menu_item("Copy " + _get_plugin_name() + " Examples...", _open_path_dialog)
    _show_plugin_dialogues()
```

#### _exit_tree() -> void

插件退出编辑器树时调用。

**功能**:
- 移除工具菜单项

**示例**:
```gdscript
func _exit_tree():
    remove_tool_menu_item("Copy " + _get_plugin_name() + " Examples...")
```

### 工具方法

#### _get_plugin_name() -> String

获取插件名称。

**返回值**: 插件名称字符串

#### get_plugin_path() -> String

获取插件路径。

**返回值**: 插件脚本所在目录路径

**示例**:
```gdscript
func get_plugin_path() -> String:
    return get_script().resource_path.get_base_dir() + "/"
```

#### get_plugin_examples_path() -> String

获取插件示例路径。

**返回值**: 示例目录路径

**示例**:
```gdscript
func get_plugin_examples_path() -> String:
    return get_plugin_path() + EXAMPLES_RELATIVE_PATH
```

#### _update_main_scene(main_scene_path: String) -> void

更新项目的主场景设置。

**参数**:
- `main_scene_path`: 主场景路径

**功能**:
1. 设置 application/run/main_scene
2. 保存项目设置

**示例**:
```gdscript
func _update_main_scene(main_scene_path: String):
    ProjectSettings.set_setting("application/run/main_scene", main_scene_path)
    ProjectSettings.save()
```

#### _replace_file_contents(file_path: String, target_path: String) -> void

替换文件内容（移除 UID 引用）。

**参数**:
- `file_path`: 文件路径
- `target_path`: 目标路径（用于替换）

**功能**:
1. 读取文件内容
2. 使用正则表达式移除 UID
3. 替换示例路径为目标路径
4. 写回文件

**正则表达式**:
```gdscript
const UID_PREG_MATCH = r'uid="uid:\/\/[0-9a-z]+" '
```

**示例**:
```gdscript
func _replace_file_contents(file_path: String, target_path: String):
    var file = FileAccess.open(file_path, FileAccess.READ)
    var regex = RegEx.new()
    regex.compile(UID_PREG_MATCH)
    var original_content = file.get_as_text()
    var replaced_content = regex.sub(original_content, "", true)
    replaced_content = replaced_content.replace(get_plugin_examples_path(), target_path)
    file.store_string(replaced_content)
```

#### _save_resource(resource_path, resource_destination, whitelisted_extensions) -> Error

保存资源文件。

**参数**:
- `resource_path`: 源资源路径
- `resource_destination`: 目标路径
- `whitelisted_extensions`: 白名单扩展名

**返回值**: Error 类型

**功能**:
1. 检查文件扩展名
2. 加载资源
3. 保存资源到目标路径

**示例**:
```gdscript
func _save_resource(resource_path: String, resource_destination: String, whitelisted_extensions: PackedStringArray = []) -> Error:
    var file_object = load(resource_path)
    if file_object is Resource:
        return ResourceSaver.save(file_object, resource_destination, ResourceSaver.FLAG_CHANGE_PATH)
    return ERR_FILE_UNRECOGNIZED
```

#### _copy_file_path(file_path, destination_path, target_path, raw_copy_file_extensions) -> Error

复制文件路径。

**参数**:
- `file_path`: 源文件路径
- `destination_path`: 目标文件路径
- `target_path`: 目标目录路径
- `raw_copy_file_extensions`: 直接复制的扩展名列表

**返回值**: Error 类型

**功能**:
1. 检查是否需要直接复制（如.md 文件）
2. 保存资源文件
3. 替换文件内容

**示例**:
```gdscript
func _copy_file_path(file_path: String, destination_path: String, target_path: String, raw_copy_file_extensions: PackedStringArray = []) -> Error:
    if file_path.get_extension() in raw_copy_file_extensions:
        return _raw_copy_file_path(file_path, destination_path)
    var error = _save_resource(file_path, destination_path)
    if error == ERR_FILE_UNRECOGNIZED:
        error = _raw_copy_file_path(file_path, destination_path)
        _delayed_reimporting_file(destination_path)
    return error
```

#### _copy_directory_path(dir_path, target_path, raw_copy_file_extensions) -> void

复制目录路径。

**参数**:
- `dir_path`: 源目录路径
- `target_path`: 目标目录路径
- `raw_copy_file_extensions`: 直接复制的扩展名列表

**功能**:
1. 遍历源目录
2. 递归复制子目录
3. 复制文件

**示例**:
```gdscript
func _copy_directory_path(dir_path: String, target_path: String, raw_copy_file_extensions: PackedStringArray = []):
    var dir = DirAccess.open(dir_path)
    if dir:
        dir.list_dir_begin()
        var file_name = dir.get_next()
        while file_name != "":
            if dir.current_is_dir():
                _copy_directory_path(full_file_path, target_path, raw_copy_file_extensions)
            else:
                _copy_file_path(full_file_path, destination_path, target_path, raw_copy_file_extensions)
            file_name = dir.get_next()
```

#### _delayed_reimporting_file(file_path: String) -> void

延迟重新导入文件。

**参数**:
- `file_path`: 文件路径

**功能**:
1. 创建 Timer
2. 延迟后调用 ResourceFileSystem.reimport_files()
3. 清理 Timer

**示例**:
```gdscript
func _delayed_reimporting_file(file_path: String):
    var timer: Timer = Timer.new()
    timer.timeout.connect(func():
        EditorInterface.get_resource_filesystem().reimport_files([file_path])
        timer.queue_free()
    )
    add_child(timer)
    timer.start(REIMPORT_FILE_DELAY)
```

#### _delayed_saving(target_path: String) -> void

延迟保存。

**参数**:
- `target_path`: 目标路径

**功能**:
1. 创建 Timer
2. 延迟后扫描文件系统并保存场景
3. 清理 Timer

#### _copy_to_directory(target_path: String) -> void

复制到目标目录。

**参数**:
- `target_path`: 目标目录路径

**功能**:
1. 保存目标路径到项目设置
2. 复制示例目录
3. 延迟保存

#### _open_path_dialog() -> void

打开路径选择对话框。

**功能**:
1. 加载 DestinationDialog 场景
2. 连接 dir_selected 信号
3. 添加到场景树

#### _open_confirmation_dialog() -> void

打开确认对话框。

**功能**:
1. 加载 CopyConfirmationDialog 场景
2. 连接 confirmed 信号
3. 添加到场景树

#### _show_plugin_dialogues() -> void

显示插件对话框。

**功能**:
1. 检查是否已显示过
2. 显示确认对话框
3. 设置标记避免重复显示

## 核心流程

### 插件安装流程

```
1. 用户安装插件
   ↓
2. _enter_tree() 调用
   ├─ 添加菜单项
   └─ 显示对话框（首次）
   ↓
3. 用户选择"Copy Examples"
   ↓
4. _open_confirmation_dialog()
   ↓
5. 用户确认
   ↓
6. _open_path_dialog()
   ↓
7. 用户选择目标目录
   ↓
8. _copy_to_directory(target_path)
   ├─ 保存路径到项目设置
   ├─ _copy_directory_path()
   │   ├─ 遍历目录
   │   ├─ 复制文件
   │   └─ 替换内容
   └─ _delayed_saving()
```

### 文件复制流程

```
1. _copy_file_path()
   ↓
2. 检查文件类型
   ├─ Markdown (.md) → _raw_copy_file_path()
   ├─ 资源文件 → _save_resource()
   └─ 其他 → _raw_copy_file_path()
   ↓
3. 替换文件内容
   ├─ 移除 UID
   └─ 替换路径
   ↓
4. 重新导入（如果需要）
   └─ _delayed_reimporting_file()
```

## 架构设计

### 插件架构

1. **生命周期层**: _enter_tree(), _exit_tree()
2. **工具层**: get_plugin_path(), _get_plugin_name()
3. **复制层**: _copy_file_path(), _copy_directory_path()
4. **处理层**: _replace_file_contents(), _save_resource()
5. **延迟层**: _delayed_reimporting_file(), _delayed_saving()

### 文件处理策略

```
文件类型判断
  ├─ Markdown (.md)
  │   └─ 直接复制
  ├─ Godot 资源 (.tscn, .tres, etc)
  │   ├─ 保存资源
  │   └─ 替换内容（移除 UID）
  └─ 其他文件
      ├─ 直接复制
      └─ 延迟重新导入
```

### 延迟处理设计

使用 Timer 实现延迟操作：
- RESAVING_DELAY (0.5s): 等待文件复制完成
- REIMPORT_FILE_DELAY (0.2s): 等待文件写入完成
- OPEN_EDITOR_DELAY (0.1s): 延迟打开编辑器

## 使用场景

### 安装示例文件

```gdscript
# 用户操作：
# 1. 在编辑器菜单选择 "Copy Sprout Lands TileMap Examples..."
# 2. 确认对话框
# 3. 选择目标目录
# 4. 自动复制示例文件
```

### 项目设置

```gdscript
# 插件会自动设置：
ProjectSettings.set_setting("sprout_lands_tilemap/copy_path", target_path)
ProjectSettings.set_setting("sprout_lands_tilemap/disable_plugin_dialogues", true)
```

## TODO

- [ ] 说明 UID 的作用和为什么要移除
- [ ] 补充 DestinationDialog 和 CopyConfirmationDialog 的实现
- [ ] 说明如何处理资源文件的依赖关系
- [ ] 添加错误处理机制的说明

## 备注

- **这是 Editor 插件，不是游戏运行时逻辑**
- 用于 Sprout Lands TileMap 资源包的安装
- 自动处理文件复制、资源保存、UID 移除等
- 使用延迟操作确保文件操作完成
- 总代码行数：约 170 行
- 只在编辑器环境中运行
