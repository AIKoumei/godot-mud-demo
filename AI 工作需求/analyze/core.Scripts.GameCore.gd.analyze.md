# 基础规则

## 基础规则
- 禁止在函数内部创建函数
- 禁止使用多行注释"""，"""注释内容"""，使用#注释
- 函数注解、模块注解使用##

## 基础代码调用用例

- 调用模块方法
   ```gdscript
   result = GameCore.ModManager.call_mod(mod_name:String, method_name:String, ...args)
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
GameCore

## 模块路径
res://core/Scripts/GameCore.gd

## 模块功能
游戏核心脚本，负责游戏初始化、主循环、资源加载和场景管理

## 涉及模块
- ModManager: 模块管理器
- ArrayTools: 数组工具
- DictionaryTools: 字典工具
- BaseTools: 基础工具
- Settings: 游戏设置

# 成员变量

- debugging: bool
   - 调试模式开关

- VERSION: String
   - 版本号常量 "v.0.0.1"

- mod_manager: ModManager
   - 模块管理器实例

- SceneStateMachine: Node
   - 场景状态机引用

- ArrayTools: _ArrayTools
   - 数组工具实例

- DictionaryTools: _DictionaryTools
   - 字典工具实例

- BaseTools: _BaseTools
   - 基础工具实例

- Settings: _Settings
   - 设置实例

# 成员方法

- _ready() -> void
   - @return void
   - 功能说明：
      - 初始化游戏核心
      - 打印版本信息
      - 调用_initialize_game()

- _process(delta: float) -> void
   - @param delta: 帧时间间隔
   - @return void
   - 功能说明：
      - 游戏主循环
      - 当前为空实现

- _initialize_game() -> void
   - @return void
   - 功能说明：
      - 初始化游戏
      - 获取 SceneStateMachine 引用
      - 连接场景状态机的状态进入信号

- _load_resources() -> void
   - @return void
   - 功能说明：
      - 加载游戏资源
      - TODO: 实现资源加载逻辑

- _update_game(delta: float) -> void
   - @param delta: 帧时间间隔
   - @return void
   - 功能说明：
      - 游戏主逻辑更新
      - 当前为空实现

- _update_paused(delta: float) -> void
   - @param delta: 帧时间间隔
   - @return void
   - 功能说明：
      - 暂停状态更新
      - 当前为空实现

- _shutdown_game() -> void
   - @return void
   - 功能说明：
      - 关闭游戏
      - 清理资源
      - 保存游戏状态
      - 调用 get_tree().quit()

- get_mods_layer() -> Node
   - @return Node: ModsLayer 节点
   - 功能说明：
      - 获取 Mods 层节点

- get_game_scene_layer() -> Node
   - @return Node: GameSceneLayer 节点
   - 功能说明：
      - 获取游戏场景层节点

- get_pause_scene_layer() -> Node
   - @return Node: PauseSceneLayer 节点
   - 功能说明：
      - 获取暂停场景层节点

- get_main_layer() -> Node
   - @return Node: Main 节点
   - 功能说明：
      - 获取主节点

- get_UI_layer() -> Node
   - @return Node: CanvasLayer 节点
   - 功能说明：
      - 获取 UI 层节点

- _on_logo_scene_state_entered() -> void
   - @return void
   - 功能说明：
      - Logo 场景状态进入回调
      - 打印信息
      - 发送到 InitiateGameScene

- _on_initiate_game_scene_state_entered() -> void
   - @return void
   - 功能说明：
      - 初始化游戏场景状态进入回调
      - 加载资源
      - 加载所有模块
      - 发送到 LoadingGameScene

- _on_loading_game_scene_state_entered() -> void
   - @return void
   - 功能说明：
      - 加载游戏场景状态进入回调
      - 发送到 StartMenuScene

- _on_start_menu_scene_state_entered() -> void
   - @return void
   - 功能说明：
      - 开始菜单场景状态进入回调
      - 调用 DefaultGameScene 模块的 change_scene 方法

# 数据文件

无
