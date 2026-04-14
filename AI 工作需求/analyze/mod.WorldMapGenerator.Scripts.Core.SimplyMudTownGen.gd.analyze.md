# mod.WorldMapGenerator.Scripts.Core.SimplyMudTownGen.gd 分析文档

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
SimplyMudTownGen

## 模块路径
res/mods/WorldMapGenerator/Scripts/Core/SimplyMudTownGen.gd

## 模块功能
简化 MUD 城镇生成器，基于网格和噪声的程序化城镇生成系统。实现了完整的城镇生成流程，包括:
1. 生成城镇轮廓掩码 (使用 Simplex 噪声)
2. 扫描线连接确保轮廓闭合
3. 生成城墙和边缘
4. 生成主干道和城门
5. 修补城墙漏洞
6. 回路检测和剪枝
7. 智能生成区块和次级道路

## 模块依赖
- FastNoiseLite: Simplex 噪声生成
- RandomNumberGenerator: 随机数生成

## 节点类型定义
```gdscript
enum NodeType {
    CENTER,         # 城镇中心
    WALL,           # 城墙
    DEL_WALL,       # 删除的城墙
    START_WALL,     # 起始城墙
    END_WALL,       # 结束城墙
    PATCH_WALL,     # 修补的城墙
    MAIN_ROAD,      # 主干道
    SECONDARY_ROADS,# 次级道路
    GATE,           # 城门
    GATE_WALL,      # 城门城墙
}
```

## 数据结构

### TownNode (城镇节点)
```gdscript
class TownNode:
    var id: int           # 节点 ID
    var type: int         # 节点类型
    var pos: Vector2i     # 节点位置
```

### SimplyMudTownData (城镇数据)
```gdscript
class SimplyMudTownData:
    var nodes: Dictionary           # 所有节点
    var center: Vector2i            # 中心位置
    var start_wall: Vector2i        # 起始城墙
    var end_wall: Vector2i          # 结束城墙
    var mask: Dictionary            # 轮廓掩码
    var edge: Dictionary            # 边缘点
    var patched_edge: Dictionary    # 修补的边缘
    var delete_wall: Dictionary     # 删除的城墙
    var main_road: Dictionary       # 主干道
    var secondary_roads: Dictionary # 次级道路
    var gate: Dictionary            # 城门
    var gate_wall: Dictionary       # 城门城墙
    var blocks: Array               # 区块数组
```

## 模块用例

```gdscript
# 示例 1：生成配置
var cfg = SimplyMudTownGen.gen_config({
    "seed": 12345,
    "size_type": "MEDIUM",
    "shape_type": "CIRCLE"
})

# 示例 2：生成城镇
var data = SimplyMudTownGen.generate_town(cfg)

# 示例 3：转换为字典
var dict_data = data.to_dict()

# 示例 4：获取节点颜色
var color = SimplyMudTownGen.NODE_COLOR[SimplyMudTownGen.NodeType.WALL]
```

# 成员变量

- static var NODE_COLOR: Dictionary
  - 节点类型颜色映射
  - 用于可视化渲染

- static var noise: FastNoiseLite
  - Simplex 噪声生成器
  - 用于生成不规则轮廓

- static var dir4: Array
  - 四个方向向量
  - [(-1,0), (1,0), (0,-1), (0,1)]

# 成员方法

## 配置方法

- static func gen_config(override: Dictionary = {}) -> Dictionary
  - @args:
    - override: 覆盖配置
  - @return Dictionary: 生成的配置
  - functions:
    - 随机生成 size_type (SMALL/MEDIUM/LARGE)
    - 随机生成 shape_type (CIRCLE/RECT)
    - 随机生成 irregularity (0.0-0.6)
    - 随机生成 smoothness (0.0-1.0)
    - 应用 override 覆盖
    - 返回配置字典

## 主生成方法

- static func generate_town(cfg: Dictionary) -> SimplyMudTownData
  - @args:
    - cfg: 配置字典
  - @return SimplyMudTownData: 生成的城镇数据
  - functions:
    - 1. 初始化随机数生成器和噪声
    - 2. 生成城镇大小 (size)
    - 3. 生成轮廓掩码 (_generate_contour_mask)
    - 4. 扫描线连接 (_scanline_connect)
    - 5. 选择中心 (_pick_center)
    - 6. 查找边缘点 (_find_edge_points)
    - 7. 生成主干道 (generate_main_roads)
    - 8. 调整城门掩码 (_adjust_gate_mask)
    - 9. 修补城墙 (patch_walls)
    - 10. 回路检测 (find_wall_loop)
    - 11. 构建节点
    - 12. 生成区块 (gen_blocks)
    - 13. 返回城镇数据

