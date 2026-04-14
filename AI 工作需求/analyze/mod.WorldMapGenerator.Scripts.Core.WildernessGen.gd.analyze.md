# WildernessGen.gd 分析文档 (WorldMapGenerator 版本)

## 基础规则

- 禁止在函数内部创建函数（包括 lambda 函数、匿名函数）
- 禁止使用多行注释，使用#注释
- 函数注解、模块注解使用##

## 模块概述

**文件路径**: `res://mods/WorldMapGenerator/Scripts/Core/WildernessGen.gd`

**模块名称**: WildernessGen (荒野地形生成器)

**模块类型**: 核心工具类

**继承**: RefCounted（推测）

**依赖模块**: 
- OpenSimplexNoise (Godot 内置噪声类)
- Godot 数学库

**功能说明**: 
这是 WorldMapGenerator 模块中的荒野地形生成器，与世界地图管理器中的 WildernessGen.gd 功能类似。基于 Simplex 噪声和侵蚀算法生成自然地形，包括高度图生成、水流侵蚀、热侵蚀、分位数映射等功能。

**涉及模块**:
- WorldMapGenerator (主模块)
- OpenSimplexNoise (Godot 内置噪声)

## 配置、输入输出数据结构

### 1. 全局配置结构 (CONFIG)

```json
{
  "width": 512,                    # 地图宽度
  "height": 512,                   # 地图高度
  "noise_scale": 32,               # 噪声缩放因子
  "noise_zoom": 16,                # 噪声放大倍数
  "water_erosion_iterations": 100, # 水流侵蚀迭代次数
  "thermal_erosion_iterations": 100, # 热侵蚀迭代次数
  "combined_iterations": 100,      # 混合侵蚀迭代次数
  "quantile_bins": [0.0, 0.1, 0.2, 0.4, 0.6, 0.8, 0.9, 1.0],
  "quantile_weights": [0.03, 0.07, 0.10, 0.60, 0.10, 0.07, 0.03],
  "color_map": {
    "0.0-0.1": "#00008B",  # 深蓝色 (深海)
    "0.1-0.2": "#0000FF",  # 蓝色 (海洋)
    "0.2-0.4": "#006400",  # 深绿色 (森林/平原)
    "0.4-0.6": "#FFFF00",  # 黄色 (草原)
    "0.6-0.8": "#FFA500",  # 橙色 (丘陵)
    "0.8-0.9": "#FF0000",  # 红色 (山地)
    "0.9-1.0": "#000000"   # 黑色 (高山/积雪)
  }
}
```

### 2. 输入数据结构

```json
{
  "seed": 123,                    # 随机种子
  "height_map": [[0.5, 0.6, ...], ...],  # 高度图（二维数组）
  "noise_maps": [...],            # 噪声图列表
  "terrain_mask": [...],          # 地形掩码
  "heat_mask": [...],             # 热度掩码
  "weights": [0.7, 0.2, 0.1]      # 噪声权重
}
```

### 3. 输出数据结构

```json
{
  "metadata": {
    "version": "1.0.0",
    "generated_at": "2023-12-31 12:00:00",
    "config": {
      "seed": 123,
      "width": 256,
      "height": 256
    },
    "size": [256, 256]
  },
  "data": {
    "size": [256, 256],
    "final_height_level": [[0, 1, 2, ...], ...]
  }
}
```

## 成员变量

### 静态常量

```gdscript
const CONFIG = {
    "width": 512,
    "height": 512,
    "noise_scale": 32,
    "noise_zoom": 16,
    "water_erosion_iterations": 100,
    "thermal_erosion_iterations": 100,
    "combined_iterations": 100,
    "quantile_bins": [0.0, 0.1, 0.2, 0.4, 0.6, 0.8, 0.9, 1.0],
    "quantile_weights": [0.03, 0.07, 0.10, 0.60, 0.10, 0.07, 0.03],
    "color_map": { ... }
}
```

## 成员方法

### 静态方法

#### create_2d_array(height, width, default_value) -> Array

生成二维数组。

**参数**:
- `height`: 数组高度
- `width`: 数组宽度
- `default_value`: 默认值（默认 0.0）

**返回值**: 二维数组

**示例**:
```gdscript
var array = WildernessGen.create_2d_array(256, 256, 0.0)
# 创建 256x256 的二维数组，初始值为 0.0
```

#### copy_2d_array(array) -> Array

复制二维数组。

**参数**:
- `array`: 要复制的二维数组

**返回值**: 数组的深拷贝

**示例**:
```gdscript
var copy = WildernessGen.copy_2d_array(original_array)
```

#### simplex_noise(width, height, seed_offset) -> Array

生成 Simplex 噪声图（使用 OpenSimplexNoise）。

**参数**:
- `width`: 噪声图宽度
- `height`: 噪声图高度
- `seed_offset`: 种子偏移量

**返回值**: 噪声图（二维数组，值范围 0-1）

**核心算法**:
1. 使用 OpenSimplexNoise 生成基础噪声
2. 将 [-1, 1] 映射到 [0, 1]
3. 分位数变换：将均匀分布映射为正态分布
   - 收集所有噪声值并排序
   - 计算每个值的分位数
   - 使用逆高斯函数转换为正态分布
   - 映射回 [0, 1] 范围

**示例**:
```gdscript
var noise_map = WildernessGen.simplex_noise(256, 256, 123)
```

