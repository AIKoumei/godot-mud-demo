# mod.WorldMapManager.Scripts.Core.WildernessGen.gd 分析文档

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
WildernessGen

## 模块路径
res/mods/WorldMapManager/Scripts/Core/WildernessGen.gd

## 模块功能
荒野地图生成器，基于 Simplex 噪声的地形生成系统。实现了完整的管线化地形生成流程，包括:
1. 噪声图生成 (3 层噪声叠加)
2. 高度图生成和归一化
3. 平滑滤波和非线性拉伸
4. 地形掩码生成和区域性抬升/降低
5. 热度图生成
6. 水流侵蚀和热侵蚀算法
7. 分位数映射处理
8. 高度概括和颜色映射

## 模块依赖
- SimplexNoise: Simplex 噪声生成
- FastNoiseLite: Godot 内置噪声生成器
- RandomNumberGenerator: 随机数生成
- 数学函数：sqrt, floor, clamp, log

## 全局配置 (CONFIG)
```json
{
  "width": 512,
  "height": 512,
  "noise_scale": 32,
  "noise_zoom": 16,
  "water_erosion_iterations": 100,
  "thermal_erosion_iterations": 100,
  "combined_iterations": 100,
  "quantile_bins": [0.0, 0.1, 0.2, 0.4, 0.6, 0.8, 0.9, 1.0],
  "quantile_weights": [0.03, 0.07, 0.10, 0.60, 0.10, 0.07, 0.03],
  "color_map": {
    "0.0-0.1": "#00008B",
    "0.1-0.2": "#0000FF",
    "0.2-0.4": "#006400",
    "0.4-0.6": "#FFFF00",
    "0.6-0.8": "#FFA500",
    "0.8-0.9": "#FF0000",
    "0.9-1.0": "#000000"
  }
}
```

## 输入输出数据结构

### 输入数据结构 (input_data)
```json
{
  "seed": 12345,
  "width": 512,
  "height": 512,
  "noise_maps": [],
  "height_map": [],
  "terrain_mask": [],
  "heat_mask": []
}
```

### 输出数据结构 (final_data)
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

## 模块用例

```gdscript
# 示例 1：生成完整地图
var map_data = WildernessGen.generate_map(12345, 256, 256)

# 示例 2：生成噪声图
var noise_input = {"seed": 12345, "width": 256, "height": 256}
var noise_data = WildernessGen.generate_noise_maps(noise_input)

# 示例 3：生成高度图
var height_input = {"seed": 12345, "noise_maps": noise_data.noise_maps}
var height_data = WildernessGen.generate_height_map(height_input)

# 示例 4：归一化高度图
var normalized = WildernessGen.normalize_height_map(height_data)

# 示例 5：平滑滤波
var smoothed = WildernessGen.smooth_filter(normalized)

# 示例 6：非线性拉伸
var stretched = WildernessGen.nonlinear_stretch(smoothed)

# 示例 7：生成地形掩码
var terrain_mask_data = WildernessGen.generate_terrain_mask(stretched)

# 示例 8：区域性抬升
var raised = WildernessGen.regional_raise_lower(terrain_mask_data)

# 示例 9：生成热度掩码
var heat_data = WildernessGen.generate_heat_mask(raised)

# 示例 10：混合侵蚀处理
var eroded = WildernessGen.mix_processing(heat_data)

# 示例 11：分位数映射
var mapped = WildernessGen.quantile_mapping_process(eroded)

# 示例 12：高度概括
var summarized = WildernessGen.height_summarize_process(mapped)

# 示例 13：生成颜色地图
var color_data = WildernessGen.generate_color_map(summarized)

# 示例 14：创建二维数组
var array = WildernessGen.create_2d_array(256, 256, 0.0)

# 示例 15：复制二维数组
var copy = WildernessGen.copy_2d_array(array)
```

# 成员变量

- CONFIG: Dictionary (static, const)
  - 全局配置常量
  - 包含地图生成的所有参数设置

