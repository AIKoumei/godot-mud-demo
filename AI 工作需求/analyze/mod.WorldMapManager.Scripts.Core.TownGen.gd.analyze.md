# mod.WorldMapManager.Scripts.Core.TownGen.gd 分析文档

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
TownGen

## 模块路径
res/mods/WorldMapManager/Scripts/Core/TownGen.gd

## 模块功能
城镇生成系统，基于 Simplex 噪声的程序化城镇生成。实现了完整的管线化生成流程，包括:
1. 生成城镇基础轮廓 (使用 Simplex 噪声偏移)
2. 确定城镇中心
3. 生成主干道与城门
4. 生成城墙
5. 生成区块与次级道路
6. 边缘合法性校验
7. 生成最终数据结构

## 模块依赖
- SimplexNoise: Simplex 噪声生成
- 数学函数：sqrt, ceil, abs

## 配置结构
```json
{
  "size": "MEDIUM",  // SMALL/MEDIUM/LARGE
  "shape": "CIRCLE", // CIRCLE/RECTANGLE
  "seed": 12345,
  "width": 20,
  "height": 20,
  "irregularity_strength": 12.0,
  "irregularity_length": 6.0
}
```

## 节点颜色定义
```gdscript
NODE_COLOR = {
  "mask": [70, 70, 70],      # 基础轮廓
  "edge": [90, 90, 90],      # 边缘
  "wall": [170, 120, 100],   # 城墙
  "gate": [150, 150, 200],   # 城门
  "gate_wall": [100, 100, 150], # 城门城墙
  "primary_road": [180, 180, 180], # 主干道
  "secondary_road": [200, 200, 200], # 次级道路
  "block": [120, 120, 120],  # 区块
  "center": [255, 0, 0],     # 中心
  "empty": [255, 255, 255]   # 空白
}
```

## 输出数据结构
```json
{
  "metadata": {
    "version": "1.0.2",
    "generated_at": "2023-12-31 12:00:00",
    "config": {...},
    "size": [width, height]
  },
  "data": {
    "mask": ["x,y", ...],
    "edges": ["x,y", ...],
    "center": [x, y],
    "nodes": ["x,y", ...],
    "blocks": {
      "1": {"size": [5,5], "position": [x,y], "nodes": ["x,y",...]}
    },
    "primary_road": ["x,y", ...],
    "secondary_roads": ["x,y", ...],
    "walls": ["x,y", ...],
    "gates": ["x,y", ...],
    "gate_walls": ["x,y", ...],
    "all_walls": ["x,y", ...],
    "total_nodes": {
      "x,y": {"type": "road|wall|gate|block|center"}
    }
  }
}
```

## 模块用例

```gdscript
# 示例 1：生成城镇配置
var config = TownGen.gen_config("MEDIUM", "CIRCLE", 12345)

# 示例 2：创建城镇生成器并运行
var town_gen = TownGen.new(config)
var town_data = town_gen.run()

# 示例 3：生成小型矩形城镇
var small_config = TownGen.gen_config("SMALL", "RECTANGLE", 54321)
var small_town = TownGen.new(small_config).run()

# 示例 4：生成大型城镇
var large_config = TownGen.gen_config("LARGE", "CIRCLE", 99999)
var large_town = TownGen.new(large_config).run()

# 示例 5：获取辅助函数
var points = TownGen.get_points_between(0, 0, 10, 10)
var distance = TownGen.distance_to_center(5, 5, 10, 10)
var hex_color = TownGen.rgb_to_hex([255, 0, 0])
```

# 成员变量

- config: Dictionary
  - 城镇配置
  - 包含 size, shape, seed, width, height 等

- seed: int
  - 随机种子

- rng: RandomNumberGenerator
  - 随机数生成器

- noise: SimplexNoise
  - Simplex 噪声实例

- steps: Array
  - 生成步骤记录

# 成员方法

## 辅助函数 (static)

