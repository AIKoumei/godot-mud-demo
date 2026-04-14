# TownGen.old.gd 分析文档

## 基础规则

- 禁止在函数内部创建函数（包括 lambda 函数、匿名函数）
- 禁止使用多行注释，使用#注释
- 函数注解、模块注解使用##

## 模块概述

**文件路径**: `res://mods/WorldMapManager/Scripts/Core/TownGen.old.gd`

**模块名称**: TownGen_Old (旧版城镇生成器)

**模块类型**: 核心工具类

**依赖模块**: 
- SimplexNoise (噪声生成)
- RandomNumberGenerator (随机数生成)

**功能说明**: 
旧版本的城镇生成器，实现了基于 Simplex 噪声的程序化城镇生成。这是 TownGen.gd 的前身，包含了完整的城镇生成流程，但已被新版本替代。主要用于版本对比和向后兼容。

**涉及模块**:
- WorldMapManager (主模块)
- SimplexNoise (噪声工具)

## 配置、输入输出数据结构

### 1. 全局配置结构 (gen_config 返回值)

```json
{
  "size": "SMALL",              # 城镇尺寸 (SMALL/MEDIUM/LARGE)
  "shape": "CIRCLE",            # 城镇形状 (CIRCLE/RECTANGLE)
  "seed": 123456,               # 随机种子
  "width": 16,                  # 城镇宽度
  "height": 16,                 # 城镇高度
  "irregularity_strength": 8.0, # 轮廓不规则强度
  "irregularity_length": 6.0    # 轮廓不规则长度
}
```

### 2. 节点颜色定义 (NODE_COLOR)

```json
{
  "mask": [70, 70, 70],         # 基础轮廓（深灰色）
  "edge": [90, 90, 90],         # 边缘（灰色）
  "wall": [170, 120, 100],      # 城墙（棕色）
  "gate": [150, 150, 200],      # 城门（淡紫色）
  "gate_wall": [100, 100, 150], # 城门城墙（灰蓝色）
  "primary_road": [180, 180, 180], # 主干道（浅灰色）
  "secondary_road": [200, 200, 200], # 次级道路（更浅灰色）
  "block": [120, 120, 120],     # 区块（中灰色）
  "center": [255, 0, 0],        # 中心（红色）
  "empty": [255, 255, 255]      # 空白（白色）
}
```

### 3. 输入数据结构

各步骤函数的输入均为字典，包含以下字段：
- "mask": 城镇区域的节点列表 ["x,y", "x,y", ...]
- "edges": 城镇边缘的节点列表 ["x,y", "x,y", ...]
- "center": 城镇中心节点 "x,y"
- "primary_road": 主干道节点列表
- "gates": 城门节点列表
- "gate_walls": 城门城墙节点列表
- "walls": 城墙节点列表
- "blocks": 区块字典
- "secondary_roads": 次级道路节点列表
- "width": 城镇宽度
- "height": 城镇高度

### 4. 输出数据结构

最终输出数据结构：
```json
{
  "metadata": {
    "version": "1.0.2",
    "generated_at": "2023-12-31 12:00:00",
    "config": { ... },
    "size": [width, height]
  },
  "data": {
    "mask": [...],
    "edges": [...],
    "center": [x, y],
    "nodes": [...],
    "blocks": { ... },
    "primary_road": [...],
    "secondary_roads": [...],
    "walls": [...],
    "gates": [...],
    "gate_walls": [...],
    "all_walls": [...]
  }
}
```

## 成员变量

### 实例变量

```gdscript
var config: Dictionary          # 配置字典
var seed: int                   # 随机种子
var rng: RandomNumberGenerator  # 随机数生成器
var noise: SimplexNoise         # Simplex 噪声生成器
var steps: Array                # 生成步骤记录
```

### 静态常量

```gdscript
const NODE_COLOR: Dictionary    # 节点颜色映射表
```

## 成员方法

### 静态方法

#### gen_config(size, shape, seed) -> Dictionary

生成城镇生成器配置。

