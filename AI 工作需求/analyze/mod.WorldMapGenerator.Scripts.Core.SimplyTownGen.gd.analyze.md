# mod.WorldMapGenerator.Scripts.Core.SimplyTownGen.gd 分析文档

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
SimplyTownGen

## 模块路径
res/mods/WorldMapGenerator/Scripts/Core/SimplyTownGen.gd

## 模块功能
简化城镇生成器，基于节点图和 A* 算法的程序化城镇生成系统。实现了完整的城镇生成流程，包括:
1. 生成城镇节点图 (中心、建筑、道路)
2. 支持多种城镇形状 (圆形、矩形、放射网状)
3. 使用 A* 算法生成节点间路径
4. 根据道路等级生成不同宽度的道路
5. 生成郊外区域和城镇大门
6. 转换为二维网格数组
7. 道路等级判定和渲染映射

## 模块依赖
- RandomNumberGenerator: 随机数生成
- 数学函数：sqrt, cos, sin, ceil, min, max, abs

## 节点类型定义
```gdscript
enum TownNodeType {
    EMPTY,          # 空白
    CENTER,         # 城镇中心
    BUILDING,       # 建筑
    ROAD,           # 城内道路
    OUTSKIRT,       # 郊外区域
    PATH,           # A* 生成的道路格子
    BLOCKED,        # 不可通行 (障碍)
    OUTSKIRT_ROAD,  # 郊外道路
    GATE,           # 城镇大门
}
```

## 道路等级定义
```gdscript
道路等级基于节点评分 (road_score):
- MAIN (主干道): road_score >= 2 的节点连接，宽度 5
- SECONDARY (次干道): 一端 road_score >= 2，宽度 3
- OUTSKIRT (郊外道路): 郊外区域连接，宽度 3
- LOCAL (普通道路): 其他道路，宽度 2
```

## 数据结构

### TownNode (城镇节点)
```gdscript
class TownNode:
    var id: int                    # 节点唯一标识
    var node_type: int             # 节点类型 (TownNodeType)
    var name: String               # 节点名称
    var pos: Vector2               # 节点位置
    var neighbors: Array[int]      # 邻居节点 ID 列表
```

### SimplyTownData (城镇数据)
```gdscript
class SimplyTownData:
    var nodes: Array[TownNode]     # 所有节点列表
    var center_id: int             # 中心节点 ID
```

## 模块用例

```gdscript
# 示例 1：生成圆形城镇
var data = SimplyTownGen.generate_town(
    SimplyTownGen.TownShapeType.CIRCLE,
    8,    # 建筑数量
    3,    # 分支数量
    12345 # 随机种子
)

# 示例 2：生成矩形城镇
var rect_data = SimplyTownGen.generate_town(
    SimplyTownGen.TownShapeType.RECTANGLE,
    10,
    0,
    54321
)

# 示例 3：生成放射网状城镇
var radial_data = SimplyTownGen.generate_town(
    SimplyTownGen.TownShapeType.RADIAL_NET,
    12,
    4,    # 4 个分支
    99999
)

# 示例 4：转换为二维网格
var grid = SimplyTownGen.to_grid(data, 1.0)

# 示例 5：转换为带路径的二维网格
var grid_with_paths = SimplyTownGen.to_grid_with_paths(data, 1.0)

# 示例 6：转换为颜色网格
var color_grid = SimplyTownGen.to_color_grid_with_paths(data, 1.0)

# 示例 7：获取节点类型渲染信息
var render_info = SimplyTownGen.NODE_RENDER_MAP[SimplyTownGen.TownNodeType.ROAD]
print(render_info["color"])  # 输出：Color(1.0, 0.6, 0.0, 1.0)
print(render_info["road_score"])  # 输出：1

# 示例 8：判定道路等级
var node = data.get_node(1)
var road_type = SimplyTownGen._classify_road_between(node, data.get_node(2))
print(road_type)  # 输出："MAIN", "SECONDARY", "LOCAL", 或 "OUTSKIRT"
```

# 成员变量

## 静态常量

- static var NODE_RENDER_MAP: Dictionary
  - 节点类型渲染映射表
  - 包含每种类型的 value, color, road_score
  - 用于可视化和道路等级判定