- get_points_between(start_x:int, start_y:int, end_x:int, end_y:int) -> Array
  - @args:
    - start_x, start_y: 起点坐标
    - end_x, end_y: 终点坐标
  - @return Array: 两点之间的所有整数坐标点
  - functions:
    - 使用 Bresenham 直线算法
    - 包含起点，不包含终点
    - 返回坐标点列表 ("x,y")

- distance_to_center(x:int, y:int, center_x:int, center_y:int) -> float
  - @args:
    - x, y: 点坐标
    - center_x, center_y: 中心坐标
  - @return float: 欧几里得距离
  - functions:
    - 计算点到中心的距离
    - 返回 sqrt((x-center_x)^2 + (y-center_y)^2)

- rgb_to_hex(rgb:Array) -> String
  - @args:
    - rgb: [r, g, b] 数组
  - @return String: hex 颜色字符串
  - functions:
    - 将 RGB 转换为十六进制格式
    - 返回 "#RRGGBBff"

- deduplicate_array(array:Array) -> Array
  - @args:
    - array: 要去除重复的数组
  - @return Array: 去重后的数组
  - functions:
    - 使用字典作为集合
    - 返回唯一元素列表

- gen_config(size, shape, seed) -> Dictionary
  - @args:
    - size: 城镇尺寸 (SMALL/MEDIUM/LARGE)
    - shape: 城镇形状 (CIRCLE/RECTANGLE)
    - seed: 随机种子
  - @return Dictionary: 配置字典
  - functions:
    - 根据尺寸确定宽高范围
      - SMALL: 12-16
      - MEDIUM: 16-22
      - LARGE: 22-30
    - 生成不规则强度和长度
    - 返回完整配置

## 构造函数

- _init(config:Dictionary)
  - @args:
    - config: 配置字典
  - functions:
    - 保存配置
    - 初始化随机数生成器
    - 创建 SimplexNoise 实例
    - 初始化 steps 数组

## 主流程方法

- run() -> Dictionary
  - @return Dictionary: 最终生成数据
  - functions:
    - 步骤 1: 生成基础轮廓 (step_1_generate_mask)
    - 步骤 2: 确定城镇中心 (step_2_determine_center)
    - 步骤 3: 生成主干道与城门 (step_3_generate_roads)
    - 步骤 4.1: 重新检查边缘 (step_4_1_recheck_edges)
    - 步骤 4.2: 验证边缘合法性 (validate_edge_connectivity)
    - 步骤 4: 生成城墙 (step_4_generate_walls)
    - 步骤 5: 生成区块与次级道路 (step_5_generate_blocks)
    - 生成最终数据 (generate_final_data)
    - 返回完整数据

## 步骤 1: 生成基础轮廓

- step_1_generate_mask() -> Dictionary
  - @return Dictionary: 包含 mask, edges, width, height
  - functions:
    - 1. 生成原始 mask (无噪声):
      - CIRCLE: 距离中心 <= 最大半径
      - RECTANGLE: 在边界内
    - 2. 对原始 mask 做完整的 edge 标记:
      - 检查九宫格内是否有无效节点
      - 有则标记为 edge
    - 3. 对原始 edge 应用噪声偏移:
      - 使用多层噪声 (低频 + 中频 + 高频)
      - 叠加：0.5*noise1 + 0.3*noise2 + 0.2*noise3
      - 映射到 [-irregularity_length, irregularity_length]
      - 圆形：朝径向方向偏移
      - 矩形：朝垂直于边缘的方向偏移
    - 4. 处理偏移:
      - 获取原始点和偏移点之间的所有节点
      - 移除中间节点
      - 如果向外偏移，添加中间节点到 mask
    - 5. 重新检测 edge:
      - 移除所有现有 edge
      - 对调整后的 mask 重新进行 edge 检测
    - 6. 移除只有一个邻居的 edge 节点:
      - 检查十字线方向 (上、下、左、右)
      - 使用 BFS 处理连锁反应
    - 7. 后处理 edge:
      - 标记必要节点 (横邻居或竖邻居为 2)
      - BFS 遍历，标记移除节点 (邻居为 3)
      - 移除非必要节点
    - 8. 去重并返回

