## 地图生成器
## 基于 Simplex 噪声的地形生成系统
## 实现了噪声生成、地形特征、侵蚀算法、分位数映射等功能

import noise
import numpy as np
import json
import os
import matplotlib.pyplot as plt
import datetime
import random

## 全局配置
CONFIG = {
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
        "0.0-0.1": "#00008B",  # 深蓝色
        "0.1-0.2": "#0000FF",  # 蓝色
        "0.2-0.4": "#006400",  # 深绿色
        "0.4-0.6": "#FFFF00",  # 黄色
        "0.6-0.8": "#FFA500",  # 橙色
        "0.8-0.9": "#FF0000",  # 红色
        "0.9-1.0": "#000000"   # 黑色
    }
}

## 生成 Simplex 噪声图
## 将均匀分布映射为正态分布
def simplex_noise(width, height, seed_offset):
    # 生成基础噪声
    noise_map = np.zeros((height, width))
    for y in range(height):
        for x in range(width):
            # 使用 seed_offset 确保不同种子生成不同噪声
            noise_value = noise.simplex(2, x / CONFIG["noise_scale"], y / CONFIG["noise_scale"], seed_offset)
            # 将 [-1, 1] 映射到 [0, 1]
            noise_map[y][x] = (noise_value + 1) / 2
    
    # 分位数变换：将均匀分布映射为正态分布
    # 使用 numpy 的 percentile 函数实现
    sorted_noise = np.sort(noise_map.flatten())
    for y in range(height):
        for x in range(width):
            # 计算当前值的分位数
            quantile = np.searchsorted(sorted_noise, noise_map[y][x]) / len(sorted_noise)
            # 使用逆高斯函数（近似）将分位数转换为正态分布
            # 这里使用 Box-Muller 变换的近似
            if quantile < 0.5:
                z = -np.sqrt(-2 * np.log(2 * quantile))
            else:
                z = np.sqrt(-2 * np.log(2 * (1 - quantile)))
            # 将正态分布值映射回 [0, 1]
            noise_map[y][x] = (z + 3) / 6  # 假设 z 在 [-3, 3] 之间
    
    return noise_map

## 生成噪声图
def generate_noise_maps(input_data):
    seed = input_data.get("seed", 0)
    width = CONFIG["width"]
    height = CONFIG["height"]
    
    # 生成3张噪声图
    noise_maps = []
    for i in range(3):
        noise_map = simplex_noise(width, height, seed + i)
        noise_maps.append(noise_map)
    
    return {
        "seed": seed,
        "noise_maps": noise_maps
    }

## 生成高度地图
def generate_height_map(input_data):
    noise_maps = input_data["noise_maps"]
    weights = input_data.get("weights", [0.7, 0.2, 0.1])
    
    # 叠加噪声图
    height_map = np.zeros_like(noise_maps[0])
    for i, noise_map in enumerate(noise_maps):
        height_map += noise_map * weights[i]
    
    return {
        "seed": input_data["seed"],
        "height_map": height_map,
        "weights": weights
    }

## 归一化高度地图
def normalize_height_map(input_data):
    height_map = input_data["height_map"]
    
    # 归一化到 [0, 1]
    min_val = np.min(height_map)
    max_val = np.max(height_map)
    if max_val > min_val:
        normalized_map = (height_map - min_val) / (max_val - min_val)
    else:
        normalized_map = height_map
    
    return {
        "seed": input_data["seed"],
        "height_map": normalized_map
    }

## 平滑滤波
def smooth_filter(input_data):
    height_map = input_data["height_map"]
    height, width = height_map.shape
    
    # 3x3 平均滤波器
    smoothed_map = np.zeros_like(height_map)
    for y in range(height):
        for x in range(width):
            # 计算邻域平均值
            sum_val = 0
            count = 0
            for dy in [-1, 0, 1]:
                for dx in [-1, 0, 1]:
                    ny = y + dy
                    nx = x + dx
                    if 0 <= ny < height and 0 <= nx < width:
                        sum_val += height_map[ny][nx]
                        count += 1
            smoothed_map[y][x] = sum_val / count
    
    # 再次归一化到 [0, 1]
    min_val = np.min(smoothed_map)
    max_val = np.max(smoothed_map)
    if max_val > min_val:
        smoothed_map = (smoothed_map - min_val) / (max_val - min_val)
    
    return {
        "seed": input_data["seed"],
        "height_map": smoothed_map
    }

