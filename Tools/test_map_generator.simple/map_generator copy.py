#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
地图生成器脚本

功能：
1. 生成Simplex噪声图
2. 叠加噪声图生成高度图
3. 归一化高度图
4. 平滑滤波处理
5. 生成地形特征
6. 应用侵蚀算法
7. 分位数映射控制噪声分布
8. 生成高度等级和可视化

所有步骤都生成灰度图并放大16倍
输出文件保存在output目录下
"""

import os
import numpy as np
from PIL import Image
import noise
import random
import datetime

# 全局种子变量
GLOBAL_SEED = None


def create_output_dir():
    """
    创建输出目录
    
    Returns:
        输出目录路径
    """
    output_dir = 'output'
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
    return output_dir


def generate_seed(seed=None):
    """
    生成或返回指定的种子
    
    Args:
        seed: 可选的种子值
    
    Returns:
        种子值
    """
    if seed is None:
        return random.randint(0, 999999)
    return seed


def simplex_noise(width, height, seed_offset=0):
    """
    生成Simplex噪声图
    
    Args:
        width: 宽度
        height: 高度
        seed_offset: 基于种子的偏移量
    
    Returns:
        噪声图数组
    """
    global GLOBAL_SEED
    
    # 使用基于全局种子的派生种子
    local_seed = GLOBAL_SEED + seed_offset
    np.random.seed(local_seed)
    
    # 生成基础噪声
    noise_map = np.zeros((height, width))
    
    # 优先使用noise模块生成Simplex噪声
    if noise is not None:
        try:
            # 使用noise模块的simplex噪声
            scale = 10.0
            for y in range(height):
                for x in range(width):
                    # 尝试使用snoise2方法
                    noise_value = noise.snoise2(
                        x / scale,
                        y / scale,
                        octaves=3,
                        persistence=0.5,
                        lacunarity=2.0,
                        repeatx=width,
                        repeaty=height,
                        base=local_seed
                    )
                    noise_map[y, x] = (noise_value + 1) / 2  # 归一化到[0, 1]
        except Exception as e:
            # 如果noise模块使用失败，回退到自定义实现
            print(f"使用noise模块失败: {e}，回退到自定义实现")
            # 使用自定义实现
            local_noise = np.random.rand(height, width)
            
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
            noise_map = uniform_to_normal(local_noise)
    else:
        # 如果noise模块不可用，使用自定义实现
        local_noise = np.random.rand(height, width)
        
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
        noise_map = uniform_to_normal(local_noise)
    
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
    
    # 应用分布变换，将噪声映射为正态分布
    noise_normal = uniform_to_normal(noise_map)
    
    # 转换为0-255范围
    noise_uint8 = (noise_normal * 255).astype(np.uint8)
    
    return noise_uint8


def simplex_noise_step(input_data):
    """
    生成Simplex噪声图的步骤
    
    Args:
        input_data: 包含以下字段的字典:
            - seed: 随机种子
            - width: 宽度
            - height: 高度
            - seed_offset: 基于种子的偏移量
    
    Returns:
        包含噪声图的字典
    """
    seed = input_data.get('seed', 0)
    width = input_data.get('width', 32)
    height = input_data.get('height', 32)
    seed_offset = input_data.get('seed_offset', 0)
    
    # 使用基于种子的派生种子
    local_seed = seed + seed_offset
    np.random.seed(local_seed)
    
    # 生成基础噪声
    noise_map = np.zeros((height, width))
    
    # 优先使用noise模块生成Simplex噪声
    if noise is not None:
        try:
            # 使用noise模块的simplex噪声
            scale = 10.0
            for y in range(height):
                for x in range(width):
                    # 尝试使用simplex2方法
                    
                    noise_value = noise.snoise2(
                        x / scale,
                        y / scale,
                        octaves=3,
                        persistence=0.5,
                        lacunarity=2.0,
                        repeatx=width,
                        repeaty=height,
                        base=local_seed
                    )
                    noise_map[y, x] = (noise_value + 1) / 2  # 归一化到[0, 1]
        except Exception as e:
            # 如果noise模块使用失败，回退到自定义实现
            print(f"使用noise模块失败: {e}，回退到自定义实现")
            # 使用自定义实现
            local_noise = np.random.rand(height, width)
            
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
            noise_map = uniform_to_normal(local_noise)
    else:
        # 如果noise模块不可用，使用自定义实现
        local_noise = np.random.rand(height, width)
        
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
        noise_map = uniform_to_normal(local_noise)
    
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
    
    # 应用分布变换，将噪声映射为正态分布
    noise_normal = uniform_to_normal(noise_map)
    
    # 转换为0-255范围
    noise_uint8 = (noise_normal * 255).astype(np.uint8)
    
    return {
        'seed': seed,
        'width': width,
        'height': height,
        'noise_map': noise_uint8
    }


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


def apply_smooth_filter_step(input_data):
    """
    应用3*3平均滤波器的步骤
    
    Args:
        input_data: 包含以下字段的字典:
            - array: 输入数组
            - height: 高度
            - width: 宽度
    
    Returns:
        包含平滑后数组的字典
    """
    array = input_data.get('array')
    height = input_data.get('height')
    width = input_data.get('width')
    
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
    
    return {
        'array': smoothed,
        'height': height,
        'width': width
    }


def normalize_array_step(input_data):
    """
    归一化数组的步骤
    
    Args:
        input_data: 包含以下字段的字典:
            - array: 输入数组
            - target_range: 目标范围，默认为[0, 255]
    
    Returns:
        包含归一化后数组的字典
    """
    array = input_data.get('array')
    target_range = input_data.get('target_range', [0, 255])
    
    min_val = np.min(array)
    max_val = np.max(array)
    if max_val > min_val:
        normalized = (array - min_val) / (max_val - min_val) * (target_range[1] - target_range[0]) + target_range[0]
    else:
        normalized = np.zeros_like(array)
    
    return {
        'array': normalized.astype(np.uint8 if target_range == [0, 255] else array.dtype)
    }


def normalize_array(array, target_range=[0, 255]):
    """
    归一化数组
    
    Args:
        array: 输入数组
        target_range: 目标范围，默认为[0, 255]
    
    Returns:
        归一化后的数组
    """
    min_val = np.min(array)
    max_val = np.max(array)
    if max_val > min_val:
        normalized = (array - min_val) / (max_val - min_val) * (target_range[1] - target_range[0]) + target_range[0]
    else:
        normalized = np.zeros_like(array)
    
    return normalized.astype(np.uint8 if target_range == [0, 255] else array.dtype)


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


def generate_map(seed, output_dir):
    """
    生成地图的主要逻辑
    
    Args:
        seed: 随机种子
        output_dir: 输出目录
    """
    # 设置当前种子
    global GLOBAL_SEED
    GLOBAL_SEED = seed
    np.random.seed(GLOBAL_SEED)
    
    # 默认参数
    width = 32  # 32*32
    height = 32  # 32*32
    pixel_size = 16  # 放大16倍
    
    # 1.1 生成3张噪声图
    print("1.1 生成噪声图...")
    noise_maps = []
    for i in range(3):
        noise = simplex_noise(width, height, seed_offset=i)
        noise_maps.append(noise)
    
    # 1.2 叠加噪声图生成高度图
    print("\n1.2 叠加噪声图生成高度图...")
    weights = [0.7, 0.2, 0.1]
    height_map = np.zeros((height, width), dtype=np.float32)
    
    for i, (noise, weight) in enumerate(zip(noise_maps, weights)):
        height_map += noise.astype(np.float32) * weight
    
    # 1.3 归一化高度图
    print("\n1.3 归一化高度图...")
    normalized_height_map = normalize_array(height_map)
    
    # 1.4 平滑滤波
    print("\n1.4 平滑滤波...")
    # 应用平滑滤波器
    smoothed = apply_smooth_filter(normalized_height_map, height, width)
    # 归一化平滑后的结果
    smoothed_normalized = normalize_array(smoothed)
    
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
    
    # 2.2 生成地形抬升掩码
    print("\n2.2 生成地形抬升掩码...")
    mask_width = 8
    mask_height = 8
    target_size = 512
    
    # 生成8*8的噪声图
    terrain_mask_small = simplex_noise(mask_width, mask_height, seed_offset=999)
    
    # 将8*8的噪声图放大到512*512
    from PIL import Image
    terrain_mask_img = Image.fromarray(terrain_mask_small)
    terrain_mask = np.array(terrain_mask_img.resize((target_size, target_size), Image.NEAREST))
    
    # 2.2.1 区域性抬升/降低
    print("\n2.2.1 区域性抬升/降低...")
    raised = np.zeros_like(stretched, dtype=np.float32)
    
    # 计算掩码的缩放因子，因为我们需要将512x512的掩码映射到32x32的高度图
    mask_scale_x = target_size / width
    mask_scale_y = target_size / height
    
    for y in range(height):
        for x in range(width):
            # 获取拉伸后的高度值并归一化到[0, 1]
            value = stretched[y, x] / 255.0
            
            # 获取对应位置的掩码值（从512x512掩码中采样）
            mask_x = min(int(x * mask_scale_x), target_size - 1)
            mask_y = min(int(y * mask_scale_y), target_size - 1)
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
    
    # 3.0 生成热度图掩码
    print("\n3.0 生成热度图掩码...")
    mask_width = 4
    mask_height = 4
    target_size = 512
    
    # 生成4*4的噪声图作为热度图掩码
    water_erosion_mask_small = simplex_noise(mask_width, mask_height, seed_offset=1000)
    
    # 将4*4的噪声图放大到512*512
    water_erosion_mask_img = Image.fromarray(water_erosion_mask_small)
    water_erosion_mask = np.array(water_erosion_mask_img.resize((target_size, target_size), Image.NEAREST))
    
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
    
    # 计算热度图掩码的缩放因子，因为我们需要将512x512的掩码映射到32x32的高度图
    mask_scale_x = target_size / width
    mask_scale_y = target_size / height
    
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
            mask_x = min(int(x * mask_scale_x), target_size - 1)
            mask_y = min(int(y * mask_scale_y), target_size - 1)
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
                mask_x = min(int(x * mask_scale_x), target_size - 1)
                mask_y = min(int(y * mask_scale_y), target_size - 1)
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
    
    # 3.3.0 混合处理
    print("\n3.3.0 混合处理...")
    
    # A: 水流侵蚀
    # B: 热侵蚀
    
    # 执行多次循环：B+A+B+A（大循环100次，循环中先执行B，再执行A）
    cycle_eroded = np.zeros_like(thermal_eroded, dtype=np.float32)
    cycle_eroded = thermal_eroded.copy()
    
    for cycle in range(iterations):
        # 先应用热侵蚀（B）
        for y in range(height):
            for x in range(width):
                # 根据热度图执行热侵蚀，热度图值大于0.5的区域才执行
                mask_x = min(int(x * mask_scale_x), target_size - 1)
                mask_y = min(int(y * mask_scale_y), target_size - 1)
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
    
        # 再应用水流侵蚀（A）
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
            mask_x = min(int(x * mask_scale_x), target_size - 1)
            mask_y = min(int(y * mask_scale_y), target_size - 1)
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
    
    # 处理3.3.0的结果
    results = [
        ('cycle.B+A+B+A', cycle_eroded_uint8)
    ]
    
    # 定义必要的辅助函数
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
        
        # 保存结果到列表，用于后续处理
        quantile_results.append((name, mapped_array))
    
    # 4.1.2 对4.1.1的每个结果做高度概括
    print("\n4.1.2 对分位数映射结果做高度概括...")
    
    quantile_summarize_2x2 = []  # 保存2x2结果
    
    for name, result_array in quantile_results:
        # 执行2x2高度概括
        summarized_2x2 = height_summarize(result_array, 2)
        
        # 保存结果到列表，用于后续处理
        quantile_summarize_2x2.append((name, summarized_2x2))
    
    # 4.1.3 对4.1.2的每个结果生成颜色图
    print("\n4.1.3 对高度概括结果生成颜色图...")
    
    # 处理2x2结果
    for name, result_array in quantile_summarize_2x2:
        # 生成颜色图（使用与3.5.2相同的映射表）
        color_map = generate_color_map_v3(result_array)
        # 添加高度等级文本（按自定义梯度），2x2字体大小为32
        color_map_with_levels = add_height_levels_v2(result_array, color_map, font_size=32)
        
        # 5.1 生成当前种子的灰度颜色映射图并保存图片
        # 对4.1.3生成的高度地图的灰度颜色映射图进行保存
        # 保存结果，命名格式为5.1.seed.[seed].png
        save_path = os.path.join(output_dir, f'5.1.seed.{seed}.png')
        save_image(color_map_with_levels, save_path, 1)
        print(f"  保存种子 {seed} 的灰度颜色映射图到 {save_path}")
        
        # 生成最终数据...
        # 使用4.1.2的高度概括结果（2x2）作为final_height_level
        final_data = generate_final_data(seed, summarized_2x2, summarized_2x2.shape[1], summarized_2x2.shape[0])
        
        # 保存最终数据为JSON文件
        import json
        json_path = os.path.join(output_dir, f'seed_{seed}.final_data.json')
        with open(json_path, 'w', encoding='utf-8') as f:
            json.dump(final_data, f, indent=2, ensure_ascii=False)
        print(f"  保存最终数据到 {json_path}")


def generate_noise_maps(input_data):
    """
    生成3张Simplex噪声图
    
    Args:
        input_data: 包含以下字段的字典:
            - seed: 随机种子
            - width: 宽度，默认为32
            - height: 高度，默认为32
    
    Returns:
        包含噪声图的字典
    """
    seed = input_data.get('seed')
    width = input_data.get('width', 32)
    height = input_data.get('height', 32)
    
    print("1.1 生成噪声图...")
    noise_maps = []
    for i in range(3):
        noise = simplex_noise(width, height, seed_offset=i)
        noise_maps.append(noise)
    
    return {
        'seed': seed,
        'width': width,
        'height': height,
        'noise_maps': noise_maps
    }


def generate_height_map(input_data):
    """
    叠加3张噪声图生成高度地图
    
    Args:
        input_data: 包含以下字段的字典:
            - seed: 随机种子
            - width: 宽度
            - height: 高度
            - noise_maps: 噪声图列表
            - weights: 权重数组，默认值为[0.7, 0.2, 0.1]
    
    Returns:
        包含高度地图的字典
    """
    seed = input_data.get('seed')
    width = input_data.get('width')
    height = input_data.get('height')
    noise_maps = input_data.get('noise_maps')
    weights = input_data.get('weights', [0.7, 0.2, 0.1])
    
    print("\n1.2 叠加噪声图生成高度地图...")
    height_map = np.zeros((height, width), dtype=np.float32)
    
    for i, (noise, weight) in enumerate(zip(noise_maps, weights)):
        height_map += noise.astype(np.float32) * weight
    
    return {
        'seed': seed,
        'width': width,
        'height': height,
        'height_map': height_map
    }


def normalize_height_map(input_data):
    """
    对高度地图进行归一化
    
    Args:
        input_data: 包含以下字段的字典:
            - seed: 随机种子
            - width: 宽度
            - height: 高度
            - height_map: 高度地图
    
    Returns:
        包含归一化高度地图的字典
    """
    seed = input_data.get('seed')
    width = input_data.get('width')
    height = input_data.get('height')
    height_map = input_data.get('height_map')
    
    print("\n1.3 归一化高度地图...")
    normalized_height_map = normalize_array(height_map)
    
    return {
        'seed': seed,
        'width': width,
        'height': height,
        'normalized_height_map': normalized_height_map
    }


def smooth_filter(input_data):
    """
    对归一化后的高度地图进行平滑处理
    
    Args:
        input_data: 包含以下字段的字典:
            - seed: 随机种子
            - width: 宽度
            - height: 高度
            - normalized_height_map: 归一化高度地图
    
    Returns:
        包含平滑后高度地图的字典
    """
    seed = input_data.get('seed')
    width = input_data.get('width')
    height = input_data.get('height')
    normalized_height_map = input_data.get('normalized_height_map')
    
    print("\n1.4 平滑滤波...")
    # 应用平滑滤波器
    smoothed = apply_smooth_filter(normalized_height_map, height, width)
    # 归一化平滑后的结果
    smoothed_normalized = normalize_array(smoothed)
    
    return {
        'seed': seed,
        'width': width,
        'height': height,
        'smoothed_normalized': smoothed_normalized
    }


def nonlinear_stretch(input_data):
    """
    对高度地图进行非线性拉伸处理
    
    Args:
        input_data: 包含以下字段的字典:
            - seed: 随机种子
            - width: 宽度
            - height: 高度
            - smoothed_normalized: 平滑后高度地图
    
    Returns:
        包含拉伸后高度地图的字典
    """
    seed = input_data.get('seed')
    width = input_data.get('width')
    height = input_data.get('height')
    smoothed_normalized = input_data.get('smoothed_normalized')
    
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
    
    return {
        'seed': seed,
        'width': width,
        'height': height,
        'stretched': stretched
    }


def generate_terrain_mask(input_data):
    """
    生成地形抬升掩码
    
    Args:
        input_data: 包含以下字段的字典:
            - seed: 随机种子
            - width: 宽度
            - height: 高度
    
    Returns:
        包含地形抬升掩码的字典
    """
    seed = input_data.get('seed')
    width = input_data.get('width')
    height = input_data.get('height')
    
    print("\n2.2 生成地形抬升掩码...")
    mask_width = 8
    mask_height = 8
    target_size = 512
    
    # 生成8*8的噪声图
    terrain_mask_small = simplex_noise(mask_width, mask_height, seed_offset=999)
    
    # 将8*8的噪声图放大到512*512
    from PIL import Image
    terrain_mask_img = Image.fromarray(terrain_mask_small)
    terrain_mask = np.array(terrain_mask_img.resize((target_size, target_size), Image.NEAREST))
    
    return {
        'seed': seed,
        'width': width,
        'height': height,
        'terrain_mask': terrain_mask,
        'target_size': target_size
    }


def regional_raise_lower(input_data):
    """
    区域性抬升/降低
    
    Args:
        input_data: 包含以下字段的字典:
            - seed: 随机种子
            - width: 宽度
            - height: 高度
            - stretched: 拉伸后高度地图
            - terrain_mask: 地形抬升掩码
            - target_size: 目标大小
    
    Returns:
        包含抬升/降低后高度地图的字典
    """
    seed = input_data.get('seed')
    width = input_data.get('width')
    height = input_data.get('height')
    stretched = input_data.get('stretched')
    terrain_mask = input_data.get('terrain_mask')
    target_size = input_data.get('target_size')
    
    print("\n2.2.1 区域性抬升/降低...")
    raised = np.zeros_like(stretched, dtype=np.float32)
    
    # 计算掩码的缩放因子，因为我们需要将512x512的掩码映射到32x32的高度图
    mask_scale_x = target_size / width
    mask_scale_y = target_size / height
    
    for y in range(height):
        for x in range(width):
            # 获取拉伸后的高度值并归一化到[0, 1]
            value = stretched[y, x] / 255.0
            
            # 获取对应位置的掩码值（从512x512掩码中采样）
            mask_x = min(int(x * mask_scale_x), target_size - 1)
            mask_y = min(int(y * mask_scale_y), target_size - 1)
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
    
    return {
        'seed': seed,
        'width': width,
        'height': height,
        'raised': raised
    }


def generate_heatmap_mask(input_data):
    """
    生成热度图掩码
    
    Args:
        input_data: 包含以下字段的字典:
            - seed: 随机种子
            - width: 宽度
            - height: 高度
    
    Returns:
        包含热度图掩码的字典
    """
    seed = input_data.get('seed')
    width = input_data.get('width')
    height = input_data.get('height')
    
    print("\n3.0 生成热度图掩码...")
    mask_width = 4
    mask_height = 4
    target_size = 512
    
    # 生成4*4的噪声图作为热度图掩码
    water_erosion_mask_small = simplex_noise(mask_width, mask_height, seed_offset=1000)
    
    # 将4*4的噪声图放大到512*512
    from PIL import Image
    water_erosion_mask_img = Image.fromarray(water_erosion_mask_small)
    water_erosion_mask = np.array(water_erosion_mask_img.resize((target_size, target_size), Image.NEAREST))
    
    return {
        'seed': seed,
        'width': width,
        'height': height,
        'water_erosion_mask': water_erosion_mask,
        'target_size': target_size
    }


def water_erosion(input_data):
    """
    水流侵蚀
    
    Args:
        input_data: 包含以下字段的字典:
            - seed: 随机种子
            - width: 宽度
            - height: 高度
            - raised: 抬升/降低后高度地图
            - water_erosion_mask: 热度图掩码
            - target_size: 目标大小
    
    Returns:
        包含水流侵蚀后高度地图的字典
    """
    seed = input_data.get('seed')
    width = input_data.get('width')
    height = input_data.get('height')
    raised = input_data.get('raised')
    water_erosion_mask = input_data.get('water_erosion_mask')
    target_size = input_data.get('target_size')
    
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
    
    # 计算热度图掩码的缩放因子，因为我们需要将512x512的掩码映射到32x32的高度图
    mask_scale_x = target_size / width
    mask_scale_y = target_size / height
    
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
            mask_x = min(int(x * mask_scale_x), target_size - 1)
            mask_y = min(int(y * mask_scale_y), target_size - 1)
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
    
    return {
        'seed': seed,
        'width': width,
        'height': height,
        'water_eroded': water_eroded,
        'water_eroded_uint8': water_eroded_uint8
    }


def thermal_erosion(input_data):
    """
    热侵蚀
    
    Args:
        input_data: 包含以下字段的字典:
            - seed: 随机种子
            - width: 宽度
            - height: 高度
            - raised: 抬升/降低后高度地图
            - water_erosion_mask: 热度图掩码
            - target_size: 目标大小
    
    Returns:
        包含热侵蚀后高度地图的字典
    """
    seed = input_data.get('seed')
    width = input_data.get('width')
    height = input_data.get('height')
    raised = input_data.get('raised')
    water_erosion_mask = input_data.get('water_erosion_mask')
    target_size = input_data.get('target_size')
    
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
    
    # 8个方向的偏移
    directions = [(-1, -1), (-1, 0), (-1, 1),
                 (0, -1),          (0, 1),
                 (1, -1),  (1, 0),  (1, 1)]
    
    # 计算热度图掩码的缩放因子，因为我们需要将512x512的掩码映射到32x32的高度图
    mask_scale_x = target_size / width
    mask_scale_y = target_size / height
    
    for _ in range(thermal_iterations):
        # 对每个格子进行处理（包括边缘）
        for y in range(height):
            for x in range(width):
                # 根据热度图执行热侵蚀，热度图值大于0.5的区域才执行
                mask_x = min(int(x * mask_scale_x), target_size - 1)
                mask_y = min(int(y * mask_scale_y), target_size - 1)
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
    
    return {
        'seed': seed,
        'width': width,
        'height': height,
        'thermal_eroded': thermal_eroded,
        'thermal_eroded_uint8': thermal_eroded_uint8
    }


def mix_processing(input_data):
    """
    混合处理
    
    Args:
        input_data: 包含以下字段的字典:
            - seed: 随机种子
            - width: 宽度
            - height: 高度
            - thermal_eroded: 热侵蚀后高度地图
            - water_erosion_mask: 热度图掩码
            - target_size: 目标大小
    
    Returns:
        包含混合处理后高度地图的字典
    """
    seed = input_data.get('seed')
    width = input_data.get('width')
    height = input_data.get('height')
    thermal_eroded = input_data.get('thermal_eroded')
    water_erosion_mask = input_data.get('water_erosion_mask')
    target_size = input_data.get('target_size')
    
    print("\n3.3.0 混合处理...")
    
    # A: 水流侵蚀
    # B: 热侵蚀
    
    # 执行多次循环：B+A+B+A（大循环100次，循环中先执行B，再执行A）
    cycle_eroded = np.zeros_like(thermal_eroded, dtype=np.float32)
    cycle_eroded = thermal_eroded.copy()
    
    iterations = 100
    min_slope = 0.005  # 最小坡度，低于此值水不流动
    base_erosion = 0.005  # 基础侵蚀量
    base_deposition = 0.003  # 基础沉积量
    critical_slope = 0.15  # 临界值
    small_slope = 0.02     # 过小的高度差
    collapse_amount = 0.05  # 坍塌量
    amplify_amount = 0.01   # 放大差值量
    
    # 8个方向的偏移
    directions = [(-1, -1), (-1, 0), (-1, 1),
                 (0, -1),          (0, 1),
                 (1, -1),  (1, 0),  (1, 1)]
    
    # 计算热度图掩码的缩放因子，因为我们需要将512x512的掩码映射到32x32的高度图
    mask_scale_x = target_size / width
    mask_scale_y = target_size / height
    
    for cycle in range(iterations):
        # 先应用热侵蚀（B）
        for y in range(height):
            for x in range(width):
                # 根据热度图执行热侵蚀，热度图值大于0.5的区域才执行
                mask_x = min(int(x * mask_scale_x), target_size - 1)
                mask_y = min(int(y * mask_scale_y), target_size - 1)
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
    
        # 再应用水流侵蚀（A）
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
            mask_x = min(int(x * mask_scale_x), target_size - 1)
            mask_y = min(int(y * mask_scale_y), target_size - 1)
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
    
    return {
        'seed': seed,
        'width': width,
        'height': height,
        'cycle_eroded': cycle_eroded,
        'cycle_eroded_uint8': cycle_eroded_uint8
    }


def quantile_mapping_process(input_data):
    """
    分位数映射
    
    Args:
        input_data: 包含以下字段的字典:
            - seed: 随机种子
            - width: 宽度
            - height: 高度
            - cycle_eroded_uint8: 混合处理后高度地图
    
    Returns:
        包含分位数映射后高度地图的字典
    """
    seed = input_data.get('seed')
    width = input_data.get('width')
    height = input_data.get('height')
    cycle_eroded_uint8 = input_data.get('cycle_eroded_uint8')
    
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
    
    # 处理3.3.0的结果
    results = [
        ('cycle.B+A+B+A', cycle_eroded_uint8)
    ]
    
    quantile_results = []  # 保存4.1.1的结果
    for name, result_array in results:
        # 应用分位数映射
        mapped_array = quantile_mapping(result_array, distribution)
        
        # 保存结果到列表，用于后续处理
        quantile_results.append((name, mapped_array))
    
    return {
        'seed': seed,
        'width': width,
        'height': height,
        'quantile_results': quantile_results
    }


def height_summarize_process(input_data):
    """
    高度概括
    
    Args:
        input_data: 包含以下字段的字典:
            - seed: 随机种子
            - width: 宽度
            - height: 高度
            - quantile_results: 分位数映射结果
    
    Returns:
        包含高度概括结果的字典
    """
    seed = input_data.get('seed')
    width = input_data.get('width')
    height = input_data.get('height')
    quantile_results = input_data.get('quantile_results')
    
    print("\n4.1.2 对分位数映射结果做高度概括...")
    
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
    
    quantile_summarize_2x2 = []  # 保存2x2结果
    
    for name, result_array in quantile_results:
        # 执行2x2高度概括
        summarized_2x2 = height_summarize(result_array, 2)
        
        # 保存结果到列表，用于后续处理
        quantile_summarize_2x2.append((name, summarized_2x2))
    
    return {
        'seed': seed,
        'width': width,
        'height': height,
        'quantile_summarize_2x2': quantile_summarize_2x2
    }


def generate_color_map(input_data):
    """
    生成颜色图和高度等级
    
    Args:
        input_data: 包含以下字段的字典:
            - seed: 随机种子
            - width: 宽度
            - height: 高度
            - quantile_summarize_2x2: 高度概括结果
            - output_dir: 输出目录
    
    Returns:
        包含生成结果的字典
    """
    seed = input_data.get('seed')
    width = input_data.get('width')
    height = input_data.get('height')
    quantile_summarize_2x2 = input_data.get('quantile_summarize_2x2')
    output_dir = input_data.get('output_dir')
    
    print("\n4.1.3 对高度概括结果生成颜色图...")
    
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
    
    def add_height_levels_v2(array, color_map, target_size=512, font_size=32):
        """
        在彩色图上添加高度等级文本
        
        Args:
            array: 输入数组 (0-255)
            color_map: 彩色图数组
            target_size: 目标输出大小（宽高相同）
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
    
    # 处理2x2结果
    for name, result_array in quantile_summarize_2x2:
        # 生成颜色图（使用与3.5.2相同的映射表）
        color_map = generate_color_map_v3(result_array)
        # 添加高度等级文本（按自定义梯度），2x2字体大小为32
        color_map_with_levels = add_height_levels_v2(result_array, color_map, font_size=32)
        
        # 5.1 生成当前种子的灰度颜色映射图并保存图片
        # 对4.1.3生成的高度地图的灰度颜色映射图进行保存
        # 保存结果，命名格式为5.1.seed.[seed].png
        save_path = os.path.join(output_dir, f'5.1.seed.{seed}.png')
        save_image(color_map_with_levels, save_path, 1)
        print(f"  保存种子 {seed} 的灰度颜色映射图到 {save_path}")
        
        # 生成最终数据...
        # 使用4.1.2的高度概括结果（2x2）作为final_height_level
        final_data = generate_final_data(seed, result_array, result_array.shape[1], result_array.shape[0])
        
        # 保存最终数据为JSON文件
        import json
        json_path = os.path.join(output_dir, f'seed_{seed}.final_data.json')
        with open(json_path, 'w', encoding='utf-8') as f:
            json.dump(final_data, f, indent=2, ensure_ascii=False)
        print(f"  保存最终数据到 {json_path}")
    
    return {
        'seed': seed,
        'width': width,
        'height': height,
        'output_dir': output_dir
    }