## 步骤 2: 确定城镇中心

- step_2_determine_center(mask_data:Dictionary) -> Dictionary
  - @args:
    - mask_data: 包含 mask 的字典
  - @return Dictionary: 包含 center 的字典
  - functions:
    - 计算几何中心 (width/2, height/2)
    - 检查几何中心是否在 mask 内
    - 如果不在，找到离几何中心最近的有效点
    - 返回包含 center 的结果

## 步骤 3: 生成主干道与城门

- step_3_generate_roads(center_data:Dictionary) -> Dictionary
  - @args:
    - center_data: 包含 center 的字典
  - @return Dictionary: 包含 primary_road, gates, gate_walls
  - functions:
    - 从中心向四个方向生成主干道:
      - 上、下、左、右
    - 检查每个点:
      - 如果在 mask 内且不是 edge: 添加到主干道
      - 如果到达 edge:
        - 检查是否是最后一个轮廓
        - 是：作为城门，生成城门城墙
        - 否：作为触及点，继续前进
      - 如果超出 mask: 停止
    - 生成城门城墙:
      - 在城门垂直主干道的两个方向
      - 添加到 mask 和 edges
    - 返回主干道、城门、城门城墙

## 步骤 4: 生成城墙

- step_4_generate_walls(road_data:Dictionary) -> Dictionary
  - @args:
    - road_data: 包含 edges, gates, primary_road
  - @return Dictionary: 包含 walls, all_walls
  - functions:
    - 遍历所有 edges:
      - 避开城门
      - 避开城门城墙
      - 避开主干道
      - 检查九宫格内是否都是有效节点
        - 是：不作为城墙，从 edges 移除
        - 否：作为城墙
    - 合并城墙和城门城墙
    - 返回 walls 和 all_walls

## 步骤 4.1: 重新检查边缘

- step_4_1_recheck_edges(road_data:Dictionary) -> Dictionary
  - @args:
    - road_data: 包含 mask 和 edges
  - @return Dictionary: 更新后的 road_data
  - functions:
    - 构建 mask 集合
    - 重新检测 edge 节点:
      - 对每个 mask 节点
      - 检查九宫格内是否有无效节点
      - 有则标记为 edge
    - 更新 edges 列表

## 步骤 4.2: 验证边缘合法性

- validate_edge_connectivity(wall_data:Dictionary) -> void
  - @args:
    - wall_data: 包含 edges
  - functions:
    - 构建 edge 集合
    - 计算每个 edge 节点的邻居数量 (十字线方向)
    - 检查首尾节点数量:
      - 0 个：闭合环 (合法)
      - 2 个：开放路径 (合法)
      - 其他：不合法，打印错误

## 步骤 5: 生成区块与次级道路

- step_5_generate_blocks(wall_data:Dictionary) -> Dictionary
  - @args:
    - wall_data: 包含 walls, primary_road, gates
  - @return Dictionary: 包含 blocks, secondary_roads
  - functions:
    - 1. 先尝试在中心附近生成第一个 5x5 区块:
      - 扩大搜索范围 (5 格)
      - 如果找不到，尝试 4x4 或 3x3
    - 2. 循环生成区块，直到没有可用点:
      - 收集所有候选区块
      - 计算每个点作为不同大小区块起始点的最佳距离
      - 优先级：距离中心近 > 大区块 > 距离主干道近
      - 选择最佳候选
      - 生成区块
      - 在区块周边生成次级道路
    - 3. 后处理：检查次级道路连通性:
      - 找出所有连通组件
      - 检查是否与其他道路连通
      - 移除不连通的次级道路
      - 生成大小为 1 的后处理区块
    - 返回 blocks 和 secondary_roads

## 最终数据生成

- generate_final_data(block_data:Dictionary) -> Dictionary
  - @args:
    - block_data: 包含所有生成数据
  - @return Dictionary: 最终数据字典
  - functions:
    - 构建 metadata:
      - version: "1.0.2"
      - generated_at: 当前时间
      - config: 配置
      - size: [width, height]
    - 构建 data:
      - mask, edges, center, nodes
      - blocks, primary_road, secondary_roads
      - walls, gates, gate_walls, all_walls
    - 构建 total_nodes:
      - 标记每个节点的类型
      - mask, center, primary_road, secondary_road
      - wall, gate, gate_wall
    - 返回完整数据

