## 地图可视化工具 - 读取 Godot 存档并生成可视化地图
## 支持 town 和 wilderness 两种地图类型

import json
import os
import sys
import random
from pathlib import Path
from datetime import datetime

try:
    import numpy as np
    import matplotlib.pyplot as plt
    from matplotlib.colors import ListedColormap
    from matplotlib.patches import Rectangle
    import matplotlib.patches as mpatches
except ImportError:
    print("错误：请安装必要的依赖库")
    print("pip install numpy matplotlib")
    sys.exit(1)


## 日志输出函数
def log_message(message):
    """
    同时在控制台和 output.log 文件中输出日志
    """
    print(message)
    # 确保 output 目录存在
    output_dir = "output"
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
    # 写入日志文件
    with open(os.path.join(output_dir, "output.log"), "a", encoding="utf-8") as f:
        f.write(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] {message}\n")


## 节点颜色定义（town 类型）
TOWN_NODE_COLOR = {
    "mask": [70, 70, 70],
    "edge": [90, 90, 90],
    "wall": [170, 120, 100],
    "gate": [150, 150, 200],
    "gate_wall": [100, 100, 150],
    "primary_road": [180, 180, 180],
    "secondary_road": [200, 200, 200],
    "block": [120, 120, 120],
    "center": [255, 0, 0],
    "floor": [160, 160, 160],
    "empty": [255, 255, 255]
}


## 高度等级颜色定义（wilderness 类型）
HEIGHT_LEVEL_COLOR = {
    0: [0, 0, 139],      # abyssal_sea - 深蓝色
    1: [0, 100, 255],    # coastal_sea - 蓝色
    2: [34, 139, 34],    # flat - 深绿色
    3: [154, 205, 50],   # plain - 黄绿色
    4: [189, 183, 107],  # hill - 暗金黄色
    5: [160, 82, 45],    # mountain_slope - 褐色
    6: [255, 255, 255]   # peak - 白色
}


## 读取 Godot 存档文件
def load_godot_save(filepath):
    """
    读取 Godot 存档文件（JSON 格式）
    Args:
        filepath: 存档文件路径
    Returns:
        解析后的数据字典
    """
    log_message(f"读取存档文件：{filepath}")
    
    if not os.path.exists(filepath):
        log_message(f"错误：文件不存在 - {filepath}")
        return None
    
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            data = json.load(f)
        log_message(f"成功读取存档：{filepath}")
        return data
    except json.JSONDecodeError as e:
        log_message(f"错误：JSON 解析失败 - {e}")
        return None
    except Exception as e:
        log_message(f"错误：读取文件失败 - {e}")
        return None