# 成员方法

## 基础工具方法

- create_2d_array(height:int, width:int, default_value:float) -> Array
  - @args:
    - height: 数组高度
    - width: 数组宽度
    - default_value: 默认值，默认 0.0
  - @return Array: 二维数组
  - functions:
    - 创建指定大小的二维数组
    - 填充默认值
    - 返回二维数组

- copy_2d_array(array:Array) -> Array
  - @args:
    - array: 要复制的二维数组
  - @return Array: 复制后的二维数组
  - functions:
    - 深度复制二维数组
    - 逐行逐列复制数据
    - 返回新数组

## 噪声生成方法

- simplex_noise(width:int, height:int, seed_offset:int) -> Array
  - @args:
    - width: 噪声图宽度
    - height: 噪声图高度
    - seed_offset: 种子偏移量
  - @return Array: 噪声图 (二维数组)
  - functions:
    - 使用 FastNoiseLite 生成基础 Simplex 噪声
    - 将 [-1, 1] 映射到 [0, 1]
    - 执行分位数变换，将均匀分布映射为正态分布
    - 使用 Box-Muller 变换近似
    - 返回噪声图

- generate_noise_maps(input_data:Dictionary) -> Dictionary
  - @args:
    - input_data: 包含 seed, width, height
  - @return Dictionary: 包含 seed, noise_maps
  - functions:
    - 生成 3 张不同的噪声图
    - 使用 seed, seed+1, seed+2 作为种子偏移
    - 返回噪声图列表

## 高度图处理方法

- generate_height_map(input_data:Dictionary) -> Dictionary
  - @args:
    - input_data: 包含 noise_maps, weights
  - @return Dictionary: 包含 seed, height_map, weights
  - functions:
    - 叠加 3 张噪声图
    - 使用权重 [0.7, 0.2, 0.1]
    - 返回高度图

- normalize_height_map(input_data:Dictionary) -> Dictionary
  - @args:
    - input_data: 包含 height_map
  - @return Dictionary: 包含 seed, height_map
  - functions:
    - 找到最小值和最大值
    - 归一化到 [0, 1] 区间
    - 返回归一化后的高度图

- smooth_filter(input_data:Dictionary) -> Dictionary
  - @args:
    - input_data: 包含 height_map
  - @return Dictionary: 包含 seed, height_map
  - functions:
    - 使用 3x3 平均滤波器
    - 计算邻域平均值
    - 再次归一化到 [0, 1]
    - 返回平滑后的高度图

- nonlinear_stretch(input_data:Dictionary) -> Dictionary
  - @args:
    - input_data: 包含 height_map
  - @return Dictionary: 包含 seed, height_map
  - functions:
    - 低值 (<0.2): 压缩得更低 (深海)
    - 中值 (0.2-0.7): 尽量拉平 (平原)
    - 高值 (>0.7): 拉伸得更高 (山脉)
    - 返回拉伸后的高度图

## 地形掩码方法

- generate_terrain_mask(input_data:Dictionary) -> Dictionary
  - @args:
    - input_data: 包含 seed, height_map
  - @return Dictionary: 包含 seed, height_map, terrain_mask
  - functions:
    - 生成 8*8 的低分辨率噪声图
    - 放大到实际地图大小
    - 返回地形掩码

- regional_raise_lower(input_data:Dictionary) -> Dictionary
  - @args:
    - input_data: 包含 height_map, terrain_mask
  - @return Dictionary: 包含 seed, height_map
  - functions:
    - 山脉带 (>0.7): 抬升
    - 海洋带 (<0.2): 降低
    - 平原带：保留
    - 归一化到 [0, 1]
    - 返回调整后的高度图

- generate_heat_mask(input_data:Dictionary) -> Dictionary
  - @args:
    - input_data: 包含 seed, height_map
  - @return Dictionary: 包含 seed, height_map, heat_mask
  - functions:
    - 生成 4*4 的低分辨率噪声图
    - 放大到实际地图大小
    - 返回热度掩码