## 非线性拉伸
def nonlinear_stretch(input_data):
    height_map = input_data["height_map"]
    stretched_map = np.zeros_like(height_map)
    
    for y in range(height_map.shape[0]):
        for x in range(height_map.shape[1]):
            val = height_map[y][x]
            if val < 0.2:
                # 低值：压缩得更低
                stretched_map[y][x] = (val / 0.2) * 0.1
            elif val < 0.7:
                # 中值：尽量拉平
                stretched_map[y][x] = 0.1 + ((val - 0.2) / 0.5) * 0.3
            else:
                # 高值：拉伸得更高
                stretched_map[y][x] = 0.4 + ((val - 0.7) / 0.3) * 0.6
    
    return {
        "seed": input_data["seed"],
        "height_map": stretched_map
    }

## 生成地形抬升掩码
def generate_terrain_mask(input_data):
    seed = input_data["seed"]
    width = CONFIG["width"]
    height = CONFIG["height"]
    
    # 生成8*8的噪声图，然后放大到512*512
    mask_small = simplex_noise(8, 8, seed + 10)
    mask = np.zeros((height, width))
    
    # 放大掩码
    for y in range(height):
        for x in range(width):
            sy = int(y * 8 / height)
            sx = int(x * 8 / width)
            mask[y][x] = mask_small[sy][sx]
    
    return {
        "seed": seed,
        "height_map": input_data["height_map"],
        "terrain_mask": mask
    }

## 区域性抬升/降低
def regional_raise_lower(input_data):
    height_map = input_data["height_map"]
    terrain_mask = input_data["terrain_mask"]
    
    adjusted_map = np.zeros_like(height_map)
    for y in range(height_map.shape[0]):
        for x in range(height_map.shape[1]):
            val = height_map[y][x]
            mask_val = terrain_mask[y][x]
            
            if val > 0.7:
                # 山脉带：抬升
                new_val = val * 2.0 * mask_val
                adjusted_map[y][x] = max(new_val, 0.7)
            elif val < 0.2:
                # 海洋带：降低
                new_val = val * 0.3 * mask_val
                adjusted_map[y][x] = min(new_val, 0.2)
            else:
                # 平原带：保留
                adjusted_map[y][x] = val
    
    # 归一化到 [0, 1]
    min_val = np.min(adjusted_map)
    max_val = np.max(adjusted_map)
    if max_val > min_val:
        adjusted_map = (adjusted_map - min_val) / (max_val - min_val)
    
    return {
        "seed": input_data["seed"],
        "height_map": adjusted_map
    }

## 生成热度图掩码
def generate_heat_mask(input_data):
    seed = input_data["seed"]
    width = CONFIG["width"]
    height = CONFIG["height"]
    
    # 生成4*4的噪声图，然后放大到512*512
    mask_small = simplex_noise(4, 4, seed + 20)
    mask = np.zeros((height, width))
    
    # 放大掩码
    for y in range(height):
        for x in range(width):
            sy = int(y * 4 / height)
            sx = int(x * 4 / width)
            mask[y][x] = mask_small[sy][sx]
    
    return {
        "seed": seed,
        "height_map": input_data["height_map"],
        "heat_mask": mask
    }

## 水流侵蚀
def water_erosion(input_data):
    height_map = input_data["height_map"].copy()
    heat_mask = input_data["heat_mask"]
    iterations = CONFIG["water_erosion_iterations"]
    
    height, width = height_map.shape
    erosion_rate = 0.001
    deposition_rate = 0.0005
    min_slope = 0.005
    
    for _ in range(iterations):
        # 随机选择非边缘格子
        y = random.randint(1, height - 2)
        x = random.randint(1, width - 2)
        
        # 检查热度图
        if heat_mask[y][x] < 0.5:
            continue
        
        # 找最陡下坡方向
        max_slope = 0
        best_dir = None
        current_height = height_map[y][x]
        
        for dy in [-1, 0, 1]:
            for dx in [-1, 0, 1]:
                if dy == 0 and dx == 0:
                    continue
                ny = y + dy
                nx = x + dx
                neighbor_height = height_map[ny][nx]
                slope = current_height - neighbor_height
                if slope > max_slope and slope > min_slope:
                    max_slope = slope
                    best_dir = (dy, dx)
        
        if best_dir:
            # 侵蚀当前点
            erosion_amount = max_slope * erosion_rate * heat_mask[y][x]
            height_map[y][x] = max(0, height_map[y][x] - erosion_amount)
            
            # 沉积到下游
            dy, dx = best_dir
            ny = y + dy
            nx = x + dx
            deposition_amount = erosion_amount * deposition_rate
            height_map[ny][nx] = min(1, height_map[ny][nx] + deposition_amount)
    
    return {
        "seed": input_data["seed"],
        "height_map": height_map,
        "heat_mask": heat_mask
    }