## 解析地图数据
def parse_map_data(save_data):
    """
    从存档数据中解析地图数据
    Args:
        save_data: 存档数据
    
    支持的输入数据结构：
    结构 1 - 测试数据标准结构（Godot MUD Demo）：
    ```json
    {
        "data": {
            "map_type": "town" 或 "wilderness",
            "map_sub_type": "...",
            "total_nodes": {
                "0,0": {"type": "mask"},
                "1,0": {"type": "wall"},
                ...
            },
            "blocks": {...},
            "height_levels": [[...], ...]
        },
        "metadata": {
            "config": {
                "map_data": {
                    "final_height_level": [[...], ...]
                }
            }
        }
    }
    ```
    
    结构 2 - README 标准结构：
    ```json
    {
        "metadata": {
            "config": {
                "map_type": "town/wilderness",
                "map_data": {
                    "total_nodes": {...},
                    "blocks": {...},
                    "final_height_level": [[...], ...]
                }
            }
        }
    }
    ```
    
    Returns:
        地图数据字典，包含 map_type 和具体地图数据
    """
    if not save_data:
        return None
    
    if not isinstance(save_data, dict):
        return None
    
    # 优先尝试测试数据结构：data 字段 + metadata.config.map_data
    if "data" in save_data:
        data = save_data["data"]
        if isinstance(data, dict):
            # 获取 map_type
            map_type = data.get("map_type", "town")
            
            # 如果是 wilderness 类型，尝试从 metadata.config.map_data 获取 final_height_level
            if map_type == "wilderness":
                if "metadata" in save_data:
                    metadata = save_data["metadata"]
                    if isinstance(metadata, dict) and "config" in metadata:
                        config = metadata["config"]
                        if isinstance(config, dict) and "map_data" in config:
                            map_data_config = config["map_data"]
                            # 合并 data 和 metadata.config.map_data
                            if isinstance(map_data_config, dict):
                                if "final_height_level" in map_data_config:
                                    data["final_height_level"] = map_data_config["final_height_level"]
                                # 同时合并 blocks 和 total_nodes（如果 data 中没有或为空）
                                if (not data.get("blocks")) and "blocks" in map_data_config:
                                    data["blocks"] = map_data_config["blocks"]
                                if (not data.get("total_nodes")) and "total_nodes" in map_data_config:
                                    data["total_nodes"] = map_data_config["total_nodes"]
            
            # 如果是 town 类型，也尝试从 metadata.config.map_data 获取 blocks 和 total_nodes
            if map_type == "town":
                if "metadata" in save_data:
                    metadata = save_data["metadata"]
                    if isinstance(metadata, dict) and "config" in metadata:
                        config = metadata["config"]
                        if isinstance(config, dict) and "map_data" in config:
                            map_data_config = config["map_data"]
                            # 合并 blocks 和 total_nodes
                            if isinstance(map_data_config, dict):
                                if (not data.get("blocks")) and "blocks" in map_data_config:
                                    data["blocks"] = map_data_config["blocks"]
                                if (not data.get("total_nodes")) and "total_nodes" in map_data_config:
                                    data["total_nodes"] = map_data_config["total_nodes"]
            
            # 添加 map_type 字段
            data["map_type"] = map_type
            return data
    
    # 尝试 README 标准结构：metadata.config.map_data
    if "metadata" in save_data:
        metadata = save_data["metadata"]
        if isinstance(metadata, dict) and "config" in metadata:
            config = metadata["config"]
            if isinstance(config, dict) and "map_data" in config:
                map_data = config["map_data"]
                # 添加 map_type 字段
                if "map_type" in config:
                    map_data["map_type"] = config["map_type"]
                return map_data
    
    # 列表格式
    if isinstance(save_data, list) and len(save_data) > 0:
        return save_data[0]
    
    return None