## 侵蚀算法

- water_erosion(input_data:Dictionary) -> Dictionary
  - @args:
    - input_data: 包含 height_map, heat_mask
  - @return Dictionary: 包含 seed, height_map, heat_mask
  - functions:
    - 随机选择非边缘格子
    - 只在湿润区域 (heat_mask >= 0.5) 执行
    - 找最陡下坡方向
    - 侵蚀源头，沉积到下游
    - 执行 CONFIG.water_erosion_iterations 次
    - 返回侵蚀后的高度图

- thermal_erosion(input_data:Dictionary) -> Dictionary
  - @args:
    - input_data: 包含 height_map, heat_mask
  - @return Dictionary: 包含 seed, height_map, heat_mask
  - functions:
    - 只在温暖区域 (heat_mask >= 0.5) 执行
    - 临界坡度 (>0.15): 坍塌 (高处降，低处升)
    - 小坡度 (<0.02): 放大差值
    - 执行 CONFIG.thermal_erosion_iterations 次
    - 确保值在 [0, 1] 范围内
    - 返回侵蚀后的高度图

- mix_processing(input_data:Dictionary) -> Dictionary
  - @args:
    - input_data: 包含 height_map, heat_mask, seed
  - @return Dictionary: 包含 seed, height_map
  - functions:
    - 大循环执行 CONFIG.combined_iterations 次
    - 先执行热侵蚀，形成陡峭地形
    - 再执行水流侵蚀，雕刻山谷
    - 返回混合侵蚀后的高度图

## 后处理方法

- quantile_mapping_process(input_data:Dictionary) -> Dictionary
  - @args:
    - input_data: 包含 height_map
  - @return Dictionary: 包含 seed, height_map
  - functions:
    - 收集所有高度值并排序
    - 计算每个值的分位数
    - 映射到目标分布 (更多平原，更少极端地形)
    - 使用 CONFIG.quantile_bins 和 quantile_weights
    - 返回映射后的高度图

- height_summarize_process(input_data:Dictionary) -> Dictionary
  - @args:
    - input_data: 包含 height_map
  - @return Dictionary: 包含 seed, height_map, height_levels
  - functions:
    - 2*2 格子取平均值，降低分辨率
    - 生成高度等级 (0-6)
    - 使用 CONFIG.quantile_bins 划分等级
    - 返回概括后的高度图和高度等级

- generate_color_map(input_data:Dictionary) -> Dictionary
  - @args:
    - input_data: 包含 height_levels
  - @return Dictionary: 包含 seed, height_levels, color_map
  - functions:
    - 根据高度等级生成颜色
    - 将 hex 颜色转换为 RGB
    - 返回颜色地图

## 主流程方法

- generate_map(seed:int, width:int, height:int) -> Dictionary
  - @args:
    - seed: 随机种子
    - width: 地图宽度，默认 512
    - height: 地图高度，默认 512
  - @return Dictionary: 包含 metadata 和 data
  - functions:
    - 1. 生成噪声图 (generate_noise_maps)
    - 2. 生成高度图 (generate_height_map)
    - 3. 归一化 (normalize_height_map)
    - 4. 平滑滤波 (smooth_filter)
    - 5. 非线性拉伸 (nonlinear_stretch)
    - 6. 生成地形掩码 (generate_terrain_mask)
    - 7. 区域性抬升 (regional_raise_lower)
    - 8. 生成热度掩码 (generate_heat_mask)
    - 9. 混合侵蚀 (mix_processing)
    - 10. 分位数映射 (quantile_mapping_process)
    - 11. 高度概括 (height_summarize_process)
    - 12. 生成颜色地图 (generate_color_map)
    - 构建最终数据结构
    - 返回完整的地图数据

- get_current_time() -> String
  - @return String: 当前时间字符串 (yyyy-MM-dd HH:mm:ss)
  - functions:
    - 使用 Time.get_datetime_dict_from_system()
    - 格式化时间字符串
    - 返回格式化后的时间

