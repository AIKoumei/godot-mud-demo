# 基础规则

## 基础规则
- 禁止在函数内部创建函数
- 禁止使用多行注释"""，"""注释内容"""，使用#注释
- 函数注解、模块注解使用##

## 基础代码调用用例

- 调用模块方法
   ```gdscript
   result = GameCore.ModManager.call_mod("ModManager", "load_all_mods")
   result = GameCore.ModManager.call_mod("ModManager", "call_mod", mod_name, method, args)
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
ModManager

## 模块路径
res://core/Scripts/ModManager/ModManager.gd

## 模块功能
模块管理器，负责 mod 扫描、依赖解析、加载、卸载、入口场景调度，以及模块间事件系统

## 涉及模块
- ModEventListenerFilter: 事件监听过滤器
- GameCore: 游戏核心

# 成员变量

- VERSION: String
   - 版本号 "v0.0.1"

- loaded_mods: Dictionary
   - 已加载的 mod 数据：
   ```json
   {
      "mod_name": {
         "config": {},
         "data": {},
         "path": "res://mods/mod_name",
         "scene": Node,
         "enabled": false,
         "loaded": false
      }
   }
   ```

- MODS_ROOT: String
   - 默认 mod 根目录 "res://res/mods"

- _event_filters: Dictionary
   - 事件过滤器字典

- _event_dispatch_table: Dictionary
   - 事件快速分发表

# 成员方法

- _init() -> void
   - @return void
   - 功能说明：
      - 初始化 ModManager

- load_json(path: String) -> Dictionary
   - @param path: JSON 文件路径
   - @return Dictionary: 解析后的字典
   - 功能说明：
      - 从 res://加载 JSON 文件

- load_json_user(path: String) -> Dictionary
   - @param path: JSON 文件路径
   - @return Dictionary: 解析后的字典
   - 功能说明：
      - 从 user://加载 JSON 文件

- save_json_user(path: String, data: Dictionary) -> void
   - @param path: JSON 文件路径
   - @param data: 要保存的字典
   - @return void
   - 功能说明：
      - 保存 JSON 到 user://

- compare_version(a: String, b: String) -> int
   - @param a: 版本号 a
   - @param b: 版本号 b
   - @return int: 1(a>b), 0(a=b), -1(a<b)
   - 功能说明：
      - 比较版本号

- merge_user_and_default(default: Dictionary, user: Dictionary, label: String, mod_name: String) -> Dictionary
   - @param default: 默认配置
   - @param user: 用户配置
   - @param label: 配置标签
   - @param mod_name: 模块名称
   - @return Dictionary: 合并后的配置
   - 功能说明：
      - 合并 user 和 res 配置
      - 根据版本决定使用哪个配置

- scan_mods(mods_path: String = MODS_ROOT) -> Dictionary
   - @param mods_path: mod 目录路径
   - @return Dictionary: 扫描到的 mod 字典
   - 功能说明：
      - 扫描 mod 目录
      - 读取 ModuleConfig.json

- build_dependency_graph(mods: Dictionary) -> Dictionary
   - @param mods: mod 字典
   - @return Dictionary: 依赖图
   - 功能说明：
      - 构建依赖关系图

- detect_cycle(graph: Dictionary) -> bool
   - @param graph: 依赖图
   - @return bool: 是否存在循环依赖
   - 功能说明：
      - 检测循环依赖（DFS）

- topological_sort(graph: Dictionary) -> Array
   - @param graph: 依赖图
   - @return Array: 拓扑排序结果
   - 功能说明：
      - 拓扑排序（DFS）

- get_mod_load_order(mods_path: String = MODS_ROOT) -> Array
   - @param mods_path: mod 目录路径
   - @return Array: mod 加载顺序
   - 功能说明：
      - 计算按依赖顺序的加载顺序

- load_all_mods(mods_path: String = MODS_ROOT) -> void
   - @param mods_path: mod 目录路径
   - @return void
   - 功能说明：
      - 按依赖顺序加载所有 mod
      - 先 load 再 enable

- load_mod(mod_name: String, mods_path: String = MODS_ROOT) -> bool
   - @param mod_name: mod 名称
   - @param mods_path: mod 目录路径
   - @return bool: 加载是否成功
   - 功能说明：
      - 加载单个 mod
      - 合并 user 和 res 配置
      - 实例化入口场景
      - 挂载脚本

- enable_mod(mod_name: String) -> bool
   - @param mod_name: mod 名称
   - @return bool: 启用是否成功
   - 功能说明：
      - 启用 mod
      - 先启用依赖

- disable_mod(mod_name: String) -> bool
   - @param mod_name: mod 名称
   - @return bool: 禁用是否成功
   - 功能说明：
      - 禁用 mod

- unload_mod(mod_name: String) -> bool
   - @param mod_name: mod 名称
   - @return bool: 卸载是否成功
   - 功能说明：
      - 卸载 mod
      - 先禁用再释放场景

- get_loaded_mods() -> Array
   - @return Array: 已加载 mod 名称数组
   - 功能说明：
      - 获取已加载的 mod 列表

- get_mod_config(mod_name: String) -> Dictionary
   - @param mod_name: mod 名称
   - @return Dictionary: mod 配置
   - 功能说明：
      - 获取 mod 配置

- get_mod_data(mod_name: String) -> Dictionary
   - @param mod_name: mod 名称
   - @return Dictionary: mod 数据
   - 功能说明：
      - 获取 mod 数据

- get_mod_scene(mod_name: String) -> Node
   - @param mod_name: mod 名称
   - @return Node: mod 场景节点
   - 功能说明：
      - 获取 mod 场景

- call_mod(mod_name: String, method: String, ...args) -> Variant
   - @param mod_name: mod 名称
   - @param method: 方法名
   - @param args: 可变参数
   - @return Variant: 方法返回值
   - 功能说明：
      - 调用 mod 方法
      - 检查 mod 是否存在和启用

- register_mod_event_listener(mod_name: String, filter: ModEventListenerFilter) -> void
   - @param mod_name: mod 名称
   - @param filter: 事件监听过滤器
   - @return void
   - 功能说明：
      - 注册事件监听器

- unregister_mod_event_listener(mod_name: String, filter: ModEventListenerFilter) -> void
   - @param mod_name: mod 名称
   - @param filter: 事件监听过滤器
   - @return void
   - 功能说明：
      - 注销事件监听器

- unregister_all_mod_event_listeners(mod_name: String) -> void
   - @param mod_name: mod 名称
   - @return void
   - 功能说明：
      - 注销所有事件监听器

- emit_mod_event(from_mod: String, event_name: String, event_data: Dictionary = {}) -> void
   - @param from_mod: 发送事件的 mod 名称
   - @param event_name: 事件名称
   - @param event_data: 事件数据
   - @return void
   - 功能说明：
      - 分发事件到匹配的监听器
      - 支持 Once 自动移除

- emit_ui_scene_event(event_name: String, event_data: Dictionary = {}) -> void
   - @param event_name: 事件名称
   - @param event_data: 事件数据
   - @return void
   - 功能说明：
      - 发送 UI 场景事件

# 数据文件

无