## 可视化 town 类型地图
def visualize_town_map(map_data, output_path):
    """
    可视化城镇地图
    Args:
        map_data: 地图数据
        output_path: 输出文件路径
    
    功能：
    - 将 total_nodes 转换为可视化地图
    - block 区域画上随机高饱和度颜色的内边框和 block id
    
    支持的数据结构：
    1. 测试数据结构：
       - total_nodes: {"x,y": {"type": "node_type"}, ...}
       - blocks: {"block_id": {"nodes": ["x,y", ...], ...}, ...}
    2. 简化结构（map_nodes 数组）：
       - map_nodes: [{"map_position": [x, y], "type": "node_type"}, ...]
    """
    log_message("开始可视化城镇地图...")
    
    # 优先使用 total_nodes（测试数据结构）
    total_nodes = map_data.get("total_nodes", {})
    
    # 如果 total_nodes 为空，尝试从 map_nodes 构建
    if not total_nodes and "map_nodes" in map_data:
        map_nodes = map_data.get("map_nodes", [])
        log_message(f"从 map_nodes 构建 total_nodes，共 {len(map_nodes)} 个节点")
        for node in map_nodes:
            # 尝试多个位置获取坐标：node.map_position 或 node.attributes.map_position
            pos = node.get("map_position")
            if not pos or not isinstance(pos, list) or len(pos) != 2:
                # 尝试从 attributes 中获取
                attributes = node.get("attributes", {})
                pos = attributes.get("map_position", [0, 0])
            
            if isinstance(pos, list) and len(pos) == 2:
                node_key = f"{pos[0]},{pos[1]}"
                # 优先使用 type 字段，其次使用 map_cell_type 字段
                node_type = node.get("type", node.get("map_cell_type", attributes.get("map_cell_type", "mask")))
                total_nodes[node_key] = {"type": node_type}
        
        log_message(f"构建完成，total_nodes 共 {len(total_nodes)} 个节点")
    
    blocks = map_data.get("blocks", {})
    log_message(f"blocks 数量：{len(blocks)}")
    
    if not total_nodes:
        log_message("错误：没有节点数据")
        log_message(f"map_data 的键：{list(map_data.keys())}")
        return
    
    # 计算地图边界
    min_x, min_y = float('inf'), float('inf')
    max_x, max_y = 0, 0
    
    for node_str in total_nodes.keys():
        x, y = map(int, node_str.split(","))
        min_x = min(min_x, x)
        min_y = min(min_y, y)
        max_x = max(max_x, x)
        max_y = max(max_y, y)
    
    # 计算地图尺寸
    width = max_x - min_x + 1
    height = max_y - min_y + 1
    
    log_message(f"地图尺寸：{width} x {height}")
    
    # 创建图像和图形
    grid_size = max(width, height)
    img_size = max(512, min(2048, grid_size * 32))
    
    # 创建图形和坐标轴
    fig = plt.figure(figsize=(img_size/100, img_size/100), dpi=100)
    ax = fig.add_axes([0, 0, 1, 1])
    ax.set_xlim(0, img_size)
    ax.set_ylim(img_size, 0)  # Y 轴向下
    ax.axis('off')
    
    # 计算每个格子的大小
    cell_size = img_size / grid_size
    
    # 绘制背景（白色）
    ax.add_patch(Rectangle((0, 0), img_size, img_size, color='white'))
    
    # 绘制节点
    for node_str, node_info in total_nodes.items():
        x, y = map(int, node_str.split(","))
        grid_x = x - min_x
        grid_y = y - min_y
        
        start_x = grid_x * cell_size
        start_y = grid_y * cell_size
        
        # 获取节点类型
        if isinstance(node_info, dict):
            node_type = node_info.get("type", "mask")
        else:
            node_type = "mask"
        
        color = TOWN_NODE_COLOR.get(node_type, TOWN_NODE_COLOR["mask"])
        r, g, b = [c / 255.0 for c in color]
        
        ax.add_patch(Rectangle((start_x, start_y), cell_size, cell_size, color=(r, g, b)))
    
    # 绘制 block 的内边框和 id
    import colorsys
    
    for block_id, block_data in blocks.items():
        nodes = block_data.get("nodes", [])
        if not nodes:
            continue
        
        # 计算 block 的边界
        block_min_x, block_min_y = float('inf'), float('inf')
        block_max_x, block_max_y = 0, 0
        
        for node_str in nodes:
            if isinstance(node_str, str) and ',' in node_str:
                x, y = map(int, node_str.split(","))
            elif isinstance(node_str, list) and len(node_str) == 2:
                x, y = node_str
            else:
                continue
            
            block_min_x = min(block_min_x, x)
            block_min_y = min(block_min_y, y)
            block_max_x = max(block_max_x, x)
            block_max_y = max(block_max_y, y)
        
        if block_min_x == float('inf'):
            continue
        
        # 计算 block 在图像中的位置
        grid_start_x = (block_min_x - min_x) * cell_size
        grid_start_y = (block_min_y - min_y) * cell_size
        block_width = (block_max_x - block_min_x + 1) * cell_size
        block_height = (block_max_y - block_min_y + 1) * cell_size
        
        # 生成随机高饱和度颜色
        random.seed(hash(block_id) % (2**32))
        hue = random.random()
        saturation = 0.8 + random.random() * 0.2  # 0.8-1.0
        value = 0.7 + random.random() * 0.3  # 0.7-1.0
        
        # HSV 转 RGB
        r, g, b = colorsys.hsv_to_rgb(hue, saturation, value)
        
        # 绘制内边框（比外边框小一点）
        border_width = min(4, cell_size * 0.15)
        inner_offset = border_width
        
        # 上边框
        ax.add_patch(Rectangle(
            (grid_start_x + inner_offset, grid_start_y + inner_offset),
            block_width - 2 * inner_offset, border_width,
            color=(r, g, b), linewidth=0
        ))
        # 下边框
        ax.add_patch(Rectangle(
            (grid_start_x + inner_offset, grid_start_y + block_height - inner_offset - border_width),
            block_width - 2 * inner_offset, border_width,
            color=(r, g, b), linewidth=0
        ))
        # 左边框
        ax.add_patch(Rectangle(
            (grid_start_x + inner_offset, grid_start_y + inner_offset),
            border_width, block_height - 2 * inner_offset,
            color=(r, g, b), linewidth=0
        ))
        # 右边框
        ax.add_patch(Rectangle(
            (grid_start_x + block_width - inner_offset - border_width, grid_start_y + inner_offset),
            border_width, block_height - 2 * inner_offset,
            color=(r, g, b), linewidth=0
        ))
        
        # 绘制 block id 在中心位置
        center_x = grid_start_x + block_width / 2
        center_y = grid_start_y + block_height / 2
        font_size = max(8, min(cell_size * 0.4, 24))
        ax.text(center_x, center_y, str(block_id),
                ha='center', va='center',
                fontsize=font_size,
                color='black',
                fontweight='bold',
                bbox=dict(boxstyle='round', facecolor='white', alpha=0.7, edgecolor='none'))
    
    # 保存图像
    plt.savefig(output_path, bbox_inches='tight', pad_inches=0)
    plt.close()
    
    log_message(f"城镇地图已保存到：{output_path}")


