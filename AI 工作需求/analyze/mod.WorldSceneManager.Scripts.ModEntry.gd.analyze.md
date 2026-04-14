# mod.WorldSceneManager.Scripts.ModEntry.gd 分析文档

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
WorldSceneManager

## 模块路径
res/mods/WorldSceneManager/Scripts/ModEntry.gd

## 模块功能
世界场景可视化协调层，负责管理世界场景的可视化渲染。主要职责包括：
1. 持有 WorldMapScene 实例（只创建一次）
2. 当 location 改变时调用 world_map_scene.render_from_instance()
3. 管理玩家节点（spawn_player_at）
4. 不负责地图玩法逻辑（由 WorldMapInstanceManager 负责）
5. 不负责地图渲染细节（由 WorldMapScene 负责）

## 模块依赖
- WorldMapScene: 世界地图场景类
- EntityInstanceManager: 获取玩家实例数据
- ModEventListenerFilter: 事件监听过滤

## 模块用例

```gdscript
# 示例 1：设置场景根节点
var root_node = get_tree().get_current_scene()
WorldSceneManager.set_root_node(root_node)

# 示例 2：加载 location 的世界场景
WorldSceneManager.load_scene_for_location("file_island")

# 示例 3：生成玩家节点
var start_point = {"x": 10, "y": 10}
WorldSceneManager.spawn_player_at("player_001", start_point)

# 示例 4：世界更新
WorldSceneManager.update(delta)
```

# 成员变量

- _current_location_id: String
  - 当前 location ID

- _root_node: Node
  - 场景根节点（通常是 UI 场景中的 SubViewport Root）

- _world_map_scene: WorldMapScene
  - 世界地图场景实例（只创建一次）

- _player_node: Node2D
  - 玩家节点

# 成员方法

- _on_mod_load() -> bool
  - @return bool: 模块加载是否成功
  - functions:
    - 打印模块加载信息
    - 返回 true

- set_root_node(root:Node) -> void
  - @args:
    - root: 场景根节点
  - functions:
    - 设置场景根节点
    - 通常是 UI 场景中的 SubViewport Root

- load_scene_for_location(location_id:String) -> bool
  - @args:
    - location_id: location ID
  - @return bool: 是否加载成功
  - functions:
    - 设置当前 location ID
    - 确保 root_node 存在（如果不存在，使用当前场景）
    - 如果没有 WorldMapScene，则创建一个
      - 加载场景资源（res://res/mods/WorldSceneManager/Scenes/GameScenes/WorldRootScene.tscn）
      - 如果场景资源不存在，创建新的 WorldMapScene 实例
      - 设置名称为"WorldMapScene"
      - 添加到 root_node
    - 调用 WorldMapScene.render_from_instance(location_id) 渲染地图
    - 打印加载信息

- spawn_player_at(player_instance_id:String, start_point:Dictionary) -> bool
  - @args:
    - player_instance_id: 玩家实例 ID
    - start_point: 起始点 {x, y}
  - @return bool: 是否生成成功
  - functions:
    - 检查 root_node 是否存在
    - 移除旧玩家节点（如果存在）
    - 从 EntityInstanceManager 获取玩家实例数据
    - 检查玩家实例数据是否有效
    - 获取玩家场景路径（scene_path）
    - 创建玩家节点
      - 如果 scene_path 为空，创建占位节点（Node2D）
      - 否则加载场景资源并实例化
    - 设置玩家位置
    - 挂载到 root_node
    - 打印生成信息

- update(delta:float) -> void
  - @args:
    - delta: 时间增量
  - functions:
    - 世界更新（TODO: 摄像机跟随、单位动画更新等）

# 数据文件

- 无直接依赖的数据文件
- 场景资源：res://res/mods/WorldSceneManager/Scenes/GameScenes/WorldRootScene.tscn

# 模块交互

## 调用的其他模块
- EntityInstanceManager: get_entity() 获取玩家实例数据
- ModEventListenerFilter: 事件监听过滤

## 被其他模块调用
- GameManager: 调用 load_scene_for_location() 加载世界场景
- DefaultGameScene: 调用 set_root_node() 设置根节点
- MudEntityInteractionSystem: 调用 spawn_player_at() 生成玩家

## 发送的事件
- 无

# 核心流程

## 场景加载流程
1. GameManager 调用 WorldSceneManager.load_scene_for_location(location_id)
2. 设置当前 location ID
3. 检查 root_node 是否存在，如果不存在使用当前场景
4. 检查 WorldMapScene 是否存在
   - 如果不存在，加载场景资源或创建新实例
   - 设置名称并添加到 root_node
5. 调用 WorldMapScene.render_from_instance(location_id) 渲染地图
6. 打印加载信息

## 玩家生成流程
1. 调用 spawn_player_at(player_instance_id, start_point)
2. 检查 root_node 是否存在
3. 移除旧玩家节点（如果存在）
4. 从 EntityInstanceManager 获取玩家实例数据
5. 检查玩家实例数据是否有效
6. 获取玩家场景路径
7. 创建玩家节点
   - 如果 scene_path 为空，创建占位节点
   - 否则加载场景资源并实例化
8. 设置玩家位置（从 start_point 获取 x, y 坐标）
9. 挂载到 root_node
10. 打印生成信息

## 世界更新流程
1. 每帧调用 update(delta)
2. TODO: 实现摄像机跟随逻辑
3. TODO: 实现单位动画更新逻辑
4. TODO: 实现其他世界更新逻辑

# 架构设计

## 职责分离
- WorldSceneManager: 协调层，负责场景管理和玩家生成
- WorldMapScene: 渲染层，负责地图渲染细节
- WorldMapInstanceManager: 玩法层，负责地图玩法逻辑

## 单例模式
- WorldMapScene 只创建一次，后续复用
- 玩家节点在生成新玩家时替换旧节点

## 可视化层设计
- 持有一个 WorldMapScene 实例
- 当 location 改变时，调用 render_from_instance() 重新渲染
- 管理玩家节点的生成和销毁
- 不负责具体的地图渲染逻辑（由 WorldMapScene 负责）
