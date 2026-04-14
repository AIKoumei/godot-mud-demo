# 基础规则

## 代码注释

# 为文件适当添加注释，包括给出配置、输入输出数据结构的注释

# 在文件头给出模块的主要功能以及对应方法

# 给出功能的用例

## entity 配置文件："%s/Data/Entities.json" % GameCore.mod\_manager.loaded\_mods\[mod\_name].path

## 基础代码内容：

```
## res/mods/EntityManager/Scripts/ModEntry.gd
extends ModInterface

# 核心存储: { "entity_id": { ...blueprint_data... } }
var _entity_templates: Dictionary = {}

func _on_mod_load() -> bool:
    return true

# ---------------------------------------------------------
# 外部接口：注册相关
# ---------------------------------------------------------

## 接口 A：注册单个实体模板 (供脚本动态调用)
## @param source_mod: 提交者的 mod_name
## @param entity_id: 实体的唯一标识符
## @param blueprint: 实体的数据结构
func register_entity(source_mod: String, entity_id: String, blueprint: Dictionary) -> bool:
    if _entity_templates.has(entity_id):
        var existing_mod = _entity_templates[entity_id].get("_source_mod", "Unknown")
        push_warning("[EntityManager] 注册冲突: ID '%s' 已被 Mod '%s' 占用" % [entity_id, existing_mod])
        return false
    
    # 注入来源元数据
    blueprint["_source_mod"] = source_mod
    _entity_templates[entity_id] = blueprint
    # print("[EntityManager] Mod '%s' 成功注册了单个实体: %s" % [source_mod, entity_id])
    return true

## 接口 B：批量注册 JSON 数据包 (适配你设计的 metadata/data 结构)
## @param source_mod: 提交者的 mod_name
## @param packet: 包含 metadata 和 data.entities 的字典
func register_entity_packet(source_mod: String, packet: Dictionary) -> void:
    if not packet.has("data") or not packet.data.has("entities"):
        push_error("[EntityManager] Mod '%s' 提交的数据包格式非法" % source_mod)
        return
        
    var entities_dict = packet.data.entities
    var count = 0
    
    for entity_id in entities_dict:
        if register_entity(source_mod, entity_id, entities_dict[entity_id]):
            count += 1
            
    print("[EntityManager] Mod '%s' 批量注册了 %d 个实体模板" % [source_mod, count])

# ---------------------------------------------------------
# 外部接口：查询相关
# ---------------------------------------------------------

func get_entity_template(entity_id: String) -> Dictionary:
    return _entity_templates.get(entity_id, {})

func has_template(entity_id: String) -> bool:
    return _entity_templates.has(entity_id)
```

## Entities.json 数据格式：

```json
{
    metadata:{
        version: "1.0.0",
        generate_at: "YYYY-MM-DD HH:MM:SS",
        ...
    },
    data:{
        entities:{
            "entity_id":{
                entity_type:"entity_type",
                attributes:{
                    <!-- 可选属性 -->
                    description:"description",
                    passable:{                      <!-- 可选属性，用于表示是否可以通过该格子 -->
                        filter_id:{
                            has_action:"move",
                        },
                    },
                    portal:[map_instance_id,...],   <!-- 可选属性，用于表示该格子是一个传送门，指向其他地图实例 -->
                    required : {                    <!-- 用于生成地图的时候，连续创建必要的 entity -->
                        "entity_type": {
                            "shopkeeper": {},       <!-- 文档预览属性 -->
                            "vending_machine": {},  <!-- 文档预览属性 -->
                            ...
                        },
                        "entity_id": {
                            "health_potion": {},    <!-- 文档预览属性 -->
                            ...
                        } 
                    },
                    ...
                },
                ...
            }
        },
        entity_types:{
            ...
        },
        ...
    }
}
```

## 模块有数据 entity 类型：