**参数**:
- `size`: 城镇尺寸 (SMALL/MEDIUM/LARGE)，默认为随机
- `shape`: 城镇形状 (CIRCLE/RECTANGLE)，默认为随机
- `seed`: 随机种子，默认为随机生成

**返回值**: 配置字典

**功能**: 根据尺寸确定宽高范围，生成不规则强度和长度参数。

**示例**:
```gdscript
var config = TownGen_Old.gen_config("MEDIUM", "CIRCLE", 123456)
# 返回：{"size": "MEDIUM", "shape": "CIRCLE", "seed": 123456, "width": 18, "height": 18, ...}
```

#### get_points_between(start_x, start_y, end_x, end_y) -> Array

获取两点之间的所有整数坐标点（包含起点，不包含终点）。

**参数**:
- `start_x`: 起点 x 坐标
- `start_y`: 起点 y 坐标
- `end_x`: 终点 x 坐标
- `end_y`: 终点 y 坐标

**返回值**: 坐标点字符串列表 ["x,y", ...]

**算法**: 使用 Bresenham 直线算法

**示例**:
```gdscript
var points = TownGen_Old.get_points_between(0, 0, 5, 5)
# 返回：["0,0", "1,1", "2,2", "3,3", "4,4"]
```

#### distance_to_center(x, y, center_x, center_y) -> float

计算点到中心的距离。

**参数**:
- `x`: 点的 x 坐标
- `y`: 点的 y 坐标
- `center_x`: 中心 x 坐标
- `center_y`: 中心 y 坐标

**返回值**: 欧几里得距离

**示例**:
```gdscript
var dist = TownGen_Old.distance_to_center(3, 4, 0, 0)
# 返回：5.0
```

#### rgb_to_hex(rgb) -> String

将 RGB 颜色转换为十六进制格式。

**参数**:
- `rgb`: RGB 颜色数组 [r, g, b]

**返回值**: 十六进制颜色字符串 "#RRGGBBff"

**示例**:
```gdscript
var hex = TownGen_Old.rgb_to_hex([255, 0, 0])
# 返回："#ff0000ff"
```

#### deduplicate_array(array) -> Array

数组去重。

**参数**:
- `array`: 输入数组

**返回值**: 去重后的数组

**示例**:
```gdscript
var unique = TownGen_Old.deduplicate_array(["a", "b", "a", "c"])
# 返回：["a", "b", "c"]
```

### 实例方法

#### _init(config: Dictionary)

初始化城镇生成器。

**参数**:
- `config`: 配置字典

**功能**:
- 保存配置
- 初始化随机数生成器
- 创建 SimplexNoise 实例
- 初始化步骤记录数组

#### run() -> Dictionary

运行完整的生成流程。

**返回值**: 最终生成数据字典

**生成步骤**:
1. 生成基础轮廓 (step_1_generate_mask)
2. 确定城镇中心 (step_2_determine_center)
3. 生成主干道与城门 (step_3_generate_roads)
4. 重新检查边缘 (step_4_1_recheck_edges)
5. 验证边缘连通性 (validate_edge_connectivity)
6. 生成城墙 (step_4_generate_walls)
7. 生成区块与次级道路 (step_5_generate_blocks)
8. 生成最终数据 (generate_final_data)

**示例**:
```gdscript
var config = TownGen_Old.gen_config(null, null, 123456)
var generator = TownGen_Old.new(config)
var result = generator.run()
```

#### step_1_generate_mask() -> Dictionary

步骤 1: 生成城镇基础轮廓。

**返回值**: 包含 mask 和 edges 的字典

**核心逻辑**:
1. 生成原始 mask（无噪声）
   - 圆形：距离中心不超过最大半径
   - 矩形：在边界内
2. 对原始 mask 做完整的 edge 标记
   - 检查九宫格内是否有无效节点
3. 对原始 edge 应用噪声偏移
   - 使用多层噪声增加不规则性
   - 根据形状计算偏移方向（径向/垂直）
4. 移除只有一个邻居的 edge 节点
5. 标记必要节点和移除节点
6. 移除非必要节点