## 枚举类型

- enum TownNodeType
  - 定义所有节点类型
  - 用于区分不同功能的节点

- enum TownShapeType
  - 定义城镇形状类型
  - CIRCLE: 圆形城镇
  - RECTANGLE: 矩形城镇
  - RADIAL_NET: 放射网状城镇

# 成员方法

## 主入口方法

- static func generate_town(shape_type, building_count: int = 8, branch_count: int = 3, seed: int = 12345) -> SimplyTownData
  - @args:
    - shape_type: 城镇形状类型 (TownShapeType)
    - building_count: 建筑数量，默认 8
    - branch_count: 分支数量 (放射状用),默认 3
    - seed: 随机种子，默认 12345
  - @return SimplyTownData: 生成的城镇数据
  - functions:
    - 1. 初始化随机数生成器
    - 2. 如果 shape_type 不是 int，随机生成
    - 3. 确保 branch_count >= 2
    - 4. 创建 SimplyTownData 实例
    - 5. 创建中心节点 (id=0, type=CENTER, pos=(0,0))
    - 6. 根据形状类型调用对应生成函数:
       - CIRCLE: _generate_circle_town()
       - RECTANGLE: _generate_rectangle_town()
       - RADIAL_NET: _generate_radial_net_town()
    - 7. 生成郊外区域 (_generate_outskirts())
    - 8. 返回城镇数据

## 城镇生成方法

### 圆形城镇生成

- static func _generate_circle_town(data, rng, start_id, building_count) -> int
  - @args:
    - data: 城镇数据
    - rng: 随机数生成器
    - start_id: 起始节点 ID
    - building_count: 建筑数量
  - @return int: 下一个可用节点 ID
  - functions:
    - 1. 设置半径 radius=10.0, 道路半径 road_radius=5.0
    - 2. 遍历 building_count 次:
       - 计算角度 t = TAU * i / building_count
       - 计算建筑位置：bx = cos(t)*radius, by = sin(t)*radius
       - 计算道路位置：rx = cos(t)*road_radius, ry = sin(t)*road_radius
       - 创建道路节点 (id, ROAD, (rx,ry))
       - 创建建筑节点 (id+1, BUILDING, (bx,by))
       - 连接：中心→道路→建筑
    - 3. 返回下一个 ID

### 矩形城镇生成

- static func _generate_rectangle_town(data, rng, start_id, building_count) -> int
  - @args:
    - data: 城镇数据
    - rng: 随机数生成器
    - start_id: 起始节点 ID
    - building_count: 建筑数量
  - @return int: 下一个可用节点 ID
  - functions:
    - 1. 计算行列数：cols=sqrt(building_count), rows=building_count/cols
    - 2. 设置间距 spacing=6.0
    - 3. 遍历 rows*cols 网格:
       - 计算建筑位置：bx = (x-cols*0.5+0.5)*spacing
       - 计算道路位置：lerp(center.pos, 40%)
       - 创建道路节点和建筑节点
       - 连接：中心→道路→建筑
    - 4. 返回下一个 ID

### 放射网状城镇生成

- static func _generate_radial_net_town(data, rng, start_id, building_count, branch_count) -> int
  - @args:
    - data: 城镇数据
    - rng: 随机数生成器
    - start_id: 起始节点 ID
    - building_count: 建筑数量
    - branch_count: 分支数量
  - @return int: 下一个可用节点 ID
  - functions:
    - 1. 确保 branch_count >= 2
    - 2. 计算每个分支的建筑数：buildings_per_branch
    - 3. 遍历 branch_count 个分支:
       - 计算分支角度：angle = TAU * branch / branch_count
       - 计算分支长度：branch_len = 12.0 + random(-2.0, 4.0)
       - 遍历分支上的建筑:
         * 计算道路位置 (沿角度方向)
         * 计算建筑位置 (带偏移)
         * 创建道路节点和建筑节点
         * 连接：上一个节点→道路→建筑
    - 4. 返回下一个 ID

### 郊外区域生成

