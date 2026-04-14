# mod.DefaultGameScene.Scripts.ModEntry.gd 分析文档

## 基础规则

### 基础规则
- 禁止在函数内部创建函数
- 禁止使用多行注释"""，"""注释内容"""，使用#注释
- 函数注解、模块注解使用##

### 基础代码调用用例

- 数组去重
   ```gdscript
   new_array = GameCore.ArrayTools.deduplicate(array)
   ```

- 字典合并
   ```gdscript
   new_dict = GameCore.DictionaryTools.merge(dict_1, dict_2)
   ```

- 时间获取
   ```gdscript
   time_string =  Time.get_datetime_string_from_system()
   ```

- 调用其他模块
   ```gdscript
   result = GameCore.ModManager.call_mod(mod_name:String, method_name:String, ...args)
   ```

### 代码注释

- 为文件适当添加注释
   - 给出配置
   - 给出输入输出的数据结构
   - 说明模块的功能
   - 给出模块的用例
   - 给出涉及模块的名称

- 在文件头给出模块的主要功能以及对应方法

- 给出功能的用例

### 模块交互

- 通过 GameCore.mod_manager.call_mod(mod_name, method_name, args) 调用其他模块的方法
- 不需要判断 Engine.has_meta(mod_name)
- 因为 GameCore.mod_manager.call_mod 已经判断了，如果模块不存在，不会调用空模块，所以不会报错。

# 模块概述

## 模块名称
DefaultGameScene

## 模块路径
res/mods/DefaultGameScene/Scripts/ModEntry.gd

## 模块功能
默认游戏场景管理模块，负责维护游戏场景配置和提供统一的场景切换接口。主要职责包括:
1. 维护游戏场景配置 (路径 + 类型)
2. 定义 SceneType 字符串类型 (WORLD, UI_MAIN, UI_OVERLAY)
3. 封装 SceneManager 提供统一的场景切换接口
4. 管理 UI 场景 (StartMenu, NewGame, PauseMenu, GameOver 等)
5. 管理游戏场景 (World, Battle 等)
6. 管理特殊 UI (DigimonVpetUI 虚拟宠物 UI)

## 模块依赖
- SceneManager: 场景切换管理
- ModInterface: 模块接口基类

## 场景类型定义
```gdscript
SceneType: String
- "WORLD": 游戏世界场景
- "UI_MAIN": 主 UI 场景
- "UI_OVERLAY": 覆盖 UI 场景
```

## 模块用例

```gdscript
# 示例 1：切换到开始菜单
DefaultGameScene.change_scene("StartMenu")

# 示例 2：切换到新游戏设置场景
DefaultGameScene.change_scene("NewGameScene")

# 示例 3：切换到世界生成场景
DefaultGameScene.change_scene("WorldGenerateScene")

# 示例 4：切换到游戏世界
DefaultGameScene.change_scene("GameWorld", true)  # 使用淡入淡出

# 示例 5：切换到战斗场景
DefaultGameScene.change_scene("BattleScene", true)

# 示例 6：推入暂停菜单
DefaultGameScene.push_scene("PauseMenu")

# 示例 7：弹出当前场景
DefaultGameScene.pop_scene()

# 示例 8：获取场景信息
var info = DefaultGameScene.get_scene_info("StartMenu")
print(info)  # {"path": "...", "type": "UI_MAIN"}

# 示例 9：显示虚拟宠物 UI
DefaultGameScene.change_scene("DigimonVpetUI")
```

# 成员变量

## 导出变量 (场景路径)
- @export var GameWorldScene: String
  - 游戏世界场景路径

- @export var BattleScene: String
  - 战斗场景路径

- @export var StartMenuScene: String
  - 开始菜单场景路径
  - 默认值："res://res/mods/DefaultGameScene/Scenes/UIScenes/StartMenuScene.tscn"

- @export var NewGameScene: String
  - 新游戏设置场景路径
  - 默认值："res://res/mods/DefaultGameScene/Scenes/UIScenes/NewGameScene.tscn"

- @export var WorldGenerateScene: String
  - 世界生成场景路径
  - 默认值："res://res/mods/DefaultGameScene/Scenes/UIScenes/WorldGenerateScene.tscn"

- @export var PauseMenuScene: String
  - 暂停菜单场景路径

- @export var GameOverScene: String
  - 游戏结束场景路径

- @export var DigimonVpetUI: String
  - 数码兽虚拟宠物 UI 场景路径
  - 默认值："res://res/mods/DefaultGameScene/Scenes/GameScenes/DigimonVpetUI.tscn"

## 内部变量
- var _scene_table: Dictionary
  - 内部场景表
  - 存储场景名称到配置 (path, type) 的映射
  - 数据结构：{scene_name: {path: String, type: String}}

# 成员方法

## 生命周期方法

- _on_mod_load() -> bool
  - @return bool: 模块加载是否成功
  - functions:
    - 调用父类 _on_mod_load()
    - 初始化 _scene_table 字典
    - 配置所有场景的路径和类型:
      - GameWorld: WORLD
      - BattleScene: WORLD
      - StartMenu: UI_MAIN
      - NewGameScene: UI_MAIN
      - WorldGenerateScene: UI_MAIN
      - PauseMenu: UI_OVERLAY
      - GameOver: UI_MAIN
      - DigimonVpetUI: UI_MAIN
    - 返回加载成功标志

## 场景切换接口

- change_scene(scene_name: String, use_fade: bool = false) -> void
  - @args:
    - scene_name: 场景名称
    - use_fade: 是否使用淡入淡出效果，默认 false
  - functions:
    - 调用 get_scene_info() 获取场景信息
    - 检查场景是否存在
    - 调用 SceneManager.change_scene():
      - 参数：path, type, use_fade, {scene_name}
    - 切换到指定场景

- push_scene(scene_name: String, use_fade: bool = true) -> void
  - @args:
    - scene_name: 场景名称
    - use_fade: 是否使用淡入淡出效果，默认 true
  - functions:
    - 调用 get_scene_info() 获取场景信息
    - 检查场景是否存在
    - 调用 SceneManager.push_scene():
      - 参数：path, type, use_fade
    - 将场景推入栈顶

- pop_scene(use_fade: bool = true) -> void
  - @args:
    - use_fade: 是否使用淡入淡出效果，默认 true
  - functions:
    - 调用 SceneManager.pop_scene()
    - 弹出栈顶场景

## 工具方法

- get_scene_info(scene_name: String) -> Dictionary
  - @args:
    - scene_name: 场景名称
  - @return Dictionary: 场景信息 {path, type}
  - functions:
    - 从 _scene_table 中查找场景
    - 返回场景配置
    - 如果不存在，返回空字典

# 数据文件

## 场景资源文件
- StartMenuScene.tscn
  - 路径：res://res/mods/DefaultGameScene/Scenes/UIScenes/StartMenuScene.tscn
  - 类型：UI_MAIN
  - 功能：游戏开始菜单

- NewGameScene.tscn
  - 路径：res://res/mods/DefaultGameScene/Scenes/UIScenes/NewGameScene.tscn
  - 类型：UI_MAIN
  - 功能：新游戏设置

- WorldGenerateScene.tscn
  - 路径：res://res/mods/DefaultGameScene/Scenes/UIScenes/WorldGenerateScene.tscn
  - 类型：UI_MAIN
  - 功能：世界生成场景

- DigimonVpetUI.tscn
  - 路径：res://res/mods/DefaultGameScene/Scenes/GameScenes/DigimonVpetUI.tscn
  - 类型：UI_MAIN
  - 功能：数码兽虚拟宠物 UI

# 模块交互

## 调用的其他模块
- SceneManager: change_scene(), push_scene(), pop_scene()

## 被其他模块调用
- GameManager: 调用 change_scene() 切换场景
- StartMenuScene: 调用 change_scene() 切换到新游戏
- NewGameScene: 调用 change_scene() 切换到世界生成

## 发送的事件
- 无

# 核心流程

## 模块加载流程
```
1. 调用 _on_mod_load()
2. 调用父类 _on_mod_load()
3. 初始化 _scene_table 字典
4. 配置所有场景:
   - GameWorld: {path: GameWorldScene, type: "WORLD"}
   - BattleScene: {path: BattleScene, type: "WORLD"}
   - StartMenu: {path: StartMenuScene, type: "UI_MAIN"}
   - NewGameScene: {path: NewGameScene, type: "UI_MAIN"}
   - WorldGenerateScene: {path: WorldGenerateScene, type: "UI_MAIN"}
   - PauseMenu: {path: PauseMenuScene, type: "UI_OVERLAY"}
   - GameOver: {path: GameOverScene, type: "UI_MAIN"}
   - DigimonVpetUI: {path: DigimonVpetUI, type: "UI_MAIN"}
5. 返回加载成功标志
```

## 场景切换流程
```
1. 调用 change_scene(scene_name, use_fade)
2. 调用 get_scene_info(scene_name)
3. 检查场景信息是否为空
   - 如果为空，打印错误并返回
4. 调用 SceneManager.change_scene():
   - 参数：info.path, info.type, use_fade, {scene_name}
5. SceneManager 执行场景切换
```

## 场景推入流程
```
1. 调用 push_scene(scene_name, use_fade)
2. 调用 get_scene_info(scene_name)
3. 检查场景信息是否为空
   - 如果为空，打印错误并返回
4. 调用 SceneManager.push_scene():
   - 参数：info.path, info.type, use_fade
5. SceneManager 将场景推入栈顶
```

## 场景弹出流程
```
1. 调用 pop_scene(use_fade)
2. 调用 SceneManager.pop_scene(use_fade)
3. SceneManager 弹出栈顶场景
```

# 架构设计

## 场景分类架构
- WORLD 类型:
  - GameWorld: 游戏主世界
  - BattleScene: 战斗场景
- UI_MAIN 类型:
  - StartMenu: 开始菜单
  - NewGameScene: 新游戏设置
  - WorldGenerateScene: 世界生成
  - GameOver: 游戏结束
  - DigimonVpetUI: 虚拟宠物 UI
- UI_OVERLAY 类型:
  - PauseMenu: 暂停菜单

## 场景管理策略
- 使用 SceneManager 统一管理场景
- 封装场景切换接口，提供便捷方法
- 支持淡入淡出效果
- 支持场景栈 (push/pop)

## 配置化设计
- 所有场景路径通过 @export 导出
- 可在 Inspector 中可视化配置
- 便于扩展和修改

## 扩展性设计
- 使用字典存储场景配置
- 易于添加新场景
- 支持自定义场景类型

# 使用场景

## 1. 游戏流程控制
- 启动游戏 → StartMenu
- 新游戏 → NewGameScene → WorldGenerateScene → GameWorld
- 游戏中暂停 → PauseMenu
- 游戏结束 → GameOver

## 2. UI 管理
- 主 UI 场景切换
- 覆盖 UI 显示/隐藏
- 虚拟宠物 UI 显示

## 3. 战斗系统
- 进入战斗 → BattleScene
- 战斗结束 → 返回 GameWorld

# TODO

- [ ] 添加场景预加载功能
  - [ ] preload_scene(scene_name)
  - [ ] 减少场景切换延迟

- [ ] 添加场景过渡动画
  - [ ] 自定义过渡效果
  - [ ] 支持动画配置

- [ ] 添加场景回调
  - [ ] on_scene_loaded(scene_name)
  - [ ] on_scene_unloaded(scene_name)

- [ ] 优化场景管理
  - [ ] 场景缓存
  - [ ] 异步加载

- [ ] 添加场景历史记录
  - [ ] 支持返回上一个场景
  - [ ] 场景历史栈
