# mod.WorldMapManager.Scripts.Core.SimplexNoise.gd 分析文档

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
SimplexNoise

## 模块路径
res/mods/WorldMapManager/Scripts/Core/SimplexNoise.gd

## 模块功能
Simplex 噪声实现类，用于生成程序化地形和不规则形状。主要职责包括:
1. 实现 Simplex 噪声算法
2. 生成 2D 噪声图
3. 使用排列数组 (permutation array) 实现噪声的随机性
4. 支持种子初始化，确保可重复生成

## 模块依赖
- RandomNumberGenerator: 随机数生成器
- 数学函数：sqrt, floor, int, floor

## 噪声数据结构
```
排列数组 (perm): 长度为 512 的数组 (256*2)
- 前 256 个元素是 0-255 的随机排列
- 后 256 个元素是前 256 个的复制，用于避免边界检查
```

## 模块用例

```gdscript
# 示例 1：创建 Simplex 噪声实例
var noise = SimplexNoise.new(12345)

# 示例 2：生成 2D 噪声值
var value = noise.noise2d(10.0, 20.0, 0.05)

# 示例 3：生成噪声图
var width = 256
var height = 256
var noise_map = []
for y in range(height):
    var row = []
    for x in range(width):
        var val = noise.noise2d(float(x), float(y), 0.05)
        row.append(val)
    noise_map.append(row)

# 示例 4：使用不同种子生成不同噪声
var noise1 = SimplexNoise.new(111)
var noise2 = SimplexNoise.new(222)
var val1 = noise1.noise2d(10.0, 20.0, 0.05)
var val2 = noise2.noise2d(10.0, 20.0, 0.05)
# val1 != val2
```

# 成员变量

- seed: int
  - 随机种子，用于初始化排列数组
  - 相同的种子会生成相同的噪声图

- perm: Array
  - 排列数组，长度为 512 (256*2)
  - 前 256 个元素是 0-255 的随机排列
  - 后 256 个元素是前 256 个的复制
  - 用于 Simplex 噪声的梯度选择

# 成员方法

- _init(seed:int) -> void
  - @args:
    - seed: 随机种子
  - functions:
    - 初始化 seed 和 perm 数组
    - 填充 perm 数组为 0-255
    - 使用 RandomNumberGenerator 打乱 perm 数组
    - 复制 perm 数组到末尾，形成长度为 512 的数组
    - 打乱算法：Fisher-Yates shuffle 的变体

- noise2d(x:float, y:float, scale:float) -> float
  - @args:
    - x: x 坐标
    - y: y 坐标
    - scale: 缩放因子，默认 0.05
  - @return float: 噪声值，范围约为 [-1, 1]
  - functions:
    - 应用缩放因子到 x 和 y
    - 计算 Simplex 坐标变换 (F2, G2 常量)
    - 确定当前点所在的单纯形 (三角形)
    - 计算三个顶点到当前点的距离
    - 使用梯度函数计算每个顶点的贡献
    - 返回三个贡献值的和乘以 70.0

- _grad(hash_val:int, x:float, y:float) -> float
  - @args:
    - hash_val: 哈希值，用于选择梯度方向
    - x: x 距离
    - y: y 距离
  - @return float: 梯度值
  - functions:
    - 根据 hash_val 的低 3 位选择梯度方向
    - 使用 x 或 y 作为基值
    - 根据哈希值决定符号
    - 返回梯度贡献值

# 数据文件

- 无直接依赖的数据文件

# 模块交互

## 调用的其他模块
- RandomNumberGenerator: 生成随机数用于打乱排列数组

## 被其他模块调用
- WildernessGen: simplex_noise() 生成噪声图
- TownGen: 生成不规则城镇轮廓

## 发送的事件
- 无

# 核心流程

## 排列数组初始化流程
1. 创建长度为 256 的数组，填充 0-255
2. 使用 RandomNumberGenerator 生成随机数
3. 执行 Fisher-Yates shuffle 算法:
   - 从后向前遍历数组
   - 对每个位置 i，随机选择 0-i 之间的位置 j
   - 交换 i 和 j 位置的元素
4. 复制前 256 个元素到数组末尾
5. 形成长度为 512 的排列数组

## 2D 噪声生成流程
1. 应用缩放因子到输入坐标
2. 计算单纯形坐标变换:
   - F2 = 0.5 * (sqrt(3.0) - 1.0)
   - G2 = (3.0 - sqrt(3.0)) / 6.0
   - s = (x + y) * F2
   - i = floor(x + s), j = floor(y + s)
3. 确定当前点所在的三角形顶点:
   - 计算 X0, Y0 (左下角)
   - 根据 x0, y0 大小确定中间顶点 (i1, j1)
   - 计算 x1, y1, x2, y2
4. 使用排列数组获取三个顶点的哈希值:
   - n0 = _grad(perm[i + perm[j]], x0, y0)
   - n1 = _grad(perm[i + i1 + perm[j + j1]], x1, y1)
   - n2 = _grad(perm[i + 1 + perm[j + 1]], x2, y2)
5. 返回 70.0 * (n0 + n1 + n2)

## 梯度计算流程
1. 取 hash_val 的低 3 位 (hash_val & 7)
2. 根据低 2 位决定使用 x 还是 y:
   - h < 4: u = y, v = x
   - h >= 4: u = x, v = y
3. 根据第 1 位和第 2 位决定符号:
   - h & 1 == 0: u 为正，否则为负
   - h & 2 == 0: v 为正，否则为负
4. 返回 u + v

# 架构设计

## Simplex 噪声算法
- 基于单纯形 (三角形) 的噪声算法
- 相比 Perlin 噪声，计算效率更高
- 噪声分布更均匀，方向性更好
- 支持任意维度的噪声生成

## 排列数组设计
- 使用 512 长度的数组避免边界检查
- 前 256 个元素随机排列
- 后 256 个元素复制前 256 个
- 使用 hash(i + hash(j)) 访问，确保随机性

## 常量设计
- F2 和 G2: Simplex 坐标变换常量
- 70.0: 归一化因子，使输出范围约为 [-1, 1]
- scale: 控制噪声的频率和细节程度

## 应用场景
- 地形生成：高度图、温度图、湿度图
- 纹理生成：云层、火焰、水流
- 程序化内容：植被分布、建筑布局
- 动画：自然运动、形变效果