# 数据文件

- 无直接依赖的数据文件

# 模块交互

## 调用的其他模块
- SimplexNoise: 生成噪声偏移
- RandomNumberGenerator: 随机数生成

## 被其他模块调用
- MudMapGenerator: generate_town() 生成城镇地图

## 发送的事件
- 无

# 核心流程

## 完整城镇生成流程 (7 步)

### 步骤 1: 生成基础轮廓
```
输入：config (size, shape, seed, irregularity)
输出：mask, edges

1. 生成原始 mask:
   - CIRCLE: 距离中心 <= max_radius
   - RECTANGLE: 在边界内

2. 标记原始 edges:
   - 检查九宫格邻居
   - 有无效邻居则标记为 edge

3. 应用噪声偏移:
   - 使用 3 层噪声 (0.05, 0.1, 0.15 频率)
   - 叠加：0.5*n1 + 0.3*n2 + 0.2*n3
   - 映射到 [-irregularity_length, irregularity_length]
   - 圆形：径向偏移
   - 矩形：垂直边缘偏移

4. 处理偏移:
   - Bresenham 算法获取中间点
   - 移除中间点
   - 向外偏移则添加中间点到 mask

5. 重新检测 edges:
   - 移除所有 edges
   - 重新九宫格检测

6. 移除单邻居 edge:
   - 检查十字线邻居
   - BFS 处理连锁反应

7. 后处理:
   - 找到起始节点 (横/竖邻居=2)
   - BFS 遍历
   - 标记必要节点 (邻居=2)
   - 标记移除节点 (邻居=3)
   - 移除非必要节点
```

### 步骤 2: 确定城镇中心
```
输入：mask
输出：center

1. 计算几何中心 (width/2, height/2)
2. 检查是否在 mask 内
3. 不在则找最近的 mask 点
```

### 步骤 3: 生成主干道与城门
```
输入：center, mask, edges
输出：primary_road, gates, gate_walls

for 方向 in [上，下，左，右]:
    从中心向外延伸:
        - 在 mask 内且非 edge: 添加到主干道
        - 到达 edge:
            - 检查下一个点是否在 mask 内
            - 不在：城门，生成城门城墙
            - 在：触及点，继续
        - 超出 mask: 停止

城门城墙生成:
    - 垂直主干道方向
    - 左右或上下各一个
```

### 步骤 4: 生成城墙
```
输入：edges, gates, primary_road
输出：walls, all_walls

遍历 edges:
    - 跳过城门
    - 跳过城门城墙
    - 跳过主干道
    - 检查九宫格:
        - 全有效：移除 edge
        - 有无效：作为城墙

合并 walls + gate_walls = all_walls
```

### 步骤 5: 生成区块与次级道路
```
输入：mask, center, primary_road, walls, gates
输出：blocks, secondary_roads

1. 生成第一个区块 (优先 5x5):
   - 从中心向外搜索
   - 检查区块有效性
   - 生成区块
   - 生成周边次级道路

2. 循环生成剩余区块:
   - 收集所有候选 (不同大小：5,4,3,2,1)
   - 计算优先级:
     * 距离中心距离 (负)
     * 区块大小
     * 距离主干道距离 (负)
   - 排序选择最佳
   - 生成区块
   - 生成次级道路
   - 从 occupied 移除

3. 后处理次级道路:
   - BFS 找连通组件
   - 检查是否连接主干道
   - 移除不连通的
   - 生成 1x1 后处理区块
```

## 边缘处理算法详解

