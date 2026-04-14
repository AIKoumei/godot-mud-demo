# 基础规则

## 基础规则
- 禁止在函数内部创建函数
- 禁止使用多行注释"""，"""注释内容"""，使用#注释
- 函数注解、模块注解使用##

## 基础代码调用用例

- 调用模块方法
   ```gdscript
   result = GameCore.ModManager.call_mod("ModInterface", "emit_mod_event", event_name, event_data)
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
ModInterface

## 模块路径
res://core/Scripts/ModManager/ModInterface.gd

## 模块功能
模块接口定义脚本，规范 mod 开发标准，提供模块生命周期管理和事件系统

## 涉及模块
- ModEventListenerFilter: 事件监听过滤器
- ModManager: 模块管理器
- GameCore: 游戏核心

# 成员变量

- mod_name: String
   - 模块名称（由 ModManager 注入）

- mod_config: Dictionary
   - 模块配置（ModuleConfig.json）

- mod_data: Dictionary
   - 模块数据（ModuleConfig.json）

- _listeners: Dictionary
   - 监听器字典

- _listener_to_name: Dictionary
   - 监听器到名称的映射

# 成员方法

- _ready() -> void
   - @return void
   - 功能说明：
      - 模块初始化（脚本挂载到场景节点时）
      - 调用_on_mod_init()

- enable_mod() -> void
   - @return void
   - 功能说明：
      - 启用模块
      - 调用_on_mod_enable()

- disable_mod() -> void
   - @return void
   - 功能说明：
      - 禁用模块
      - 调用_on_mod_disable()

- load_mod() -> bool
   - @return bool: 加载是否成功
   - 功能说明：
      - 加载模块
      - 调用_on_mod_load()

- unload_mod() -> void
   - @return void
   - 功能说明：
      - 卸载模块
      - 调用_on_mod_unload()

- on_mod_event(_mod_name: String, event_name: String, event_data: Dictionary) -> void
   - @param _mod_name: 发送事件的模块名
   - @param event_name: 事件名称
   - @param event_data: 事件数据
   - @return void
   - 功能说明：
      - 处理模块事件
      - 调用_on_mod_event()

- _on_mod_init() -> void
   - @return void
   - 功能说明：
      - 生命周期：模块脚本被挂载到场景节点时调用
      - 子类实现

- _on_mod_enable() -> void
   - @return void
   - 功能说明：
      - 生命周期：模块启用（入口场景实例化后）
      - 子类实现

- _on_mod_disable() -> void
   - @return void
   - 功能说明：
      - 生命周期：模块禁用（未来支持）
      - 子类实现

- _on_mod_load() -> bool
   - @return bool: 加载是否成功
   - 功能说明：
      - 生命周期：模块加载
      - 子类实现

- _on_mod_unload() -> void
   - @return void
   - 功能说明：
      - 生命周期：模块卸载（场景被移除前）
      - 子类实现

- _on_mod_event(_mod_name: String, event_name: String, event_data: Dictionary) -> void
   - @param _mod_name: 发送事件的模块名
   - @param event_name: 事件名称
   - @param event_data: 事件数据
   - @return void
   - 功能说明：
      - 处理游戏事件，供 mod 重写

- emit_mod_event(event_name: String, event_data: Dictionary = {}) -> void
   - @param event_name: 事件名称
   - @param event_data: 事件数据
   - @return void
   - 功能说明：
      - 发送事件（直接使用自己的 mod_name）

- register_event_listener(filter: ModEventListenerFilter) -> ModEventListenerFilter
   - @param filter: 事件监听过滤器
   - @return ModEventListenerFilter: 注册的过滤器
   - 功能说明：
      - 注册事件监听器

- unregister_event_listener(filter: ModEventListenerFilter) -> void
   - @param filter: 事件监听过滤器
   - @return void
   - 功能说明：
      - 注销事件监听器

- after_unregister_event_listener(filter: ModEventListenerFilter) -> void
   - @param filter: 事件监听过滤器
   - @return void
   - 功能说明：
      - 注销后处理

- get_listener_by_name(filter_name: String) -> ModEventListenerFilter
   - @param filter_name: 过滤器名称
   - @return ModEventListenerFilter: 过滤器
   - 功能说明：
      - 根据名称获取监听器

- register_event_listener_with_name(filter: ModEventListenerFilter, filter_name: String) -> ModEventListenerFilter
   - @param filter: 事件监听过滤器
   - @param filter_name: 过滤器名称
   - @return ModEventListenerFilter: 注册的过滤器
   - 功能说明：
      - 注册带名称的事件监听器

- unregister_event_listener_with_name(filter_name: String) -> void
   - @param filter_name: 过滤器名称
   - @return void
   - 功能说明：
      - 注销带名称的事件监听器

- get_mod_path() -> String
   - @return String: 模块路径
   - 功能说明：
      - 获取模块路径

# 数据文件

无