- static func _generate_outskirts(data, rng, start_id) -> void
  - @args:
    - data: 城镇数据
    - rng: 随机数生成器
    - start_id: 起始节点 ID
  - functions:
    - 1. 收集所有道路节点 ID
    - 2. 如果没有道路节点，返回
    - 3. 计算出口数量：exit_count = road_ids.size()/3
    - 4. 打乱 road_ids
    - 5. 遍历 exit_count 个出口:
       - 获取道路节点
       - 计算从中心到道路的方向
       - 计算郊外位置：out_pos = road.pos + dir*8.0
       - 创建郊外节点 (OUTSKIRT)
       - 计算大门位置：lerp(road.pos, out_pos, 50%)
       - 创建大门节点 (GATE)
       - 连接：道路→大门→郊外
    - 6. 生成郊外区域和城镇大门

## 道路等级判定方法

- static func _road_score_for_node(n: TownNode) -> int
  - @args:
    - n: 城镇节点
  - @return int: 道路评分
  - functions:
    - 从 NODE_RENDER_MAP 获取 road_score
    - 如果没有，返回 0

- static func _classify_road_between(a: TownNode, b: TownNode) -> String
  - @args:
    - a: 节点 A
    - b: 节点 B
  - @return String: 道路等级 ("MAIN", "SECONDARY", "LOCAL", "OUTSKIRT")
  - functions:
    - 1. 检查是否是郊外连接 (GATE↔OUTSKIRT)
       - 是：返回 "OUTSKIRT"
    - 2. 获取两个节点的 road_score
    - 3. 判断重要性：score >= 2 为重要节点
    - 4. 判定道路等级:
       - 两端都重要：MAIN (主干道)
       - 一端重要：SECONDARY (次干道)
       - 都不重要：LOCAL (普通道路)
    - 5. 返回道路等级

- static func _path_width_for_road_type(road_type: String) -> int
  - @args:
    - road_type: 道路等级
  - @return int: 道路宽度
  - functions:
    - match road_type:
      - "MAIN": 5
      - "SECONDARY": 3
      - "OUTSKIRT": 3
      - "LOCAL": 2
      - 其他：2

- static func _connect_nodes(data, a_id, b_id) -> String
  - @args:
    - data: 城镇数据
    - a_id: 节点 A ID
    - b_id: 节点 B ID
  - @return String: 道路等级
  - functions:
    - 1. 检查 a_id == b_id，是则返回 "LOCAL"
    - 2. 获取节点 a 和 b
    - 3. 调用 _classify_road_between() 判定等级
    - 4. 互相添加到 neighbors 列表
    - 5. 返回道路等级

## A* 路径生成方法

- static func in_bounds(w, h, p: Vector2i) -> bool
  - @args:
    - w: 宽度
    - h: 高度
    - p: 坐标点
  - @return bool: 是否在边界内
  - functions:
    - 检查 p.x 和 p.y 是否在 [0, w) 和 [0, h) 范围内

- static func is_walkable(walkable, p: Vector2i) -> bool
  - @args:
    - walkable: 可通行掩码
    - p: 坐标点
  - @return bool: 是否可通行
  - functions:
    - 返回 walkable[p.x][p.y]

- static func _astar(start: Vector2i, goal: Vector2i, walkable: Array) -> Array
  - @args:
    - start: 起点坐标
    - goal: 终点坐标
    - walkable: 可通行掩码
  - @return Array: 路径坐标数组
  - functions:
    - 1. 初始化 open, closed, came_from 字典
    - 2. 初始化 g (实际代价) 和 f (估计总代价) 字典
    - 3. 将起点加入 open
    - 4. 主循环 (open 不为空):
       - 找到 f 值最小的节点 current
       - 如果 current == goal:
         * 回溯 came_from 构建路径
         * 反转路径
         * 返回路径
       - 将 current 从 open 移到 closed
       - 遍历四个方向的邻居:
         * 检查边界、可通行、是否在 closed
         * 计算 tentative_g = g[current] + 1
         * 如果更优，更新 came_from, g, f
         * 加入 open
    - 5. 如果找不到路径，返回空数组