- _ready() -> void
  - functions:
    - 测试函数，遍历种子 0-9
    - 生成 10 张地图
    - 打印生成信息

# 数据文件

- 无直接依赖的数据文件
- 使用 CONFIG 常量配置参数

# 模块交互

## 调用的其他模块
- FastNoiseLite: Godot 内置噪声生成器
- SimplexNoise: Simplex 噪声类
- RandomNumberGenerator: 随机数生成
- Time: 时间获取

## 被其他模块调用
- MudMapGenerator: generate_map() 生成荒野地图

## 发送的事件
- 无

# 核心流程

## 完整地形生成流程 (12 步)

### 阶段 1：基础噪声生成 (步骤 1-2)
1. **生成噪声图**: 创建 3 张不同的噪声图
   - 使用 seed, seed+1, seed+2 作为种子
   - 执行分位数变换，映射为正态分布
   - 输出：noise_maps[3][height][width]

2. **生成高度图**: 将 3 张噪声图按权重叠加
   - 权重：[0.7, 0.2, 0.1]
   - 第一张为主，后两张补充细节
   - 输出：height_map[height][width]

### 阶段 2：地形特征塑造 (步骤 3-8)
3. **归一化**: 将高度值映射到 [0, 1]
   - 找到最小值和最大值
   - 线性映射

4. **平滑滤波**: 使用 3x3 平均滤波器
   - 计算邻域平均值
   - 去除噪声尖峰
   - 再次归一化

5. **非线性拉伸**: 增强地形特征
   - 低值 (<0.2): 压缩到 [0, 0.1] (深海)
   - 中值 (0.2-0.7): 压缩到 [0.1, 0.4] (平原)
   - 高值 (>0.7): 拉伸到 [0.4, 1.0] (山脉)

6. **生成地形掩码**: 8*8 低分辨率噪声
   - 放大到地图大小
   - 用于区域性调整

7. **区域性抬升/降低**: 根据掩码调整
   - 山脉 (>0.7): 抬升
   - 海洋 (<0.2): 降低
   - 平原：保留
   - 归一化

8. **生成热度掩码**: 4*4 低分辨率噪声
   - 放大到地图大小
   - 用于侵蚀算法

### 阶段 3：侵蚀处理 (步骤 9)
9. **混合侵蚀处理**: 结合热侵蚀和水流侵蚀
   - 循环 combined_iterations (100) 次
   - 每次循环:
     a. 热侵蚀：模拟热力坍塌
        - 临界坡度 >0.15: 坍塌
        - 小坡度 <0.02: 放大差值
     b. 水流侵蚀：模拟雨水雕刻
        - 随机选择湿润区域
        - 找最陡下坡
        - 侵蚀源头，沉积下游
   - 形成真实地形 (悬崖、山谷、河道)

### 阶段 4：后处理 (步骤 10-12)
10. **分位数映射**: 控制高度分布
    - 收集所有高度值并排序
    - 计算分位数
    - 映射到目标分布
    - 更多平原 (60%), 更少极端地形

11. **高度概括**: 降低分辨率
    - 2*2 格子取平均值
    - 分辨率减半 (512->256)
    - 生成高度等级 (0-6)
    - 便于后续使用

12. **生成颜色地图**: 可视化
    - 根据高度等级映射颜色
    - 0: 深海 (深蓝)
    - 1: 海洋 (蓝)
    - 2: 森林 (深绿)
    - 3: 草原 (黄)
    - 4: 丘陵 (橙)
    - 5: 山地 (红)
    - 6: 积雪 (黑)

## 侵蚀算法详解

### 水流侵蚀算法
```
for iteration in range(100):
    1. 随机选择非边缘格子 (x, y)
    2. 检查热度图，只在湿润区域执行 (heat_mask[y][x] >= 0.5)
    3. 找最陡下坡方向:
       - 检查九宫格邻居
       - 计算坡度 = current_height - neighbor_height
       - 选择坡度最大且 > min_slope (0.005) 的方向
    4. 如果找到下坡方向:
       - 侵蚀源头：height_map[y][x] -= slope * erosion_rate * heat_mask
       - 沉积下游：height_map[ny][nx] += erosion_amount * deposition_rate
```