## 热侵蚀
def thermal_erosion(input_data):
    height_map = input_data["height_map"].copy()
    heat_mask = input_data["heat_mask"]
    iterations = CONFIG["thermal_erosion_iterations"]
    
    height, width = height_map.shape
    critical_slope = 0.15
    small_slope = 0.02
    erosion_amount = 0.05
    
    for _ in range(iterations):
        for y in range(1, height - 1):
            for x in range(1, width - 1):
                # 检查热度图
                if heat_mask[y][x] < 0.5:
                    continue
                
                current_height = height_map[y][x]
                for dy in [-1, 0, 1]:
                    for dx in [-1, 0, 1]:
                        if dy == 0 and dx == 0:
                            continue
                        ny = y + dy
                        nx = x + dx
                        neighbor_height = height_map[ny][nx]
                        height_diff = current_height - neighbor_height
                        
                        if height_diff > critical_slope:
                            # 坍塌：高处降，低处升
                            height_map[y][x] -= erosion_amount
                            height_map[ny][nx] += erosion_amount
                        elif abs(height_diff) < small_slope:
                            # 放大差值
                            height_map[y][x] += 0.01
                            height_map[ny][nx] -= 0.01
    
    # 确保值在 [0, 1] 范围内
    height_map = np.clip(height_map, 0, 1)
    
    return {
        "seed": input_data["seed"],
        "height_map": height_map,
        "heat_mask": heat_mask
    }

## 混合处理
def mix_processing(input_data):
    height_map = input_data["height_map"]
    heat_mask = input_data["heat_mask"]
    
    # 大循环100次，先执行热侵蚀，再执行水流侵蚀
    for _ in range(CONFIG["combined_iterations"]):
        # 热侵蚀
        thermal_result = thermal_erosion({"seed": input_data["seed"], "height_map": height_map, "heat_mask": heat_mask})
        height_map = thermal_result["height_map"]
        
        # 水流侵蚀
        water_result = water_erosion({"seed": input_data["seed"], "height_map": height_map, "heat_mask": heat_mask})
        height_map = water_result["height_map"]
    
    return {
        "seed": input_data["seed"],
        "height_map": height_map
    }

## 分位数映射处理
def quantile_mapping_process(input_data):
    height_map = input_data["height_map"]
    
    # 分位数映射
    sorted_values = np.sort(height_map.flatten())
    mapped_map = np.zeros_like(height_map)
    
    bins = CONFIG["quantile_bins"]
    weights = CONFIG["quantile_weights"]
    
    # 计算累积权重
    cum_weights = [0]
    for w in weights:
        cum_weights.append(cum_weights[-1] + w)
    
    for y in range(height_map.shape[0]):
        for x in range(height_map.shape[1]):
            val = height_map[y][x]
            # 计算当前值的分位数
            quantile = np.searchsorted(sorted_values, val) / len(sorted_values)
            
            # 映射到目标分布
            for i in range(len(cum_weights) - 1):
                if cum_weights[i] <= quantile < cum_weights[i + 1]:
                    mapped_map[y][x] = bins[i] + (quantile - cum_weights[i]) / weights[i] * (bins[i + 1] - bins[i])
                    break
    
    return {
        "seed": input_data["seed"],
        "height_map": mapped_map
    }

