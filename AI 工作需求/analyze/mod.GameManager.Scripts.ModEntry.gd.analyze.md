# 基础规则

## 基础规则
- 禁止在函数内部创建函数
- 禁止使用多行注释"""，"""注释内容"""，使用#注释
- 函数注解、模块注解使用##

## 基础代码调用用例

- 开始新游戏
   ```gdscript
   GameCore.ModManager.call_mod("GameManager", "new_game")
   ```

- 保存游戏
   ```gdscript
   GameCore.ModManager.call_mod("GameManager", "save_game")
   ```

- 暂停游戏
   ```gdscript
   GameCore.ModManager.call_mod("GameManager", "pause_game")
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
GameManager

## 模块路径
res://mods/GameManager/Scripts/ModEntry.gd

## 模块功能
游戏管理模块，负责游戏状态管理、新游戏流程、保存/加载游戏、暂停/恢复游戏

## 涉及模块
- ModInterface: 基础接口
- PlayerDataManager: 玩家数据管理
- EntityInstanceManager: 实体实例管理
- WorldMapInstanceManager: 世界地图实例管理
- WorldSceneManager: 世界场景管理
- SceneManager: 场景管理
- DefaultGameScene: 默认游戏场景
- PlayerManager: 玩家管理

# 成员变量

- state: GameState
   - 当前游戏状态
   - 默认值：GameState.TITLE

- GameState: Enum
   - 游戏状态枚举：
      - TITLE: 标题
      - NEW_GAME: 新游戏
      - LOADING: 加载中
      - RUNNING: 运行中
      - PAUSED: 暂停
      - SAVING: 保存中

# 成员方法

- _on_mod_init() -> void
   - @return void
   - 功能说明：
      - 模块初始化时调用
      - 打印初始化信息

- _on_mod_enable() -> void
   - @return void
   - 功能说明：
      - 模块启用时调用
      - 注册事件监听器

- _on_mod_load() -> bool
   - @return bool: 加载是否成功
   - 功能说明：
      - 模块加载时调用

- _on_mod_unload() -> void
   - @return void
   - 功能说明：
      - 模块卸载时调用

- new_game() -> void
   - @return void
   - 功能说明：
      - 开始新游戏流程
      - 设置默认存档位
      - 切换到新游戏场景
      - 等待地图初始化
      - 创建玩家实体
      - 初始化玩家队伍
      - 切换到主游戏场景
      - 加载地图场景
      - 生成玩家节点

- save_game() -> void
   - @return void
   - 功能说明：
      - 保存游戏
      - 调用 Save 模块保存

- load_game() -> void
   - @return void
   - 功能说明：
      - 加载游戏
      - 调用 Save 模块加载
      - 显示 UI 并绑定数据

- pause_game() -> void
   - @return void
   - 功能说明：
      - 暂停游戏
      - 设置暂停状态
      - 显示暂停菜单

- resume_game() -> void
   - @return void
   - 功能说明：
      - 恢复游戏
      - 清除暂停状态
      - 隐藏暂停菜单

- _process(delta: float) -> void
   - @param delta: 帧时间间隔
   - @return void
   - 功能说明：
      - 游戏主循环（可选）
      - 当前为空实现

- _on_mod_event(_mod_name: String, event_name: String, event_data: Dictionary) -> void
   - @param _mod_name: 发送事件的模块名
   - @param event_name: 事件名称
   - @param event_data: 事件数据
   - @return void
   - 功能说明：
      - 处理模块事件
      - 监听地图初始化完成事件
      - 监听场景就绪事件

# 数据文件

- ModuleConfig.json: 模块配置文件

## 游戏状态

```json
{
    "TITLE": 0,
    "NEW_GAME": 1,
    "LOADING": 2,
    "RUNNING": 3,
    "PAUSED": 4,
    "SAVING": 5
}
```

## 新游戏流程

1. 设置默认存档位
2. 切换到新游戏场景
3. 等待地图初始化完成
4. 随机选择出生地图（如果未指定）
5. 创建玩家实体
6. 初始化玩家实体
7. 切换到主游戏场景
8. 加载地图场景
9. 生成玩家节点
10. 初始化 UI
11. 创建初始存档
12. 发送 new_game_finished 事件