```json
entity_types:{
    "map_entity":{
        entity_type:"ground_level",
        render_order:0,
        child_entity_type:[
            // ground 层，例如：地形、植被、树木、建筑
            "ground_level",
            // entity 层
            "entity_level",
            // cover 层，例如：出口
            "cover_level",
            ...
        ],
    },
    // 类型 ground_level ，用于表示在 ground_layer 层级上的物体，例如：地形、植被、树木、建筑
    "ground_level":{
        entity_type:"ground_level",
        render_order:1000,
        parent_entity_type:[
            "map_entity",
        ],
        child_entity_type:[
            // 地形
            "terrain",
            // 植被
            "vegetation",
            // 建筑
            "building",
            ...
        ],
        ...
    },
    // 地形
    "terrain":{
        entity_type:"terrain",
        render_order:1200,
        parent_entity_type:[
            // 地形
            "ground_level",
        ],
        child_entity_type:[
            // 平原，无阻挡，基础移动地形
            "plain",
            // 山地 / 岩石，高阻挡
            "mountain",
            // 土路 / 泥地，无阻挡，偏野外场景
            "dirt",
            // 沙地 / 荒漠
            "sand",
            // 水域（浅）
            "water",
            // 水域（深），深水 / 海洋
            "deep_water",
            // 雪地，全类型可通行但减速
            "snow",
            // 冰面
            "ice",
            // 沼泽，减速
            "swamp",
            // 熔岩
            "lava",
            ...
        ],
        ...
    },
    // 植被
    "vegetation":{
        entity_type:"terrain",
        render_order:1400,
        parent_entity_type:[
            "ground_level",
        ],
        child_entity_type:[
            "grass",
            "tree",
            "bush",
            ...
        ],
        ...
    },
    // 建筑
    "building":{
        entity_type:"building",
        render_order:1600,
        parent_entity_type:[
            "ground_level",
        ],
        child_entity_type:[
            "floor",
            "wall",
            "door",
            "decoration",
            ...
        ],
        ...
    },
    "door":{
        entity_type:"door",
        parent_entity_type:[
            "building",
        ],
        child_entity_type:[
            "gate",
            ...
        ],
        ...
    },
    "wall":{
        entity_type:"wall",
        parent_entity_type:[
            "building",
        ],
        child_entity_type:[
            "gate_wall",
            ...
        ],
        ...
    },
    // entity_level 类型：用于放置渲染在中层的entity，例如玩家、怪物、物品等可动的少量entity
    "entity_level":{
        entity_type:"entity_level",
        render_order:3000,
        parent_entity_type:[
            "map_entity",
        ],
        child_entity_type:[
            "human",
            "digimon",
            "item",
        ],
        ...
    },
    "item":{
        entity_type:"item",
        parent_entity_type:[
            "entity_level",
        ],
        // 加上 .item 后缀，是因为例如 door 会成为 map_obj ，所以 item 下面的掉落物 door 就不能以 door 命名了
        child_entity_type:[
            "portal.item",
            "potion.item",
            "weapon.item",
            "book.item",
            "decoration.item",
        ],
        ...
    },
    
    ...
    // 最上层，用来存放一些特殊的 entity，例如：出口
    // 出口，用于表示地图的出口，一般是放置在最前面的一个图标，用来提示玩家
    "cover_level":{
        entity_type:"cover_level",
        render_order:10000,
        parent_entity_type:[
            "map_entity",
        ],
        child_entity_type:[
            "exit",
            ...
        ],
        ...
    },
}
```

- entity 类型的单个数据格式
  - entity\_type 拥有 render\_sort\_index ，用于表示多个entity在同个渲染层级下的渲染顺序
    - 例如：在 ground\_layer 下，terrain 的 render\_sort\_index 比 grass 的 render\_sort\_index 更小，会被渲染在下面，更高的 render\_sort\_index 会被更晚渲染，也就是会显示在更上层
    - 如果当前 entity\_type 没有设置 render\_sort\_index ，则往 parent 查找 render\_sort\_index 作为自身的 render\_sort\_index ，如果 parent 没有 render\_sort\_index 则持续寻找，直到根节点为止
    - 如果在渲染的时候，前后 entity 的 render\_sort\_index 相同，则不改变两者的排序，按现有的顺序进行渲染

```json
entity_type:{
    entity_type:"ground_level"|"entity_level"|"other entity_type"...,
    // render_order
    render_order:int,
    // child_entity_type：可选属性，表示该实体类型的子类型
    child_entity_type:[
        "entity_type_1",
        "entity_type_2",
        ...
    ],
    // parent_entity_type：可选属性，表示该实体类型的父
    parent_entity_type:[
        "entity_type_1",
        "entity_type_2",
        ...
    ],
    ...
}
```

# 功能概要

```
模块中有 entity 数据的相关索引，用于快速查找实体模板，在对 entity 数据进行注册后，需要更新索引，以保持索引的准确性。
```

