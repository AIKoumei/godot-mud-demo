# TownGen.gd 分析文档 (WorldMapGenerator 版本)

## 基础规则

- 禁止在函数内部创建函数（包括 lambda 函数、匿名函数）
- 禁止使用多行注释，使用#注释
- 函数注解、模块注解使用##

## 模块概述

**文件路径**: `res://mods/WorldMapGenerator/Scripts/Core/TownGen.gd`

**模块名称**: WorldMapGeneratorTownGen (世界地图生成器 - 城镇生成)

**模块类型**: 核心工具类

**继承**: RefCounted

**依赖模块**: 
- RandomNumberGenerator (随机数生成)
- Godot 数学库 (sqrt, floor 等)

**功能说明**: 
这是 WorldMapGenerator 模块中的城镇生成器实现，与世界地图管理器中的 TownGen.gd 功能类似。实现了基于 Simplex 噪声的程序化城镇生成，包括轮廓生成、城墙、道路、区块等元素。

**涉及模块**:
- WorldMapGenerator (主模块)
- SimplexNoise (噪声工具 - 内嵌实现)

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

### 2. 输入数据结构

各步骤函数的输入均为字典，包含：
- "mask": 城镇区域的节点列表
- "edges": 边缘节点列表
- "center": 中心节点
- "primary_road": 主干道节点列表
- "gates": 城门节点列表
- "blocks": 区块字典
- "secondary_roads": 次级道路节点列表

### 3. 输出数据结构

最终输出：
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
    "all_walls": [...],
    "total_nodes": { ... }
  }
}
```

## 成员变量

### 静态变量

```gdscript
static var _simplex_perm_cache = {}  # Simplex 噪声 perm 数组缓存
```

## 成员方法

### 静态方法

#### get_points_between(start_x, start_y, end_x, end_y) -> Array

获取两点之间的所有整数坐标点（使用 Bresenham 直线算法）。

**参数**:
- `start_x`, `start_y`: 起点坐标
- `end_x`, `end_y`: 终点坐标

**返回值**: 坐标点字符串列表 ["x,y", ...]

**算法**: Bresenham 直线算法

**示例**:
```gdscript
var points = WorldMapGeneratorTownGen.get_points_between(0, 0, 5, 5)
# ["0,0", "1,1", "2,2", "3,3", "4,4"]
```

#### distance_to_center(x, y, center_x, center_y) -> float

计算点到中心的欧几里得距离。

**参数**:
- `x`, `y`: 点坐标
- `center_x`, `center_y`: 中心坐标

**返回值**: 距离值

#### _init_simplex_perm(seed) -> Array

初始化 Simplex 噪声的 perm 数组。

**参数**:
- `seed`: 随机种子

**返回值**: 排列数组

**特点**: 使用缓存避免重复计算

#### simplex_noise2d(x, y, seed, scale) -> float

生成 2D Simplex 噪声值。

**参数**:
- `x`, `y`: 坐标
- `seed`: 随机种子
- `scale`: 缩放因子（默认 0.05）

**返回值**: 噪声值（范围约 -1 到 1）

**实现**: 基础 Simplex 噪声算法

#### _simplex_grad(hash_val, x, y) -> float

计算 Simplex 噪声的梯度值。

**参数**:
- `hash_val`: 哈希值
- `x`, `y`: 坐标偏移

**返回值**: 梯度值

## 核心流程

### Simplex 噪声生成流程

```
1. _init_simplex_perm(seed)
   ├─ 初始化 perm 数组 [0, 1, 2, ..., 255]
   ├─ 使用种子打乱数组
   ├─ 扩展 perm 数组（append_array）
   └─ 缓存到 _simplex_perm_cache
   ↓
2. simplex_noise2d(x, y, seed, scale)
   ├─ 应用缩放因子
   ├─ 计算单纯形坐标（2D 单形网格）
   ├─ 查找 perm 数组获取梯度
   ├─ 计算三个顶点的贡献值
   └─ 返回加权和（70.0 * (n0 + n1 + n2)）
