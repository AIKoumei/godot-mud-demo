# 1. 最终输出的数据格式为：
    {
        metadata:{
        version: "1.0.2",
        generated_at: "2023-12-31 12:00:00",
        ...
        }
        data:{
            entit : {
                name: "entity_type_name",
                type: "entity",
                attributes: {
                    role: [entity_role,entity_role,...],
                    attribute_name: attribute_value,
                    ...
                },
                description: "entity_template_description",
                ...
            }
            ...
        }
    }
# 2. 有type template 配置：
{
    "entity":{
        "type": "entity",
        "attributes": {
            "attribute_name": attribute_value,
            ...
        },
    },
    <!-- 用来表示地图节点的类型，包括地面、墙、路、建筑，并不是传统的 entity -->
    "map_node":{
        "type": "map_node",
        "attributes": {
            "map_node_type": "ground"|"gate"|"wall"|"road"|"building"|"glass"|"water surface"|"mountain",
            <!-- 有key没value就是true，value是passable -->
            "passable": {
                has_action: {
                    "move":{
                        "action_id": "move",
                    },
                    "filter_id":{
                        "action_id": action_id,
                    },
                    ...
                },
                ...
            },
            ...
        },
    },
    "player":{
        "type": "entity",
        "attributes": {
            "entity_type": "player",
            <!-- 有key没value就是true，value是passable -->
            "actions": {
                "move": {},
                ...
            },
            ...
        },
    },
    ...
}
# 3. 每个type都会给entity一套默认的属性，这些属性会被合并到entity的attributes中
# 4. template 的命名字样是给文档看的，不是给代码用的，所以名字/数据不需要带template

#  配置说明
##  在这一点下罗列出 EntityTypeTemplates.json 所有的 配置字段和字段的可选项
##  metadata 配置
- version: string, 固定为 "1.0.4"
- generated_at: string, 生成时间，格式为 "yyyy-MM-dd HH:mm:ss"

##  data 配置

## 1. entity 配置
- type: string, 固定为 "entity"
- attributes: object

## 2. map_node_ground 配置
- type: string, 固定为 "map_node"
- attributes:
  - map_node_type: string, 固定为 "ground"
  - passable: object
    - has_action: object
      - move: object
        - action_id: string, 固定为 "move"
      - filter_id: object
        - action_id: string, 固定为 "action_id"

## 3. map_node_gate 配置
- type: string, 固定为 "map_node"
- attributes:
  - map_node_type: string, 固定为 "gate"
  - passable: object
    - has_action: object
      - move: object
        - action_id: string, 固定为 "move"
      - filter_id: object
        - action_id: string, 固定为 "action_id"

## 4. map_node_wall 配置
- type: string, 固定为 "map_node"
- attributes:
  - map_node_type: string, 固定为 "wall"
  - passable: object
    - has_action: object
      - filter_id: object
        - action_id: string, 固定为 "action_id"

## 5. map_node_road 配置
- type: string, 固定为 "map_node"
- attributes:
  - map_node_type: string, 固定为 "road"
  - passable: object
    - has_action: object
      - move: object
        - action_id: string, 固定为 "move"
      - filter_id: object
        - action_id: string, 固定为 "action_id"

## 6. map_node_building 配置
- type: string, 固定为 "map_node"
- attributes:
  - map_node_type: string, 固定为 "building"
  - passable: object
    - has_action: object
      - filter_id: object
        - action_id: string, 固定为 "action_id"

## 7. map_node_glass 配置
- type: string, 固定为 "map_node"
- attributes:
  - map_node_type: string, 固定为 "glass"
  - passable: object
    - has_action: object
      - filter_id: object
        - action_id: string, 固定为 "action_id"

## 8. map_node_water_surface 配置
- type: string, 固定为 "map_node"
- attributes:
  - map_node_type: string, 固定为 "water surface"
  - passable: object
    - has_action: object
      - filter_id: object
        - action_id: string, 固定为 "action_id"

## 9. map_node_mountain 配置
- type: string, 固定为 "map_node"
- attributes:
  - map_node_type: string, 固定为 "mountain"
  - passable: object
    - has_action: object
      - filter_id: object
        - action_id: string, 固定为 "action_id"

## 10. player 配置
- type: string, 固定为 "entity"
- attributes:
  - entity_type: string, 固定为 "player"
  - actions: object
    - move: object