### 热侵蚀算法
```
for iteration in range(100):
    for y in range(1, height-1):
        for x in range(1, width-1):
            if heat_mask[y][x] < 0.5: continue
            
            for each neighbor:
                height_diff = current - neighbor
                
                if height_diff > critical_slope (0.15):
                    # 坍塌：高处降，低处升
                    height_map[y][x] -= 0.05
                    height_map[ny][nx] += 0.05
                elif abs(height_diff) < small_slope (0.02):
                    # 放大差值，增强对比度
                    height_map[y][x] += 0.01
                    height_map[ny][nx] -= 0.01
```

## 分位数映射算法

### 目标分布
```
区间边界：[0.0, 0.1, 0.2, 0.4, 0.6, 0.8, 0.9, 1.0]
目标权重：[0.03, 0.07, 0.10, 0.60, 0.10, 0.07, 0.03]
累积权重：[0.0, 0.03, 0.10, 0.20, 0.80, 0.90, 0.97, 1.0]
```

### 映射过程
```
1. 收集所有高度值并排序
2. 对每个像素:
   a. 计算当前值的分位数 (排名/总数)
   b. 找到分位数所在的目标区间
   c. 线性映射到目标值
   d. 例如：分位数 0.5 在 [0.2, 0.8] 区间，映射到 [0.2, 0.4]
```

# 架构设计

## 管线化架构
- 12 个处理步骤，每步接收上一步输出
- 纯函数式设计，不修改输入数据
- 每步返回新字典，包含处理结果
- 易于调试和测试单个步骤

## 数据流设计
```
seed -> noise_maps -> height_map -> normalized -> smoothed -> stretched
    -> terrain_mask -> raised -> heat_mask -> eroded -> mapped -> summarized -> color_map
```

## 算法设计原则

### 1. 噪声叠加
- 使用 3 层噪声，权重递减 [0.7, 0.2, 0.1]
- 第一层：基础地形
- 第二层：中等细节
- 第三层：高频细节

### 2. 分位数变换
- 将均匀分布映射为正态分布
- 使用 Box-Muller 变换近似
- 使地形更自然 (更多中间值)

### 3. 非线性拉伸
- 增强地形对比度
- 压缩深海和平原
- 拉伸山脉

### 4. 侵蚀模拟
- 热侵蚀：形成陡峭悬崖
- 水流侵蚀：雕刻山谷河道
- 混合处理：先热后水，更真实

### 5. 分位数映射
- 控制地形分布
- 60% 平原，20% 丘陵，20% 极端地形
- 使游戏地图更平衡

## 性能优化

### 1. 分辨率降低
- 原始生成：512x512
- 最终输出：256x256 (2*2 平均)
- 减少后续处理数据量

### 2. 掩码优化
- 地形掩码：8*8 -> 放大
- 热度掩码：4*4 -> 放大
- 减少噪声计算量

### 3. 迭代次数控制
- 侵蚀算法：100 次
- 平衡效果和性能

## 应用场景

### 1. 荒野地图生成
- 主世界地图
- 野外区域
- 自然景观

### 2. 程序化内容
- 随机地图生成
- Roguelike 游戏
- 开放世界

### 3. 地形可视化
- 高度图渲染
- 颜色映射
- 3D 地形网格

# TODO

- [ ] 添加更多侵蚀算法 (冰川侵蚀、风蚀等)
- [ ] 支持河流生成 (从高处流向低处)
- [ ] 支持生物群系生成 (根据温度和湿度)
- [ ] 添加资源分布 (矿产、森林等)
- [ ] 支持 3D 地形网格生成
- [ ] 优化性能 (多线程、GPU 加速)