```

### 城镇生成流程（与世界地图管理器版本类似）

```
1. gen_config() 
   ↓
2. TownGen.new(config)
   ↓
3. run()
   ├─ step_1_generate_mask()      # 生成轮廓和边缘
   ├─ step_2_determine_center()   # 确定中心点
   ├─ step_3_generate_roads()     # 生成主干道和城门
   ├─ step_4_1_recheck_edges()    # 重新检查边缘
   ├─ step_4_2_validate_edge_connectivity() # 验证边缘连通性
   ├─ step_4_generate_walls()     # 生成城墙
   ├─ step_5_generate_blocks()    # 生成区块和次级道路
   └─ generate_final_data()       # 生成最终数据
```

## 架构设计

### 分层架构

1. **配置层**: gen_config() 生成配置
2. **初始化层**: _init() 初始化生成器
3. **执行层**: run() 执行完整流程
4. **步骤层**: step_1 到 step_5 执行具体步骤
5. **工具层**: 辅助函数（距离计算、噪声生成等）

### Simplex 噪声实现

```gdscript
# 2D Simplex 噪声核心算法
static func simplex_noise2d(x, y, seed, scale):
    # 1. 应用缩放
    x *= scale
    y *= scale
    
    # 2. 获取 perm 数组
    var perm = _init_simplex_perm(seed)
    
    # 3. 计算单形坐标
    var F2 = 0.5 * (sqrt(3.0) - 1.0)
    var G2 = (3.0 - sqrt(3.0)) / 6.0
    
    # 4. 确定单形顶点
    # 5. 计算梯度贡献
    # 6. 返回加权和
```

### 数据流设计

```
配置 → 初始化 → 轮廓生成 → 中心确定 → 道路生成 
  → 边缘检查 → 城墙生成 → 区块生成 → 最终数据
```

## 使用场景

### 基本使用

```gdscript
# 生成配置
var config = WorldMapGeneratorTownGen.gen_config("MEDIUM", "CIRCLE", 123456)

# 创建生成器（假设类有 new 方法）
var generator = WorldMapGeneratorTownGen.new(config)

# 运行生成
var result = generator.run()

# 访问生成数据
var mask = result.data.mask
var roads = result.data.primary_road
var blocks = result.data.blocks
```

### Simplex 噪声使用

```gdscript
# 生成噪声值
var noise_value = WorldMapGeneratorTownGen.simplex_noise2d(10.0, 20.0, 123456, 0.05)

# 生成噪声图
var noise_map = []
for y in range(256):
    var row = []
    for x in range(256):
        row.append(WorldMapGeneratorTownGen.simplex_noise2d(x, y, 123456, 0.05))
    noise_map.append(row)
```

## 与世界地图管理器版本的对比

### 相同点
- 核心算法一致（Bresenham 直线、Simplex 噪声）
- 数据结构相同
- 城镇生成流程类似

### 不同点
- **类名**: WorldMapGeneratorTownGen vs TownGen_Old
- **用途**: WorldMapGenerator 模块使用 vs 备份文件
- **实现细节**: 可能有细微差异（需要完整代码对比）

## TODO

- [ ] 补充完整的城镇生成步骤实现
- [ ] 与世界地图管理器版本进行详细对比
- [ ] 说明为什么需要两个版本
- [ ] 添加更多代码示例和流程图
- [ ] 补充 step_1 到 step_5 的详细实现

## 备注

- 这是 WorldMapGenerator 模块中的城镇生成器
- 与世界地图管理器的 TownGen.gd 功能类似
- 内嵌了 Simplex 噪声实现
- 使用 perm 数组缓存优化性能
- 总代码行数：约 600+ 行（完整文件）
- 当前只读取了前 200 行，主要包含辅助函数和噪声实现