## 轮廓生成方法

- static func _pick_town_size(size_type: String, rng) -> Vector2i
  - @args:
    - size_type: 大小类型
    - rng: 随机数生成器
  - @return Vector2i: 城镇大小
  - functions:
    - SMALL: 12-18
    - MEDIUM: 20-30
    - LARGE: 32-48

- static func _generate_contour_mask(cfg, w, h) -> Dictionary
  - @args:
    - cfg: 配置
    - w: 宽度
    - h: 高度
  - @return Dictionary: 轮廓掩码
  - functions:
    - 遍历所有格子
    - 调用 _is_inside_shape() 判断
    - 在 mask 中添加符合条件的点

- static func _is_inside_shape(x, y, cfg, w, h) -> bool
  - @args:
    - x, y: 坐标
    - cfg: 配置
    - w, h: 宽高
  - @return bool: 是否在形状内
  - functions:
    - 获取噪声值
    - 计算变形因子
    - RECT: 矩形边界判断
    - CIRCLE: 圆形边界判断

## 中心选择方法

- static func _pick_center(mask, w, h) -> Vector2i
  - @args:
    - mask: 轮廓掩码
    - w, h: 宽高
  - @return Vector2i: 中心位置
  - functions:
    - 计算几何中心
    - 如果几何中心在 mask 内，返回
    - 否则找最近的点

## 扫描线连接方法

- static func _scanline_connect(mask, w, h) -> void
  - @args:
    - mask: 轮廓掩码
    - w, h: 宽高
  - functions:
    - 遍历每一行
    - 找到最左和最右点
    - 检查与上一行的连接
    - 如果不连接，填充直线

- static func _is_connected(mask, start, goal, forbidden) -> bool
  - @args:
    - mask: 轮廓掩码
    - start: 起点
    - goal: 终点
    - forbidden: 禁止点
  - @return bool: 是否连通
  - functions:
    - BFS 搜索
    - 检查 8 个方向
    - 避开 forbidden 点

- static func _fill_line(mask, a, b) -> void
  - @args:
    - mask: 轮廓掩码
    - a, b: 两点
  - functions:
    - 使用线性插值
    - 填充两点之间的所有点

## 边缘查找方法

- static func _find_edge_points(mask) -> Array
  - @args:
    - mask: 轮廓掩码
  - @return Array: 边缘点数组
  - functions:
    - 遍历所有 mask 点
    - 检查 4 个方向是否有空位
    - 有空位则为边缘点

## 城墙修补方法

- static func patch_walls(edge_points, forbidden) -> Dictionary
  - @args:
    - edge_points: 边缘点
    - forbidden: 禁止点
  - @return Dictionary: {edge_set, patch_set}
  - functions:
    - 检查对角线边缘点
    - 如果形成斜角，填充直角
    - 返回修补后的边缘和修补点

## 主干道生成方法

- static func generate_main_roads(center, mask, edge_points) -> Dictionary
  - @args:
    - center: 中心
    - mask: 轮廓掩码
    - edge_points: 边缘点
  - @return Dictionary: {main_road_set, gate_set}
  - functions:
    - 从中心向 4 个方向延伸
    - 遇到边缘点则设为城门
    - 否则设为主干道
    - 返回主干道和城门

## 城门调整方法

- static func _adjust_gate_mask(gate_pos, main_road_set, mask, gate_wall_set) -> Variant
  - @args:
    - gate_pos: 城门位置
    - main_road_set: 主干道
    - mask: 轮廓掩码
    - gate_wall_set: 城门城墙
  - @return Variant: 城外位置
  - functions:
    - 找到主干道方向
    - 计算城外位置
    - 在城门两侧添加城墙
    - 移除城外位置的掩码

## 回路检测方法

- static func find_wall_loop(edge_set, center) -> Dictionary
  - @args:
    - edge_set: 边缘点集合
    - center: 中心
  - @return Dictionary: {loop, delete_set}
  - functions:
    - DFS 遍历所有边缘点
    - 检测回路
    - 选择包含中心的回路
    - 删除不在回路上的边缘点
    - 返回回路和删除点

- static func _point_in_polygon(pt, poly) -> bool
  - @args:
    - pt: 点
    - poly: 多边形
  - @return bool: 是否在多边形内
  - functions:
    - 射线法判断
    - 计算交点数量

## 区块生成方法

