# mod.WorldSceneManager.Scripts.Core.MapMudCell.gd 分析文档

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
MapMudCell

## 模块路径
res/mods/WorldSceneManager/Scripts/Core/MapMudCell.gd

## 模块功能
地图单元格显示组件，用于在世界地图上显示实体图标和旗帜标记。主要职责包括:
1. 显示实体图标 (TextureRect)
2. 显示旗帜图标 (TextureRect)
3. 管理 InfoLayer 和 MapTag 层
4. 支持图标位置偏移

## 模块依赖
- 无外部依赖

## 场景结构
```
MapMudCell (Node2D)
├── InfoLayer (Node2D) - 信息层
│   └── MapUnit (Node2D) - 实体单元
│       └── Icon (TextureRect) - 实体图标
└── MapTag (Node2D) - 标记层
    └── Icon (TextureRect) - 旗帜图标
```

## 模块用例

```gdscript
# 示例 1：创建 MapMudCell 实例
var map_cell = MapMudCell.new()

# 示例 2：设置实体图标
map_cell.set_entity_icon("res://mods/MyMod/Sprites/WorldMap/Icon/human.png")

# 示例 3：设置旗帜图标
var offset = Vector2(10, -10)
map_cell.set_flag_icon("res://mods/MyMod/Sprites/WorldMap/Icon/flag.png", offset)

# 示例 4：实例化 MapMudCell 场景
var map_cell_scene = load("res://res/mods/WorldSceneManager/Scenes/GameScenes/MapMudCell.tscn")
var map_cell = map_cell_scene.instantiate()
map_cell.position = Vector2(100, 100)
EntityLayer.add_child(map_cell)

# 示例 5：从缓存池获取 MapMudCell
var map_cell = CachePoolManager.get_cached("res://res/mods/WorldSceneManager/Scenes/GameScenes/MapMudCell.tscn")
```

# 成员变量

## 节点引用 (@onready)
- @onready var InfoLayer: Node2D
  - 信息层节点
  - 包含实体单元和图标

- @onready var MapUnit: Node2D
  - 实体单元节点
  - InfoLayer 的子节点

- @onready var UnitIcon: TextureRect
  - 实体图标
  - MapUnit 的子节点
  - 显示实体类型的图标

- @onready var MapTag: Node2D
  - 标记层节点
  - 包含旗帜图标

- @onready var TagIcon: TextureRect
  - 旗帜图标
  - MapTag 的子节点
  - 显示特殊标记 (如任务点、兴趣点等)

# 成员方法

## 图标设置方法

- set_entity_icon(path: String) -> void
  - @args:
    - path: 图标资源路径
  - functions:
    - 检查资源是否存在 (ResourceLoader.exists)
    - 如果存在:
      - 加载资源 (ResourceLoader.load)
      - 检查是否为 Texture2D 类型
      - 设置 UnitIcon.texture
    - 如果不存在:
      - 打印警告信息
      - 格式：[MapMudCell] entity icon not found: {path}

- set_flag_icon(path: String, offset: Vector2) -> void
  - @args:
    - path: 旗帜图标资源路径
    - offset: 图标偏移量
  - functions:
    - 检查资源是否存在 (ResourceLoader.exists)
    - 如果存在:
      - 加载资源 (ResourceLoader.load)
      - 检查是否为 Texture2D 类型
      - 设置 TagIcon.texture
      - 设置 TagIcon.position = offset
    - 如果不存在:
      - 打印警告信息
      - 格式：[MapMudCell] flag icon not found: {path}

# 数据文件

- 实体图标资源
  - 路径格式：{mod_root_path}/Sprites/WorldMap/Icon/{entity_type}.png
  - 例如：res://mods/MyMod/Sprites/WorldMap/Icon/human.png

- 旗帜图标资源
  - 路径格式：{mod_root_path}/Sprites/WorldMap/Icon/{flag_type}.png
  - 例如：res://mods/MyMod/Sprites/WorldMap/Icon/quest.png

# 模块交互

## 调用的其他模块
- 无

## 被其他模块调用
- WorldMapScene: _render_entity(), _render_flag()
- CachePoolManager: 缓存 MapMudCell 实例

## 发送的事件
- 无

# 核心流程

## 设置实体图标流程
```
1. 接收图标路径 path
2. 检查资源是否存在
   - ResourceLoader.exists(path)
3. 如果存在:
   a. 加载资源
      - ResourceLoader.load(path)
   b. 检查类型是否为 Texture2D
   c. 设置 UnitIcon.texture = tex
4. 如果不存在:
   a. 打印警告
   b. 格式：[MapMudCell] entity icon not found: {path}
```

## 设置旗帜图标流程
```
1. 接收图标路径 path 和偏移 offset
2. 检查资源是否存在
   - ResourceLoader.exists(path)
3. 如果存在:
   a. 加载资源
      - ResourceLoader.load(path)
   b. 检查类型是否为 Texture2D
   c. 设置 TagIcon.texture = tex
   d. 设置 TagIcon.position = offset
4. 如果不存在:
   a. 打印警告
   b. 格式：[MapMudCell] flag icon not found: {path}
```

## 实例化流程 (由 WorldMapScene 调用)
```
1. 从 CachePoolManager 获取缓存
   - CachePoolManager.get_cached(map_mud_cell_path)
2. 如果缓存中没有:
   a. 检查 MudCellScene 是否已加载
   b. 如果已加载:
      - MudCellScene.instantiate()
   c. 如果未加载:
      - 直接加载场景资源
      - load(map_mud_cell_path)
      - scene.instantiate()
3. 设置位置
   - map_cell.position = tilemap.map_to_local(pos_vec)
4. 添加到 EntityLayer
   - EntityLayer.add_child(map_cell)
5. 保存到 _cells 字典
   - _cells[pos] = map_cell
```

# 架构设计

## 分层设计
- InfoLayer: 信息层
  - 显示实体相关信息
  - 包含实体图标
- MapTag: 标记层
  - 显示特殊标记
  - 包含旗帜图标

## 节点结构
- 使用 Node2D 作为根节点
  - 便于位置变换
  - 支持旋转和缩放
- 使用 TextureRect 显示图标
  - 自动适配纹理大小
  - 支持锚点和对齐

## 资源加载策略
- 延迟加载：使用时才加载资源
- 错误处理：资源不存在时打印警告
- 类型检查：确保加载的是 Texture2D

## 缓存策略
- 由 CachePoolManager 管理
- 避免重复实例化
- 提高性能

# 使用场景

## 1. 实体显示
- 玩家实体
- NPC 实体
- 怪物实体
- 物品实体

## 2. 标记显示
- 任务点
- 兴趣点
- 传送点
- 危险区域

## 3. 建筑显示
- 商店
- 任务中心
- 训练中心
- 家园

# TODO

- [ ] 添加动画支持
  - [ ] 实体动画
  - [ ] 旗帜飘动动画

- [ ] 添加交互功能
  - [ ] 点击事件
  - [ ] 悬停提示

- [ ] 优化性能
  - [ ] 对象池
  - [ ] 批量渲染

- [ ] 添加更多显示元素
  - [ ] 血条
  - [ ] 名称标签
  - [ ] 状态图标
