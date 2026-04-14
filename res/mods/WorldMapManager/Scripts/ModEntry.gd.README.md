
#  基础规则
# 0.1. 基础规则
    禁止在函数内部创建函数
    禁止使用多行注释"""，"""注释内容"""，使用#注释
    函数注解、模块注解使用##
# 0.2. 基础代码调用用例
    数组去重
        new_array = GameCore.ArrayTools.deduplicate(array)
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
    通过 GameCore.ModManager.call_mod(mod_name, method_name, args) 调用其他模块的方法
#  基础逻辑/基础功能
##  声明全局种子，GameCore.Settings.GameSettings.WorldSeed，所有方法的随机数都基于这个种子，每个步骤的随机数都基于全局种子，确保可重复生成相同结果。
##  基础代码内容：
    extends ModInterface
    class_name WorldMapManager

    var _location_maps: Dictionary = {} # location gen map
    var _location_mud_maps: Dictionary = {} # location mud map

    func _on_mod_event(_mod_name: String, event_name: String, event_data: Dictionary) -> void:
        super._on_mod_event(_mod_name, event_name, event_data)
        if _mod_name == "WorldMapGenerator" and event_name == "after_gen_all_location_map_finished":
            _location_maps = event_data.get("location_map_datas",{}) as Dictionary
            generate_all_refined_map()
        # TODO 加一个 popup msg
        elif event_name == "SaveAllMapTemplateData":
            save_all_location_maps()

    func gen_all_locations():
        # 监听生成地图完成
        register_event_listener_with_name(ModEventListenerFilter.new()
            .set_listen_type(ModEventListenerFilter.ListenType.ONCE)
            .set_mod_filter_type(ModEventListenerFilter.ModFilterType.TARGET)
            .set_mod_name("WorldMapGenerator")
            .set_event_filter_type(ModEventListenerFilter.EventFilterType.TARGET)
            .set_event_name("after_gen_all_location_map_finished")
            , "after_gen_all_location_map_finished"
        )
        GameCore.mod_manager.call_mod("WorldMapGenerator", "gen_all_location_map")

    func after_gen_all_location_map_finished():
        save_all_location_maps()
        emit_mod_event.call_deferred("after_gen_all_location_map_finished", {
            "mud_maps":_location_mud_maps
        })

    func save_all_location_maps():
        if GameCore.debugging and SaveManager.has_mod_slot_file(GameCore.Settings.GameSettings.GameSlot, "%s/map_%s.sav" % [mod_name, _location_mud_maps.keys()[0].uri_encode()]):
            return
        for data in _location_mud_maps.values():
            var map_name = data.get("data",{}).get("name", "unknow_map")
            if map_name == "unknow_map":
                push_warning("[%s] save_all_location_maps 中未知的 name" % mod_name)
            SaveManager.save_mod_slot_data(GameCore.Settings.GameSettings.GameSlot, "%s/map_%s"%[mod_name, map_name.uri_encode()], data)

    # 线程相关变量
    var map_process_thread: Thread = Thread.new() # 地图处理线程
    var map_process_mutex: Mutex = Mutex.new() # 互斥锁（保证数据安全）
    var is_map_process_running: bool = false # 标记线程是否运行

    func _gen_all_location_map():
        for map in _location_maps.values():
            var map_name = map.get("name", "")
            if map_name == "":
                continue
            map_process_mutex.lock()
            _location_mud_maps[map_name] = MudMapGenerator.generate_mud_map_template(map).duplicate_deep()
            map_process_mutex.unlock()
            #emit_mod_event("generate_one_refined_map_template", {
            #	"map_name":map_name,
            #	"map_data":_location_mud_maps[map_name]
            #})
            after_one_location_generate_finished(_location_mud_maps[map_name])
            
        after_gen_all_location_map_finished.call_deferred()
        
        is_map_process_running = false

        
    func after_one_location_generate_finished(mud_map):
        var map_name = mud_map.metadata.map_name
        emit_mod_event("generate_one_refined_map_template", {
            "map_name":map_name,
            "map_data":_location_mud_maps[map_name]
        })

    func generate_all_refined_map():
        if is_map_process_running: return
        is_map_process_running = true
        
        if GameCore.debugging and SaveManager.has_mod_slot_file(GameCore.Settings.GameSettings.GameSlot, "%s/map_%s.sav" % [mod_name, _location_maps.keys()[0].uri_encode()]):
            print("从缓存中加载 _location_mud_maps")
            for map in _location_maps.values():
                var map_name = map.get("name","")
                if map_name == "":
                    continue
                if GameCore.debugging and SaveManager.has_mod_slot_file(GameCore.Settings.GameSettings.GameSlot, "%s/map_%s.sav" % [mod_name, map_name.uri_encode()]):
                    _location_mud_maps[map_name] = SaveManager.load_mod_slot_data(GameCore.Settings.GameSettings.GameSlot, "%s/map_%s" % [mod_name, map_name.uri_encode()])
                after_one_location_generate_finished(_location_mud_maps[map_name])
                await get_tree().create_timer(0).timeout
            is_map_process_running = false
            after_gen_all_location_map_finished.call_deferred()
            return


        map_process_thread.start(_gen_all_location_map)
    ...
##  提供功能
## 1. mud_map_template 的增删改查
#  成员变量
#  成员方法
#  数据文件