## 可视化 wilderness 类型地图
def visualize_wilderness_map(map_data, output_path):
    """
    可视化郊外地图
    Args:
        map_data: 地图数据
        output_path: 输出文件路径
    
    功能：
    - 将 final_height_level 转换为可视化地图
    - 每个高度格子使用随机颜色
    - 每个高度格子画上高度值
    
    支持的数据结构：
    1. 测试数据结构：
       - final_height_level: [[h1, h2, ...], [h3, h4, ...], ...]
       - height_levels: [[h1, h2, ...], ...] (备用)
    2. map_nodes 数组（备用）：
       - map_nodes: [{"map_position": [x, y], "attributes": {"height_level": h}}, ...]
    """
    log_message("开始可视化郊外地图...")
    
    # 优先使用 final_height_level（测试数据结构）
    height_levels = map_data.get("final_height_level", [])
    
    # 如果 final_height_level 为空，尝试 height_levels
    if not height_levels:
        height_levels = map_data.get("height_levels", [])
    
    map_nodes = map_data.get("map_nodes", [])
    size = map_data.get("size", [0, 0])
    
    if not height_levels and not map_nodes:
        log_message("错误：没有高度等级数据")
        log_message(f"map_data 的键：{list(map_data.keys())}")
        return
    
    # 如果有 height_levels，使用它来确定地图大小
    if height_levels:
        width = len(height_levels)
        height = len(height_levels[0]) if width > 0 else 0
        log_message(f"地图尺寸（从 height_levels）：{width} x {height}")
    elif size:
        width = size[0]
        height = size[1]
        log_message(f"地图尺寸（从 size）：{width} x {height}")
    else:
        # 从 map_nodes 计算边界
        min_x, min_y = float('inf'), float('inf')
        max_x, max_y = 0, 0
        
        for node in map_nodes:
            pos = node.get("map_position", [0, 0])
            if isinstance(pos, list) and len(pos) == 2:
                x, y = pos
                min_x = min(min_x, x)
                min_y = min(min_y, y)
                max_x = max(max_x, x)
                max_y = max(max_y, y)
        
        width = max_x - min_x + 1
        height = max_y - min_y + 1
        log_message(f"地图尺寸（从 map_nodes）：{width} x {height}")
    
    # 创建图像
    grid_size = max(width, height)
    img_size = max(512, min(2048, grid_size * 32))
    
    # 创建图形和坐标轴
    fig = plt.figure(figsize=(img_size/100, img_size/100), dpi=100)
    ax = fig.add_axes([0, 0, 1, 1])
    ax.set_xlim(0, img_size)
    ax.set_ylim(img_size, 0)  # Y 轴向下
    ax.axis('off')
    
    # 计算每个格子的大小
    cell_size = img_size / grid_size
    
    # 绘制背景（白色）
    ax.add_patch(Rectangle((0, 0), img_size, img_size, color='white'))
    
    # 导入 colorsys 用于颜色转换
    import colorsys
    
    # 如果有 height_levels，直接绘制
    if height_levels:
        for x in range(width):
            for y in range(height):
                if x < len(height_levels) and y < len(height_levels[x]):
                    height_level = height_levels[x][y]
                else:
                    height_level = 0
                
                # 生成随机颜色（基于坐标和高度）
                random.seed(hash(f"{x}_{y}_{height_level}") % (2**32))
                hue = random.random()
                saturation = 0.5 + random.random() * 0.5  # 0.5-1.0
                value = 0.6 + random.random() * 0.4  # 0.6-1.0
                
                r, g, b = colorsys.hsv_to_rgb(hue, saturation, value)
                
                start_x = x * cell_size
                start_y = y * cell_size
                
                # 绘制格子
                ax.add_patch(Rectangle((start_x, start_y), cell_size, cell_size, color=(r, g, b), linewidth=0))
                
                # 绘制高度值在格子中心
                center_x = start_x + cell_size / 2
                center_y = start_y + cell_size / 2
                font_size = max(6, min(cell_size * 0.3, 18))
                ax.text(center_x, center_y, str(height_level),
                        ha='center', va='center',
                        fontsize=font_size,
                        color='black',
                        fontweight='bold')
    else:
        # 从 map_nodes 绘制
        min_x, min_y = float('inf'), float('inf')
        max_x, max_y = 0, 0
        
        for node in map_nodes:
            # 尝试多个位置获取坐标：node.map_position 或 node.attributes.map_position
            pos = node.get("map_position")
            if not pos or not isinstance(pos, list) or len(pos) != 2:
                attributes = node.get("attributes", {})
                pos = attributes.get("map_position", attributes.get("mapPosition", [0, 0]))
            
            if isinstance(pos, list) and len(pos) == 2:
                x, y = pos
                min_x = min(min_x, x)
                min_y = min(min_y, y)
                max_x = max(max_x, x)
                max_y = max(max_y, y)
        
        for node in map_nodes:
            # 尝试多个位置获取坐标
            pos = node.get("map_position")
            if not pos or not isinstance(pos, list) or len(pos) != 2:
                attributes = node.get("attributes", {})
                pos = attributes.get("map_position", attributes.get("mapPosition", [0, 0]))
            
            if not isinstance(pos, list) or len(pos) != 2:
                continue
            
            x, y = pos
            grid_x = x - min_x if min_x != float('inf') else x
            grid_y = y - min_y if min_y != float('inf') else y
            
            start_x = grid_x * cell_size
            start_y = grid_y * cell_size
            
            # 获取高度等级
            attributes = node.get("attributes", {})
            height_level = attributes.get("height_level", attributes.get("heightLevel", 2))
            
            # 生成随机颜色（基于坐标和高度）
            random.seed(hash(f"{grid_x}_{grid_y}_{height_level}") % (2**32))
            hue = random.random()
            saturation = 0.5 + random.random() * 0.5
            value = 0.6 + random.random() * 0.4
            
            r, g, b = colorsys.hsv_to_rgb(hue, saturation, value)
            
            # 绘制格子
            ax.add_patch(Rectangle((start_x, start_y), cell_size, cell_size, color=(r, g, b), linewidth=0))
            
            # 绘制高度值在格子中心
            center_x = start_x + cell_size / 2
            center_y = start_y + cell_size / 2
            font_size = max(6, min(cell_size * 0.3, 18))
            ax.text(center_x, center_y, str(height_level),
                    ha='center', va='center',
                    fontsize=font_size,
                    color='black',
                    fontweight='bold')
    
    # 保存图像
    plt.savefig(output_path, bbox_inches='tight', pad_inches=0)
    plt.close()
    
    log_message(f"郊外地图已保存到：{output_path}")