## 模块提供接收字典数据，批量注册entity的方法

```
例如，读取 Entities.json 文件，将文件内容交给 regist_entities_from_json 方法
```

## 注册 entity 的时候，需要对 entity 的数据赋值 entity\_id，用于唯一标识该实体。

# 成员变量

```
建立索引： indexer_entity_templates_by_type[entity_type] = [entity_template_id, ...]
    用于快速获取指定实体类型的所有实体模板
建立索引： indexer_child_entity_types_by_parent_type[entity_type] = [entity_type,child_entity_type,...]，包含该类型和它的所有子孙类型。
    用于判断指定实体类型是否属于该大类，例如，"road" 属于 "road" ，也属于 "ground_level" 大类
    索引的value中需要包含entity_type本身
建立索引： indexer_parent_entity_types_by_child_type[entity_type] = [entity_type,parent_entity_type,...]，包含该类型和它的所有祖父类型。
    索引的value中需要包含entity_type本身
```

## entity\_templates: Dictionary

```
用于存储所有注册的实体模板
```

## entity\_types: Dictionary

```
用于存储所有注册的实体类型
```

# 成员方法

## 在 \_on\_mod\_enable 的时候，加载 Entities.json 文件，并注册所有实体模板

## get\_entity\_templates\_by\_type(entity\_type: String) -> Dictionary

```
用于获取指定实体类型的所有实体模板。
查询时优先查询索引
```

## is\_entity\_type(entity\_type: String, target\_type: String) -> Boolean

```
判断entity_type是否属于target_type类型
如果 entity_type not in entity_types or target_type not in entity_types
    返回 false
如果 entity_type in indexer_child_entity_types_by_child_type.keys()
    判断 target_type 是否在 indexer_child_entity_types_by_child_type[entity_type] 中，
否则 entity_type not in indexer_parent_entity_types_by_child_type.keys()
    build indexer
    重新查询一遍索引
```

## is\_sub\_entity\_type(entity\_type: String, target\_type: String) -> Boolean

```
判断entity_type是否是target_type的子类型
如果 entity_type not in entity_types or target_type not in entity_types
    返回 false
如果 target_type in indexer_child_entity_types_by_child_type.keys()
    判断 entity_type 是否在 indexer_child_entity_types_by_child_type[target_type] 中
否则 target_type not in indexer_parent_entity_types_by_child_type.keys()
    build indexer
    重新查询一遍索引
```

## get\_entity\_templates\_with\_parent\_by\_type(entity\_type: String) -> Dictionary
- 用于获取指定实体类型的实体，包括父类型的实体

## get\_entity\_templates\_with\_child\_by\_type(entity\_type: String) -> Dictionary
- 用于获取指定实体类型的实体，包括子类型的实体

## get_parent_entity_type_by_child_type(entity_type: String) -> Array
- 查询entity_type.parent_entity_type，获取指定实体类型的父类型
- @return parent_entity_type : Array 父类型列表
    - 如果不存在父类型，则返回空列表

## get_render_order(entity_type: String) -> int
- 查询entity_type.render_order，获取指定实体类型的渲染排序索引
- @return render_order : int 渲染排序索引
    - 如果不存在渲染排序索引，则获取父类型的渲染排序索引
        - 如果父类型也不存在渲染排序索引，则继续获取父类型的父类型的渲染排序索引
        - 重复以上过程，直到找到渲染排序索引或到达根类型
        - 如果到达根类型，返回 根类型的渲染排序索引。

# 数据文件

## 该模块目录下的 Data/Entities.json 文件，是该模块的实体配置文件

```
生成 Entities.json 数据的时候，参考其他的 entity ，按照 entity type 中的类型，补全 entity 例子
```

## 该文件有部分数据为：

