## 修复 Entities.json 中缺少的 passable 字段
import json
from datetime import datetime

def get_current_time():
    return datetime.now().strftime("%Y-%m-%d %H:%M:%S")

def fix_entities_json(file_path):
    print(f"[{get_current_time()}] 开始修复 {file_path}")
    
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except Exception as e:
        print(f"错误：无法读取文件 - {e}")
        return
    
    entities = data["data"]["entities"]
    fixes_applied = 0
    
    ## 定义修复规则
    ## 规则：(entity_id, passable_value)
    ## passable_value: "pass" 表示可通行，"block" 表示不可通行
    fix_rules = [
        ("plain", "pass"),
        ("terrain_mountain", "block"),
        ("terrain_deep_water", "block"),
        ("terrain_lava", "block"),
        ("vegetation_tree", "block"),
        ("building_wall", "block"),
        ("default_wall", "block"),
        ("default_door", "pass"),
        ("default_gate", "pass"),
        ("default_gate_wall", "block"),
    ]
    
    for entity_id, passable_value in fix_rules:
        if entity_id in entities:
            attributes = entities[entity_id].get("attributes", {})
            if "passable" not in attributes:
                ## 根据 passable_value 设置正确的 passable 结构
                if passable_value == "pass":
                    ## 可通行：有 move 动作就允许通过
                    attributes["passable"] = {
                        "default": {
                            "has_action": "move"
                        }
                    }
                else:
                    ## 不可通行：false 条件
                    attributes["passable"] = {
                        "false": {}
                    }
                
                entities[entity_id]["attributes"] = attributes
                fixes_applied += 1
                print(f"已修复: {entity_id} -> passable={passable_value}")
    
    ## 更新 metadata 的 generate_at
    data["metadata"]["generate_at"] = get_current_time()
    
    ## 保存修复后的文件
    try:
        with open(file_path, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=4)
        print(f"\n[{get_current_time()}] 修复完成，共修复 {fixes_applied} 个实体")
    except Exception as e:
        print(f"错误：无法保存文件 - {e}")

if __name__ == "__main__":
    entities_file = r"g:\WIN11\ming.jun\godot_projects\godot-mud-demo\res\mods\EntityManager\Data\Entities.json"
    fix_entities_json(entities_file)