#### generate_noise_maps(input_data) -> Dictionary

生成噪声图列表。

**参数**:
- `input_data`: 包含 seed 的字典

**返回值**: 包含 seed 和 noise_maps 的字典

**功能**:
- 生成 3 张噪声图（使用不同的种子偏移）
- 用于后续高度图生成

**示例**:
```gdscript
var result = WildernessGen.generate_noise_maps({"seed": 123})
var noise_maps = result.noise_maps  # [noise1, noise2, noise3]
```

#### generate_height_map(input_data) -> Dictionary

生成高度地图。

**参数**:
- `input_data`: 包含 noise_maps 和 weights 的字典

**返回值**: 包含 height_map 的字典

**功能**:
- 叠加 3 张噪声图
- 使用权重控制各层影响

**示例**:
```gdscript
var height_result = WildernessGen.generate_height_map({
    "noise_maps": noise_maps,
    "weights": [0.7, 0.2, 0.1]
})
```

## 核心流程

### 地形生成完整流程

```
1. generate_noise_maps()
   ├─ 生成 3 张噪声图
   └─ 使用不同种子偏移
   ↓
2. generate_height_map()
   ├─ 叠加噪声图
   └─ 应用权重
   ↓
3. [后续步骤 - 未读取完整代码]
   ├─ 水流侵蚀
   ├─ 热侵蚀
   ├─ 分位数映射
   └─ 生成最终高度等级
```

### Simplex 噪声生成流程

```
1. 创建 OpenSimplexNoise 实例
   ↓
2. 设置参数（seed, octaves, period, persistence）
   ↓
3. 遍历每个像素生成噪声值
   ↓
4. 将 [-1, 1] 映射到 [0, 1]
   ↓
5. 分位数变换
   ├─ 收集并排序所有值
   ├─ 计算分位数
   ├─ 逆高斯变换
   └─ 映射回 [0, 1]
```

### 分位数变换算法

```gdscript
# 1. 收集所有噪声值并排序
var sorted_noise = []
for y in range(height):
    for x in range(width):
        sorted_noise.append(noise_map[y][x])
sorted_noise.sort()

# 2. 对每个像素进行分位数变换
for y in range(height):
    for x in range(width):
        var value = noise_map[y][x]
        # 计算分位数
        var quantile = 0.0
        for i in range(sorted_noise.size()):
            if sorted_noise[i] >= value:
                quantile = float(i) / float(sorted_noise.size())
                break
        
        # 逆高斯变换（Box-Muller 近似）
        var z = 0.0
        if quantile < 0.5:
            z = -sqrt(-2.0 * log(2.0 * quantile))
        else:
            z = sqrt(-2.0 * log(2.0 * (1.0 - quantile)))
        
        # 映射回 [0, 1]
        noise_map[y][x] = (z + 3.0) / 6.0
```

## 架构设计

### 分层架构

1. **配置层**: CONFIG 常量定义
2. **工具层**: create_2d_array, copy_2d_array
3. **噪声层**: simplex_noise, generate_noise_maps
4. **地形层**: generate_height_map, erosion 等
5. **输出层**: generate_color_map, height_summarize_process

### 数据流设计

```
种子 → 噪声图 → 高度图 → 侵蚀处理 → 分位数映射 → 高度等级 → 颜色映射
```

### 算法特点

1. **OpenSimplexNoise**: 使用 Godot 内置噪声类
2. **分位数变换**: 将均匀分布映射为正态分布
3. **多层噪声**: 叠加多层噪声增加细节
4. **侵蚀算法**: 模拟自然侵蚀过程

## 使用场景

### 基本地形生成

```gdscript
# 1. 生成噪声图
var noise_result = WildernessGen.generate_noise_maps({"seed": 123})

# 2. 生成高度图
var height_result = WildernessGen.generate_height_map({
    "noise_maps": noise_result.noise_maps,
    "weights": [0.7, 0.2, 0.1]
})

# 3. 后续处理（侵蚀、映射等）
# ...
```

### 自定义配置

```gdscript
# 使用自定义配置
var custom_config = WildernessGen.CONFIG.duplicate()
custom_config.width = 512
custom_config.height = 512
custom_config.water_erosion_iterations = 200
```

## 与世界地图管理器版本的对比

### 相同点
- 核心算法一致（噪声生成、侵蚀、分位数映射）
- 配置结构相同
- 数据结构类似

### 不同点
- **噪声实现**: 使用 OpenSimplexNoise vs 自实现 SimplexNoise
- **类名**: WildernessGen vs WildernessGen_Old
- **用途**: WorldMapGenerator 模块使用 vs 备份文件

## TODO

- [ ] 补充完整的侵蚀算法实现
- [ ] 补充分位数映射的详细实现
- [ ] 与世界地图管理器版本进行详细对比
- [ ] 添加更多代码示例和流程图
- [ ] 说明颜色映射的生成逻辑

## 备注

- 这是 WorldMapGenerator 模块中的荒野地形生成器
- 与世界地图管理器的 WildernessGen.gd 功能类似
- 使用 Godot 内置的 OpenSimplexNoise 类
- 实现了分位数变换将均匀分布映射为正态分布
- 总代码行数：约 600+ 行（完整文件）
- 当前只读取了前 200 行，主要包含基础函数和噪声生成
