## 检查 Entities.json 的合法性和完整性
import json
from datetime import datetime

def get_current_time():
    return datetime.now().strftime("%Y-%m-%d %H:%M:%S")

def check_entities_json(file_path):
    print(f"[{get_current_time()}] 开始检查 {file_path}")
    
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except Exception as e:
        print(f"错误：无法读取文件 - {e}")
        return
    
    issues = []
    
    ## 1. 检查基本结构
    if "metadata" not in data:
        issues.append("缺少 metadata 字段")
    if "data" not in data:
        issues.append("缺少 data 字段")
    if "data" in data and "entities" not in data["data"]:
        issues.append("data 中缺少 entities 字段")
    if "data" in data and "entity_types" not in data["data"]:
        issues.append("data 中缺少 entity_types 字段")
    
    if issues:
        print("\n=== 基本结构问题 ===")
        for issue in issues:
            print(f"- {issue}")
    
    ## 2. 检查 entity_types 完整性
    expected_entity_types = [
        "map_entity", "ground_level", "terrain", "vegetation", "building",
        "entity_level", "door", "wall", "decoration", "gate", "gate_wall",
        "human", "digimon", "item", "cover_level", "plain", "mountain", "dirt",
        "sand", "water", "deep_water", "snow", "ice", "swamp", "lava",
        "grass", "tree", "bush", "floor", "exit", "portal.item", "potion.item",
        "weapon.item", "book.item", "decoration.item"
    ]
    
    print("\n=== 检查 entity_types ===")
    existing_types = list(data["data"]["entity_types"].keys()) if "data" in data and "entity_types" in data["data"] else []
    
    missing_types = [t for t in expected_entity_types if t not in existing_types]
    if missing_types:
        print(f"缺失的 entity_types: {missing_types}")
    else:
        print("所有预期的 entity_types 都存在 ✓")
    
    ## 3. 检查实体的 passable 字段
    print("\n=== 检查实体的 passable 字段 ===")
    entities = data["data"]["entities"] if "data" in data and "entities" in data["data"] else {}
    
    ## 定义需要 passable 字段的实体类型
    passable_required_types = [
        "plain", "mountain", "dirt", "sand", "water", "deep_water", 
        "snow", "ice", "swamp", "lava", "grass", "tree", "bush",
        "floor", "wall", "door", "default_wall", "default_door", 
        "default_gate", "default_gate_wall"
    ]
    
    entities_without_passable = []
    entities_with_passable = []
    
    for entity_id, entity_data in entities.items():
        entity_type = entity_data.get("entity_type", "")
        attributes = entity_data.get("attributes", {})
        
        ## 判断是否需要 passable 字段
        needs_passable = False
        if entity_type in passable_required_types:
            needs_passable = True
        if entity_id in passable_required_types:
            needs_passable = True
        
        if needs_passable:
            if "passable" not in attributes:
                entities_without_passable.append(entity_id)
            else:
                entities_with_passable.append(entity_id)
    
    if entities_without_passable:
        print(f"以下实体缺少 passable 字段:")
        for entity_id in entities_without_passable:
            print(f"  - {entity_id}")
    else:
        print("所有需要 passable 字段的实体都已包含 ✓")
    
    if entities_with_passable:
        print(f"\n已包含 passable 字段的实体 ({len(entities_with_passable)}):")
        for entity_id in entities_with_passable[:10]:  ## 只显示前10个
            print(f"  - {entity_id}")
        if len(entities_with_passable) > 10:
            print(f"  ... 还有 {len(entities_with_passable) - 10} 个")
    
    ## 4. 检查实体的 entity_type 是否在 entity_types 中定义
    print("\n=== 检查实体的 entity_type 合法性 ===")
    invalid_entity_types = []
    
    for entity_id, entity_data in entities.items():
        entity_type = entity_data.get("entity_type", "")
        if entity_type and entity_type not in existing_types:
            invalid_entity_types.append((entity_id, entity_type))
    
    if invalid_entity_types:
        print(f"以下实体的 entity_type 未在 entity_types 中定义:")
        for entity_id, entity_type in invalid_entity_types:
            print(f"  - {entity_id}: {entity_type}")
    else:
        print("所有实体的 entity_type 都合法 ✓")
    
    print(f"\n[{get_current_time()}] 检查完成")

if __name__ == "__main__":
    entities_file = r"g:\WIN11\ming.jun\godot_projects\godot-mud-demo\res\mods\EntityManager\Data\Entities.json"
    check_entities_json(entities_file)