def generate_final_data(seed, summarized_data, width, height):
    """
    生成最终数据，格式符合README.md的要求
    
    Args:
        seed: 随机种子
        summarized_data: 4.1.2的高度概括结果
        width: 宽度
        height: 高度
    
    Returns:
        最终数据字典
    """
    import datetime
    
    # 构建metadata
    metadata = {
        "version": "1.0.0",
        "generated_at": datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "config": {
            "seed": seed,
            "width": width,
            "height": height
        },
        "size": [width, height]
    }
    
    # 构建data
    # 将高度图转换为[0, 1]区间
    normalized_data = summarized_data / 255.0
    
    # 将高度值映射到4.1.3中定义的高度等级
    def map_to_level(value):
        """
        将[0, 1]区间的高度值映射到4.1.3中定义的高度等级
        0.0-0.1: 0
        0.1-0.2: 1
        0.2-0.4: 2
        0.4-0.6: 3
        0.6-0.8: 4
        0.8-0.9: 5
        0.9-1.0: 6
        """
        if value < 0.1:
            return 0
        elif value < 0.2:
            return 1
        elif value < 0.4:
            return 2
        elif value < 0.6:
            return 3
        elif value < 0.8:
            return 4
        elif value < 0.9:
            return 5
        else:
            return 6
    
    # 应用等级映射
    final_height_level = []
    for row in normalized_data:
        level_row = []
        for value in row:
            level_row.append(map_to_level(value))
        final_height_level.append(level_row)
    
    data = {
        "size": [width, height],
        "final_height_level": final_height_level
    }
    
    # 构建最终数据
    final_data = {
        "metadata": metadata,
        "data": data
    }
    
    return final_data


def main():
    """
    主函数
    """
    # 创建输出目录
    output_dir = create_output_dir()
    
    # 5.1 遍历种子0-9...
    print("5.1 遍历种子0-9...")
    for seed in range(0, 10):
        print(f"\n处理种子 {seed}...")
        generate_map(seed, output_dir)
    
    print("\n地图生成完成！")

if __name__ == "__main__":
    main()