- static func _write_path_with_width(grid, path: Array, width: int) -> void
  - @args:
    - grid: 网格数组
    - path: 路径坐标数组
    - width: 道路宽度
  - functions:
    - 1. 计算半径 r = width/2
    - 2. 遍历路径上的每个点 p:
       - 遍历以 p 为中心的 (2r+1)×(2r+1) 区域
       - 检查边界
       - 如果是 EMPTY，设置为 PATH
    - 3. 生成带宽度的道路

## 网格转换方法

- static func to_grid(data: SimplyTownData, cell_size: float = 1.0) -> Array
  - @args:
    - data: 城镇数据
    - cell_size: 单元格大小，默认 1.0
  - @return Array: 二维网格数组
  - functions:
    - 1. 如果节点为空，返回空数组
    - 2. 计算边界：min_x, max_x, min_y, max_y
    - 3. 计算网格大小：w, h
    - 4. 初始化网格，填充 EMPTY
    - 5. 遍历所有节点:
       - 计算网格坐标：gx, gy
       - 检查边界
       - 设置网格值 = NODE_RENDER_MAP[node_type]["value"]
    - 6. 返回网格

- static func to_grid_with_paths(data: SimplyTownData, cell_size: float = 1.0) -> Array
  - @args:
    - data: 城镇数据
    - cell_size: 单元格大小，默认 1.0
  - @return Array: 带路径的二维网格数组
  - functions:
    - 1. 调用 to_grid() 生成基础网格
    - 2. 生成可通行掩码 walkable_mask:
       - BUILDING 和 BLOCKED 不可通行
       - 其他可通行
    - 3. 创建节点坐标映射 node_pos:
       - 对每个节点，计算网格坐标
    - 4. 遍历所有节点的邻居:
       - 获取另一个节点
       - 调用 _classify_road_between() 判定等级
       - 调用 _path_width_for_road_type() 获取宽度
       - 调用 _astar() 生成路径
       - 调用 _write_path_with_width() 写入带宽度的 PATH
    - 5. 自动填补道路:
       - 遍历网格
       - 如果空格子上下左右都是 ROAD 或 PATH
       - 设置为 ROAD (填补空隙)
    - 6. 返回带路径的网格

- static func to_color_grid(data: SimplyTownData, cell_size: float = 1.0) -> Array
  - @args:
    - data: 城镇数据
    - cell_size: 单元格大小，默认 1.0
  - @return Array: 颜色网格数组
  - functions:
    - 1. 调用 to_grid() 生成基础网格
    - 2. 创建颜色网格
    - 3. 遍历网格:
       - 调用 _value_to_node_type() 转换为节点类型
       - 获取颜色：NODE_RENDER_MAP[node_type]["color"]
    - 4. 返回颜色网格

- static func to_color_grid_with_paths(data: SimplyTownData, cell_size: float = 1.0) -> Array
  - @args:
    - data: 城镇数据
    - cell_size: 单元格大小，默认 1.0
  - @return Array: 带路径的颜色网格数组
  - functions:
    - 1. 调用 to_grid_with_paths() 生成带路径网格
    - 2. 创建颜色网格
    - 3. 遍历网格:
       - 调用 _value_to_node_type() 转换
       - 获取颜色
    - 4. 返回颜色网格

## 辅助方法

- static func _value_to_node_type(val: int)
  - @args:
    - val: 网格值
  - @return: 节点类型
  - functions:
    - 遍历 NODE_RENDER_MAP
    - 找到 value 匹配的 key
    - 返回节点类型，找不到返回 "EMPTY"

- static func _min_x(data) -> float
  - @args:
    - data: 城镇数据
  - @return float: 最小 x 坐标
  - functions:
    - 遍历所有节点，返回最小 pos.x

- static func _max_x(data) -> float
  - @args:
    - data: 城镇数据
  - @return float: 最大 x 坐标
  - functions:
    - 遍历所有节点，返回最大 pos.x

- static func _min_y(data) -> float
  - @args:
    - data: 城镇数据
  - @return float: 最小 y 坐标
  - functions:
    - 遍历所有节点，返回最小 pos.y

- static func _max_y(data) -> float
  - @args:
    - data: 城镇数据
  - @return float: 最大 y 坐标
  - functions:
    - 遍历所有节点，返回最大 pos.y

# 数据文件

- 无直接依赖的数据文件

# 模块交互

## 调用的其他模块
- 无