**噪声处理**:
```gdscript
# 使用多层噪声
var noise_value_1 = noise.noise2d(x, y, 0.05)  # 低频
var noise_value_2 = noise.noise2d(x, y, 0.1)   # 中频
var noise_value_3 = noise.noise2d(x, y, 0.15)  # 高频
var combined_noise = noise_value_1 * 0.5 + noise_value_2 * 0.3 + noise_value_3 * 0.2
```

#### step_2_determine_center(mask_data) -> Dictionary

步骤 2: 确定城镇中心。

**参数**:
- `mask_data`: 包含 mask 的字典

**返回值**: 包含 center 的字典

**逻辑**:
1. 计算几何中心
2. 检查几何中心是否在 mask 内
3. 如果不在，找到离几何中心最近的有效点

#### step_3_generate_roads(center_data) -> Dictionary

步骤 3: 生成主干道与城门。

**参数**:
- `center_data`: 包含 center 的字典

**返回值**: 包含 primary_road 和 gates 的字典

**逻辑**:
1. 从中心向四个方向（上、下、左、右）生成主干道
2. 检测边缘点作为城门
3. 生成城门城墙（在城门垂直主干道的两个方向）
4. 从 edges 中移除触及点

#### step_4_1_recheck_edges(road_data) -> Dictionary

步骤 4.1: 在后处理后，对 mask 再进行一遍 edge 的检查。

**参数**:
- `road_data`: 包含 mask 和 edges 的字典

**返回值**: 更新后的 road_data 字典

**逻辑**:
1. 构建 mask 集合便于快速查找
2. 重新检测 edge 节点
3. 对每个 mask 节点，检查其九宫格内是否有无效节点
4. 如果有无效节点，标记为 edge 节点

#### validate_edge_connectivity(wall_data) -> void

步骤 4.2: 进行 edge 合法性校对。

**参数**:
- `wall_data`: 包含 edges 的字典

**功能**: 检查 edge 是否首尾相连

**验证逻辑**:
1. 构建 edge 集合便于快速查找
2. 计算每个 edge 节点的邻居数量（十字线方向）
3. 检查是否有节点只有一个邻居（首尾节点）
4. 如果首尾节点数量不是 0 或 2，说明 edge 不合法

**错误处理**: 不合法时打印错误信息

#### step_4_generate_walls(road_data) -> Dictionary

步骤 4: 生成城墙。

**参数**:
- `road_data`: 包含 edges 和 gates 的字典

**返回值**: 包含 walls 的字典

**逻辑**:
1. 将轮廓的最远边缘生成为城墙
2. 避开城门和城门城墙
3. 避开主干道
4. 检查当前节点九空格内的节点是否都是有效节点
5. 如果都是有效节点，则不作为城墙节点

#### step_5_generate_blocks(wall_data) -> Dictionary

步骤 5: 生成区块与次级道路。

**参数**:
- `wall_data`: 包含 walls 的字典

**返回值**: 包含 blocks 和 secondary_roads 的字典

**逻辑**:
1. 从中心向外四个方向生成区块
2. 先尝试生成第一个 5x5 的区块
3. 如果没有找到合适位置，尝试生成 4x4 或 3x3 的区块
4. 循环生成区块，直到没有可用点
5. 在区块周边生成次级道路
6. 后处理：检查次级道路的连通性

**区块优先级**:
- 距离中心距离（优先选择近的）
- 区块大小（优先选择大的）
- 距离主干道距离（优先选择近的）

**连通性检查**:
1. 找出所有次级道路的连通组件（BFS）
2. 检查每个连通组件是否与主干道连通
3. 移除不连通的次级道路节点
4. 生成大小为 1 的后处理区块

#### generate_final_data(block_data) -> Dictionary

生成最终数据。

**参数**:
- `block_data`: 包含所有生成数据的字典

**返回值**: 最终数据字典

**数据结构**:
```json
{
  "metadata": {
    "version": "1.0.2",
    "generated_at": "2023-12-31 12:00:00",
    "config": config,
    "size": [width, height]
  },
  "data": {
    "mask": [...],
    "edges": [...],
    "center": [x, y],
    "nodes": [...],
    "blocks": { ... },
    "primary_road": [...],
    "secondary_roads": [...],
    "walls": [...],
    "gates": [...],
    "gate_walls": [...],
    "all_walls": [...]
  }
}
```

