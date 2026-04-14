#  基础规则
# 1. 代码注释
# 1.1. 为文件适当添加注释，包括给出配置、输入输出数据结构的注释
# 1.2. 在文件头给出模块的主要功能以及对应方法
# 1.3. 给出功能的用例
# 2. 模块交互
    通过 GameCore.ModManager.call_mod(mod_name, method_name, ...args) 调用其他模块的方法
    例如，GameCore.ModManager.call_mod("LocationManager", "get_location", location_name)
#  基础逻辑/基础功能
    模块为静态模块
##  声明全局种子，GameCore.Settings.GameSettings.WorldSeed，所有方法的随机数都基于这个种子，每个步骤的随机数都基于全局种子，确保可重复生成相同结果。
##  基础代码内容：
    class_name MudMapGenerator
    ...
##  提供功能：
## 1. 生成 mud map template
## 1.1. 接受输入：
    config:{
        name:string,
        map_type:"town"|"wilderness",
        ...
    }
## 1.2. 输出：
```json
{
    metadata:{
        version: "1.0.0",
        generate_at: "YYYY-MM-DD HH:MM:SS",
        config:config,
        ...
    },
    data:{
        map_id:config.location_name,
        map_name:config.location_name,
        map_type:"town"|"wilderness",
        map_sub_type:"village"|"town"|"city"|"mountain"|"jungle"|"forest"|"swamp"|"desert"|"ice"|"snow"|"water"|"land"|"space"|"void"|"other"...,
        map_size:[width,height],
        <!-- 可选，一般是 town 类型 的数据 -->
        blocks:{
            "block_id":{
                size:[width,height],
                nodes:[[x,y]...],
            },
            ...
        },
        map_nodes:[
            {
                entity_type:"entity"|"plain"|"grass"|"dirt"|"rock"|"water"|"ice"|"snow"|"other"...,
                attributes:{
                    map_position:[x,y],
                    // 可选，描述，默认 ""
                    description:"",
                    // 可选，是否可通行，默认 {}，代表 true
                    passable:{
                        "filter_id":{
                            "has_action":"move"
                        },
                        ...
                    },
                    // 可选，遇敌列表，默认 []
                    encounter_id_list:[{
                        encounter_id:"encounter_id",
                        <!-- 可选，遇敌权重，默认 100，如果有多个遇敌，根据权重随机选择，如果没有设置权重，则使用 data.encounters 中对应 encounter_id 的权重 -->
                        weight:100,
                        <!-- 可选，遇敌规则，置空则无限制条件，如果有多个遇敌规则，遇敌需要满足所有条件，如果没有设置规则，则使用 data.encounters 中对应 encounter_id 的规则 -->
                        encounter_rules:[
                            {
                                filter_type:"player_attribute"|...,
                                "operator":"=="|"!="|">"|">="|"<<"|"<="|"in"|"not in",
                                "value":...,
                                ...
                            },
                            ...
                        ],
                        ...
                    }],
                    ...
                },
                ...
            },
            {
                entity_type:"entity"|"decoration"|"item"|"human"|"digimon"|"other"...,
                attributes:{
                    map_position:[x,y],
                    // 可选，描述，默认 ""
                    description:"",
                    // 可选，动作，默认 {}
                    actions:{
                        move:{},
                        ...
                    },
                    ...
                },
                ...
            },
            ...
        ],
        <!-- 可选，用于在行走格子的时候触发战斗的判断 -->
        encounters:{
            "encounter_id":{
                entity_type:"human",
                // 可选，遇敌权重，默认 100
                weight:100,
                ...
            },
            ...
        }
        ...
    }
}
```
## 1.3. 功能逻辑
    <!-- 通过 LocationManager 获取所有 location 的配置，遍历所有 location 的配置 -->
    接收 LocationManager 中的单个 location 的配置
    根据 location 配置中的 mud_map_typ 调用不同的生成器
        res\mods\WorldMapManager\Scripts\Core\TownGen.gd 生成城镇地图
            town 的数据例子：Data/example.town_data.json
        res\mods\WorldMapManager\Scripts\Core\WildernessGen.gd 生成郊外地图
            wilderness 数据例子：Data/example.wilderness_data.json
    根据地图的生成规则，细化地图数据，添加地图节点，地图块，地图区域等信息
        1. 目前没有规则配置，使用默认逻辑
    如果类型是 town，则默认按以下逻辑生成 mud map template：
        town 数据例子：Data/example.town_data.json
        1. 遍历 town_data.data.total_nodes
            跳过 type 为 mask 的节点
            根据节点类型 type ，从 EntityManager.get_entity_templates_by_type 中获取对应类型的实体配置
            用随机生成器从 templates 中选择一个实体配置
            生成对应的地图节点 map_node ，并添加到 map_nodes 中
        2. 遍历 town_data.data.blocks 中的所有地图块配置
            为生成的 mud_map_template 添加数据 mud_map_template.data.blocks[block_id] = {
                size:town_data.data.blocks[block_id].size,
                position:town_data.data.blocks[block_id].position,
                nodes:town_data.data.blocks[block_id].nodes,
            }
            遍历 block 中记录的节点
                从 EntityManager.get_entity_templates_by_type 中获取 type=floor 的实体配置
                生成对应的地图节点 map_node ，并添加到 mud_map_template.data.map_nodes 中
                map_node.attributes 添加属性 block_id=block_id
        3. 在所有 gate 位置添加 exit 实体
    如果类型是 wilderness，则默认按以下逻辑生成 mud map template：
        wilderness 数据例子：Data/example.wilderness_data.json
        wilderness.data.final_height_level 储存着地图的高度等级
        为生成的 mud_map_template 添加数据 mud_map_template.data.height_levels[x] = [y1,y2,...]
        1. 遍历 wilderness.data.final_height_level 中的所有高度等级
            根据高度等级，按表格{
                0:"abyssal_sea",
                1:"coastal_sea",
                2:"flat",
                3:"plain",
                4:"hill",
                5:"mountain_slope",
                6:"peak",
            } 从 EntityManager.get_entity_templates_by_type 中获取对应高度等级的实体配置
            生成对应的地图节点 map_node ，并添加到 mud_map_template.data.map_nodes 中
            map_node.attributes 添加属性 height_level=height_level
        2. 在地图边缘的所有高度等级3的位置上添加 exit 实体
    在添加 exit 实体后，通过 LocationManager.get_relationship 获取 relationship 配置
        根据配置，对 exit 实体的 attributes.exits : [] 添加所有的relationship数据 location_id:{
            location_id:location_name,
            visual_name:location_name,
            <!-- 可选，是否可见，默认可见，如果有多个可见规则，需要满足所有条件，否则不显示 -->
            <!-- 如果有visiable_rules且不为空，则需要先判断visiable_rules的条件 -->
            visible:true,
            <!-- 可选，可见规则，置空则无限制条件，如果有多个可见规则，需要满足所有条件，否则不显示 -->
            visiable_rules:[
                {
                    filter_type:"player_attribute"|...,
                    "operator":"=="|"!="|">"|">="|"<<"|"<="|"in"|"not in",
                    "value":...,
                    ...
                },
                ...
            ],
            ...
        }
#  成员变量
##  mud_map_templates ：dictionary ， 用于存储生成的 mud map template
    键值对：
        键： map_id
        值： 对应的 mud map template 数据
#  成员方法
#  数据文件
