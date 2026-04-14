#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
地图生成器脚本

功能：
1. 生成Perlin噪声图
2. 叠加噪声图生成高度图
3. 归一化高度图
4. 平滑滤波处理
5. 颜色映射可视化

所有步骤都生成灰度图并放大16倍
输出文件保存在output目录下
"""

import os
import numpy as np
from PIL import Image

# 声明随机的全局种子
GLOBAL_SEED = 0
# 设置numpy的全局种子
np.random.seed(GLOBAL_SEED)


def create_output_dir():
    """
    创建输出目录
    """
    output_dir = 'output'
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
    return output_dir


def perlin_noise(width, height, seed_offset=0):
    """
    生成Perlin噪声图
    
    Args:
        width: 宽度
        height: 高度
        seed_offset: 基于全局种子的偏移量，用于生成不同的噪声图
    
    Returns:
        噪声图数组 (0-255)
    """
    # 使用基于全局种子的派生种子
    local_seed = GLOBAL_SEED + seed_offset
    np.random.seed(local_seed)
    
    # 生成基础噪声
    noise = np.random.rand(height, width)
    
    # 使用逆高斯函数/分位数变换，将均匀分布映射为正态分布
    # 利用Box-Muller变换生成正态分布
    def uniform_to_normal(uniform_values):
        """
        将均匀分布转换为正态分布
        使用Box-Muller变换
        """
        # 确保输入是[0, 1)范围
        uniform_values = np.clip(uniform_values, 1e-10, 1 - 1e-10)
        
        # Box-Muller变换
        u1 = uniform_values
        u2 = np.random.rand(height, width)
        
        z0 = np.sqrt(-2 * np.log(u1)) * np.cos(2 * np.pi * u2)
        
        # 将正态分布标准化到[0, 1]范围
        z_min = np.min(z0)
        z_max = np.max(z0)
        if z_max > z_min:
            normalized = (z0 - z_min) / (z_max - z_min)
        else:
            normalized = np.zeros_like(z0)
        
        return normalized
    
    # 应用分布变换
    noise_normal = uniform_to_normal(noise)
    
    # 简单的噪声平滑处理
    smoothed = np.zeros((height, width))
    scale = 10.0
    
    for y in range(height):
        for x in range(width):
            # 计算噪声值
            nx = x / scale
            ny = y / scale
            
            # 简单的插值噪声
            int_x = int(nx)
            int_y = int(ny)
            frac_x = nx - int_x
            frac_y = ny - int_y
            
            # 双线性插值
            a = noise_normal[y, x]
            b = noise_normal[y, min(x + 1, width - 1)] if x + 1 < width else noise_normal[y, x]
            c = noise_normal[min(y + 1, height - 1), x] if y + 1 < height else noise_normal[y, x]
            d = noise_normal[min(y + 1, height - 1), min(x + 1, width - 1)] if (y + 1 < height and x + 1 < width) else noise_normal[y, x]
            
            # 插值计算
            ab = a * (1 - frac_x) + b * frac_x
            cd = c * (1 - frac_x) + d * frac_x
            value = ab * (1 - frac_y) + cd * frac_y
            
            smoothed[y, x] = value * 255
    
    return smoothed.astype(np.uint8)


def save_image(array, path, pixel_size=1):
    """
    保存数组为图像，可选放大倍数
    
    Args:
        array: 图像数组
        path: 保存路径
        pixel_size: 每个像素点放大的倍数
    """
    # 获取数组形状
    if len(array.shape) == 3:
        # 彩色图
        height, width, _ = array.shape
    else:
        # 灰度图
        height, width = array.shape
    
    # 如果需要放大
    if pixel_size > 1:
        # 放大后的高度和宽度
        new_height = height * pixel_size
        new_width = width * pixel_size
        
        # 创建放大后的数组
        if len(array.shape) == 3:
            # 彩色图
            enlarged = np.zeros((new_height, new_width, 3), dtype=np.uint8)
        else:
            # 灰度图
            enlarged = np.zeros((new_height, new_width), dtype=np.uint8)
        
        # 填充放大后的像素
        for y in range(height):
            for x in range(width):
                for py in range(pixel_size):
                    for px in range(pixel_size):
                        if len(array.shape) == 3:
                            enlarged[y * pixel_size + py, x * pixel_size + px] = array[y, x]
                        else:
                            enlarged[y * pixel_size + py, x * pixel_size + px] = array[y, x]
        
        image = Image.fromarray(enlarged)
    else:
        # 不需要放大，直接保存
        image = Image.fromarray(array)
    
    image.save(path)


def apply_smooth_filter(array, height, width):
    """
    应用3*3平均滤波器
    
    Args:
        array: 输入数组
        height: 高度
        width: 宽度
    
    Returns:
        平滑后的数组
    """
    smoothed = np.zeros_like(array, dtype=np.float32)
    
    # 对中间区域应用3*3平均滤波器
    for y in range(1, height - 1):
        for x in range(1, width - 1):
            # 计算3*3区域的平均值
            smoothed[y, x] = np.mean(array[y-1:y+2, x-1:x+2])
    
    # 处理边界 - 对边界像素也应用平滑处理
    
    # 处理四个角落
    # 左上角
    smoothed[0, 0] = np.mean(array[0:2, 0:2])
    # 右上角
    smoothed[0, width-1] = np.mean(array[0:2, width-2:width])
    # 左下角
    smoothed[height-1, 0] = np.mean(array[height-2:height, 0:2])
    # 右下角
    smoothed[height-1, width-1] = np.mean(array[height-2:height, width-2:width])
    
    # 处理上下边缘的中间像素
    for x in range(1, width - 1):
        # 上边缘
        smoothed[0, x] = np.mean(array[0:2, x-1:x+2])
        # 下边缘
        smoothed[height-1, x] = np.mean(array[height-2:height, x-1:x+2])
    
    # 处理左右边缘的中间像素
    for y in range(1, height - 1):
        # 左边缘
        smoothed[y, 0] = np.mean(array[y-1:y+2, 0:2])
        # 右边缘
        smoothed[y, width-1] = np.mean(array[y-1:y+2, width-2:width])
    
    return smoothed


def normalize_array(array):
    """
    归一化数组到[0, 255]区间
    
    Args:
        array: 输入数组
    
    Returns:
        归一化后的数组 (0-255)
    """
    min_val = np.min(array)
    max_val = np.max(array)
    if max_val > min_val:
        normalized = (array - min_val) / (max_val - min_val) * 255
    else:
        normalized = np.zeros_like(array)
    return normalized.astype(np.uint8)


def main():
    """
    主函数
    """
    # 创建输出目录
    output_dir = create_output_dir()
    
    # 默认参数
    width = 32  # 更改为32*32
    height = 32  # 更改为32*32
    pixel_size = 16  # 放大16倍
    
    # 1.1 生成3张噪声图
    print("1.1 生成噪声图...")
    noise_maps = []
    for i in range(3):
        noise = perlin_noise(width, height, seed_offset=i)
        noise_maps.append(noise)
        save_path = os.path.join(output_dir, f'1.1.noise_{i+1}.png')
        save_image(noise, save_path, pixel_size)
        print(f"  保存噪声图 {i+1} 到 {save_path}")
    
    # 1.2 叠加噪声图生成高度图
    print("\n1.2 叠加噪声图生成高度图...")
    weights = [0.7, 0.2, 0.1]
    height_map = np.zeros((height, width), dtype=np.float32)
    
    for i, (noise, weight) in enumerate(zip(noise_maps, weights)):
        height_map += noise.astype(np.float32) * weight
    
    height_map_uint8 = height_map.astype(np.uint8)
    save_path = os.path.join(output_dir, '1.2.height_map.png')
    save_image(height_map_uint8, save_path, pixel_size)
    print(f"  保存高度图到 {save_path}")
    
    # 1.3 归一化高度图
    print("\n1.3 归一化高度图...")
    normalized_height_map = normalize_array(height_map)
    save_path = os.path.join(output_dir, '1.3.normalized_height_map.png')
    save_image(normalized_height_map, save_path, pixel_size)
    print(f"  保存归一化高度图到 {save_path}")
    
    # 1.4 平滑滤波
    print("\n1.4 平滑滤波...")
    # 应用平滑滤波器
    smoothed = apply_smooth_filter(normalized_height_map, height, width)
    # 归一化平滑后的结果
    smoothed_normalized = normalize_array(smoothed)
    save_path = os.path.join(output_dir, '1.4.smoothed_height_map.png')
    save_image(smoothed_normalized, save_path, pixel_size)
    print(f"  保存平滑后的高度图到 {save_path}")
    
    # 1.5 颜色映射可视化
    print("\n1.5 颜色映射可视化...")
    # 创建彩色图像
    color_visualized = np.zeros((height, width, 3), dtype=np.uint8)
    
    for y in range(height):
        for x in range(width):
            # 获取平滑后的灰度值并归一化到[0, 1]
            gray_value = smoothed_normalized[y, x] / 255.0
            
            # 颜色映射
            if gray_value <= 0.3:
                # [0,0.3] 为蓝色
                color = [0, 0, 255]
            else:
                # 其他范围保持灰度
                gray = int(gray_value * 255)
                color = [gray, gray, gray]
            
            color_visualized[y, x] = color
    
    save_path = os.path.join(output_dir, '1.5.visualized_height_map.png')
    save_image(color_visualized, save_path, pixel_size)
    print(f"  保存颜色映射可视化高度图到 {save_path}")
    
    # 2.1 非线性拉伸处理
    print("\n2.1 非线性拉伸处理...")
    stretched = np.zeros_like(smoothed_normalized, dtype=np.float32)
    
    for y in range(height):
        for x in range(width):
            # 获取平滑后的灰度值并归一化到[0, 1]
            value = smoothed_normalized[y, x] / 255.0
            
            # 非线性拉伸
            if value < 0.2:
                # 0~0.2 的低值：压缩得更低
                stretched[y, x] = (value / 0.2) * 0.1 * 255
            elif value < 0.7:
                # 0.2~0.7 的中值：尽量拉平
                stretched[y, x] = (0.1 + (value - 0.2) / 0.4 * 0.3) * 255
            else:
                # 0.7~1.0 的高值：拉伸得更高
                stretched[y, x] = (0.4 + (value - 0.7) / 0.4 * 0.7) * 255
    
    stretched_uint8 = stretched.astype(np.uint8)
    save_path = os.path.join(output_dir, '2.1.stretched_height_map.png')
    save_image(stretched_uint8, save_path, pixel_size)
    print(f"  保存非线性拉伸后的高度图到 {save_path}")
    
    # 2.2 生成地形抬升掩码
    print("\n2.2 生成地形抬升掩码...")
    mask_width = 8
    mask_height = 8
    mask_pixel_size = 128  # 放大128倍
    
    # 生成8*8的噪声图
    terrain_mask = perlin_noise(mask_width, mask_height, seed_offset=999)
    
    save_path = os.path.join(output_dir, '2.2.0.terrain_raise_mask.png')
    save_image(terrain_mask, save_path, mask_pixel_size)
    print(f"  保存地形抬升掩码到 {save_path}")
    
    # 2.2.1 区域性抬升/降低
    print("\n2.2.1 区域性抬升/降低...")
    raised = np.zeros_like(stretched, dtype=np.float32)
    
    # 计算掩码的缩放因子
    mask_scale_x = mask_width / width
    mask_scale_y = mask_height / height
    
    for y in range(height):
        for x in range(width):
            # 获取拉伸后的高度值并归一化到[0, 1]
            value = stretched[y, x] / 255.0
            
            # 获取对应位置的掩码值
            mask_x = min(int(x * mask_scale_x), mask_width - 1)
            mask_y = min(int(y * mask_scale_y), mask_height - 1)
            mask_value = terrain_mask[mask_y, mask_x] / 255.0
            
            if value > 0.7:
                # 山脉带：高度 = 原始高度 × 抬升系数（2.0），最低不低于0.7
                # 应用掩码值进行区域性调整
                raise_factor = 1.5 + mask_value * 0.5  # 1.5-2.0之间的抬升系数
                new_value = min(value * raise_factor, 1.0)
                new_value = max(new_value, 0.7)  # 保证是山脉而非丘陵
            elif value < 0.2:
                # 海洋带：高度 = 原始高度 × 降低系数（0.3），最高不超过0.2
                # 应用掩码值进行区域性调整
                lower_factor = 0.2 + mask_value * 0.1  # 0.2-0.3之间的降低系数
                new_value = max(value * lower_factor, 0.0)
                new_value = min(new_value, 0.2)  # 保证是深海
            else:
                # 平原带：保留拉伸后的平坦高度，不额外调整
                new_value = value
            
            raised[y, x] = new_value * 255
    
    raised_uint8 = raised.astype(np.uint8)
    save_path = os.path.join(output_dir, '2.2.1.raised_height_map.png')
    save_image(raised_uint8, save_path, pixel_size)
    print(f"  保存区域性抬升/降低后的高度图到 {save_path}")
    
    # 3.0 生成热度图掩码
    print("\n3.0 生成热度图掩码...")
    mask_width = 4
    mask_height = 4
    mask_pixel_size = 256  # 放大256倍
    
    # 生成4*4的噪声图作为热度图掩码
    water_erosion_mask = perlin_noise(mask_width, mask_height, seed_offset=1000)
    
    save_path = os.path.join(output_dir, '3.0.0.water_erosion_mask.png')
    save_image(water_erosion_mask, save_path, mask_pixel_size)
    print(f"  保存热度图掩码到 {save_path}")
    
    # 3.1 水流侵蚀
    print("\n3.1 水流侵蚀...")
    water_eroded = np.zeros_like(raised, dtype=np.float32)
    
    # 复制原始高度图
    water_eroded = raised.copy()
    
    # 水流侵蚀参数
    iterations = 100
    min_slope = 0.005  # 最小坡度，低于此值水不流动
    base_erosion = 0.005  # 基础侵蚀量
    base_deposition = 0.003  # 基础沉积量
    
    # 8个方向的偏移
    directions = [(-1, -1), (-1, 0), (-1, 1),
                 (0, -1),          (0, 1),
                 (1, -1),  (1, 0),  (1, 1)]
    
    # 计算热度图掩码的缩放因子
    mask_scale_x = mask_width / width
    mask_scale_y = mask_height / height
    
    for _ in range(iterations):
        # 第二步：随机选地方 "下雨"（避免地形偏向）
        # 收集所有非边缘格子
        non_edge_cells = []
        for y in range(1, height - 1):
            for x in range(1, width - 1):
                non_edge_cells.append((y, x))
        
        # 打乱顺序
        np.random.shuffle(non_edge_cells)
        
        # 遍历打乱后的格子
        for (y, x) in non_edge_cells:
            current_height = water_eroded[y, x] / 255.0
            
            # 结合热度图：检查当前格子的雨水热度
            mask_x = min(int(x * mask_scale_x), mask_width - 1)
            mask_y = min(int(y * mask_scale_y), mask_height - 1)
            heat_value = water_erosion_mask[mask_y, mask_x] / 255.0
            
            # 如果热度低于0.5（干旱），跳过
            if heat_value < 0.5:
                continue
            
            # 热度高于0.5（湿润），热度越高，水流越急
            intensity_factor = 1.0 + (heat_value - 0.5) * 2.0  # 1.0-2.0之间
            
            # 第三步：找 "水往哪流"（最陡下坡方向）
            steepest_slope = 0
            best_direction = None
            
            for dy, dx in directions:
                neighbor_y = y + dy
                neighbor_x = x + dx
                neighbor_height = water_eroded[neighbor_y, neighbor_x] / 255.0
                slope = current_height - neighbor_height
                
                # 只有下坡方向且坡度够陡才考虑
                if slope > steepest_slope and slope > min_slope:
                    steepest_slope = slope
                    best_direction = (dy, dx)
            
            # 如果没有合适的下坡方向，跳过
            if best_direction is None:
                continue
            
            # 第四步："水流冲泥土"（侵蚀上游）
            # 侵蚀量与坡度和热度相关
            erosion_amount = base_erosion * steepest_slope * intensity_factor
            
            # 侵蚀当前格子
            new_height = current_height - erosion_amount
            new_height = max(0, new_height)  # 保证不低于0
            water_eroded[y, x] = new_height * 255
            
            # 第五步："泥土堆下来"（沉积下游）
            dy, dx = best_direction
            neighbor_y = y + dy
            neighbor_x = x + dx
            
            # 沉积量与坡度和热度相关
            deposition_amount = base_deposition * steepest_slope * intensity_factor
            
            # 沉积到下游
            neighbor_height = water_eroded[neighbor_y, neighbor_x] / 255.0
            new_neighbor_height = neighbor_height + deposition_amount
            new_neighbor_height = min(1.0, new_neighbor_height)  # 保证不超过1
            water_eroded[neighbor_y, neighbor_x] = new_neighbor_height * 255
    
    # 处理边缘的水流侵蚀
    # 对边缘格子进行简单的侵蚀处理
    for y in range(height):
        for x in range(width):
            if y == 0 or y == height-1 or x == 0 or x == width-1:
                # 边缘格子也需要水流侵蚀
                current_height = water_eroded[y, x] / 255.0
                
                # 计算平均坡度
                total_slope = 0
                count = 0
                
                for dy, dx in directions:
                    neighbor_y = y + dy
                    neighbor_x = x + dx
                    if 0 <= neighbor_y < height and 0 <= neighbor_x < width:
                        neighbor_height = water_eroded[neighbor_y, neighbor_x] / 255.0
                        slope = current_height - neighbor_height
                        if slope > min_slope:
                            total_slope += slope
                            count += 1
                
                if count > 0:
                    avg_slope = total_slope / count
                    # 轻微侵蚀边缘
                    erosion_amount = base_erosion * avg_slope * 0.5  # 边缘侵蚀量减半
                    new_height = max(0, current_height - erosion_amount)
                    water_eroded[y, x] = new_height * 255
    
    water_eroded_uint8 = water_eroded.astype(np.uint8)
    save_path = os.path.join(output_dir, '3.1.water_eroded_height_map.png')
    save_image(water_eroded_uint8, save_path, pixel_size)
    print(f"  保存水流侵蚀后的高度图到 {save_path}")
    
    # 3.2 热侵蚀
    print("\n3.2 热侵蚀...")
    thermal_eroded = np.zeros_like(raised, dtype=np.float32)
    
    # 复制原始高度图
    thermal_eroded = raised.copy()
    
    # 热侵蚀参数
    thermal_iterations = 100
    critical_slope = 0.15  # 临界值
    small_slope = 0.02     # 过小的高度差
    collapse_amount = 0.05  # 坍塌量
    amplify_amount = 0.01   # 放大差值量
    
    for _ in range(thermal_iterations):
        # 对每个格子进行处理（包括边缘）
        for y in range(height):
            for x in range(width):
                # 根据热度图执行热侵蚀，热度图值大于0.5的区域才执行
                mask_x = min(int(x * mask_scale_x), mask_width - 1)
                mask_y = min(int(y * mask_scale_y), mask_height - 1)
                heat_value = water_erosion_mask[mask_y, mask_x] / 255.0
                
                # 只有热度值大于0.5的区域才执行热侵蚀
                if heat_value > 0.5:
                    current_height = thermal_eroded[y, x] / 255.0
                    
                    # 计算与相邻格子的高度差
                    for dy, dx in directions:
                        neighbor_y = y + dy
                        neighbor_x = x + dx
                        if 0 <= neighbor_y < height and 0 <= neighbor_x < width:
                            neighbor_height = thermal_eroded[neighbor_y, neighbor_x] / 255.0
                            height_diff = current_height - neighbor_height
                            
                            if abs(height_diff) > critical_slope:
                                # 高度差超过临界值，高处坍塌到低处
                                if height_diff > 0:
                                    # 当前格子更高，降低当前格子，升高邻居
                                    thermal_eroded[y, x] = max(0, thermal_eroded[y, x] - collapse_amount * 255)
                                    thermal_eroded[neighbor_y, neighbor_x] = min(255, thermal_eroded[neighbor_y, neighbor_x] + collapse_amount * 255)
                                else:
                                    # 邻居更高，降低邻居，升高当前格子
                                    thermal_eroded[neighbor_y, neighbor_x] = max(0, thermal_eroded[neighbor_y, neighbor_x] - collapse_amount * 255)
                                    thermal_eroded[y, x] = min(255, thermal_eroded[y, x] + collapse_amount * 255)
                            elif abs(height_diff) < small_slope:
                                # 高度差过小，放大差值
                                if height_diff > 0:
                                    # 当前格子略高，进一步升高
                                    thermal_eroded[y, x] = min(255, thermal_eroded[y, x] + amplify_amount * 255)
                                    thermal_eroded[neighbor_y, neighbor_x] = max(0, thermal_eroded[neighbor_y, neighbor_x] - amplify_amount * 255)
                                else:
                                    # 邻居略高，进一步升高邻居
                                    thermal_eroded[neighbor_y, neighbor_x] = min(255, thermal_eroded[neighbor_y, neighbor_x] + amplify_amount * 255)
                                    thermal_eroded[y, x] = max(0, thermal_eroded[y, x] - amplify_amount * 255)
    
    thermal_eroded_uint8 = thermal_eroded.astype(np.uint8)
    save_path = os.path.join(output_dir, '3.2.thermal_eroded_height_map.png')
    save_image(thermal_eroded_uint8, save_path, pixel_size)
    print(f"  保存热侵蚀后的高度图到 {save_path}")
    
    # 3.3.0 混合处理
    print("\n3.3.0 混合处理...")
    
    # A: 水流侵蚀
    save_path = os.path.join(output_dir, '3.3.0.A.water_eroded.png')
    save_image(water_eroded_uint8, save_path, pixel_size)
    print(f"  保存水流侵蚀结果到 {save_path}")
    
    # B: 热侵蚀
    save_path = os.path.join(output_dir, '3.3.0.B.thermal_eroded.png')
    save_image(thermal_eroded_uint8, save_path, pixel_size)
    print(f"  保存热侵蚀结果到 {save_path}")
    
    # A+B: 先水流侵蚀，再热侵蚀
    ab_eroded = np.zeros_like(water_eroded, dtype=np.float32)
    ab_eroded = water_eroded.copy()
    
    # 对水流侵蚀结果应用热侵蚀
    for _ in range(thermal_iterations):
        for y in range(height):
            for x in range(width):
                # 根据热度图执行热侵蚀，热度图值大于0.5的区域才执行
                mask_x = min(int(x * mask_scale_x), mask_width - 1)
                mask_y = min(int(y * mask_scale_y), mask_height - 1)
                heat_value = water_erosion_mask[mask_y, mask_x] / 255.0
                
                # 只有热度值大于0.5的区域才执行热侵蚀
                if heat_value > 0.5:
                    current_height = ab_eroded[y, x] / 255.0
                    for dy, dx in directions:
                        neighbor_y = y + dy
                        neighbor_x = x + dx
                        if 0 <= neighbor_y < height and 0 <= neighbor_x < width:
                            neighbor_height = ab_eroded[neighbor_y, neighbor_x] / 255.0
                            height_diff = current_height - neighbor_height
                            
                            if abs(height_diff) > critical_slope:
                                if height_diff > 0:
                                    ab_eroded[y, x] = max(0, ab_eroded[y, x] - collapse_amount * 255)
                                    ab_eroded[neighbor_y, neighbor_x] = min(255, ab_eroded[neighbor_y, neighbor_x] + collapse_amount * 255)
                                else:
                                    ab_eroded[neighbor_y, neighbor_x] = max(0, ab_eroded[neighbor_y, neighbor_x] - collapse_amount * 255)
                                    ab_eroded[y, x] = min(255, ab_eroded[y, x] + collapse_amount * 255)
                            elif abs(height_diff) < small_slope:
                                if height_diff > 0:
                                    ab_eroded[y, x] = min(255, ab_eroded[y, x] + amplify_amount * 255)
                                    ab_eroded[neighbor_y, neighbor_x] = max(0, ab_eroded[neighbor_y, neighbor_x] - amplify_amount * 255)
                                else:
                                    ab_eroded[neighbor_y, neighbor_x] = min(255, ab_eroded[neighbor_y, neighbor_x] + amplify_amount * 255)
                                    ab_eroded[y, x] = max(0, ab_eroded[y, x] - amplify_amount * 255)
    
    ab_eroded_uint8 = ab_eroded.astype(np.uint8)
    save_path = os.path.join(output_dir, '3.3.0.A+B.water_then_thermal.png')
    save_image(ab_eroded_uint8, save_path, pixel_size)
    print(f"  保存先水流后热侵蚀结果到 {save_path}")
    
    # B+A: 先热侵蚀，再水流侵蚀
    ba_eroded = np.zeros_like(thermal_eroded, dtype=np.float32)
    ba_eroded = thermal_eroded.copy()
    
    # 对热侵蚀结果应用水流侵蚀
    for _ in range(iterations):
        # 收集所有非边缘格子
        non_edge_cells = []
        for y in range(1, height - 1):
            for x in range(1, width - 1):
                non_edge_cells.append((y, x))
        
        # 打乱顺序
        np.random.shuffle(non_edge_cells)
        
        # 遍历打乱后的格子
        for (y, x) in non_edge_cells:
            current_height = ba_eroded[y, x] / 255.0
            
            # 结合热度图：检查当前格子的雨水热度
            mask_x = min(int(x * mask_scale_x), mask_width - 1)
            mask_y = min(int(y * mask_scale_y), mask_height - 1)
            heat_value = water_erosion_mask[mask_y, mask_x] / 255.0
            
            # 如果热度低于0.5（干旱），跳过
            if heat_value < 0.5:
                continue
            
            # 热度高于0.5（湿润），热度越高，水流越急
            intensity_factor = 1.0 + (heat_value - 0.5) * 2.0  # 1.0-2.0之间
            
            # 找最陡下坡方向
            steepest_slope = 0
            best_direction = None
            
            for dy, dx in directions:
                neighbor_y = y + dy
                neighbor_x = x + dx
                neighbor_height = ba_eroded[neighbor_y, neighbor_x] / 255.0
                slope = current_height - neighbor_height
                
                # 只有下坡方向且坡度够陡才考虑
                if slope > steepest_slope and slope > min_slope:
                    steepest_slope = slope
                    best_direction = (dy, dx)
            
            if best_direction is not None:
                dy, dx = best_direction
                neighbor_y = y + dy
                neighbor_x = x + dx
                
                # 侵蚀当前格子
                erosion_amount = base_erosion * steepest_slope * intensity_factor
                new_height = max(0, current_height - erosion_amount)
                ba_eroded[y, x] = new_height * 255
                
                # 在下游沉积
                deposition_amount = base_deposition * steepest_slope * intensity_factor
                neighbor_height = ba_eroded[neighbor_y, neighbor_x] / 255.0
                new_neighbor_height = min(1.0, neighbor_height + deposition_amount)
                ba_eroded[neighbor_y, neighbor_x] = new_neighbor_height * 255
    
    # 处理边缘的水流侵蚀
    for y in range(height):
        for x in range(width):
            if y == 0 or y == height-1 or x == 0 or x == width-1:
                current_height = ba_eroded[y, x] / 255.0
                total_slope = 0
                count = 0
                for dy, dx in directions:
                    neighbor_y = y + dy
                    neighbor_x = x + dx
                    if 0 <= neighbor_y < height and 0 <= neighbor_x < width:
                        neighbor_height = ba_eroded[neighbor_y, neighbor_x] / 255.0
                        slope = current_height - neighbor_height
                        if slope > min_slope:
                            total_slope += slope
                            count += 1
                if count > 0:
                    avg_slope = total_slope / count
                    erosion_amount = base_erosion * avg_slope * 0.5
                    new_height = max(0, current_height - erosion_amount)
                    ba_eroded[y, x] = new_height * 255
    
    ba_eroded_uint8 = ba_eroded.astype(np.uint8)
    save_path = os.path.join(output_dir, '3.3.0.B+A.thermal_then_water.png')
    save_image(ba_eroded_uint8, save_path, pixel_size)
    print(f"  保存先热后水流侵蚀结果到 {save_path}")
    
    # B+A+B+A+...（顺序循环）
    print("\n3.3.0 顺序循环处理...")
    cycle_eroded = np.zeros_like(thermal_eroded, dtype=np.float32)
    cycle_eroded = thermal_eroded.copy()
    
    # 执行多次循环：B+A+B+A
    for cycle in range(iterations):
        # 先应用水流侵蚀（A）
        # 收集所有非边缘格子
        non_edge_cells = []
        for y in range(1, height - 1):
            for x in range(1, width - 1):
                non_edge_cells.append((y, x))
        
        # 打乱顺序
        np.random.shuffle(non_edge_cells)
        
        # 遍历打乱后的格子
        for (y, x) in non_edge_cells:
            current_height = cycle_eroded[y, x] / 255.0
            
            # 结合热度图：检查当前格子的雨水热度
            mask_x = min(int(x * mask_scale_x), mask_width - 1)
            mask_y = min(int(y * mask_scale_y), mask_height - 1)
            heat_value = water_erosion_mask[mask_y, mask_x] / 255.0
            
            # 如果热度低于0.5（干旱），跳过
            if heat_value < 0.5:
                continue
            
            # 热度高于0.5（湿润），热度越高，水流越急
            intensity_factor = 1.0 + (heat_value - 0.5) * 2.0  # 1.0-2.0之间
            
            # 找最陡下坡方向
            steepest_slope = 0
            best_direction = None
            
            for dy, dx in directions:
                neighbor_y = y + dy
                neighbor_x = x + dx
                neighbor_height = cycle_eroded[neighbor_y, neighbor_x] / 255.0
                slope = current_height - neighbor_height
                
                # 只有下坡方向且坡度够陡才考虑
                if slope > steepest_slope and slope > min_slope:
                    steepest_slope = slope
                    best_direction = (dy, dx)
            
            if best_direction is not None:
                dy, dx = best_direction
                neighbor_y = y + dy
                neighbor_x = x + dx
                
                # 侵蚀当前格子
                erosion_amount = base_erosion * steepest_slope * intensity_factor
                new_height = max(0, current_height - erosion_amount)
                cycle_eroded[y, x] = new_height * 255
                
                # 在下游沉积
                deposition_amount = base_deposition * steepest_slope * intensity_factor
                neighbor_height = cycle_eroded[neighbor_y, neighbor_x] / 255.0
                new_neighbor_height = min(1.0, neighbor_height + deposition_amount)
                cycle_eroded[neighbor_y, neighbor_x] = new_neighbor_height * 255
    
        # 再应用热侵蚀（B）
        for y in range(height):
            for x in range(width):
                # 根据热度图执行热侵蚀，热度图值大于0.5的区域才执行
                mask_x = min(int(x * mask_scale_x), mask_width - 1)
                mask_y = min(int(y * mask_scale_y), mask_height - 1)
                heat_value = water_erosion_mask[mask_y, mask_x] / 255.0
                
                # 只有热度值大于0.5的区域才执行热侵蚀
                if heat_value > 0.5:
                    current_height = cycle_eroded[y, x] / 255.0
                    
                    # 计算与相邻格子的高度差
                    for dy, dx in directions:
                        neighbor_y = y + dy
                        neighbor_x = x + dx
                        if 0 <= neighbor_y < height and 0 <= neighbor_x < width:
                            neighbor_height = cycle_eroded[neighbor_y, neighbor_x] / 255.0
                            height_diff = current_height - neighbor_height
                            
                            if abs(height_diff) > critical_slope:
                                # 高度差超过临界值，高处坍塌到低处
                                if height_diff > 0:
                                    # 当前格子更高，降低当前格子，升高邻居
                                    cycle_eroded[y, x] = max(0, cycle_eroded[y, x] - collapse_amount * 255)
                                    cycle_eroded[neighbor_y, neighbor_x] = min(255, cycle_eroded[neighbor_y, neighbor_x] + collapse_amount * 255)
                                else:
                                    # 邻居更高，降低邻居，升高当前格子
                                    cycle_eroded[neighbor_y, neighbor_x] = max(0, cycle_eroded[neighbor_y, neighbor_x] - collapse_amount * 255)
                                    cycle_eroded[y, x] = min(255, cycle_eroded[y, x] + collapse_amount * 255)
                            elif abs(height_diff) < small_slope:
                                # 高度差过小，放大差值
                                if height_diff > 0:
                                    # 当前格子略高，进一步升高
                                    cycle_eroded[y, x] = min(255, cycle_eroded[y, x] + amplify_amount * 255)
                                    cycle_eroded[neighbor_y, neighbor_x] = max(0, cycle_eroded[neighbor_y, neighbor_x] - amplify_amount * 255)
                                else:
                                    # 邻居略高，进一步升高邻居
                                    cycle_eroded[neighbor_y, neighbor_x] = min(255, cycle_eroded[neighbor_y, neighbor_x] + amplify_amount * 255)
                                    cycle_eroded[y, x] = max(0, cycle_eroded[y, x] - amplify_amount * 255)

    # 处理边缘
    for y in range(height):
        for x in range(width):
            if y == 0 or y == height-1 or x == 0 or x == width-1:
                current_height = cycle_eroded[y, x] / 255.0
                total_slope = 0
                count = 0
                for dy, dx in directions:
                    neighbor_y = y + dy
                    neighbor_x = x + dx
                    if 0 <= neighbor_y < height and 0 <= neighbor_x < width:
                        neighbor_height = cycle_eroded[neighbor_y, neighbor_x] / 255.0
                        slope = current_height - neighbor_height
                        if slope > min_slope:
                            total_slope += slope
                            count += 1
                if count > 0:
                    avg_slope = total_slope / count
                    erosion_amount = base_erosion * avg_slope * 0.5
                    new_height = max(0, current_height - erosion_amount)
                    cycle_eroded[y, x] = new_height * 255
    
    cycle_eroded_uint8 = cycle_eroded.astype(np.uint8)
    save_path = os.path.join(output_dir, '3.3.0.cycle.B+A+B+A.png')
    save_image(cycle_eroded_uint8, save_path, pixel_size)
    print(f"  保存顺序循环处理结果到 {save_path}")
    
    # 3.3.1 生成灰度step取0.15的灰度图
    print("\n3.3.1 生成灰度step取0.15的灰度图...")
    
    def generate_step_gray_map(array, step=0.2):
        """
        生成灰度step取0.15的灰度图
        
        Args:
            array: 输入数组 (0-255)
            step: 灰度步长，默认为0.15
            
        Returns:
            处理后的数组
        """
        height, width = array.shape
        step_map = np.zeros_like(array, dtype=np.uint8)
        
        for y in range(height):
            for x in range(width):
                # 将值归一化到[0, 1]
                value = array[y, x] / 255.0
                # 取最接近的step倍数
                stepped_value = round(value / step) * step
                # 确保值在[0, 1]范围内
                stepped_value = max(0.0, min(1.0, stepped_value))
                # 映射回[0, 255]
                step_map[y, x] = int(stepped_value * 255)
        
        return step_map
    
    # 处理五个结果
    results = [
        ('A.water_eroded', water_eroded_uint8),
        ('B.thermal_eroded', thermal_eroded_uint8),
        ('A+B.water_then_thermal', ab_eroded_uint8),
        ('B+A.thermal_then_water', ba_eroded_uint8),
        ('cycle.B+A+B+A', cycle_eroded_uint8)
    ]
    
    for name, result_array in results:
        # 生成灰度step取0.15的灰度图
        step_map = generate_step_gray_map(result_array)
        save_path = os.path.join(output_dir, f'3.3.1.{name}.png')
        save_image(step_map, save_path, pixel_size)
        print(f"  保存灰度step取0.15的{name}结果到 {save_path}")
    
    # 3.4.0 轻量后平滑
    print("\n3.4.0 轻量后平滑...")
    
    def lightweight_smooth(array):
        """
        执行轻量后平滑
        
        Args:
            array: 输入数组 (0-255)
            
        Returns:
            平滑后的数组
        """
        height, width = array.shape
        smoothed = np.copy(array)
        
        # 只处理内部格子，边缘不动
        for y in range(1, height - 1):
            for x in range(1, width - 1):
                # 获取当前高度并归一化到[0, 1]
                current_height = array[y, x] / 255.0
                
                # 跳过极端地形
                if current_height > 0.8 or current_height < 0.2:
                    continue
                
                # 计算周围8格的高度平均值
                neighbors_sum = 0.0  # 使用浮点数避免溢出
                count = 0
                for dy in [-1, 0, 1]:
                    for dx in [-1, 0, 1]:
                        if dy == 0 and dx == 0:
                            continue  # 跳过自身
                        neighbors_sum += array[y + dy, x + dx]
                        count += 1
                
                # 计算加权平均值
                neighbors_avg = neighbors_sum / count
                smoothed_value = current_height * 0.7 + (neighbors_avg / 255.0) * 0.3
                
                # 映射回[0, 255]
                smoothed[y, x] = int(smoothed_value * 255)
        
        return smoothed
    
    # 处理3.3.0的五个结果
    smooth_results = []
    for name, result_array in results:
        # 执行轻量后平滑
        smoothed_array = lightweight_smooth(result_array)
        
        # 保存结果
        save_path = os.path.join(output_dir, f'3.4.0.{name}.png')
        save_image(smoothed_array, save_path, pixel_size)
        print(f"  保存轻量后平滑的{name}结果到 {save_path}")
        
        # 保存到结果列表，用于后续处理
        smooth_results.append((name, smoothed_array))
    
    # 3.4.1 生成灰度step取0.1的灰度图
    print("\n3.4.1 生成灰度step取0.1的灰度图...")
    
    for name, result_array in smooth_results:
        # 生成灰度step取0.1的灰度图
        step_map = generate_step_gray_map(result_array, step=0.1)
        save_path = os.path.join(output_dir, f'3.4.1.{name}.png')
        save_image(step_map, save_path, pixel_size)
        print(f"  保存灰度step取0.1的{name}结果到 {save_path}")
    
    # 3.4.2 生成灰度step取0.15的灰度图
    print("\n3.4.2 生成灰度step取0.15的灰度图...")
    
    for name, result_array in smooth_results:
        # 生成灰度step取0.15的灰度图
        step_map = generate_step_gray_map(result_array, step=0.15)
        save_path = os.path.join(output_dir, f'3.4.2.{name}.png')
        save_image(step_map, save_path, pixel_size)
        print(f"  保存灰度step取0.15的{name}结果到 {save_path}")
    
    # 3.5.0 高度概括
    print("\n3.5.0 高度概括...")
    
    def height_summarize(array, grid_size=4):
        """
        对高度图进行概括处理
        每一个grid_size*grid_size的格子，取其内部所有格子的高度，取其平均值，作为该格子的高度
        
        Args:
            array: 输入数组 (0-255)
            grid_size: 格子大小，默认为4
            
        Returns:
            概括后的数组
        """
        height, width = array.shape
        # 计算输出尺寸
        out_height = (height + grid_size - 1) // grid_size
        out_width = (width + grid_size - 1) // grid_size
        
        summarized = np.zeros((out_height, out_width), dtype=np.uint8)
        
        for y in range(out_height):
            for x in range(out_width):
                # 计算当前grid_size*grid_size块的起始和结束坐标
                start_y = y * grid_size
                end_y = min(start_y + grid_size, height)
                start_x = x * grid_size
                end_x = min(start_x + grid_size, width)
                
                # 取内部所有格子的高度
                block = array[start_y:end_y, start_x:end_x]
                # 计算平均值
                avg_height = np.mean(block)
                
                summarized[y, x] = int(avg_height)
        
        return summarized
    
    # 处理3.4.0的五个结果（根据README.md的最新要求）
    summarize_results = []
    summarize_results_2x2 = []  # 保存2x2结果
    summarize_results_4x4 = []  # 保存4x4结果
    for name, result_array in smooth_results:
        # 执行2x2高度概括
        summarized_2x2 = height_summarize(result_array, 2)
        # 计算2x2的放大倍数，确保输出为512*512
        scale_2x2 = 512 // summarized_2x2.shape[1]
        # 保存结果（放大到512*512）
        save_path_2x2 = os.path.join(output_dir, f'3.5.0.2x2.{name}.png')
        save_image(summarized_2x2, save_path_2x2, scale_2x2)  # 放大到512*512
        print(f"  保存2x2高度概括的{name}结果到 {save_path_2x2}")
        
        # 执行4x4高度概括
        summarized_4x4 = height_summarize(result_array, 4)
        # 计算4x4的放大倍数，确保输出为512*512
        scale_4x4 = 512 // summarized_4x4.shape[1]
        # 保存结果（放大到512*512）
        save_path_4x4 = os.path.join(output_dir, f'3.5.0.4x4.{name}.png')
        save_image(summarized_4x4, save_path_4x4, scale_4x4)  # 放大到512*512
        print(f"  保存4x4高度概括的{name}结果到 {save_path_4x4}")
        
        # 保存结果到列表，用于后续处理
        summarize_results_2x2.append((f"2x2.{name}", summarized_2x2))
        summarize_results_4x4.append((f"4x4.{name}", summarized_4x4))
        summarize_results.append((name, summarized_4x4))
    
    # 3.5.1 生成灰度step取0.1的灰度图
    print("\n3.5.1 生成灰度step取0.1的灰度图...")
    
    # 处理2x2结果
    for name, result_array in summarize_results_2x2:
        # 生成灰度step取0.1的灰度图
        step_map = generate_step_gray_map(result_array, step=0.1)
        # 计算放大倍数，确保输出为512*512
        scale = 512 // step_map.shape[1]
        # 保存结果（放大到512*512）
        save_path = os.path.join(output_dir, f'3.5.1.{name}.png')
        save_image(step_map, save_path, scale)  # 放大到512*512
        print(f"  保存灰度step取0.1的{name}结果到 {save_path}")
    
    # 处理4x4结果
    for name, result_array in summarize_results_4x4:
        # 生成灰度step取0.1的灰度图
        step_map = generate_step_gray_map(result_array, step=0.1)
        # 计算放大倍数，确保输出为512*512
        scale = 512 // step_map.shape[1]
        # 保存结果（放大到512*512）
        save_path = os.path.join(output_dir, f'3.5.1.{name}.png')
        save_image(step_map, save_path, scale)  # 放大到512*512
        print(f"  保存灰度step取0.1的{name}结果到 {save_path}")
    
    # 3.5.2 根据灰度映射表生成颜色图
    print("\n3.5.2 根据灰度映射表生成颜色图...")
    
    def generate_color_map(array):
        """
        根据灰度映射表生成颜色图
        
        Args:
            array: 输入数组 (0-255)
            
        Returns:
            颜色图数组
        """
        height, width = array.shape
        color_map = np.zeros((height, width, 3), dtype=np.uint8)
        
        # 灰度颜色映射表
        color_mapping = [
            (0.0, 0.1, [0, 0, 0]),      # 黑色
            (0.1, 0.2, [0, 0, 255]),    # 蓝色
            (0.2, 0.3, [0, 255, 0]),    # 绿色
            (0.3, 0.4, [255, 255, 0]),  # 黄色
            (0.4, 0.5, [255, 165, 0]),  # 橙色
            (0.5, 0.6, [255, 0, 0]),    # 红色
            (0.6, 0.7, [128, 0, 128]),  # 紫色
            (0.7, 0.8, [0, 255, 255]),  # 青色
            (0.8, 0.9, [255, 255, 255])  # 白色
        ]
        
        for y in range(height):
            for x in range(width):
                # 将值归一化到[0, 1]
                value = array[y, x] / 255.0
                
                # 根据灰度值选择颜色
                for min_val, max_val, color in color_mapping:
                    if min_val <= value < max_val:
                        color_map[y, x] = color
                        break
                else:
                    # 默认颜色
                    color_map[y, x] = [0, 0, 0]
        
        return color_map
    
    # 3.5.2 处理（对3.5.0的结果）
    print("\n3.5.2 根据灰度映射表生成颜色图...")
    
    def generate_color_map_v3(array):
        """
        根据灰度映射表生成颜色图（使用3.5.2的映射表）
        
        Args:
            array: 输入数组 (0-255)
            
        Returns:
            颜色图数组
        """
        height, width = array.shape
        color_map = np.zeros((height, width, 3), dtype=np.uint8)
        
        # 3.5.2的灰度颜色映射表
        color_mapping = [
            (0.0, 0.1, [0, 0, 139]),    # 深蓝色
            (0.1, 0.2, [0, 0, 255]),    # 蓝色
            (0.2, 0.4, [0, 100, 0]),    # 深绿色
            (0.4, 0.6, [255, 255, 0]),  # 黄色
            (0.6, 0.8, [255, 165, 0]),  # 橙色
            (0.8, 0.9, [255, 0, 0]),    # 红色
            (0.9, 1.0, [0, 0, 0])       # 黑色
        ]
        
        for y in range(height):
            for x in range(width):
                # 将值归一化到[0, 1]
                value = array[y, x] / 255.0
                
                # 根据灰度值选择颜色
                for min_val, max_val, color in color_mapping:
                    if min_val <= value < max_val:
                        color_map[y, x] = color
                        break
                else:
                    # 默认颜色
                    color_map[y, x] = [0, 0, 0]
        
        return color_map
    
    def add_height_levels_v2(array, color_map, target_size=512, level_step=0.1, font_size=48):
        """
        在彩色图上添加高度等级文本
        
        Args:
            array: 输入数组 (0-255)
            color_map: 彩色图数组
            target_size: 目标输出大小（宽高相同）
            level_step: 高度等级步长
            font_size: 字体大小
            
        Returns:
            添加了高度等级文本的彩色图
        """
        from PIL import Image, ImageDraw, ImageFont
        
        # 转换为PIL图像
        height, width = color_map.shape[:2]
        image = Image.fromarray(color_map)
        
        # 放大图像到固定的512*512
        enlarged_width = target_size
        enlarged_height = target_size
        enlarged_image = image.resize((enlarged_width, enlarged_height), Image.NEAREST)
        draw = ImageDraw.Draw(enlarged_image)
        
        # 尝试加载字体，如果失败则使用默认字体
        try:
            font = ImageFont.truetype("arial.ttf", font_size)
        except:
            font = ImageFont.load_default()
        
        # 计算每个格子的大小
        cell_width = target_size / width
        cell_height = target_size / height
        
        # 在每个格子上添加高度等级
        for y in range(height):
            for x in range(width):
                # 计算格子中心坐标
                center_x = x * cell_width + cell_width // 2
                center_y = y * cell_height + cell_height // 2
                
                # 计算高度等级（根据颜色映射表的梯度）
                value = array[y, x] / 255.0
                # 根据颜色映射表的区间计算等级
                if value < 0.1:
                    level = 0
                elif value < 0.2:
                    level = 1
                elif value < 0.4:
                    level = 2
                elif value < 0.6:
                    level = 3
                elif value < 0.8:
                    level = 4
                elif value < 0.9:
                    level = 5
                else:
                    level = 6
                
                # 准备文本
                text = str(level)
                
                # 计算文本位置（居中）
                bbox = draw.textbbox((0, 0), text, font=font)
                text_width = bbox[2] - bbox[0]
                text_height = bbox[3] - bbox[1]
                text_x = center_x - text_width // 2
                text_y = center_y - text_height // 2
                
                # 获取对应格子的背景颜色
                bg_color = color_map[y, x]
                # 计算反色
                text_color = tuple(255 - c for c in bg_color)
                
                # 绘制文本（使用反色，确保在任何背景色上都清晰）
                draw.text((text_x, text_y), text, fill=text_color, font=font)
        
        # 转换回numpy数组
        result = np.array(enlarged_image)
        return result
    
    # 3.5.2 根据灰度映射表生成颜色图（处理2x2和4x4结果）
    print("\n3.5.2 根据灰度映射表生成颜色图...")
    
    # 处理2x2结果
    for name, result_array in summarize_results_2x2:
        # 生成颜色图（使用3.5.2的映射表）
        color_map = generate_color_map_v3(result_array)
        # 添加高度等级文本（按自定义梯度），2x2字体大小为32
        color_map_with_levels = add_height_levels_v2(result_array, color_map, font_size=32)
        # 保存结果
        save_path = os.path.join(output_dir, f'3.5.2.{name}.png')
        save_image(color_map_with_levels, save_path, 1)  # 已经在add_height_levels_v2中处理了放大
        print(f"  保存颜色图的{name}结果到 {save_path}")
    
    # 处理4x4结果
    for name, result_array in summarize_results_4x4:
        # 生成颜色图（使用3.5.2的映射表）
        color_map = generate_color_map_v3(result_array)
        # 添加高度等级文本（按自定义梯度），4x4字体大小为48
        color_map_with_levels = add_height_levels_v2(result_array, color_map, font_size=48)
        # 保存结果
        save_path = os.path.join(output_dir, f'3.5.2.{name}.png')
        save_image(color_map_with_levels, save_path, 1)  # 已经在add_height_levels_v2中处理了放大
        print(f"  保存颜色图的{name}结果到 {save_path}")
    
    # 3.5.3 对3.3.0的每个结果做高度概括
    print("\n3.5.3 对3.3.0的每个结果做高度概括...")
    
    # 处理3.3.0的五个结果
    summarize_results_353 = []
    summarize_results_353_2x2 = []  # 保存2x2结果
    summarize_results_353_4x4 = []  # 保存4x4结果
    for name, result_array in results:
        # 执行2x2高度概括
        summarized_2x2 = height_summarize(result_array, 2)
        # 计算2x2的放大倍数，确保输出为512*512
        scale_2x2 = 512 // summarized_2x2.shape[1]
        # 保存结果（放大到512*512）
        save_path_2x2 = os.path.join(output_dir, f'3.5.3.2x2.{name}.png')
        save_image(summarized_2x2, save_path_2x2, scale_2x2)  # 放大到512*512
        print(f"  保存2x2高度概括的{name}结果到 {save_path_2x2}")
        
        # 执行4x4高度概括
        summarized_4x4 = height_summarize(result_array, 4)
        # 计算4x4的放大倍数，确保输出为512*512
        scale_4x4 = 512 // summarized_4x4.shape[1]
        # 保存结果（放大到512*512）
        save_path_4x4 = os.path.join(output_dir, f'3.5.3.4x4.{name}.png')
        save_image(summarized_4x4, save_path_4x4, scale_4x4)  # 放大到512*512
        print(f"  保存4x4高度概括的{name}结果到 {save_path_4x4}")
        
        # 保存结果到列表，用于后续处理
        summarize_results_353_2x2.append((f"2x2.{name}", summarized_2x2))
        summarize_results_353_4x4.append((f"4x4.{name}", summarized_4x4))
        summarize_results_353.append((name, summarized_4x4))
    
    # 3.5.4 对3.5.3的每个结果生成颜色图（直接处理，不生成中间灰度图）
    print("\n3.5.4 根据灰度映射表生成颜色图...")
    
    # 处理2x2结果
    for name, result_array in summarize_results_353_2x2:
        # 生成颜色图（使用与3.5.2相同的映射表）
        color_map = generate_color_map_v3(result_array)
        # 添加高度等级文本（按自定义梯度），2x2字体大小为32
        color_map_with_levels = add_height_levels_v2(result_array, color_map, font_size=32)
        # 保存结果（命名为3.5.4.2x2.*.png，根据README.md的要求）
        save_path = os.path.join(output_dir, f'3.5.4.{name}.png')
        save_image(color_map_with_levels, save_path, 1)  # 已经在add_height_levels_v2中处理了放大
        print(f"  保存颜色图的{name}结果到 {save_path}")
    
    # 处理4x4结果
    for name, result_array in summarize_results_353_4x4:
        # 生成颜色图（使用与3.5.2相同的映射表）
        color_map = generate_color_map_v3(result_array)
        # 添加高度等级文本（按自定义梯度），4x4字体大小为48
        color_map_with_levels = add_height_levels_v2(result_array, color_map, font_size=48)
        # 保存结果（命名为3.5.4.4x4.*.png，根据README.md的要求）
        save_path = os.path.join(output_dir, f'3.5.4.{name}.png')
        save_image(color_map_with_levels, save_path, 1)  # 已经在add_height_levels_v2中处理了放大
        print(f"  保存颜色图的{name}结果到 {save_path}")
    
    # 4.1.1 对3.3.0的每个结果做分位数映射
    print("\n4.1.1 分位数映射控制噪声分布...")
    
    def quantile_mapping(array, distribution):
        """
        对高度图进行分位数映射
        
        Args:
            array: 输入数组 (0-255)
            distribution: 分位数分布字典，格式为 {(min, max): percentage}
            
        Returns:
            分位数映射后的数组
        """
        # 将数组归一化到 [0, 1]
        normalized = array / 255.0
        
        # 计算累计分布函数
        sorted_values = np.sort(normalized.flatten())
        cdf = np.arange(len(sorted_values)) / len(sorted_values)
        
        # 构建目标分位数映射
        # 首先计算每个区间的目标累积概率
        target_cdf = []
        target_values = []
        current_cdf = 0.0
        
        for (min_val, max_val), percentage in distribution.items():
            # 区间内的样本数
            count = int(len(sorted_values) * percentage / 100)
            if count > 0:
                # 生成区间内的目标值
                values = np.linspace(min_val, max_val, count)
                # 计算对应的累积概率
                cdfs = np.linspace(current_cdf, current_cdf + percentage / 100, count)
                target_values.extend(values)
                target_cdf.extend(cdfs)
                current_cdf += percentage / 100
        
        # 确保覆盖整个范围
        if len(target_values) < len(sorted_values):
            # 补充剩余值
            remaining = len(sorted_values) - len(target_values)
            values = np.linspace(0, 1, remaining)
            cdfs = np.linspace(0, 1, remaining)
            target_values.extend(values)
            target_cdf.extend(cdfs)
        
        # 排序目标值和累积概率
        sorted_indices = np.argsort(target_cdf)
        target_cdf = np.array(target_cdf)[sorted_indices]
        target_values = np.array(target_values)[sorted_indices]
        
        # 应用分位数映射
        mapped = np.zeros_like(normalized)
        for i in range(normalized.shape[0]):
            for j in range(normalized.shape[1]):
                value = normalized[i, j]
                # 找到对应的累积概率
                cdf_idx = np.searchsorted(sorted_values, value)
                if cdf_idx >= len(cdf):
                    cdf_idx = len(cdf) - 1
                
                # 找到对应的目标值
                target_idx = np.searchsorted(target_cdf, cdf[cdf_idx])
                if target_idx >= len(target_values):
                    target_idx = len(target_values) - 1
                
                mapped[i, j] = target_values[target_idx]
        
        # 映射回 [0, 255]
        return (mapped * 255).astype(np.uint8)
    
    # 定义分位数分布
    distribution = {
        (0.0, 0.1): 3,
        (0.1, 0.2): 7,
        (0.2, 0.4): 10,
        (0.4, 0.6): 60,
        (0.6, 0.8): 10,
        (0.8, 0.9): 7,
        (0.9, 1.0): 3
    }
    
    # 处理3.3.0的每个结果
    quantile_results = []  # 保存4.1.1的结果
    for name, result_array in results:
        # 应用分位数映射
        mapped_array = quantile_mapping(result_array, distribution)
        
        # 计算放大倍数，确保输出为512*512
        scale = 512 // mapped_array.shape[1]
        
        # 保存结果
        save_path = os.path.join(output_dir, f'4.1.1.{name}.png')
        save_image(mapped_array, save_path, scale)  # 放大到512*512
        print(f"  保存分位数映射的{name}结果到 {save_path}")
        
        # 保存结果到列表，用于后续处理
        quantile_results.append((name, mapped_array))
    
    # 4.1.2 对4.1.1的每个结果做高度概括
    print("\n4.1.2 对分位数映射结果做高度概括...")
    
    quantile_summarize_2x2 = []  # 保存2x2结果
    quantile_summarize_4x4 = []  # 保存4x4结果
    
    for name, result_array in quantile_results:
        # 执行2x2高度概括
        summarized_2x2 = height_summarize(result_array, 2)
        # 计算2x2的放大倍数，确保输出为512*512
        scale_2x2 = 512 // summarized_2x2.shape[1]
        # 保存结果（放大到512*512）
        save_path_2x2 = os.path.join(output_dir, f'4.1.2.2x2.{name}.png')
        save_image(summarized_2x2, save_path_2x2, scale_2x2)  # 放大到512*512
        print(f"  保存2x2高度概括的{name}结果到 {save_path_2x2}")
        
        # 执行4x4高度概括
        summarized_4x4 = height_summarize(result_array, 4)
        # 计算4x4的放大倍数，确保输出为512*512
        scale_4x4 = 512 // summarized_4x4.shape[1]
        # 保存结果（放大到512*512）
        save_path_4x4 = os.path.join(output_dir, f'4.1.2.4x4.{name}.png')
        save_image(summarized_4x4, save_path_4x4, scale_4x4)  # 放大到512*512
        print(f"  保存4x4高度概括的{name}结果到 {save_path_4x4}")
        
        # 保存结果到列表，用于后续处理
        quantile_summarize_2x2.append((name, summarized_2x2))
        quantile_summarize_4x4.append((name, summarized_4x4))
    
    # 4.1.3 对4.1.2的每个结果生成颜色图
    print("\n4.1.3 对高度概括结果生成颜色图...")
    
    # 处理2x2结果
    for name, result_array in quantile_summarize_2x2:
        # 生成颜色图（使用与3.5.2相同的映射表）
        color_map = generate_color_map_v3(result_array)
        # 添加高度等级文本（按自定义梯度），2x2字体大小为32
        color_map_with_levels = add_height_levels_v2(result_array, color_map, font_size=32)
        # 保存结果
        save_path = os.path.join(output_dir, f'4.1.3.2x2.{name}.png')
        save_image(color_map_with_levels, save_path, 1)  # 已经在add_height_levels_v2中处理了放大
        print(f"  保存颜色图的2x2.{name}结果到 {save_path}")
    
    # 处理4x4结果
    for name, result_array in quantile_summarize_4x4:
        # 生成颜色图（使用与3.5.2相同的映射表）
        color_map = generate_color_map_v3(result_array)
        # 添加高度等级文本（按自定义梯度），4x4字体大小为48
        color_map_with_levels = add_height_levels_v2(result_array, color_map, font_size=48)
        # 保存结果
        save_path = os.path.join(output_dir, f'4.1.3.4x4.{name}.png')
        save_image(color_map_with_levels, save_path, 1)  # 已经在add_height_levels_v2中处理了放大
        print(f"  保存颜色图的4x4.{name}结果到 {save_path}")
    
    print("\n地图生成完成！")


if __name__ == "__main__":
    main()