## 被其他模块调用
- WorldMapGenerator: generate_town() 生成城镇

## 发送的事件
- 无

# 核心流程

## 完整城镇生成流程

### 阶段 1：初始化
```
1. 初始化随机数生成器 (seed)
2. 确定城镇形状类型
3. 创建 SimplyTownData 实例
4. 创建中心节点:
   - id = 0
   - type = CENTER
   - pos = (0, 0)
   - name = "TownCore"
5. 设置 center_id = 0
6. next_id = 1
```

### 阶段 2：生成城镇内部结构
```
根据形状类型选择生成策略:

圆形城镇:
1. 设置半径 radius=10.0, 道路半径=5.0
2. 等角度分布 building_count 个建筑
3. 每个建筑:
   - 计算角度 t = TAU * i / building_count
   - 计算建筑位置 (cos(t)*radius, sin(t)*radius)
   - 计算道路位置 (cos(t)*road_radius, sin(t)*road_radius)
   - 创建道路节点和建筑节点
   - 连接：中心→道路→建筑

矩形城镇:
1. 计算行列数：cols=sqrt(count), rows=count/cols
2. 设置间距 spacing=6.0
3. 遍历网格:
   - 计算建筑位置
   - 计算道路位置 (lerp 40%)
   - 创建道路节点和建筑节点
   - 连接：中心→道路→建筑

放射网状城镇:
1. 确保 branch_count >= 2
2. 计算每个分支的建筑数
3. 遍历每个分支:
   - 计算分支角度
   - 计算分支长度 (随机)
   - 沿分支生成建筑和道路
   - 连接：上一个→道路→建筑
```

### 阶段 3：生成郊外区域
```
1. 收集所有道路节点 ID
2. 计算出口数量：size/3
3. 打乱 road_ids
4. 遍历出口:
   a. 获取道路节点
   b. 计算从中心到道路的方向
   c. 计算郊外位置：road.pos + dir*8.0
   d. 创建郊外节点 (OUTSKIRT)
   e. 计算大门位置：lerp(50%)
   f. 创建大门节点 (GATE)
   g. 连接：道路→大门→郊外
```

### 阶段 4：转换为网格
```
1. 调用 to_grid() 生成基础网格:
   - 计算边界
   - 初始化网格 (填充 EMPTY)
   - 遍历节点，设置网格值

2. 调用 to_grid_with_paths() 添加路径:
   a. 生成可通行掩码:
      - BUILDING 和 BLOCKED 不可通行
   b. 创建节点坐标映射
   c. 遍历所有连接:
      - 判定道路等级
      - 获取道路宽度
      - 调用 A* 生成路径
      - 写入带宽度的 PATH
   d. 自动填补空隙:
      - 检查上下左右
      - 如果都是道路，填充为 ROAD
```

## A* 路径生成算法详解

### 算法原理
```
f(n) = g(n) + h(n)
- g(n): 从起点到 n 的实际代价
- h(n): 从 n 到终点的估计代价 (直线距离)
- f(n): 总估计代价
```

### 执行流程
```
初始化:
1. open = {start}, closed = {}
2. g[start] = 0
3. f[start] = distance(start, goal)

主循环:
1. 从 open 中找到 f 值最小的节点 current
2. 如果 current == goal:
   - 回溯 came_from 构建路径
   - 返回路径
3. 将 current 从 open 移到 closed
4. 遍历 current 的四个邻居:
   - 检查边界
   - 检查可通行
   - 检查不在 closed
   - 计算 tentative_g = g[current] + 1
   - 如果更优:
     * came_from[neighbor] = current
     * g[neighbor] = tentative_g
     * f[neighbor] = tentative_g + distance(neighbor, goal)
     * open[neighbor] = true
5. 如果 open 为空，返回空路径
```

## 道路等级判定流程

### 判定规则
```
1. 检查郊外连接:
   - GATE↔OUTSKIRT: OUTSKIRT

2. 获取节点评分:
   - CENTER: 3 (非常重要)
   - GATE: 3 (重要)
   - BUILDING: 2 (一般重要)
   - ROAD/PATH: 1 (普通)
   - 其他：0

3. 判定等级:
   - 两端 score >= 2: MAIN (主干道)
   - 一端 score >= 2: SECONDARY (次干道)
   - 都 < 2: LOCAL (普通道路)
```