## 主函数
def main():
    """
    主函数
    """
    log_message("=" * 50)
    log_message("地图可视化工具启动")
    log_message(f"时间：{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    log_message("=" * 50)
    
    # 获取脚本所在目录
    script_dir = Path(__file__).parent.absolute()
    
    # 数据目录和输出目录
    data_dir = script_dir / "data" / "saves" / "slot_1" / "mods" / "WorldMapManager"
    output_dir = script_dir / "output"
    
    # 确保输出目录存在
    if not output_dir.exists():
        output_dir.mkdir(parents=True, exist_ok=True)
    
    # 查找所有存档文件
    save_files = list(data_dir.glob("map_*.sav"))
    
    if not save_files:
        log_message(f"错误：在 {data_dir} 目录下没有找到 map_*.sav 文件")
        return
    
    log_message(f"找到 {len(save_files)} 个存档文件")
    
    # 处理每个存档文件
    for save_file in save_files:
        log_message(f"\n处理文件：{save_file.name}")
        
        # 读取存档
        save_data = load_godot_save(str(save_file))
        if not save_data:
            continue
        
        # 解析地图数据
        map_data = parse_map_data(save_data)
        if not map_data:
            log_message(f"跳过：无法解析地图数据")
            continue
        
        # 获取地图类型
        map_type = map_data.get("map_type", "town")
        log_message(f"地图类型：{map_type}")
        
        # 生成输出文件名
        output_filename = save_file.stem.replace(".sav", "") + ".jpg"
        output_path = output_dir / output_filename
        
        # 根据地图类型选择可视化方法
        if map_type == "town":
            visualize_town_map(map_data, str(output_path))
        elif map_type == "wilderness":
            visualize_wilderness_map(map_data, str(output_path))
        else:
            log_message(f"警告：未知的地图类型 {map_type}，使用默认可视化")
            visualize_town_map(map_data, str(output_path))
    
    log_message("\n" + "=" * 50)
    log_message("所有地图处理完成")
    log_message("=" * 50)


if __name__ == "__main__":
    main()