## 高度概括处理
def height_summarize_process(input_data):
    height_map = input_data["height_map"]
    height, width = height_map.shape
    
    # 2*2 格子取平均值
    summary_height = height // 2
    summary_width = width // 2
    summarized_map = np.zeros((summary_height, summary_width))
    
    for y in range(summary_height):
        for x in range(summary_width):
            # 计算 2*2 区域的平均值
            sum_val = 0
            count = 0
            for dy in [0, 1]:
                for dx in [0, 1]:
                    ny = y * 2 + dy
                    nx = x * 2 + dx
                    if ny < height and nx < width:
                        sum_val += height_map[ny][nx]
                        count += 1
            summarized_map[y][x] = sum_val / count
    
    # 生成高度等级
    height_levels = np.zeros_like(summarized_map, dtype=int)
    bins = CONFIG["quantile_bins"]
    
    for y in range(summarized_map.shape[0]):
        for x in range(summarized_map.shape[1]):
            val = summarized_map[y][x]
            for i in range(len(bins) - 1):
                if bins[i] <= val < bins[i + 1]:
                    height_levels[y][x] = i
                    break
    
    return {
        "seed": input_data["seed"],
        "height_map": summarized_map,
        "height_levels": height_levels
    }

## 生成颜色地图
def generate_color_map(input_data):
    height_levels = input_data["height_levels"]
    height, width = height_levels.shape
    
    # 创建颜色映射
    colors = [
        "#00008B",  # 深蓝色
        "#0000FF",  # 蓝色
        "#006400",  # 深绿色
        "#FFFF00",  # 黄色
        "#FFA500",  # 橙色
        "#FF0000",  # 红色
        "#000000"   # 黑色
    ]
    
    # 生成颜色地图
    color_map = np.zeros((height, width, 3), dtype=np.uint8)
    for y in range(height):
        for x in range(width):
            level = height_levels[y][x]
            # 将 hex 颜色转换为 RGB
            hex_color = colors[level]
            r = int(hex_color[1:3], 16)
            g = int(hex_color[3:5], 16)
            b = int(hex_color[5:7], 16)
            color_map[y][x] = [r, g, b]
    
    return {
        "seed": input_data["seed"],
        "height_levels": height_levels,
        "color_map": color_map
    }

## 保存图片
def save_image(data, filename):
    import matplotlib.pyplot as plt
    plt.imsave(filename, data)

## 生成地图
def generate_map(seed, output_dir):
    # 确保输出目录存在
    os.makedirs(output_dir, exist_ok=True)
    
    # 生成流程
    data = {"seed": seed}
    
    # 1. 生成噪声图
    data = generate_noise_maps(data)
    # 2. 生成高度地图
    data = generate_height_map(data)
    # 3. 归一化
    data = normalize_height_map(data)
    # 4. 平滑滤波
    data = smooth_filter(data)
    # 5. 非线性拉伸
    data = nonlinear_stretch(data)
    # 6. 生成地形掩码
    data = generate_terrain_mask(data)
    # 7. 区域性抬升/降低
    data = regional_raise_lower(data)
    # 8. 生成热度掩码
    data = generate_heat_mask(data)
    # 9. 混合侵蚀处理
    data = mix_processing(data)
    # 10. 分位数映射
    data = quantile_mapping_process(data)
    # 11. 高度概括
    data = height_summarize_process(data)
    # 12. 生成颜色地图
    data = generate_color_map(data)
    
    # 生成最终 JSON 数据
    final_data = {
        "metadata": {
            "version": "1.0.0",
            "generated_at": datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            "config": {
                "seed": seed,
                "width": data["height_levels"].shape[1],
                "height": data["height_levels"].shape[0]
            },
            "size": [data["height_levels"].shape[1], data["height_levels"].shape[0]]
        },
        "data": {
            "size": [data["height_levels"].shape[1], data["height_levels"].shape[0]],
            "final_height_level": data["height_levels"].tolist()
        }
    }
    
    # 保存 JSON 文件
    json_filename = os.path.join(output_dir, f"seed_{seed}.final_data.json")
    with open(json_filename, "w", encoding="utf-8") as f:
        json.dump(final_data, f, indent=2, ensure_ascii=False)
    
    # 保存颜色地图
    color_map_filename = os.path.join(output_dir, f"5.1.seed.{seed}.color.png")
    save_image(data["color_map"], color_map_filename)
    
    return final_data

## 主函数
if __name__ == "__main__":
    # 遍历种子 0-9
    output_dir = os.path.join(os.path.dirname(__file__), "output")
    for seed in range(10):
        print(f"Generating map for seed {seed}...")
        generate_map(seed, output_dir)
    print("All maps generated successfully!")