### 宽度映射
```
- MAIN: 5 格宽
- SECONDARY: 3 格宽
- OUTSKIRT: 3 格宽
- LOCAL: 2 格宽
```

## 道路填补算法

### 填补规则
```
遍历网格中的每个空格子:
1. 检查上下左右四个邻居
2. 如果四个邻居都是 ROAD 或 PATH:
   - 设置为 ROAD
3. 目的：填补道路间的空隙，使道路连通
```

# 架构设计

## 节点图架构
- 使用图论数据结构
- 节点：TownNode (包含位置、类型、邻居)
- 边：neighbors 数组 (无向图)
- 中心辐射结构：所有节点连接到中心

## 分层生成策略
1. 第一层：城镇内部 (中心、建筑、道路)
2. 第二层：郊外区域 (OUTSKIRT)
3. 第三层：连接结构 (GATE)
4. 第四层：路径生成 (A* 算法)
5. 第五层：道路填补 (连通性优化)

## 道路等级系统
- 基于节点重要性评分
- 自动判定道路等级
- 不同等级不同宽度
- 主干道连接重要节点

## A* 路径优化
- 使用启发式搜索
- 保证找到最短路径
- 支持带宽度的道路
- 避免穿过建筑

## 网格转换策略
- 支持多种输出格式
- 基础网格 (节点)
- 带路径网格 (A* 生成)
- 颜色网格 (可视化)

## 性能优化

### 1. 随机性控制
- 使用种子确保可重复
- 分支长度随机
- 建筑位置微调

### 2. 路径生成优化
- 只在可通行区域搜索
- 使用字典存储 open/closed
- 提前终止 (找到目标)

### 3. 网格填充优化
- 只遍历一次节点
- 批量写入路径
- 自动填补空隙

## 可扩展性

### 添加新形状
```gdscript
enum TownShapeType {
    CIRCLE,
    RECTANGLE,
    RADIAL_NET,
    NEW_SHAPE,  # 添加新形状
}

static func generate_town(...):
    match shape_type:
        # ...
        NEW_SHAPE:
            next_id = _generate_new_shape(...)
```

### 添加新节点类型
```gdscript
enum TownNodeType {
    # ...
    NEW_TYPE,  # 添加新类型
}

static var NODE_RENDER_MAP = {
    # ...
    NEW_TYPE: {
        "value": 9,
        "color": Color(...),
        "road_score": 1
    }
}
```

### 自定义道路宽度
```gdscript
static func _path_width_for_road_type(road_type: String) -> int:
    match road_type:
        "MAIN": return custom_main_width
        "SECONDARY": return custom_secondary_width
        # ...
```

# 使用场景

## 1. 程序化城镇生成
- 随机生成城镇布局
- 支持多种风格
- 确保道路连通

## 2. 游戏地图设计
- 快速原型设计
- 自动生成测试地图
- 可重复生成

## 3. 可视化展示
- 颜色网格渲染
- 道路等级可视化
- 节点图展示

## 4. 路径规划
- A* 算法基础
- 带宽度的路径
- 避开障碍

# TODO

- [ ] 添加更多城镇形状
  - [ ] 线性城镇 (沿河流/道路)
  - [ ] 多中心城镇
  - [ ] 不规则形状

- [ ] 优化 A* 性能
  - [ ] 使用优先队列
  - [ ] 双向搜索
  - [ ] JPS (Jump Point Search)

- [ ] 添加地标建筑
  - [ ] 城堡/市政厅
  - [ ] 市场广场
  - [ ] 神庙/教堂

- [ ] 支持多层城镇
  - [ ] 立体交通
  - [ ] 地下通道
  - [ ] 高架桥

- [ ] 添加装饰元素
  - [ ] 树木/花园
  - [ ] 喷泉/水池
  - [ ] 路灯/长椅

- [ ] 优化道路网络
  - [ ] 环形道路
  - [ ] 停车场
  - [ ] 交通节点

- [ ] 添加区域划分
  - [ ] 住宅区
  - [ ] 商业区
  - [ ] 工业区
