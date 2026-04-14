
#  基础规则
# 0.1. 基础规则
    该代码文件的类是静态类
    禁止在函数内部创建函数
    禁止使用多行注释"""，"""注释内容"""，使用#注释
    函数注解、模块注解使用##
# 0.2. 基础代码调用用例
    数组去重
        new_array = GameCore.ArrayTools.deduplicate(array)
    字典合并
        new_dict = GameCore.DictionaryTools.merge(dict_1, dict_2)
    时间获取
        time_string =  Time.get_datetime_string_from_system()
    调用其他模块
        result = GameCore.ModManager.call_mod(mod_name:String, method_name:String, ...args)
# 1. 代码注释
# 1.1. 为文件适当添加注释
    给出配置
    给出输入输出的数据结构
    说明模块的功能
    给出模块的用例
    给出涉及模块的名称
# 1.2. 在文件头给出模块的主要功能以及对应方法
# 1.3. 给出功能的用例
# 2. 模块交互
    通过 GameCore.mod_manager.call_mod(mod_name, method_name, args) 调用其他模块的方法
        不需要判断 Engine.has_meta(mod_name)
        因为 GameCore.mod_manager.call_mod 已经判断了，如果模块不存在，不会调用空模块，所以不会报错。
#  基础逻辑/基础功能
##  声明全局种子，GameCore.Settings.GameSettings.WorldSeed
    创建随机数生成器，种子为 GameCore.Settings.GameSettings.WorldSeed
    所有方法、每个步骤的随机数都基于这个随机数生成器，确保可重复生成相同结果
##  基础代码内容：
    class_name MudMapEntityFactory

    ## 生成最基础的 Entity 字典结构
    static func create_base_entity(name: String, type: String) -> Dictionary:
        return {
            "metadata": {
                "type": type,
                "version": "1.0",
                "generate_at": Time.get_unix_time_from_system()
            },
            "data": {
                "name": name,
                "entity_type": "entity", # map_cell | entity | ...
                "attributes": {
                    "actions": {}, # 存放 action_id: bool
                    "tags": {}     # 存放业务标签
                }
            }
        }

    ## 示例：生成一个带重写逻辑的角色
    static func create_special_npc(name: String, override_action: String = "") -> Dictionary:
        var npc = create_base_entity(name, "character")
        if override_action != "":
            # 设置重写：当该 NPC 尝试 "open" 时，实际调用 "fast_open"
            npc.data.attributes["action_overrides"] = {"open": override_action}
        return npc

    ## 创建实体实例的基础数据，不包含实例id
    ## @param entity_cfg: 包含 entity_id 等配置的字典
    ## @return: 实体实例的基础数据
    static func create_entity(entity_cfg: Dictionary) -> Dictionary:
        if not entity_cfg.has("entity_id"):
            push_error("[MudMapEntityFactory] create_entity: entity_id is required")
            return {}
        
        var entity_id = entity_cfg.get("entity_id", "")
        
        # 1. 通过 EntityManager 获取实体模板
        var entity_template = GameCore.mod_manager.call_mod(
            "EntityManager",
            "get_entity_template",
            entity_id
        )
        
        if entity_template == null or entity_template.is_empty():
            push_warning("[MudMapEntityFactory] create_entity: failed to create entity instance for %s" % entity_id)
            return {}
        
        # 2. 创建实体实例
        # merge entity_template with entity_cfg
        var entity_instance = GameCore.DictionaryTools.merge(
            entity_template,
            entity_cfg
        )

        return entity_instance

    ...
##  提供功能
    生成实体实例的方法接收一个字典作为参数，返回一个实体实例数据。
    实体实例数据包含实体类型、名称、属性、位置等信息。
    实体实例数据的创建、更新、删除等操作通过 EntityInstanceManager 进行。
## 1. 实体实例的增删改查
#  成员变量
#  成员方法
##  create_entity(entity_cfg:Dictionary) -> Dictionary:
    创建实体实例的基础数据，不包含实例id
#  数据文件
