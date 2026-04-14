#!/usr/bin/env python3
## 测试不规则强度参数的效果
import sys
import os

# 添加当前目录到路径
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from map_generator import gen_config, TownGenerator

## 测试不规则强度=2的效果
def test_irregularity_strength_2():
    print("测试不规则强度=2的效果...")
    
    # 生成配置，设置不规则强度=2
    config = gen_config(size="SMALL", shape="RECTANGLE", seed=2)
    config["irregularity_strength"] = 2.0
    
    print("测试配置:")
    for key, value in config.items():
        print(f"{key}: {value}")
    
    # 创建城镇生成器
    generator = TownGenerator(config)
    
    # 生成城镇
    final_data = generator.generate_town()
    
    print("\n测试完成！")
    print(f"生成的城镇大小: {final_data['metadata']['size']}")
    print(f"生成的节点数量: {len(final_data['data']['nodes'])}")
    print(f"生成的边缘数量: {len(final_data['data']['edges'])}")

if __name__ == "__main__":
    test_irregularity_strength_2()
