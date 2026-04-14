# 基础规则

## 基础规则
- 禁止在函数内部创建函数
- 禁止使用多行注释"""，"""注释内容"""，使用#注释
- 函数注解、模块注解使用##

## 基础代码调用用例

- 调用模块方法
   ```gdscript
   result = GameCore.ModManager.call_mod("SceneManager", "change_scene", path, type)
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
SceneManager

## 模块路径
res://mods/SceneManager/Scripts/ModEntry.gd

## 模块功能
场景管理模块，负责场景切换，支持 WORLD、UI_MAIN、UI_OVERLAY 三种场景类型

## 涉及模块
- ModInterface: 基础接口
- CanvasUILayer: UI 层管理

# 成员变量

- default_use_fade: bool = false
   - 默认使用淡入淡出效果

- fade_time: float = 0.35
   - 淡入淡出时间（秒）

- _current_main_scene: Node
   - 当前主场景节点

- _ui_overlay_stack: Array[Node]
   - UI_OVERLAY 场景栈

# 成员方法

- _on_mod_enable() -> void
   - @return void
   - 功能说明：
      - 模块启用时调用
      - 注册事件监听器（ANY 类型）

- get_current_main_scene() -> Node
   - @return Node: 当前主场景
   - 功能说明：
      - 获取当前主场景节点

- _get_fade_rect() -> Control
   - @return Control: 淡入淡出控件
   - 功能说明：
      - 从 CanvasUILayer 获取 FadeRect

- _fade_out() -> void
   - @return void
   - 功能说明：
      - 淡出效果（黑屏渐显）

- _fade_in() -> void
   - @return void
   - 功能说明：
      - 淡入效果（黑屏渐隐）

- _load_world_scene(path: String) -> void
   - @param path: 场景路径
   - @return void
   - 功能说明：
      - 加载 WORLD 场景到 GameSceneLayer

- _load_ui_main_scene(path: String) -> void
   - @param path: 场景路径
   - @return void
   - 功能说明：
      - 加载 UI_MAIN 场景到 CanvasUILayer Middle 层
      - 清理旧的 UI_OVERLAY

- _load_ui_overlay_scene(path: String) -> void
   - @param path: 场景路径
   - @return void
   - 功能说明：
      - 加载 UI_OVERLAY 场景到 CanvasUILayer Top 层
      - 添加到 overlay 栈

- change_scene(path: String, type: String, use_fade: bool = default_use_fade, extra = null) -> void
   - @param path: 场景资源路径
   - @param type: 场景类型（WORLD/UI_MAIN/UI_OVERLAY）
   - @param use_fade: 是否使用淡入淡出
   - @param extra: 额外数据（包含 scene_name）
   - @return void
   - 功能说明：
      - 切换场景
      - 根据类型加载不同场景
      - 发送 after_change_scene 事件

- push_scene(path: String, type: String, use_fade: bool = default_use_fade) -> void
   - @param path: 场景资源路径
   - @param type: 场景类型（仅支持 UI_OVERLAY）
   - @param use_fade: 是否使用淡入淡出
   - @return void
   - 功能说明：
      - 压入 UI_OVERLAY 场景到栈顶

- pop_scene(use_fade: bool = default_use_fade) -> void
   - @param use_fade: 是否使用淡入淡出
   - @return void
   - 功能说明：
      - 弹出栈顶的 UI_OVERLAY 场景

- _on_mod_event(_mod_name: String, event_name: String, event_data: Dictionary) -> void
   - @param _mod_name: 发送事件的模块名
   - @param event_name: 事件名称
   - @param event_data: 事件数据
   - @return void
   - 功能说明：
      - 将事件转发给当前主场景

# 数据文件

- ModuleConfig.json: 模块配置文件
