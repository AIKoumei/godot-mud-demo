
#  基础规则
# 0.1. 基础规则
- 禁止在函数内部创建函数
- 禁止使用多行注释"""，"""注释内容"""，使用#注释
- 函数注解、模块注解使用##
# 0.2. 基础代码调用用例
- 数组去重
    ```new_array = GameCore.ArrayTools.deduplicate(array)```
- 字典合并
    ```new_dict = GameCore.DictionaryTools.merge(dict_1, dict_2)```
- 时间获取
    ```time_string =  Time.get_datetime_string_from_system()```
- 调用其他模块
    ```result = GameCore.ModManager.call_mod(mod_name:String, method_name:String, ...args)```
# 1. 代码注释
# 1.1. 为文件适当添加注释
- 给出配置
- 给出输入输出的数据结构
- 说明模块的功能
- 给出模块的用例
- 给出涉及模块的名称
# 1.2. 在文件头给出模块的主要功能以及对应方法
# 1.3. 给出功能的用例
# 2. 模块交互
- 通过 GameCore.mod_manager.call_mod(mod_name, method_name, args) 调用其他模块的方法
    - 不需要判断 Engine.has_meta(mod_name)
    - 因为 GameCore.mod_manager.call_mod 已经判断了，如果模块不存在，不会调用空模块，所以不会报错。
#  基础逻辑/基础功能
- 声明全局种子，GameCore.Settings.GameSettings.WorldSeed
    - 所有方法的随机数都基于这个种子，每个步骤的随机数都基于全局种子，确保可重复生成相同结果。
##  基础代码内容：
```gdscript
extends ModInterface
class_name WorldMapInstanceManager

func _on_mod_load() -> bool:
    print("[WorldMapInstanceManager] 模块已加载")
    register_event_listener_with_name(ModEventListenerFilter.new()
        .set_listen_type(ModEventListenerFilter.ListenType.ALWAYS)
        .set_mod_filter_type(ModEventListenerFilter.ModFilterType.ANY)
        .set_mod_name("SceneManager")
        .set_event_filter_type(ModEventListenerFilter.EventFilterType.TARGET)
        .set_event_name("SaveAllMapInstanceData")
        , "SaveAllMapInstanceData"
    )
    
    register_event_listener_with_name(ModEventListenerFilter.new()
        .set_listen_type(ModEventListenerFilter.ListenType.ALWAYS)
        .set_mod_filter_type(ModEventListenerFilter.ModFilterType.TARGET)
        .set_mod_name("EntityInstanceManager")
        .set_event_filter_type(ModEventListenerFilter.EventFilterType.TARGET)
        .set_event_name("entity_created")
        , "EntityInstanceManager.entity_created"
    )
    
    register_event_listener_with_name(ModEventListenerFilter.new()
        .set_listen_type(ModEventListenerFilter.ListenType.ALWAYS)
        .set_mod_filter_type(ModEventListenerFilter.ModFilterType.TARGET)
        .set_mod_name("EntityInstanceManager")
        .set_event_filter_type(ModEventListenerFilter.EventFilterType.TARGET)
        .set_event_name("entity_destroyed")
        , "EntityInstanceManager.entity_destroyed"
    )
    
    return true


func _on_mod_event(_mod_name: String, event_name: String, event_data: Dictionary) -> void:
    super._on_mod_event(_mod_name, event_name, event_data)
    if _mod_name == "WorldMapManager" and event_name == "after_gen_all_location_map_finished":
        #var mud_map_datas = event_data.get("mud_maps",{}) as Dictionary
        #_mud_map_instances = mud_map_datas.duplicate_deep()
        # TODO 从 mud entity Factory 中实例化 mud map 中的 entity ，并且在本模块中维护 entity_instances 表 {entity_id : {metadata:{},data:{}}}
        after_gen_all_locations_finished()
    # TODO 加一个 popup msg
    elif event_name == "SaveAllMapInstanceData":
        save_all_location_instances()
    # 处理 EntityInstanceManager 事件
    elif _mod_name == "EntityInstanceManager":
        if event_name == "entity_created":
            # 处理实体创建事件
            var entity = event_data.get("entity", {})
            if not entity.is_empty():
                var entity_instance_id = entity.get("instance_id", "")
                var attributes = entity.get("attributes", {})
                var map_data = attributes.get("map_data", {})
                if not map_data.is_empty() and entity_instance_id != "":
                    var map_instance_id = map_data.get("map_instance_id", "")
                    var position = map_data.get("position", Vector2.ZERO)
                    if map_instance_id != "":
                        # 设置实体位置
                        set_entity_position(entity_instance_id, {
                            "map_instance_id": map_instance_id,
                            "map_position": position
                        })
        elif event_name == "entity_destroyed":
            # 处理实体销毁事件
            var entity_instance_id = event_data.get("instance_id", "")
            if entity_instance_id != "":
                # 从所有地图实例中移除该实体
                _remove_entity_from_all_positions(entity_instance_id)

## 从所有位置移除实体
func _remove_entity_from_all_positions(entity_instance_id: String) -> void:
    for map_instance_id in _entity_positions.keys():
        _remove_entity_from_old_position(entity_instance_id, map_instance_id)
    
    # 从两个索引表中移除
    _remove_entity_from_all_indices(entity_instance_id)

## 从所有索引表中移除实体
func _remove_entity_from_all_indices(entity_instance_id: String) -> void:
    # 从以 map_instance_id 为索引的 entity 索引表中移除
    if _map_by_entity.has(entity_instance_id):
        var map_instance_id = _map_by_entity[entity_instance_id]
        if _entity_by_map.has(map_instance_id):
            _entity_by_map[map_instance_id].erase(entity_instance_id)
            # 如果该地图没有其他实体，移除该地图的索引
            if _entity_by_map[map_instance_id].is_empty():
                _entity_by_map.erase(map_instance_id)
    
    # 从以 entity_instance_id 为索引的地图索引表中移除
    _map_by_entity.erase(entity_instance_id)


func init_mud_maps():
    var cur_index = 0
    var map_templates = GameCore.mod_manager.call_mod("WorldMapManager", "get_all_mud_map_templates") as Dictionary
    var total_index = map_templates.size()
    # 从 WorldMapManager 中拷贝 map template，然后实例化
    for map_name in map_templates.keys():
        cur_index += 1
        # 获取地图模板
        var template = map_templates[map_name]
        
        # 实例化地图
        var instance = template.duplicate_deep()
        # 先移除来自于模板的实体
        instance.get("data",{}).map_nodes = []
        
        # 存储地图实例
        _mud_map_instances[map_name] = instance
        
        # 实例化地图中的实体
        var map_nodes = template.get("data", {}).get("map_nodes", [])
        for node in map_nodes:
            var entity_template_id = node.get("entity_id", "")
            if entity_template_id != "":
                # 构建实体配置
                var entity_cfg = node
                
                # 调用 EntityInstanceManager 创建实体实例
                var entity_instance = GameCore.mod_manager.call_mod(
                    "EntityInstanceManager",
                    "create_entity",
                    entity_cfg
                ) as Dictionary
                
                if not entity_instance.is_empty():
                    # 实例化实体后，将该 map_node 替换为包含 entity_instance_id 的结构
                    var entity_instance_id = entity_instance.get("entity_instance_id", "")
                    if entity_instance_id != "":
                        # 添加实体实例到地图节点列表
                        instance.get("data",{}).map_nodes.append({
                            "entity_instance_id":entity_instance_id,
                            "type":entity_instance.get("type",null)
                        })
                        print("[WorldMapInstanceManager] 实体实例创建成功: %s" % entity_instance_id)
        
        # 发送单个完成信号
        emit_mod_event("init_one_mud_map_entities", {
            "map_name":map_name,
            "cur_index":cur_index,
            "total_index":total_index,
        })
        await get_tree().create_timer(0.01).timeout


# ----------------------------
# 	流程：
# 		1、WorldMapManager 生成 mud map template
# 		2、接收到信号后， WorldMapInstanceManager 生成 mud map instance
# 		3、WorldMapInstanceManager 细化 mud map instance
# 		3.1、生成建筑
# ----------------------------
func gen_all_locations():
    # 监听生成地图完成
    register_event_listener_with_name(ModEventListenerFilter.new()
        .set_listen_type(ModEventListenerFilter.ListenType.ONCE)
        .set_mod_filter_type(ModEventListenerFilter.ModFilterType.TARGET)
        .set_mod_name("WorldMapManager")
        .set_event_filter_type(ModEventListenerFilter.EventFilterType.TARGET)
        .set_event_name("after_gen_all_location_map_finished")
        , "after_gen_all_location_map_finished"
    )
    # 从配置中生成地图模板
    GameCore.mod_manager.call_mod("WorldMapManager", "gen_all_locations")

func after_gen_all_locations_finished():
    await init_mud_maps()
    save_all_location_instances()
    emit_mod_event("after_gen_all_locations_finished", {
        "map_count":_mud_map_instances.size(),
        "map_instances":_mud_map_instances
    })


func save_all_location_instances():
    print("WorldMapInstanceManager.save_all_location_instances")
    for data in _mud_map_instances.values():
        var map_name = data.get("data",{}).get("name", "unknow_map")
        if map_name == "unknow_map":
            push_warning("[%s] save_all_location_instances 中未知的 name" % mod_name)
        if GameCore.debugging and SaveManager.has_mod_slot_file(GameCore.Settings.GameSettings.GameSlot, "%s/map_%s.sav" % [mod_name, map_name.uri_encode()]):
            continue
        SaveManager.save_mod_slot_data(GameCore.Settings.GameSettings.GameSlot, "%s/map_%s"%[mod_name, map_name.uri_encode()], data)


# ---------------------------------------------------------
# 获取当前实例
# ---------------------------------------------------------
func get_current_instance() -> Dictionary:
    return _mud_map_instances.get(_current_location_id, {})


# ---------------------------------------------------------
# 获取某个实例
# ---------------------------------------------------------
func get_instance(location_id: String) -> Dictionary:
    return _mud_map_instances.get(location_id, {})


func get_all_mud_map_instances() -> Dictionary:
    return _mud_map_instances


# ---------------------------------------------------------
## 获取某个实例的 map_data
## ---------------------------------------------------------
func get_map_data(location_id: String) -> Array:
    return _mud_map_instances.get(location_id, {}).get("map_data", [])

## ---------------------------------------------------------
## 根据 map_instance_id 获取所有 entity 的接口方法
## @param map_instance_id: 地图实例 ID
## @return 返回该地图上的所有实体实例 ID 列表
## ---------------------------------------------------------
func get_entities_by_map(map_instance_id: String) -> Array:
    if _entity_by_map.has(map_instance_id):
        return _entity_by_map[map_instance_id].keys()
    return []

## ---------------------------------------------------------
## 根据 cfg 创建 entity 的接口方法
## @param cfg: 配置字典，包含 entity_template_id, map_position, attributes 等信息
## @return 返回创建的实体实例数据
## ---------------------------------------------------------
func create_entity(cfg: Dictionary) -> Dictionary:
    # 提取必要参数
    var entity_template_id = cfg.get("entity_template_id", "")
    var map_instance_id = cfg.get("map_instance_id", "")
    var map_position = cfg.get("map_position", Vector2.ZERO)
    var attributes = cfg.get("attributes", {})

    # 检查必要参数
    if entity_template_id == "" or map_instance_id == "":
        push_warning("[WorldMapInstanceManager] create_entity: entity_template_id and map_instance_id are required")
        return {}

    # 构建 entity_cfg
    var entity_cfg = {
        "entity_id": entity_template_id,
        "map_instance_id": map_instance_id,
        "map_position": map_position,
        "attributes": attributes
    }

    # 调用 EntityInstanceManager 创建实体实例
    var entity_instance = GameCore.mod_manager.call_mod(
        "EntityInstanceManager",
        "create_entity",
        entity_cfg
    ) as Dictionary

    if not entity_instance.is_empty():
        print("[WorldMapInstanceManager] 实体创建成功: %s" % entity_instance.get("instance_id", ""))
    else:
        print("[WorldMapInstanceManager] 实体创建失败")

    return entity_instance


# ---------------------------------------------------------
# 设置实体在地图玩法上的逻辑位置
# （在 _entity_positions 中维护 entity 位置信息）
# ---------------------------------------------------------
## @param entity_instance_id: 实体实例 ID
## @param cfg: 配置字典，包含 map_instance_id, map_position 等信息
func set_entity_position(entity_instance_id: String, cfg: Dictionary) -> void:
    # 从配置中提取必要参数
    var map_instance_id = cfg.get("map_instance_id", "")
    var map_position = cfg.get("map_position", Vector2.ZERO)
    var x = int(cfg.get("x", map_position.x))
    var y = int(cfg.get("y", map_position.y))

    # 检查必要参数
    if map_instance_id == "":
        push_warning("[WorldMapInstanceManager] set_entity_position: map_instance_id is required")
        return

    # 确保 map_instance_id 在 _entity_positions 中存在
    if not _entity_positions.has(map_instance_id):
        _entity_positions[map_instance_id] = {}

    # 生成位置键
    var pos_key = "%d_%d" % [x, y]

    # 先移除旧位置上的该实体
    _remove_entity_from_all_indices(entity_instance_id)

    # 在新位置写入
    if not _entity_positions[map_instance_id].has(pos_key):
        _entity_positions[map_instance_id][pos_key] = {}
    
    # 存储实体实例 ID，字典内容留空
    _entity_positions[map_instance_id][pos_key][entity_instance_id] = {}

    # 更新两个索引表
    # 1. 以 map_instance_id 为索引的 entity 索引表
    if not _entity_by_map.has(map_instance_id):
        _entity_by_map[map_instance_id] = {}
    _entity_by_map[map_instance_id][entity_instance_id] = {}

    # 2. 以 entity_instance_id 为索引的地图索引表
    _map_by_entity[entity_instance_id] = map_instance_id

    print("[WorldMapInstanceManager] Entity %s placed at %s:%s,%s" % [entity_instance_id, map_instance_id, x, y])

## 从旧位置移除实体
func _remove_entity_from_old_position(entity_instance_id: String, map_instance_id: String) -> void:
    if not _entity_positions.has(map_instance_id):
        return

    var positions = _entity_positions[map_instance_id]
    for pos_key in positions.keys():
        if positions[pos_key].has(entity_instance_id):
            positions[pos_key].erase(entity_instance_id)
            # 如果该位置没有其他实体，移除该位置
            if positions[pos_key].is_empty():
                positions.erase(pos_key)
            break


# ---------------------------------------------------------
# 通用格子修改接口（破坏、建造、掉落等）
# ---------------------------------------------------------
func merge_tile_data(location_id: String, x: int, y: int, data: Dictionary) -> void:
    if not _mud_map_instances.has(location_id):
        push_warning("[WorldMapInstanceManager] merge_tile_data: no instance for %s" % location_id)
        return

    var inst: Dictionary = _mud_map_instances[location_id]
    var map_data: Array = inst.get("map_data", [])

    var found: bool = false
    for tile in map_data:
        if int(tile.get("x", -1)) == x and int(tile.get("y", -1)) == y:
            tile.merge(data)
            found = true
            break

    if not found:
        var new_tile: Dictionary = { "x": x, "y": y }
        new_tile.merge(data)
        map_data.append(new_tile)

    inst["map_data"] = map_data
    _mud_map_instances[location_id] = inst


# ---------------------------------------------------------
# 世界更新（所有实例）
# ---------------------------------------------------------
func update(delta: float) -> void:
    for location_id in _mud_map_instances.keys():
        _update_instance(location_id, delta)


func _update_instance(location_id: String, delta: float) -> void:
    var inst: Dictionary = _mud_map_instances[location_id]
    # TODO: 天气变化、单位 AI、掉落物刷新等
    pass

...
```
##  提供功能
## mud_map_instance 的增删改查
#  成员变量
## _mud_map_instances
```gdscript
##存储所有地图实例
var _mud_map_instances: Dictionary = {}
```
- 功能逻辑
    - 每一个 map_position 都有一个桶，桶中存储的是 entity_instance 列表，根据 render_order 排序
        - map_position 下没有 entity_instance 时，移除桶
        - 对桶添加/移除 entity instance 时，修改 map_nodes_dirty 中对应的 map_position 为 true
        - 渲染 map_position 时，如果 dirty=true，需要对桶中的 entity_instance 按 render_order 排序后，再进行渲染
- 数据格式
    - 基础数据来源于 map manager 中的 map template，map instance 会直接拷贝一份 template，再做异化处理
```json
{
    metadata:{...},
    data:{
        ...,
        map_nodes: {
          <!-- map_position -->
          "x,y": [
            <!-- map_node -->
            {
              entity_instance_id: entity_instance_id,
              entity_type: entity_type,
            },
            ...
          ],
        },
        <!-- 
          1. 在渲染 map_nodes[x,y] 并且 dirty=true 的时候，需要对 map_nodes[x,y] 中的 entity_instance 进行排序 
          2. 在 entity instance 的坐标改变后， entity instance manager 会 emit event，通知 map instance manager 进行 set map nodes dirty 标记
        -->
        map_nodes_dirty: {
          "x,y": true|false,
          ...
        },
        ...
    }
}
```
#  成员方法
##  init_mud_maps
- 通过 WorldMapManager 获取的 template，进行实例化。
- 实例化后，需要赋值 map_instance_id ，作为地图实例的唯一标识符
- 实例化地图的时候，遍历 map_nodes ，通过 EntityInstanceManager.create_entity 实例化实体。
    - 实例化参数包括
        ```json
        {
            实体模板 ID
            attributes : {
                map_instance_id : map_instance_id,
                map_position :[x,y],
                ...
            }
        }
        ```
    - 实例化实体后，需要将该 map_node 替换为
        ```json
        {
            entity_instance_id : entity_instance.entity_instance_id,
            entity_type: entity_instance.entity_type,
            ...
        }
        ```
       - 如果本模块在增删改查 entity_instance ，需要实例数据的时候，需要通过 EntityInstanceManager 获取对应 id 的实例
## move_entity(args: Dictionary)
- 原则上，EntityInstanceManager 以及其他涉及在地图上移动 entity 的操作都需要经过 move_entity 方法进行
- args
    - entity_instance_id: 实体实例 ID
    - new_map_instance_id: 地图实例 ID
    - new_map_position: 实体新的位置
- 从 EntityInstanceManager 中获取 entity_instance_id 对应的 entity_instance
- 如果没有 new_map_instance_id，从 entity_instance.attributes 中获取 map_instance_id
- add_entity({
    "entity_instance_id": entity_instance_id,
    "map_instance_id": new_map_instance_id,
    "map_position": new_map_position,
})
## remove_entity(args: Dictionary)
- args
    - map_instance_id: 地图实例 ID
    - entity_instance_id: 实体实例 ID
- 从 EntityInstanceManager 中获取 entity_instance_id 对应的 entity_instance
- 如果没有 map_instance_id，从 entity_instance.attributes 中获取 map_instance_id
- 在初始化参数后，如果没有 map_instance_id 
    - 结束函数
- 根据 entity_instance_id.attributes.map_instance_id 和 entity_instance_id.attributes.map_position  从 _mud_map_instances[map_instance_id][map_position] 中移除对应的 entity_instance_id 
    - 移除 entity_instance.attributes.map_instance_id
    - 移除 entity_instance.attributes.map_position
    - 设置 map_nodes_dirty 中对应的 map_position 为 true
## add_entity(args: Dictionary)
- args
    - entity_instance_id: 实体实例 ID
    - map_position: 实体新的位置
    - map_instance_id: 地图实例 ID
- 从 EntityInstanceManager 中获取 entity_instance_id 对应的 entity_instance
- 如果没有 map_instance_id
    - 从 entity_instance.attributes 中获取 map_instance_id
- 在初始化参数后，如果没有 map_instance_id 
    - 结束函数
- remove_entity({
    "entity_instance_id": entity_instance_id
})
    - 不使用 entity_instance.attributes.map_instance_id 是因为传入的 map_instance_id 与该变量不相同，这个时候代表着 entity 从一个地图实例移动到了另一个地图实例
- 根据 entity_instance_id.attributes.map_instance_id 和 entity_instance_id.attributes.map_position  从 _mud_map_instances[map_instance_id][map_position] 中添加对应的 entity_instance_id 
    - 如果 _mud_map_instances[map_instance_id][map_position] 不存在，创建一个桶:[]
    - 添加 entity_instance_id 到桶中
    - 设置 map_nodes_dirty 中对应的 map_position 为 true
## sort_map_nodes(args: Dictionary)
- args
    - map_instance_id: 地图实例 ID
    - map_position: 地图位置
- 从 _mud_map_instances[map_instance_id][map_position] 中获取 entity_instance_id 列表
- if map_nodes_dirty[map_position] == false
    - 结束函数
- 对 entity_instance_id 列表按 render_order 排序
    - 通过 GameCore.mod_manager.call_mod("EntityManager", "get_render_order", entity_type) 获取每个实体类型的渲染排序索引
    - 对 entity_instance_id 列表按 render_order 排序
    - 如果 render_order 相同，则排序不变
- 将排序后的 entity_instance_id 列表赋值给 _mud_map_instances[map_instance_id][map_position] 中的 entity_instance_id 列表
## get_sorted_map_nodes_at_map_position(args: Dictionary)
- args
    - map_instance_id: 地图实例 ID
    - map_position: 地图位置
- if map_nodes_dirty[map_position] == true
    - sort_map_nodes({
        "map_instance_id": map_instance_id,
        "map_position": map_position
    })
- 返回排序后的 entity_instance_id 列表
#  数据文件