## 核心流程

### 城镇生成完整流程

```
1. gen_config() 
   ↓
2. TownGen_Old.new(config)
   ↓
3. run()
   ├─ step_1_generate_mask()      # 生成轮廓和边缘
   ├─ step_2_determine_center()   # 确定中心点
   ├─ step_3_generate_roads()     # 生成主干道和城门
   ├─ step_4_1_recheck_edges()    # 重新检查边缘
   ├─ validate_edge_connectivity() # 验证边缘连通性
   ├─ step_4_generate_walls()     # 生成城墙
   ├─ step_5_generate_blocks()    # 生成区块和次级道路
   └─ generate_final_data()       # 生成最终数据
```

### 轮廓生成算法流程

```
1. 生成基础形状（圆形/矩形）
   ↓
2. 标记边缘节点（九宫格检测）
   ↓
3. 应用噪声偏移
   ├─ 多层噪声叠加（低频 + 中频 + 高频）
   ├─ 计算偏移方向（径向/垂直）
   └─ 应用偏移量
   ↓
4. 移除悬空节点（十字线检测）
   ↓
5. 标记必要节点（BFS 遍历）
   ↓
6. 移除非必要节点
```

### 区块生成优先级算法

```
1. 收集所有可用点
   ↓
2. 尝试不同大小的区块（5x5, 4x4, 3x3, 2x2, 1x1）
   ↓
3. 计算优先级
   ├─ 距离中心距离（负值，越近越好）
   ├─ 区块大小（正值，越大越好）
   └─ 距离主干道距离（负值，越近越好）
   ↓
4. 排序并选择最佳候选
   ↓
5. 生成区块和次级道路
   ↓
6. 重复直到没有可用点
```

## 架构设计

### 分层架构

1. **配置层**: gen_config() 生成配置
2. **初始化层**: _init() 初始化生成器
3. **执行层**: run() 执行完整流程
4. **步骤层**: step_1 到 step_5 执行具体步骤
5. **工具层**: 辅助函数（距离计算、颜色转换等）

### 数据流设计

```
配置 → 初始化 → 轮廓生成 → 中心确定 → 道路生成 
  → 边缘检查 → 城墙生成 → 区块生成 → 最终数据
```

### 算法特点

1. **噪声驱动**: 使用 Simplex 噪声生成不规则轮廓
2. **分层处理**: 12 个步骤依次处理，每步都有清晰的输入输出
3. **连通性保证**: BFS 检查道路连通性，移除孤岛
4. **优先级排序**: 区块生成按优先级排序，确保从中心向外扩散

## 使用场景

### 基本使用

```gdscript
# 生成配置
var config = TownGen_Old.gen_config("MEDIUM", "CIRCLE", 123456)

# 创建生成器
var generator = TownGen_Old.new(config)

# 运行生成
var result = generator.run()

# 访问生成数据
var mask = result.data.mask
var roads = result.data.primary_road
var blocks = result.data.blocks
```

### 可视化调试

```gdscript
# 在测试场景中使用
func _on_gen_pressed():
    var config = TownGen_Old.gen_config(null, null, randi())
    var generator = TownGen_Old.new(config)
    var town_data = generator.run()
    _draw_town(town_data)
```

## TODO

- [ ] 与新版 TownGen.gd 进行对比分析，找出差异
- [ ] 补充 step_3_generate_roads 的详细实现说明
- [ ] 补充 step_4_generate_walls 的详细实现说明
- [ ] 补充 step_5_generate_blocks 的详细实现说明
- [ ] 添加更多代码示例和流程图
- [ ] 说明为什么需要被新版本替代（性能问题？算法改进？bug 修复？）

## 备注

- 这是旧版本的城镇生成器，已被新版本的 TownGen.gd 替代
- 保留了完整的实现代码，用于版本对比和向后兼容
- 核心算法与新版类似，但实现细节可能有所不同
- 文件使用 `class_name TownGen_Old` 避免与新版冲突
- 总代码行数：约 1600+ 行（完整文件）
