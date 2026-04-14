# mod.WorldMapManager.Scripts.ModEntry.gd 分析文档

## 基础规则

### 基础规则
- 禁止在函数内部创建函数
- 禁止使用多行注释"""，"""注释内容"""，使用#注释
- 函数注解、模块注解使用##

### 基础代码调用用例

- 数组去重
   ```gdscript
   new_array = GameCore.ArrayTools.deduplicate(array)
   ```

- 字典合并
   ```gdscript
   new_dict = GameCore.DictionaryTools.merge(dict_1, dict_2)
   ```

- 时间获取
   ```gdscript
   time_string =  Time.get_datetime_string_from_system()
   ```

- 调用其他模块
   ```gdscript
   result = GameCore.ModManager.call_mod(mod_name:String, method_name:String, ...args)
   ```

### 代码注释

- 为文件适当添加注释
   - 给出配置
   - 给出输入输出的数据结构
   - 说明模块的功能
   - 给出模块的用例
   - 给出涉及模块的名称

- 在文件头给出模块的主要功能以及对应方法

- 给出功能的用例

### 模块交互

- 通过 GameCore.mod_manager.call_mod(mod_name, method_name, args) 调用其他模块的方法
- 不需要判断 Engine.has_meta(mod_name)
- 因为 GameCore.mod_manager.call_mod 已经判断了，如果模块不存在，不会调用空模块，所以不会报错。

# 模块概述

## 模块名称
WorldMapManager

## 模块路径
res/mods/WorldMapManager/Scripts/ModEntry.gd

## 模块功能
世界地图管理器，负责管理所有 location 的静态地图配置和地图模板生成。主要职责包括：
1. 管理 location 的固定配置（map_data、spawn_points、metadata 等）
2. 通过 WorldMapGenerator 生成所有 location 的地图模板
3. 管理 mud_map_template 的生命周期（增删改查）
4. 使用线程异步生成地图模板，避免阻塞主线程
5. 保存和加载地图模板数据

## 模块依赖
- WorldMapGenerator: 用于生成地图模板
- SaveManager: 用于保存/加载地图模板数据
- ModEventListenerFilter: 用于事件监听过滤

## 使用全局种子
GameCore.Settings.GameSettings.WorldSeed

## 模块用例

```gdscript
# 示例 1：获取 location 的静态配置
var location_config = WorldMapManager.get_location_static("file_island")

# 示例 2：获取地图数据
var map_data = WorldMapManager.get_map_data("file_island")

# 示例 3：获取生成点
var spawn_points = WorldMapManager.get_spawn_points("file_island")

# 示例 4：生成所有 location 的地图
WorldMapManager.gen_all_locations()

# 示例 5：获取 mud_map_template
var template = WorldMapManager.get_mud_map_template("file_island")

# 示例 6：添加或更新 mud_map_template
var template_data = {...}
WorldMapManager.add_or_update_mud_map_template("new_map", template_data)

# 示例 7：获取所有 mud_map_templates
var all_templates = WorldMapManager.get_all_mud_map_templates()
```

# 成员变量

- _locations: Dictionary
  - location map 固定配置
  - 数据结构：{location_id: {map_data:[], spawn_points:{}, metadata:{}, ...}}

- _location_maps: Dictionary
  - location 生成地图数据
  - 数据结构：{location_id: map_gen_data}

- _location_mud_maps: Dictionary
  - location mud map 模板数据
  - 数据结构：{location_id: mud_map_template}

- _version: int
  - 版本号，默认为 1

- map_process_thread: Thread
  - 地图处理线程

- map_process_mutex: Mutex
  - 互斥锁，保证数据安全

- is_map_process_running: bool
  - 标记线程是否运行

# 成员方法

- _on_mod_load() -> bool
  - @return bool: 模块加载是否成功
  - functions:
    - 运行时加载 MudMapGenerator 类
    - 检查 MudMapGenerator 是否成功加载
    - 打印已加载的 location 数量

- _on_mod_event(_mod_name:String, event_name:String, event_data:Dictionary) -> void
  - @args:
    - _mod_name: 触发事件的模块名称
    - event_name: 事件名称
    - event_data: 事件数据
  - functions:
    - 监听 WorldMapGenerator 的 after_gen_all_location_map_finished 事件
    - 接收到事件后，保存所有 location maps
    - 监听 SaveAllMapTemplateData 事件，触发保存

- get_location_static(location_id:String) -> Dictionary
  - @args:
    - location_id: location 的唯一标识符
  - @return Dictionary: location 的静态配置数据
  - functions:
    - 从 _locations 字典中获取 location 的静态配置

- get_map_data(location_id:String) -> Array
  - @args:
    - location_id: location 的唯一标识符
  - @return Array: location 的地图数据数组
  - functions:
    - 从 _locations 中获取 location 的 map_data

- get_spawn_points(location_id:String) -> Dictionary
  - @args:
    - location_id: location 的唯一标识符
  - @return Dictionary: location 的生成点配置
  - functions:
    - 从 _locations 中获取 location 的 spawn_points

- get_metadata(location_id:String) -> Dictionary
  - @args:
    - location_id: location 的唯一标识符
  - @return Dictionary: location 的元数据
  - functions:
    - 从 _locations 中获取 location 的 metadata

- get_mod_path() -> String
  - @return String: 模块的根路径
  - functions:
    - 从 GameCore.mod_manager.loaded_mods 中获取模块路径

- gen_all_locations() -> void
  - functions:
    - 注册事件监听器，监听 WorldMapGenerator 的 after_gen_all_location_map_finished 事件
    - 调用 WorldMapGenerator.gen_all_location_map() 生成所有 location 地图

- after_gen_all_location_map_finished() -> void
  - functions:
    - 保存所有 location maps
    - 发送 after_gen_all_location_map_finished 事件，包含所有 mud_maps 数据

- save_all_location_maps() -> void
  - functions:
    - 遍历 _location_mud_maps 中的所有地图数据
    - 使用 SaveManager 保存每个地图数据到存档槽位
    - 如果调试模式下已存在存档文件，则跳过保存

- _gen_all_location_map() -> void
  - functions:
    - 遍历 _location_maps 中的所有地图
    - 使用互斥锁保护数据安全
    - 调用 MudMapGenerator.generate_mud_map_template() 生成地图模板
    - 发送 generate_one_refined_map_template 事件

- get_mud_map_template(map_id:String) -> Dictionary
  - @args:
    - map_id: 地图 ID
  - @return Dictionary: mud_map_template 数据
  - functions:
    - 从 _location_mud_maps 中获取指定地图的模板

- add_or_update_mud_map_template(map_id:String, template:Dictionary) -> void
  - @args:
    - map_id: 地图 ID
    - template: mud_map_template 数据
  - functions:
    - 添加或更新指定地图的模板到 _location_mud_maps

- remove_mud_map_template(map_id:String) -> void
  - @args:
    - map_id: 地图 ID
  - functions:
    - 从 _location_mud_maps 中移除指定地图的模板

- get_all_mud_map_templates() -> Dictionary
  - @return Dictionary: 所有 mud_map_template 数据
  - functions:
    - 返回 _location_mud_maps 字典

- get_mud_map_templates_count() -> int
  - @return int: mud_map_template 数量
  - functions:
    - 返回 _location_mud_maps 的大小

- after_one_location_generate_finished(mud_map:Dictionary) -> void
  - @args:
    - mud_map: 生成的地图模板数据
  - functions:
    - 发送 generate_one_refined_map_template 事件，通知单个地图生成完成

- generate_all_refined_map() -> void
  - functions:
    - 如果线程正在运行，则直接返回
    - 在调试模式下，检查是否已有缓存数据
    - 如果有缓存，从 SaveManager 加载缓存数据
    - 如果没有缓存，启动线程异步生成所有地图模板

# 数据文件

- 无直接依赖的数据文件
- 通过 WorldMapGenerator 生成地图模板
- 使用 SaveManager 保存/加载地图模板数据到存档槽位

# 模块交互

## 调用的其他模块
- WorldMapGenerator: gen_all_location_map(), generate_mud_map_template()
- SaveManager: save_mod_slot_data(), load_mod_slot_data(), has_mod_slot_file()
- ModEventListenerFilter: 事件监听过滤

## 被其他模块调用
- WorldMapInstanceManager: 调用 get_location_static(), get_all_mud_map_templates()
- GameManager: 调用 gen_all_locations() 生成所有地图

## 发送的事件
- after_gen_all_location_map_finished: 所有地图模板生成完成
- generate_one_refined_map_template: 单个地图模板生成完成

# 核心流程

## 地图生成流程
1. GameManager 调用 WorldMapManager.gen_all_locations()
2. WorldMapManager 注册事件监听器
3. WorldMapManager 调用 WorldMapGenerator.gen_all_location_map()
4. WorldMapGenerator 生成所有 location 地图后发送事件
5. WorldMapManager 接收到事件后，调用 generate_all_refined_map()
6. generate_all_refined_map() 启动线程异步处理
7. 线程中遍历所有 location_maps，调用 MudMapGenerator 生成模板
8. 每生成一个地图，发送 generate_one_refined_map_template 事件
9. 所有地图生成完成后，发送 after_gen_all_location_map_finished 事件
10. 保存所有地图模板数据到存档

## 线程安全
- 使用 Mutex 互斥锁保护 _location_mud_maps 的写入操作
- 使用 is_map_process_running 标记防止重复启动线程
- 数据操作使用 duplicate_deep() 避免引用问题