### 噪声偏移算法
```gdscript
for edge_point in edges:
    # 多层噪声叠加
    noise1 = noise.noise2d(x, y, 0.05)  # 低频
    noise2 = noise.noise2d(x, y, 0.1)   # 中频
    noise3 = noise.noise2d(x, y, 0.15)  # 高频
    
    combined = noise1*0.5 + noise2*0.3 + noise3*0.2
    normalized = clamp(combined, -1, 1)
    offset = normalized * irregularity_length
    
    # 计算偏移方向
    if shape == CIRCLE:
        # 径向偏移
        dx = (x - center_x) / distance
        dy = (y - center_y) / distance
    else:
        # 垂直边缘偏移
        # 根据最近的边确定方向
    
    offset_x = x + dx * offset
    offset_y = y + dy * offset
```

### 边缘简化算法
```gdscript
# 步骤 1: 找到起始节点 (横邻居或竖邻居=2)
for edge in edges:
    h_neighbors = count_horizontal(edge)
    v_neighbors = count_vertical(edge)
    if h_neighbors == 2 or v_neighbors == 2:
        start_node = edge
        mark_essential(edge)
        break

# 步骤 2: BFS 遍历
queue = [start_node]
while queue:
    current = queue.pop()
    neighbors = get_cross_neighbors(current)
    
    if len(neighbors) == 3:
        # 十字路口，标记为移除
        mark_remove(current)
        mark_remove(neighbors)
    elif len(neighbors) == 2:
        # 直线，标记为必要
        mark_essential(current)
        mark_essential(neighbors)
        if neighbor was marked remove:
            unmark_remove(neighbor)
            queue.append(neighbor)

# 步骤 3: 移除非必要节点
for edge in edges:
    if not is_essential(edge):
        remove(edge)
```

## 区块生成优先级算法
```gdscript
# 优先级计算
for point in occupied:
    for block_size in [5, 4, 3, 2, 1]:
        if can_place_block(point, block_size):
            distance_to_center = calc_distance(point, center)
            distance_to_road = calc_min_distance(point, primary_road)
            
            priority = [
                -int(distance_to_center * 100),  # 越近优先级越高
                block_size,                       # 越大优先级越高
                -int(distance_to_road * 100)      # 越近优先级越高
            ]
            
            candidates.append([priority, ...])

# 排序选择最佳
candidates.sort_custom(compare_priority)
best = candidates[0]
```

# 架构设计

## 管线化架构
- 7 个主要步骤，每步接收上一步输出
- 步骤记录到 steps 数组
- 支持调试和可视化

## 数据结构设计

### 节点表示
- 使用 "x,y" 字符串表示坐标
- 便于字典键和集合操作

### 节点类型
- mask: 城镇区域
- edges: 边缘轮廓
- primary_road: 主干道
- secondary_road: 次级道路
- walls: 城墙
- gates: 城门
- blocks: 区块

## 算法设计原则

### 1. 噪声偏移
- 多层噪声叠加 (低频 + 中频 + 高频)
- 权重：0.5 + 0.3 + 0.2
- 产生自然的不规则边缘

### 2. 边缘简化
- 移除多余节点，保持轮廓简洁
- 保留必要节点 (直线连接)
- 移除十字路口节点

### 3. 区块生成
- 从中心向外扩散
- 优先大区块
- 优先靠近主干道
- 确保区块连通性

### 4. 道路系统
- 主干道：十字形，从中心到城门
- 次级道路：区块周边
- 确保所有道路连通

## 性能优化

### 1. 集合操作
- 使用字典作为集合
- O(1) 查找和删除

### 2. BFS 遍历
- 使用队列
- visited 标记避免重复

### 3. 优先级排序
- 自定义比较函数
- 多关键字排序

## 应用场景

### 1. 城镇地图
- 主世界城镇
- NPC 聚集点
- 商业中心

### 2. 程序化内容
- 随机城镇生成
- Roguelike 游戏
- 策略游戏

### 3. 可视化
- 2D 地图渲染
- 区块划分
- 道路网络

# TODO

- [ ] 添加更多建筑类型
- [ ] 支持多层城镇 (立体交通)
- [ ] 添加装饰元素 (树木、喷泉等)
- [ ] 支持特殊建筑 (城堡、教堂)
- [ ] 优化区块布局算法
- [ ] 添加城镇防御设施