- static func gen_blocks(mask, center, ban_point_set, main_road_set, wall_set) -> Dictionary
  - @args:
    - mask: 轮廓掩码
    - center: 中心
    - ban_point_set: 禁止点
    - main_road_set: 主干道
    - wall_set: 城墙
  - @return Dictionary: {blocks, secondary_roads_set}
  - functions:
    - 1. 计算所有点到中心的距离
    - 2. 按距离排序 (从近到远)
    - 3. 遍历每个点:
       - 尝试生成矩形区块
       - 根据距离决定最大尺寸
       - 检查是否可通行
       - 标记 visited
       - 添加区块
    - 4. 生成次级道路:
       - 在区块周边生成
       - 避开主干道和城墙
    - 5. 返回区块和次级道路

# 数据文件

- 无直接依赖的数据文件

# 模块交互

## 调用的其他模块
- FastNoiseLite: 噪声生成
- RandomNumberGenerator: 随机数

## 被其他模块调用
- WorldMapGenerator: generate_town() 生成城镇

## 发送的事件
- 无

# 核心流程

## 完整城镇生成流程 (12 步)

### 步骤 1：生成轮廓掩码
```
1. 确定城镇大小 (SMALL/MEDIUM/LARGE)
2. 遍历所有格子
3. 使用 Simplex 噪声判断是否在形状内
4. RECT: 矩形边界 + 噪声变形
5. CIRCLE: 圆形边界 + 噪声变形
```

### 步骤 2：扫描线连接
```
1. 遍历每一行
2. 找到最左和最右点
3. 检查与上一行的连接性
4. 使用 BFS 检查 8 连通
5. 不连通则填充直线
```

### 步骤 3：选择中心
```
1. 计算几何中心 (w/2, h/2)
2. 检查是否在 mask 内
3. 不在则找最近的 mask 点
```

### 步骤 4：查找边缘点
```
1. 遍历所有 mask 点
2. 检查 4 个方向
3. 有空位则为边缘点
```

### 步骤 5：生成主干道
```
1. 从中心向 4 个方向延伸
2. 在 mask 内且非边缘：主干道
3. 遇到边缘：城门
4. 返回主干道和城门集合
```

### 步骤 6：调整城门掩码
```
1. 对每个城门:
   - 找到主干道方向
   - 计算城外位置
   - 在城门两侧添加城墙
   - 移除城外位置的 mask
```

### 步骤 7：修补城墙
```
1. 检查对角线边缘点
2. 如果形成斜角:
   - 填充直角点
   - 添加到 patch_set
```

### 步骤 8：回路检测
```
1. DFS 遍历所有边缘点
2. 检测回路
3. 选择包含中心的回路
4. 删除不在回路上的点
```

### 步骤 9：构建节点
```
1. 遍历所有点集:
   - edge: WALL
   - delete_wall: DEL_WALL
   - start_wall: START_WALL
   - end_wall: END_WALL
   - gate: GATE
   - gate_wall: GATE_WALL
   - patch: PATCH_WALL
2. 添加 center 节点
3. 添加 main_road 节点
```

### 步骤 10：生成区块
```
1. 计算所有点到中心的距离
2. 按距离排序
3. 遍历每个点:
   - 尝试扩展矩形
   - 检查可通行性
   - 标记 visited
   - 添加区块
4. 生成次级道路 (区块周边)
```

# 架构设计

## 分层生成策略
1. 第一层：轮廓掩码 (mask)
2. 第二层：边缘检测 (edge)
3. 第三层：主干道 (main_road)
4. 第四层：城门 (gate)
5. 第五层：城墙修补 (patch)
6. 第六层：回路检测 (loop)
7. 第七层：区块生成 (blocks)
8. 第八层：次级道路 (secondary_roads)

## 噪声应用
- 使用 Simplex 噪声生成不规则轮廓
- 频率控制平滑度
- 幅度控制不规则度

## 扫描线算法
- 确保轮廓闭合
- 避免断开的边界
- 使用 BFS 检查连通性

## 回路检测
- DFS 遍历边缘
- 检测闭合回路
- 保留包含中心的回路
- 删除多余边缘

## 智能区块生成
- 从中心向外扩散
- 距离越近区块越大
- 避开主干道和城墙
- 自动生成次级道路

# 使用场景

## 1. MUD 城镇生成
- 快速生成城镇布局
- 支持多种形状
- 确保城墙闭合

## 2. 程序化内容
- 随机城镇生成
- 可重复生成 (使用种子)
- 参数化控制

## 3. 游戏地图
- 城镇内部结构
- 道路网络
- 区块划分

# TODO

- [ ] 添加更多城镇形状
- [ ] 优化区块布局
- [ ] 添加地标建筑
- [ ] 支持多层城镇
- [ ] 添加装饰元素
