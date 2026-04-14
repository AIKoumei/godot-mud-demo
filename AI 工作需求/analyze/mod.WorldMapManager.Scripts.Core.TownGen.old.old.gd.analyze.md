# TownGen.old.old.gd 分析文档

## 基础规则

- 禁止在函数内部创建函数（包括 lambda 函数、匿名函数）
- 禁止使用多行注释，使用#注释
- 函数注解、模块注解使用##

## 模块概述

**文件路径**: `res://mods/WorldMapManager/Scripts/Core/TownGen.old.old.gd`

**模块名称**: TownGen (旧旧版城镇生成器)

**模块类型**: 核心工具类（备份文件）

**依赖模块**: 
- SimplexNoise (噪声生成)
- RandomNumberGenerator (随机数生成)

**功能说明**: 
这是 TownGen 的最早版本备份，比 TownGen.old.gd 更老。包含了城镇生成的基础实现，展示了算法的演进历程。主要用于版本对比和历史追溯。

**涉及模块**:
- WorldMapManager (主模块)
- SimplexNoise (噪声工具)

## 配置、输入输出数据结构

### 1. 全局配置结构

```json
{
  "size": "SMALL",              # 城镇尺寸
  "shape": "CIRCLE",            # 城镇形状
  "seed": 123456,               # 随机种子
  "width": 16,                  # 城镇宽度
  "height": 16,                 # 城镇高度
  "irregularity_strength": 8.0, # 不规则强度
  "irregularity_length": 6.0    # 不规则长度
}
```

### 2. 输入数据结构

各步骤函数的输入均为字典，包含：
- "mask": 城镇区域节点列表
- "edges": 边缘节点列表
- "center": 中心节点
- "width": 宽度
- "height": 高度

### 3. 输出数据结构

```json
{
  "metadata": {
    "version": "1.0.0",
    "generated_at": "2023-12-31 12:00:00",
    "config": { ... },
    "size": [width, height]
  },
  "data": {
    "mask": [...],
    "edges": [...],
    "center": [x, y],
    "nodes": [...]
  }
}
```

## 成员变量

### 静态变量

```gdscript
static var _simplex_perm_cache = {}  # Simplex 噪声 perm 数组缓存
```

### 辅助函数

```gdscript
static func get_points_between(start_x, start_y, end_x, end_y) -> Array
static func distance_to_center(x, y, center_x, center_y) -> float
static func is_valid_point(x, y, mask, primary_road, gates, walls, gate_walls, secondary_roads, occupied) -> bool
static func _init_simplex_perm(seed) -> Array
static func simplex_noise2d(x, y, seed, scale) -> float
static func _simplex_grad(hash_val, x, y) -> float
static func gen_config(size, shape, seed) -> Dictionary
```

## 成员方法

### 核心方法

#### get_points_between(start_x, start_y, end_x, end_y) -> Array

使用 Bresenham 直线算法获取两点之间的所有整数坐标点。

**参数**:
- `start_x`, `start_y`: 起点坐标
- `end_x`, `end_y`: 终点坐标

**返回值**: 坐标点字符串列表

**算法**: Bresenham 直线算法

**示例**:
```gdscript
var points = get_points_between(0, 0, 5, 5)
# ["0,0", "1,1", "2,2", "3,3", "4,4"]
```

#### distance_to_center(x, y, center_x, center_y) -> float

计算点到中心的欧几里得距离。

**参数**:
- `x`, `y`: 点坐标
- `center_x`, `center_y`: 中心坐标

**返回值**: 距离值

#### is_valid_point(...) -> bool

检查点是否有效（不在障碍物中）。

**参数**:
- `x`, `y`: 点坐标
- `mask`, `primary_road`, `gates`, `walls`, `gate_walls`, `secondary_roads`, `occupied`: 各种节点列表

**返回值**: 点是否有效

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
- `scale`: 缩放因子

**返回值**: 噪声值

**实现**: 基础 Simplex 噪声算法

#### _simplex_grad(hash_val, x, y) -> float

计算 Simplex 噪声的梯度值。

**参数**:
- `hash_val`: 哈希值
- `x`, `y`: 坐标偏移

**返回值**: 梯度值

#### gen_config(size, shape, seed) -> Dictionary

生成城镇生成器配置。

**参数**:
- `size`: 城镇尺寸 (SMALL/MEDIUM/LARGE)
- `shape`: 城镇形状 (CIRCLE/RECTANGLE)
- `seed`: 随机种子

**返回值**: 配置字典

**功能**:
- 根据尺寸确定宽高范围
- 生成不规则强度和长度参数
- 使用 RandomNumberGenerator 确保可重复性

## 核心流程

### Simplex 噪声生成流程

```
1. _init_simplex_perm(seed)
   ├─ 初始化 perm 数组 [0, 1, 2, ..., 255]
   ├─ 使用种子打乱数组
   └─ 扩展 perm 数组（append_array）
   ↓
2. simplex_noise2d(x, y, seed, scale)
   ├─ 应用缩放因子
   ├─ 计算单纯形坐标
   ├─ 查找 perm 数组获取梯度
   ├─ 计算梯度贡献值
   └─ 返回加权噪声值
```

### 配置生成流程

```
1. gen_config(size, shape, seed)
   ├─ 确定尺寸选项
   ├─ 根据尺寸确定宽高
   ├─ 生成不规则参数
   └─ 返回配置字典
```

## 架构设计

### 工具函数架构

1. **几何工具**: get_points_between, distance_to_center
2. **噪声工具**: _init_simplex_perm, simplex_noise2d, _simplex_grad
3. **配置工具**: gen_config
4. **验证工具**: is_valid_point

### 缓存设计

```gdscript
# 缓存不同种子对应的 perm 数组
static var _simplex_perm_cache = {}

# 使用缓存避免重复计算
static func _init_simplex_perm(seed: int) -> Array:
    if seed not in _simplex_perm_cache:
        # 初始化并缓存
        _simplex_perm_cache[seed] = perm
    return _simplex_perm_cache[seed]
```

## 使用场景

### Simplex 噪声生成

```gdscript
# 初始化 perm 数组
var perm = TownGen._init_simplex_perm(123456)

# 生成噪声值
var noise_value = TownGen.simplex_noise2d(10.0, 20.0, 123456, 0.05)
```

### 配置生成

```gdscript
# 生成随机配置
var config = TownGen.gen_config(null, null, null)

# 生成指定配置
var config = TownGen.gen_config("MEDIUM", "CIRCLE", 123456)
```

### 点验证

```gdscript
# 检查点是否有效
var is_valid = TownGen.is_valid_point(x, y, mask, primary_road, gates, walls, gate_walls, secondary_roads, occupied)
```

## TODO

- [ ] 补充更多实现细节
- [ ] 添加与新版 TownGen.gd 的对比
- [ ] 说明这个版本的历史地位
- [ ] 分析为什么后续版本要改进

## 备注

- 这是 TownGen 的最早版本备份
- 文件已被标记为"旧版本备份文件，移除类名声明以避免冲突"
- 主要价值在于展示算法演进历程
- 包含了基础的 Simplex 噪声实现
- 总代码行数：约 300+ 行（当前读取部分）
- 这个版本可能不完整，主要作为历史参考