```json
{
    metadata:{
        version: "1.0.0",
        generate_at: "YYYY-MM-DD HH:MM:SS",
        ...
    },
    data:{
        entities:{
            "plain":{
                entity_type:"plain",
                attributes:{
                    description:"这是一个普通的地面。",
                },
                ...
            },
            ...
            // "building_item_shop":{
            //     entity_type:"building_block",
            //     attributes:{
            //         description:"这是一间道具商店。",
            //         required : {
            //             "entity_type": {
            //                 "shopkeeper": {},
            //                 "vending_machine": {},
            //                 ...
            //             },
            //         },
            //     },
            //     ...
            // },
            // "building_equipment_shop":{
            //     entity_type:"building_block",
            //     attributes:{
            //         description:"这是一间装备商店。",
            //         required : {
            //             "entity_type": {
            //                 "blacksmith": {},
            //                 ...
            //             },
            //         },
            //     },
            //     ...
            // },
            // "building_quest_center":{
            //     entity_type:"building_block",
            //     attributes:{
            //         description:"这是一间任务中心。",
            //         required : {
            //             "entity_type": {
            //                 "quest_master": {},
            //                 ...
            //             },
            //         },
            //     },
            //     ...
            // },
            // "building_training_center":{
            //     entity_type:"building_block",
            //     attributes:{
            //         description:"这是一间训练中心。",
            //         required : {
            //             "entity_type": {
            //                 "trainer": {},
            //                 ...
            //             },
            //         },
            //     },
            //     ...
            // },
            // "building_home_shop":{
            //     entity_type:"building_block",
            //     attributes:{
            //         description:"这是一间家园商店。",
            //         required : {
            //             "entity_type": {
            //                 "interior_designer": {},
            //                 ...
            //             },
            //         },
            //     },
            //     ...
            // },
            // "building_union_room":{
            //     entity_type:"building_block",
            //     attributes:{
            //         description:"这是一间联盟大厅。",
            //         required : {
            //             "entity_type": {
            //                 "union_master": {},
            //                 ...
            //             },
            //         },
            //     },
            //     ...
            // },
            // "building_home":{
            //     entity_type:"building_block",
            //     attributes:{
            //         description:"这是一间家园。",
            //     },
            //     ...
            // },
            ...
            "player":{
                entity_type:"human",
                attributes:{
                    description:"这是一个玩家。",
                    roles:[
                        "player",
                        "human",
                        ...
                    ],
                },
                ...
            },
            "shopkeeper":{
                entity_type:"human",
                attributes:{
                    description:"这是一个商店老板。",
                    roles:[
                        "shopkeeper",
                        "human",
                        ...
                    ],
                },
                ...
            },
            "vending_machine":{
                entity_type:"decoration",
                attributes:{
                    description:"这是一个自动售货机。",
                    roles:[
                        "vending_machine",
                        "decoration",
                        ...
                    ],
                },
                ...
            },
            "blacksmith":{
                entity_type:"human",
                attributes:{
                    description:"这是一个铁匠。",
                    roles:[
                        "blacksmith",
                        "human",
                        ...
                    ],
                },
                ...
            },
            "trainer":{
                entity_type:"human",
                attributes:{
                    description:"这是一个教官。",
                    roles:[
                        "trainer",
                        "human",
                        ...
                    ],
                },
                ...
            },
            "interior_designer":{
                entity_type:"human",
                attributes:{
                    description:"这是一个家园设计师。",
                    roles:[
                        "interior_designer",
                        "human",
                        ...
                    ],
                },
                ...
            },
            "union_master":{
                entity_type:"human",
                attributes:{
                    description:"这是一个联盟主。",
                    roles:[
                        "union_master",
                        "human",
                        ...
                    ],
                },
                ...
            },
            "quest_master":{
                entity_type:"human",
                attributes:{
                    description:"这是一个任务大师。",
                    roles:[
                        "quest_master",
                        "human",
                        ...
                    ],
                },
                ...
            },
            ...
            "default_wall":{
                entity_type:"wall",
                attributes:{
                    description:"这是一个默认的墙。",
                    passable:{
                        "false":{},
                        ...
                    },
                    roles:[
                        "wall",
                        ...
                    ],
                },
                ...
            },
            "default_gate":{
                entity_type:"gate",
                attributes:{
                    description:"这是一个默认的城门。",
                    portal:[],
                    roles:[
                        "gate",
                        ...
                    ],
                },
                ...
            },
            "default_gate_wall":{
                entity_type:"gate_wall",
                attributes:{
                    description:"这是一个默认的城门墙。",
                    passable:{
                        "false":{},
                        ...
                    },
                    roles:[
                        "gate_wall",
                        ...
                    ],
                },
                ...
            },
            "default_door":{
                entity_type:"door",
                attributes:{
                    description:"这是一个默认的门。",
                    roles:[
                        "door",
                        ...
                    ],
                },
                ...
            },
            ...
        }
    }
}
```

