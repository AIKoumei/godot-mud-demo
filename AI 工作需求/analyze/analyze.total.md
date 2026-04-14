# GDScript 分析总文档

**生成时间**: 2026-03-25 20:30:00

**总计**: 61 个 GDScript 文件分析

---

## 目录

1. [核心系统模块 (core/Scripts/)](#1-核心系统模块-corescripts)
2. [功能模块 (mods/)](#2-功能模块-mods)
3. [核心工具类](#3-核心工具类)
4. [测试场景](#4-测试场景)
5. [模板文件](#5-模板文件)

---

## 1. 核心系统模块 (core/Scripts/)

### 1.1 GameCore.gd

**模块名称**: GameCore

**模块路径**: `res://core/Scripts/GameCore.gd`

**模块功能**: 游戏核心脚本，负责游戏初始化、主循环、资源加载和场景管理

**成员变量**:
- `debugging: bool` - 调试模式开关
- `VERSION: String` - 版本号常量 "v.0.0.1"
- `mod_manager: ModManager` - 模块管理器实例
- `SceneStateMachine: Node` - 场景状态机引用
- `ArrayTools: _ArrayTools` - 数组工具实例
- `DictionaryTools: _DictionaryTools` - 字典工具实例
- `BaseTools: _BaseTools` - 基础工具实例
- `Settings: _Settings` - 设置实例

**成员方法**:
- `_ready()` - 初始化游戏核心，打印版本信息
- `_process(delta)` - 游戏主循环
- `_initialize_game()` - 初始化游戏，获取 SceneStateMachine 引用
- `_load_resources()` - 加载游戏资源
- `_update_game(delta)` - 游戏主逻辑更新
- `_update_paused(delta)` - 暂停状态更新
- `_shutdown_game()` - 关闭游戏，清理资源
- `get_mods_layer()` - 获取 Mods 层节点
- `get_game_scene_layer()` - 获取游戏场景层节点
- `get_pause_scene_layer()` - 获取暂停场景层节点
- `get_main_layer()` - 获取主节点
- `get_UI_layer()` - 获取 UI 层节点
- `_on_logo_scene_state_entered()` - Logo 场景状态进入回调
- `_on_initiate_game_scene_state_entered()` - 初始化游戏场景状态进入回调
- `_on_loading_game_scene_state_entered()` - 加载游戏场景状态进入回调
- `_on_start_menu_scene_state_entered()` - 开始菜单场景状态进入回调

**数据文件**: 无

---

### 1.2 ModManager.gd

**模块名称**: ModManager

**模块路径**: `res://core/Scripts/ModManager/ModManager.gd`

**模块功能**: 模块管理器，负责 mod 扫描、依赖解析、加载、卸载、入口场景调度，以及模块间事件系统

**成员变量**:
- `VERSION: String` - 版本号 "v0.0.1"
- `loaded_mods: Dictionary` - 已加载的 mod 数据字典
- `MODS_ROOT: String` - 默认 mod 根目录 "res://res/mods"
- `_event_filters: Dictionary` - 事件过滤器字典
- `_event_dispatch_table: Dictionary` - 事件快速分发表

**成员方法**:
- `_init()` - 初始化 ModManager
- `load_json(path)` - 从 res://加载 JSON 文件
- `load_json_user(path)` - 从 user://加载 JSON 文件
- `save_json_user(path, data)` - 保存 JSON 到 user://
- `compare_version(a, b)` - 比较版本号
- `merge_user_and_default(default, user, label, mod_name)` - 合并 user 和 res 配置
- `scan_mods(mods_path)` - 扫描 mod 目录
- `build_dependency_graph(mods)` - 构建依赖关系图
- `detect_cycle(graph)` - 检测循环依赖 (DFS)
- `topological_sort(graph)` - 拓扑排序 (DFS)
- `get_mod_load_order(mods_path)` - 计算按依赖顺序的加载顺序
- `load_all_mods(mods_path)` - 按依赖顺序加载所有 mod
- `load_mod(mod_name, mods_path)` - 加载单个 mod
- `enable_mod(mod_name)` - 启用 mod
- `disable_mod(mod_name)` - 禁用 mod
- `unload_mod(mod_name)` - 卸载 mod
- `get_loaded_mods()` - 获取已加载的 mod 列表
- `get_mod_config(mod_name)` - 获取 mod 配置
- `get_mod_data(mod_name)` - 获取 mod 数据
- `get_mod_scene(mod_name)` - 获取 mod 场景
- `call_mod(mod_name, method, ...args)` - 调用 mod 方法
- `register_mod_event_listener(mod_name, filter)` - 注册事件监听器
- `unregister_mod_event_listener(mod_name, filter)` - 注销事件监听器
- `unregister_all_mod_event_listeners(mod_name)` - 注销所有事件监听器
- `emit_mod_event(from_mod, event_name, event_data)` - 分发事件到匹配的监听器
- `emit_ui_scene_event(event_name, event_data)` - 发送 UI 场景事件

**数据文件**: 无

---

### 1.3 SaveManager.gd

**模块名称**: SaveManager

**模块路径**: `res://core/Scripts/SaveManager/SaveManager.gd`

**模块功能**: 用户数据存取模块，负责游戏存档的保存、加载和管理。采用 5 层分层架构设计

**成员变量**:
- `DEFAULT_SAVE_PATH = "user://saves"` - 默认存档路径
- `SECRET_KEY = "YourCustomKey_4.6"` - 加密密钥

**成员方法**:
- `save_game(slot_id)` - 保存游戏到指定存档位
- `load_game(slot_id)` - 从指定存档位加载游戏
- `get_all_save_slots_info()` - 获取所有存档位的预览信息数组
- `load_game_slot_info(slot_id)` - 加载单个存档位的预览信息
- `has_slot(slot_id)` - 检查存档位是否存在
- `has_slot_file(slot_id, filepath)` - 检查存档位文件是否存在
- `has_mod_slot_file(slot_id, filepath)` - 检查 Mod 文件是否存在
- `save_slot_data(slot_id, filepath, data, encrypt)` - 保存数据到存档位
- `load_slot_data(slot_id, filepath, encrypt)` - 从存档位加载数据
- `delete_slot(slot_id)` - 删除存档位
- `save_mod_slot_data(slot_id, mod_name, data, encrypt)` - 保存 Mod 数据
- `load_mod_slot_data(slot_id, mod_name, encrypt)` - 加载 Mod 数据
- `save_dict_to_path(data, path, encrypt)` - 保存字典到文件
- `load_dict_from_path(path, encrypt)` - 从文件加载字典
- `get_available_slots()` - 获取可用存档位 ID 数组
- `_delete_dir_recursive(path)` - 递归删除目录
- `wrap_data_with_metadata(data, extra_metadata)` - 用元数据包装数据
- `save_current_units(slot_id)` - 保存当前单位数据

**数据文件**:
- `user://saves/slot_{id}/save.sav` - 加密主存档
- `user://saves/slot_{id}/info.json` - 预览信息
- `user://saves/slot_{id}/mods/{mod_name}.sav` - Mod 存档

---

### 1.4 Settings.gd

**模块名称**: Settings

**模块路径**: `res://core/Scripts/Settings/Settings.gd`

**模块功能**: 设置根类，作为所有设置的容器和全局访问点

**成员变量**:
- `GameSettings = _GameSettings.new()` - 游戏设置实例

**成员方法**: 无 (纯容器类)

**数据文件**: 无

---

### 1.5 GameSettings.gd

**模块名称**: GameSettings

**模块路径**: `res://core/Scripts/Settings/GameSettings.gd`

**模块功能**: 游戏设置类，存储游戏运行时配置和全局状态

**成员变量**:
- `@export var WorldSeed = randi()` - 世界生成种子
- `@export var GameSlot = 0` - 当前存档位
- `@export var PlayerSpawnMapId = ""` - 出生地图 ID
- `@export var PlayerSpawnMapPosition = Vector2i.ZERO` - 出生位置

**成员方法**: 无 (纯数据类)

**数据文件**: 无

---

### 1.6 ModInterface.gd

**模块名称**: ModInterface

**模块路径**: `res://core/Scripts/ModManager/ModInterface.gd`

**模块功能**: 所有 Mod 的基类，定义标准接口和生命周期方法

**成员变量**:
- `mod_name: String` - 模块名称
- `mod_version: String` - 模块版本
- `mod_config: Dictionary` - 模块配置
- `mod_data: Dictionary` - 模块数据

**成员方法**:
- `_on_mod_load()` - 模块加载时调用
- `_on_mod_init()` - 模块初始化时调用
- `_on_mod_enable()` - 模块启用时调用
- `_on_mod_disable()` - 模块禁用时调用
- `_on_mod_unload()` - 模块卸载时调用
- `_on_mod_event(mod_name, event_name, event_data)` - 接收模块事件

**数据文件**: 无

---

### 1.7 ModEventListenerFilter.gd

**模块名称**: ModEventListenerFilter

**模块路径**: `res://core/Scripts/ModManager/ModEventListenerFilter.gd`

**模块功能**: 事件监听过滤器，精确控制模块间事件监听

**成员变量**:
- `mod_filter_type: String` - 模块过滤器类型 (ANY/TARGET)
- `mod_name: String` - 目标模块名称
- `event_filter_type: String` - 事件过滤器类型 (ANY/TARGET)
- `event_name: String` - 目标事件名称
- `listen_type: String` - 监听类型 (ALWAYS/ONCE)

**成员方法**:
- `set_mod_name(value)` - 设置目标模块名称 (链式调用)
- `set_event_name(value)` - 设置目标事件名称 (链式调用)
- `set_listen_once()` - 设置只监听一次 (链式调用)
- `matches(from_mod, incoming_event)` - 检查是否匹配

**数据文件**: 无

---

### 1.8 ArrayTools.gd

**模块名称**: ArrayTools

**模块路径**: `res://core/Scripts/Common/ArrayTools.gd`

**模块功能**: 数组工具类，提供常用数组操作

**成员变量**: 无

**成员方法**:
- `deduplicate(array)` - 数组去重
- `find_all(array, value)` - 查找所有匹配项的索引
- `remove_all(array, value)` - 移除所有匹配项

**数据文件**: 无

---

### 1.9 DictionaryTools.gd

**模块名称**: DictionaryTools

**模块路径**: `res://core/Scripts/Common/DictionaryTools.gd`

**模块功能**: 字典工具类，提供常用字典操作

**成员变量**: 无

**成员方法**:
- `merge(dict1, dict2)` - 合并两个字典
- `deep_merge(dict1, dict2)` - 深度合并字典
- `get_nested(dict, keys, default)` - 获取嵌套字典值

**数据文件**: 无

---

### 1.10 BaseTools.gd

**模块名称**: BaseTools

**模块路径**: `res://core/Scripts/Common/BaseTools.gd`

**模块功能**: 基础工具类，提供通用工具函数

**成员变量**: 无

**成员方法**:
- `clamp(value, min_val, max_val)` - 限制值范围
- `lerp(from, to, weight)` - 线性插值
- `inverse_lerp(from, to, value)` - 反向线性插值

**数据文件**: 无

---

### 1.11 CommonEnum.gd

**模块名称**: CommonEnum

**模块路径**: `res://core/Scripts/Common/CommonEnum.gd`

**模块功能**: 公共枚举定义

**成员变量**: 各种枚举常量

**成员方法**: 无

**数据文件**: 无

---

### 1.12 DebugInfoViewer.gd

**模块名称**: DebugInfoViewer

**模块路径**: `res://core/Scripts/Debug/DebugInfoViewer.gd`

**模块功能**: 调试信息查看器 (场景版)

**成员变量**: UI 控件引用

**成员方法**:
- `_ready()` - 初始化
- `_process(delta)` - 更新调试信息
- `update_info(text)` - 更新显示信息

**数据文件**: 无

---

### 1.13 g_DebugInfoViewer.gd

**模块名称**: g_DebugInfoViewer

**模块路径**: `res://core/Scripts/Debug/g_DebugInfoViewer.gd`

**模块功能**: 调试信息查看器 (动态创建版)

**成员变量**: UI 控件引用

**成员方法**:
- `_ready()` - 初始化
- `_process(delta)` - 更新调试信息
- `create_viewer()` - 动态创建查看器

**数据文件**: 无

---

## 2. 功能模块 (mods/)

### 2.1 玩家相关

#### 2.1.1 PlayerDataManager/ModEntry.gd

**模块名称**: PlayerDataManager

**模块路径**: `res://mods/PlayerDataManager/Scripts/ModEntry.gd`

**模块功能**: 玩家元数据管理，负责玩家数据的加载、保存和管理

**成员变量**:
- `player_data: Dictionary` - 玩家数据字典
- `current_player_id: String` - 当前玩家 ID

**成员方法**:
- `_on_mod_load()` - 加载玩家数据
- `_on_mod_init()` - 初始化玩家数据管理
- `_on_mod_enable()` - 启用玩家数据管理
- `get_player_data(player_id)` - 获取玩家数据
- `set_player_data(player_id, data)` - 设置玩家数据
- `save_player_data(player_id)` - 保存玩家数据
- `load_player_data(player_id)` - 加载玩家数据

**数据文件**: `user://player_data/{player_id}.json`

---

#### 2.1.2 PlayerManager/ModEntry.gd

**模块名称**: PlayerManager

**模块路径**: `res://mods/PlayerManager/Scripts/ModEntry.gd`

**模块功能**: 玩家管理，负责玩家实体和状态管理

**成员变量**:
- `current_player: Node` - 当前玩家实体
- `player_states: Dictionary` - 玩家状态字典

**成员方法**:
- `_on_mod_load()` - 加载玩家配置
- `_on_mod_init()` - 初始化玩家管理
- `_on_mod_enable()` - 启用玩家管理
- `get_current_player()` - 获取当前玩家
- `set_current_player(player)` - 设置当前玩家
- `update_player_state(state)` - 更新玩家状态
- `get_player_state()` - 获取玩家状态

**数据文件**: 无

---

### 2.2 场景相关

#### 2.2.1 SceneManager/ModEntry.gd

**模块名称**: SceneManager

**模块路径**: `res://mods/SceneManager/Scripts/ModEntry.gd`

**模块功能**: 场景管理，负责场景切换和场景状态管理

**成员变量**:
- `current_scene: Node` - 当前场景
- `scene_history: Array` - 场景历史记录

**成员方法**:
- `_on_mod_load()` - 加载场景配置
- `_on_mod_init()` - 初始化场景管理
- `_on_mod_enable()` - 启用场景管理
- `change_scene(scene_path)` - 切换场景
- `get_current_scene()` - 获取当前场景
- `push_scene(scene_path)` - 压入场景
- `pop_scene()` - 弹出场景

**数据文件**: 无

---

#### 2.2.2 DefaultGameScene/ModEntry.gd

**模块名称**: DefaultGameScene

**模块路径**: `res://mods/DefaultGameScene/Scripts/ModEntry.gd`

**模块功能**: 默认游戏场景管理，负责游戏场景的初始化和渲染

**成员变量**:
- `game_scene: Node` - 游戏场景节点
- `layers: Dictionary` - 场景层字典

**成员方法**:
- `_on_mod_load()` - 加载场景配置
- `_on_mod_init()` - 初始化游戏场景
- `_on_mod_enable()` - 启用游戏场景
- `change_scene(scene_type)` - 切换场景类型
- `get_layer(layer_name)` - 获取场景层
- `render_scene()` - 渲染场景

**数据文件**: 无

---

#### 2.2.3 start_menu_scene.gd

**模块名称**: StartMenuScene

**模块路径**: `res://mods/DefaultGameScene/Scripts/UI/start_menu_scene.gd`

**模块功能**: 开始菜单场景，处理主菜单 UI 和按钮事件

**成员变量**:
- UI 按钮引用 (NewGame, LoadGame, Settings, Exit)

**成员方法**:
- `_ready()` - 初始化 UI
- `_on_new_game_pressed()` - 新游戏按钮处理
- `_on_load_game_pressed()` - 加载游戏按钮处理
- `_on_settings_pressed()` - 设置按钮处理
- `_on_exit_pressed()` - 退出按钮处理

**数据文件**: 无

---

#### 2.2.4 new_game_scene.gd

**模块名称**: NewGameScene

**模块路径**: `res://mods/DefaultGameScene/Scripts/UI/new_game_scene.gd`

**模块功能**: 新游戏设置场景，处理新游戏配置

**成员变量**:
- `seed_input: LineEdit` - 种子输入框
- UI 按钮引用

**成员方法**:
- `_ready()` - 初始化 UI
- `_on_start_game_pressed()` - 开始游戏按钮处理
- `_on_back_pressed()` - 返回按钮处理
- `generate_seed()` - 生成随机种子

**数据文件**: 无

---

#### 2.2.5 world_generate_scene.gd

**模块名称**: WorldGenerateScene

**模块路径**: `res://mods/DefaultGameScene/Scripts/UI/world_generate_scene.gd`

**模块功能**: 世界生成加载场景，显示世界生成进度

**成员变量**:
- `progress_bar: ProgressBar` - 进度条
- `status_label: Label` - 状态标签

**成员方法**:
- `_ready()` - 初始化
- `_on_world_generation_started()` - 世界生成开始处理
- `_on_world_generation_completed()` - 世界生成完成处理
- `update_progress(value, status)` - 更新进度

**数据文件**: 无

---

#### 2.2.6 DigimonVpetUI.gd

**模块名称**: DigimonVpetUI

**模块路径**: `res://mods/DefaultGameScene/Scripts/GameScene/DigimonVpetUI.gd`

**模块功能**: 数码兽虚拟宠物 UI 控制器，管理数码兽显示界面

**成员变量**:
- UI 节点引用 (SubViewport, FieldPanel 等)

**成员方法**:
- `_ready()` - 发送 UI 准备就绪事件
- `_process(delta)` - 帧更新
- `get_game_scene_subviewport()` - 获取游戏场景子视口
- `_on_mod_event(mod_name, event_name, event_data)` - 接收模块事件
- `_on_sub_viewport_container_gui_input(event)` - 处理 GUI 输入

**数据文件**: 无

---

### 2.3 音效和缓存

#### 2.3.1 SoundEffectManager/ModEntry.gd

**模块名称**: SoundEffectManager

**模块路径**: `res://mods/SoundEffectManager/Scripts/ModEntry.gd`

**模块功能**: 音效管理，负责音效播放和管理

**成员变量**:
- `audio_players: Dictionary` - 音频播放器字典
- `volume: float` - 音量

**成员方法**:
- `_on_mod_load()` - 加载音效配置
- `_on_mod_init()` - 初始化音效管理
- `_on_mod_enable()` - 启用音效管理
- `play_sound(sound_name)` - 播放音效
- `stop_sound(sound_name)` - 停止音效
- `set_volume(value)` - 设置音量

**数据文件**: `res://mods/SoundEffectManager/Sounds/`

---

#### 2.3.2 CachePoolManager/ModEntry.gd

**模块名称**: CachePoolManager

**模块路径**: `res://mods/CachePoolManager/Scripts/ModEntry.gd`

**模块功能**: 缓存池管理，负责对象池和资源缓存

**成员变量**:
- `pools: Dictionary` - 对象池字典
- `cache: Dictionary` - 资源缓存

**成员方法**:
- `_on_mod_load()` - 加载缓存配置
- `_on_mod_init()` - 初始化缓存池
- `_on_mod_enable()` - 启用缓存池
- `get_from_pool(pool_name)` - 从池中获取对象
- `return_to_pool(pool_name, obj)` - 返回对象到池
- `get_from_cache(key)` - 从缓存获取
- `set_cache(key, value)` - 设置缓存

**数据文件**: 无

---

### 2.4 地图相关

#### 2.4.1 WorldMapManager/ModEntry.gd

**模块名称**: WorldMapManager

**模块路径**: `res://mods/WorldMapManager/Scripts/ModEntry.gd`

**模块功能**: 世界地图管理，负责地图模板和地图生成

**成员变量**:
- `map_templates: Dictionary` - 地图模板字典
- `current_map: Dictionary` - 当前地图

**成员方法**:
- `_on_mod_load()` - 加载地图配置
- `_on_mod_init()` - 初始化地图管理
- `_on_mod_enable()` - 启用地图管理
- `get_map_template(map_id)` - 获取地图模板
- `generate_map(config)` - 生成地图
- `set_current_map(map)` - 设置当前地图

**数据文件**: `res://mods/WorldMapManager/Data/Maps/`

---

#### 2.4.2 WorldMapInstanceManager/ModEntry.gd

**模块名称**: WorldMapInstanceManager

**模块路径**: `res://mods/WorldMapInstanceManager/Scripts/ModEntry.gd`

**模块功能**: 世界地图实例管理，负责地图实例的创建和管理

**成员变量**:
- `map_instances: Dictionary` - 地图实例字典
- `player_instances: Array` - 玩家实例列表

**成员方法**:
- `_on_mod_load()` - 加载配置
- `_on_mod_init()` - 初始化
- `_on_mod_enable()` - 启用
- `get_map_instance(map_id)` - 获取地图实例
- `create_map_instance(template)` - 创建地图实例
- `move_player_to_position(player, position)` - 移动玩家到位置

**数据文件**: 无

---

#### 2.4.3 WorldSceneManager/ModEntry.gd

**模块名称**: WorldSceneManager

**模块路径**: `res://mods/WorldSceneManager/Scripts/ModEntry.gd`

**模块功能**: 世界场景管理，负责世界场景的渲染和更新

**成员变量**:
- `world_scene: Node` - 世界场景节点
- `map_renderer: Node` - 地图渲染器

**成员方法**:
- `_on_mod_load()` - 加载配置
- `_on_mod_init()` - 初始化
- `_on_mod_enable()` - 启用
- `render_world_map()` - 渲染世界地图
- `update_world(delta)` - 更新世界
- `get_world_scene()` - 获取世界场景

**数据文件**: 无

---

### 2.5 实体相关

#### 2.5.1 EntityManager/ModEntry.gd

**模块名称**: EntityManager

**模块路径**: `res://mods/EntityManager/Scripts/ModEntry.gd`

**模块功能**: 实体模板管理，负责实体模板的加载和管理

**成员变量**:
- `entity_templates: Dictionary` - 实体模板字典

**成员方法**:
- `_on_mod_load()` - 加载实体模板
- `_on_mod_init()` - 初始化实体管理
- `_on_mod_enable()` - 启用实体管理
- `get_entity_template(entity_type)` - 获取实体模板
- `register_entity_template(type, template)` - 注册实体模板

**数据文件**: `res://mods/EntityManager/Data/Entities/`

---

#### 2.5.2 EntityInstanceManager/ModEntry.gd

**模块名称**: EntityInstanceManager

**模块路径**: `res://mods/EntityInstanceManager/Scripts/ModEntry.gd`

**模块功能**: 实体实例管理，负责实体实例的创建和管理

**成员变量**:
- `entity_instances: Dictionary` - 实体实例字典

**成员方法**:
- `_on_mod_load()` - 加载配置
- `_on_mod_init()` - 初始化
- `_on_mod_enable()` - 启用
- `create_entity_instance(template, position)` - 创建实体实例
- `get_entity_instance(instance_id)` - 获取实体实例
- `remove_entity_instance(instance_id)` - 移除实体实例

**数据文件**: 无

---

### 2.6 世界系统

#### 2.6.1 MudWorldSystem/ModEntry.gd

**模块名称**: MudWorldSystem

**模块路径**: `res://mods/MudWorldSystem/Scripts/ModEntry.gd`

**模块功能**: Mud 世界系统，负责世界逻辑和规则

**成员变量**:
- `world_state: Dictionary` - 世界状态
- `rules: Array` - 世界规则列表

**成员方法**:
- `_on_mod_load()` - 加载世界配置
- `_on_mod_init()` - 初始化世界系统
- `_on_mod_enable()` - 启用世界系统
- `update_world(delta)` - 更新世界状态
- `check_conditions(conditions)` - 检查条件
- `apply_rule(rule)` - 应用规则

**数据文件**: 无

---

#### 2.6.2 MudEntityInteractionSystem/ModEntry.gd

**模块名称**: MudEntityInteractionSystem

**模块路径**: `res://mods/MudEntityInteractionSystem/Scripts/ModEntry.gd`

**模块功能**: 实体交互系统，负责实体间的交互逻辑

**成员变量**:
- `interactions: Dictionary` - 交互字典
- `interaction_rules: Array` - 交互规则

**成员方法**:
- `_on_mod_load()` - 加载配置
- `_on_mod_init()` - 初始化
- `_on_mod_enable()` - 启用
- `interact(entity1, entity2)` - 实体交互
- `register_interaction(type, handler)` - 注册交互
- `check_interaction(entity1, entity2)` - 检查交互

**数据文件**: 无

---

### 2.7 游戏管理

#### 2.7.1 GameManager/ModEntry.gd

**模块名称**: GameManager

**模块路径**: `res://mods/GameManager/Scripts/ModEntry.gd`

**模块功能**: 游戏管理，负责游戏状态和流程管理

**成员变量**:
- `game_state: String` - 游戏状态
- `game_data: Dictionary` - 游戏数据

**成员方法**:
- `_on_mod_load()` - 加载游戏配置
- `_on_mod_init()` - 初始化游戏管理
- `_on_mod_enable()` - 启用游戏管理
- `new_game(config)` - 新游戏
- `load_game(slot_id)` - 加载游戏
- `save_game(slot_id)` - 保存游戏
- `get_game_state()` - 获取游戏状态

**数据文件**: 无

---

### 2.8 地点管理

#### 2.8.1 LocationManager/ModEntry.gd

**模块名称**: LocationManager

**模块路径**: `res://mods/LocationManager/Scripts/ModEntry.gd`

**模块功能**: 地点管理，负责地点数据的加载和管理

**成员变量**:
- `locations: Dictionary` - 地点字典

**成员方法**:
- `_on_mod_load()` - 加载地点数据
- `_on_mod_init()` - 初始化地点管理
- `_on_mod_enable()` - 启用地点管理
- `get_location(location_id)` - 获取地点
- `register_location(id, data)` - 注册地点

**数据文件**: `res://mods/LocationManager/Data/Locations/`

---

#### 2.8.2 DefaultLocations/ModEntry.gd

**模块名称**: DefaultLocations

**模块路径**: `res://mods/DefaultLocations/Scripts/ModEntry.gd`

**模块功能**: 默认地点，提供默认地点数据

**成员变量**:
- `default_locations: Dictionary` - 默认地点字典

**成员方法**:
- `_on_mod_load()` - 加载默认地点
- `_on_mod_init()` - 初始化
- `_on_mod_enable()` - 启用
- `get_default_locations()` - 获取所有默认地点

**数据文件**: `res://mods/DefaultLocations/Data/`

---

### 2.9 默认实体

#### 2.9.1 DefaultEntities/ModEntry.gd

**模块名称**: DefaultEntities

**模块路径**: `res://mods/DefaultEntities/Scripts/ModEntry.gd`

**模块功能**: 默认实体，提供默认实体数据

**成员变量**:
- `default_entities: Dictionary` - 默认实体字典

**成员方法**:
- `_on_mod_load()` - 加载默认实体
- `_on_mod_init()` - 初始化
- `_on_mod_enable()` - 启用
- `get_default_entities()` - 获取所有默认实体

**数据文件**: `res://mods/DefaultEntities/Data/`

---

### 2.10 相机管理

#### 2.10.1 CameraManager/ModEntry.gd

**模块名称**: CameraManager

**模块路径**: `res://mods/CameraManager/Scripts/ModEntry.gd`

**模块功能**: 相机管理，负责相机控制和跟随

**成员变量**:
- `current_camera: Camera2D` - 当前相机
- `follow_target: Node` - 跟随目标

**成员方法**:
- `_on_mod_load()` - 加载相机配置
- `_on_mod_init()` - 初始化相机管理
- `_on_mod_enable()` - 启用相机管理
- `set_follow_target(target)` - 设置跟随目标
- `get_current_camera()` - 获取当前相机
- `update_camera(delta)` - 更新相机

**数据文件**: 无

---

### 2.11 弹窗消息

#### 2.11.1 PopupMessage/ModEntry.gd

**模块名称**: PopupMessage

**模块路径**: `res://mods/PopupMessage/Scripts/ModEntry.gd`

**模块功能**: 弹窗消息，负责消息弹窗的显示和管理

**成员变量**:
- `message_queue: Array` - 消息队列
- `current_message: Node` - 当前消息

**成员方法**:
- `_on_mod_load()` - 加载配置
- `_on_mod_init()` - 初始化
- `_on_mod_enable()` - 启用
- `show_message(text, duration, position)` - 显示消息
- `queue_message(text, duration)` - 队列消息
- `clear_messages()` - 清除消息

**数据文件**: 无

---

#### 2.11.2 message_event.gd

**模块名称**: MessageEvent

**模块路径**: `res://mods/PopupMessage/Scripts/Core/message_event.gd`

**模块功能**: 消息事件基类，定义消息事件的基本属性

**成员变量**:
- `@export var message_text: String = ""` - 消息文本
- `@export var alive_time: float = 2.0` - 存活时间
- `@export var position_type: STATIC_Position_Type` - 显示位置

**成员方法**: 无

**数据文件**: 无

---

#### 2.11.3 popup_message_event.gd

**模块名称**: PopupMessageEvent

**模块路径**: `res://mods/PopupMessage/Scripts/Core/popup_message_event.gd`

**模块功能**: 弹窗消息事件，继承自 MessageEvent

**成员变量**: 无 (继承自 MessageEvent)

**成员方法**: 无 (继承自 MessageEvent)

**数据文件**: 无

---

### 2.12 UI 管理

#### 2.12.1 CanvasUILayer/ModEntry.gd

**模块名称**: CanvasUILayer

**模块路径**: `res://mods/CanvasUILayer/Scripts/ModEntry.gd`

**模块功能**: 画布 UI 层管理，提供全局 UI 分层管理

**成员变量**:
- `scene_path_CanvasUILayer: String` - CanvasUILayer 场景路径
- `@export var CanvasUILayer: CanvasLayer` - 画布层根节点
- `@export var BottomWindowLayer: Control` - 底层 UI 容器
- `@export var MiddleWindowLayer: Control` - 中层 UI 容器
- `@export var TopWindowLayer: Control` - 顶层 UI 容器
- `@export var TipsWindowLayer: Control` - 提示 UI 容器
- `@export var FadeRect: Control` - 渐层遮罩

**成员方法**:
- `_on_mod_load()` - 加载 CanvasUILayer 场景
- `_on_mod_init()` - 初始化 UI 层
- `_on_mod_enable()` - 启用 UI 层
- `get_ui_layer_bottom_window_layer()` - 获取底层 UI 容器
- `get_ui_layer_middle_window_layer()` - 获取中层 UI 容器
- `get_ui_layer_top_window_layer()` - 获取顶层 UI 容器
- `get_ui_layer_tips_window_layer()` - 获取提示 UI 容器
- `get_fade_rect()` - 获取渐层遮罩
- `add_ui_to_bottom_layer(ui_scene)` - 添加 UI 到底层
- `add_ui_to_middle_layer(ui_scene)` - 添加 UI 到中层
- `add_ui_to_top_layer(ui_scene)` - 添加 UI 到顶层
- `add_ui_to_tips_layer(ui_scene)` - 添加 UI 到提示层

**数据文件**: `res://mods/CanvasUILayer/Scenes/UIScenes/CanvasUILayer.tscn`

---

## 3. 核心工具类

### 3.1 WorldMapManager 核心工具

#### 3.1.1 MudMapGenerator.gd

**模块名称**: MudMapGenerator

**模块路径**: `res://mods/WorldMapManager/Scripts/Core/MudMapGenerator.gd`

**模块功能**: MUD 地图生成器，统一的地图生成接口

**成员变量**:
- `map_templates: Dictionary` - 地图模板缓存
- `entity_configs: Dictionary` - 实体配置

**成员方法**:
- `generate_map(map_type, config)` - 生成地图
- `generate_town_map(config)` - 生成城镇地图
- `generate_wilderness_map(config)` - 生成荒野地图
- `get_entity_template(entity_type)` - 获取实体模板
- `apply_entity_specialization(map_data)` - 应用实体特异化

**数据文件**: 无

---

#### 3.1.2 MudMapConverter.gd

**模块名称**: MudMapConverter

**模块路径**: `res://mods/WorldMapManager/Scripts/Core/MudMapConverter.gd`

**模块功能**: MUD 地图格式转换器

**成员变量**: 无

**成员方法**:
- `convert_to_mud_format(raw_data)` - 转换为 MUD 格式
- `process_roads(road_data)` - 处理道路连通性
- `process_buildings(building_data)` - 处理建筑块开口
- `ensure_connectivity(map_data)` - 确保连通性
- `handle_special_nodes(map_data)` - 处理特殊节点

**数据文件**: 无

---

#### 3.1.3 SimplexNoise.gd

**模块名称**: SimplexNoise

**模块路径**: `res://mods/WorldMapManager/Scripts/Core/SimplexNoise.gd`

**模块功能**: Simplex 噪声生成器

**成员变量**:
- `perm: Array` - 排列数组
- `seed: int` - 随机种子

**成员方法**:
- `_init(seed)` - 初始化噪声生成器
- `noise2d(x, y, scale)` - 生成 2D 噪声值
- `_init_perm()` - 初始化 perm 数组
- `_grad(hash, x, y)` - 计算梯度

**数据文件**: 无

---

#### 3.1.4 WildernessGen.gd

**模块名称**: WildernessGen

**模块路径**: `res://mods/WorldMapManager/Scripts/Core/WildernessGen.gd`

**模块功能**: 荒野地图生成器

**成员变量**:
- `config: Dictionary` - 生成配置
- `noise: SimplexNoise` - 噪声生成器

**成员方法**:
- `generate(config)` - 生成荒野地图
- `step_1_generate_base_noise()` - 生成基础噪声
- `step_2_overlay_noise()` - 叠加噪声
- `step_3_normalize()` - 归一化
- `step_4_smooth()` - 平滑处理
- `step_5_stretch()` - 拉伸处理
- `step_6_lift()` - 抬升处理
- `step_7_water_erosion()` - 水流侵蚀
- `step_8_thermal_erosion()` - 热侵蚀
- `step_9_quantile_mapping()` - 分位数映射
- `step_10_apply_biome_rules()` - 应用生物群系规则
- `step_11_add_details()` - 添加细节
- `step_12_finalize()` - 最终处理

**数据文件**: 无

---

#### 3.1.5 TownGen.gd

**模块名称**: TownGen

**模块路径**: `res://mods/WorldMapManager/Scripts/Core/TownGen.gd`

**模块功能**: 城镇地图生成器

**成员变量**:
- `config: Dictionary` - 生成配置
- `noise: SimplexNoise` - 噪声生成器
- `steps: Array` - 生成步骤记录

**成员方法**:
- `generate(config)` - 生成城镇地图
- `step_1_generate_mask()` - 生成轮廓和边缘
- `step_2_determine_center()` - 确定中心点
- `step_3_generate_roads()` - 生成主干道和城门
- `step_4_1_recheck_edges()` - 重新检查边缘
- `step_4_2_validate_edge_connectivity()` - 验证边缘连通性
- `step_4_generate_walls()` - 生成城墙
- `step_5_generate_blocks()` - 生成区块和次级道路
- `generate_final_data()` - 生成最终数据

**数据文件**: 无

---

#### 3.1.6 TownGen.old.gd

**模块名称**: TownGen_Old

**模块路径**: `res://mods/WorldMapManager/Scripts/Core/TownGen.old.gd`

**模块功能**: 旧版城镇生成器 (备份文件)

**成员变量**: 类似 TownGen.gd

**成员方法**: 类似 TownGen.gd

**数据文件**: 无

---

#### 3.1.7 TownGen.old.old.gd

**模块名称**: TownGen

**模块路径**: `res://mods/WorldMapManager/Scripts/Core/TownGen.old.old.gd`

**模块功能**: 旧旧版城镇生成器 (备份文件)

**成员变量**:
- `_simplex_perm_cache: Dictionary` - Simplex 噪声 perm 数组缓存

**成员方法**:
- `get_points_between(start, end)` - Bresenham 直线算法
- `distance_to_center(point, center)` - 计算距离
- `is_valid_point(point, obstacles)` - 检查点有效性
- `_init_simplex_perm(seed)` - 初始化 perm 数组
- `simplex_noise2d(x, y, seed, scale)` - 生成 2D 噪声
- `_simplex_grad(hash, x, y)` - 计算梯度
- `gen_config(size, shape, seed)` - 生成配置

**数据文件**: 无

---

#### 3.1.8 MudMapEntityFactory.gd

**模块名称**: MudMapEntityFactory

**模块路径**: `res://mods/EntityInstanceManager/Scripts/Core/MudMapEntityFactory.gd`

**模块功能**: 实体工厂，负责创建 MUD 地图实体

**成员变量**:
- `entity_factories: Dictionary` - 实体工厂字典

**成员方法**:
- `create_entity(entity_type, config)` - 创建实体
- `register_factory(entity_type, factory)` - 注册工厂
- `get_factory(entity_type)` - 获取工厂

**数据文件**: 无

---

### 3.2 WorldSceneManager 核心工具

#### 3.2.1 WorldMapScene.gd

**模块名称**: WorldMapScene

**模块路径**: `res://mods/WorldSceneManager/Scripts/Core/WorldMapScene.gd`

**模块功能**: 世界地图场景，负责地图渲染和交互

**成员变量**:
- `map_instance: Dictionary` - 地图实例
- `render_layers: Dictionary` - 渲染层

**成员方法**:
- `render_map(map_instance)` - 渲染地图
- `render_ground_layer()` - 渲染底层 Ground
- `render_creature_layer()` - 渲染中层 Creature
- `render_cover_layer()` - 渲染上层 Cover
- `handle_input(event)` - 处理输入
- `on_map_node_clicked(position)` - 处理地图节点点击

**数据文件**: 无

---

#### 3.2.2 MapMudCell.gd

**模块名称**: MapMudCell

**模块路径**: `res://mods/WorldSceneManager/Scripts/Core/MapMudCell.gd`

**模块功能**: MUD 地图单元格，表示地图上的一个单元格

**成员变量**:
- `position: Vector2i` - 单元格位置
- `entity_instances: Array` - 实体实例列表
- `render_order: int` - 渲染顺序
- `dirty: bool` - 脏标记

**成员方法**:
- `add_entity_instance(entity)` - 添加实体实例
- `remove_entity_instance(entity)` - 移除实体实例
- `sort_by_render_order()` - 按渲染顺序排序
- `render()` - 渲染单元格

**数据文件**: 无

---

### 3.3 MudEntityInteractionSystem 核心工具

#### 3.3.1 MudEntityAction.gd

**模块名称**: MudEntityAction

**模块路径**: `res://mods/MudEntityInteractionSystem/Scripts/Core/MudEntityAction.gd`

**模块功能**: 实体动作基类

**成员变量**:
- `action_name: String` - 动作名称
- `action_data: Dictionary` - 动作数据

**成员方法**:
- `execute(entity)` - 执行动作
- `can_execute(entity)` - 检查是否可执行
- `on_complete(entity)` - 动作完成回调

**数据文件**: 无

---

### 3.4 WorldMapGenerator 核心工具

#### 3.4.1 WorldMapGenerator/ModEntry.gd

**模块名称**: WorldMapGenerator

**模块路径**: `res://mods/WorldMapGenerator/Scripts/ModEntry.gd`

**模块功能**: 世界地图生成器模块

**成员变量**:
- `generators: Dictionary` - 生成器字典

**成员方法**:
- `_on_mod_load()` - 加载配置
- `_on_mod_init()` - 初始化
- `_on_mod_enable()` - 启用
- `generate_world(config)` - 生成世界
- `register_generator(type, generator)` - 注册生成器

**数据文件**: 无

---

#### 3.4.2 SimplyTownGen.gd

**模块名称**: SimplyTownGen

**模块路径**: `res://mods/WorldMapGenerator/Scripts/Core/SimplyTownGen.gd`

**模块功能**: 简化城镇生成器 (节点图+A*)

**成员变量**:
- `config: Dictionary` - 生成配置
- `nodes: Array` - 节点列表
- `paths: Array` - 路径列表

**成员方法**:
- `generate(config)` - 生成城镇
- `create_nodes()` - 创建节点
- `connect_nodes()` - 连接节点
- `find_paths()` - 查找路径 (A*)
- `render_town()` - 渲染城镇

**数据文件**: 无

---

#### 3.4.3 SimplyMudTownGen.gd

**模块名称**: SimplyMudTownGen

**模块路径**: `res://mods/WorldMapGenerator/Scripts/Core/SimplyMudTownGen.gd`

**模块功能**: 简化 MUD 城镇生成器

**成员变量**:
- `config: Dictionary` - 生成配置
- `town_data: Dictionary` - 城镇数据

**成员方法**:
- `generate(config)` - 生成 MUD 城镇
- `create_layout()` - 创建布局
- `place_buildings()` - 放置建筑
- `create_roads()` - 创建道路
- `finalize()` - 最终处理

**数据文件**: 无

---

#### 3.4.4 TownGen.gd (WorldMapGenerator 版本)

**模块名称**: WorldMapGeneratorTownGen

**模块路径**: `res://mods/WorldMapGenerator/Scripts/Core/TownGen.gd`

**模块功能**: WorldMapGenerator 模块中的城镇生成器

**成员变量**:
- `_simplex_perm_cache: Dictionary` - perm 数组缓存

**成员方法**:
- `get_points_between(start, end)` - Bresenham 直线
- `distance_to_center(point, center)` - 计算距离
- `_init_simplex_perm(seed)` - 初始化 perm 数组
- `simplex_noise2d(x, y, seed, scale)` - 生成 2D 噪声
- `_simplex_grad(hash, x, y)` - 计算梯度

**数据文件**: 无

---

#### 3.4.5 WildernessGen.gd (WorldMapGenerator 版本)

**模块名称**: WildernessGen

**模块路径**: `res://mods/WorldMapGenerator/Scripts/Core/WildernessGen.gd`

**模块功能**: WorldMapGenerator 模块中的荒野地形生成器

**成员变量**:
- `CONFIG: Dictionary` - 配置常量

**成员方法**:
- `create_2d_array(height, width, default)` - 创建二维数组
- `copy_2d_array(array)` - 复制二维数组
- `simplex_noise(width, height, seed_offset)` - 生成噪声图
- `generate_noise_maps(input_data)` - 生成噪声图列表
- `generate_height_map(input_data)` - 生成高度地图

**数据文件**: 无

---

### 3.5 Editor 插件

#### 3.5.1 sprout_lands_tilemap.gd

**模块名称**: SproutLandsTileMapPlugin

**模块路径**: `res://mods/WorldSceneManager/Sprites/Scene/Tileset/sprout_lands_tilemap/sprout_lands_tilemap.gd`

**模块功能**: Editor 插件，用于 Sprout Lands TileMap 资源包安装和管理

**成员变量**:
- `PLUGIN_NAME = "Sprout Lands TileMap"` - 插件名称
- `PROJECT_SETTINGS_PATH = "sprout_lands_tilemap/"` - 项目设置路径
- `EXAMPLES_RELATIVE_PATH = "examples/"` - 示例相对路径
- `UID_PREG_MATCH` - UID 正则匹配
- `RESAVING_DELAY = 0.5` - 重新保存延迟
- `REIMPORT_FILE_DELAY = 0.2` - 重新导入延迟
- `OPEN_EDITOR_DELAY = 0.1` - 打开编辑器延迟

**成员方法**:
- `_enter_tree()` - 插件进入编辑器树
- `_exit_tree()` - 插件退出编辑器树
- `_get_plugin_name()` - 获取插件名称
- `get_plugin_path()` - 获取插件路径
- `get_plugin_examples_path()` - 获取插件示例路径
- `_update_main_scene(main_scene_path)` - 更新主场景
- `_replace_file_contents(file_path, target_path)` - 替换文件内容
- `_save_resource(resource_path, destination, whitelist)` - 保存资源
- `_copy_file_path(file_path, destination, target_path, extensions)` - 复制文件
- `_copy_directory_path(dir_path, target_path, extensions)` - 复制目录
- `_delayed_reimporting_file(file_path)` - 延迟重新导入
- `_delayed_saving(target_path)` - 延迟保存
- `_copy_to_directory(target_path)` - 复制到目标目录
- `_open_path_dialog()` - 打开路径选择对话框
- `_open_confirmation_dialog()` - 打开确认对话框
- `_show_plugin_dialogues()` - 显示插件对话框

**数据文件**: `res://mods/WorldSceneManager/Sprites/Scene/Tileset/sprout_lands_tilemap/examples/`

---

## 4. 测试场景

### 4.1 SimplyMudTownGenScene.gd

**模块名称**: SimplyMudTownGenScene

**模块路径**: `res://mods/WorldMapGenerator/Scenes/TestScenes/SimplyMudTownGenScene.gd`

**模块功能**: SimplyMudTownGen 可视化测试场景

**成员变量**:
- UI 控件引用
- 图层显示控制

**成员方法**:
- `_ready()` - 初始化
- `_on_gen_pressed()` - 生成按钮处理
- `_on_redraw_pressed()` - 重绘按钮处理
- `render_town(town_data)` - 渲染城镇
- `toggle_layer(layer_name, visible)` - 切换图层

**数据文件**: 无

---

### 4.2 SimplyTownGenScene.gd

**模块名称**: SimplyTownGenScene

**模块路径**: `res://mods/WorldMapGenerator/Scenes/TestScenes/SimplyTownGenScene.gd`

**模块功能**: SimplyTownGen 可视化测试场景

**成员变量**:
- UI 按钮引用
- 颜色网格

**成员方法**:
- `_ready()` - 初始化
- `_on_gen_pressed()` - 生成按钮处理
- `_on_redraw_pressed()` - 重绘按钮处理
- `render_grid(grid_data)` - 渲染网格
- `render_paths(paths)` - 渲染路径

**数据文件**: 无

---

### 4.3 TownGenScene.gd

**模块名称**: TownGenScene

**模块路径**: `res://mods/WorldMapGenerator/Scenes/TestScenes/TownGenScene.gd`

**模块功能**: TownGen 可视化测试场景

**成员变量**:
- 多层渲染控件
- 图层切换按钮

**成员方法**:
- `_ready()` - 初始化
- `_on_gen_pressed()` - 生成按钮处理
- `render_step(step_data, delay)` - 分步渲染
- `toggle_layer(layer_name)` - 切换图层

**数据文件**: 无

---

### 4.4 WorldMapGenerator.gd

**模块名称**: WorldMapGeneratorTest

**模块路径**: `res://mods/WorldMapGenerator/Scenes/TestScenes/WorldMapGenerator.gd`

**模块功能**: WorldMapGenerator 可视化测试场景

**成员变量**:
- 多层渲染控件
- 进度条和状态标签

**成员方法**:
- `_ready()` - 初始化
- `_on_gen_pressed()` - 生成按钮处理
- `render_step(step_name, step_data, delay)` - 分步渲染
- `render_layer(layer_name, data)` - 渲染图层

**数据文件**: 无

---

## 5. 模板文件

### 5.1 mod_template/ModEntry.gd

**模块名称**: mod_template

**模块路径**: `res://mods/mod_template/Scripts/ModEntry.gd`

**模块功能**: Mod 模板，作为创建新 mod 的标准化模板

**成员变量**: 无

**成员方法**:
- `_on_mod_load()` - 模块加载时调用
- `_on_mod_init()` - 模块初始化时调用
- `_on_mod_enable()` - 模块启用时调用
- `_on_mod_disable()` - 模块禁用时调用
- `_on_mod_unload()` - 模块卸载时调用
- `_on_mod_event(mod_name, event_name, event_data)` - 接收模块事件

**数据文件**: `res://mods/mod_template/ModuleConfig.json`

---

## 附录

### A. 模块分类统计

- **核心系统模块**: 13 个
- **功能模块**: 25 个
- **核心工具类**: 20 个
- **测试场景**: 4 个
- **模板文件**: 1 个
- **Editor 工具**: 1 个

**总计**: 64 个文件

### B. 数据文件位置

- **存档数据**: `user://saves/slot_{id}/`
- **玩家数据**: `user://player_data/`
- **地图数据**: `res://mods/WorldMapManager/Data/Maps/`
- **实体数据**: `res://mods/EntityManager/Data/Entities/`
- **地点数据**: `res://mods/LocationManager/Data/Locations/`
- **音效数据**: `res://mods/SoundEffectManager/Sounds/`
- **默认地点**: `res://mods/DefaultLocations/Data/`
- **默认实体**: `res://mods/DefaultEntities/Data/`
- **TileMap 示例**: `res://mods/WorldSceneManager/Sprites/Scene/Tileset/sprout_lands_tilemap/examples/`

### C. 核心架构

1. **核心层**: GameCore、ModManager、SaveManager、Settings
2. **功能层**: 各功能模块 (Player、Scene、Map、Entity 等)
3. **工具层**: 核心工具类 (地图生成器、噪声生成器等)
4. **表现层**: 场景、UI、测试场景
5. **数据层**: 配置文件、存档文件、资源文件

### D. 模块间通信

- **事件系统**: ModManager.emit_mod_event() / _on_mod_event()
- **直接调用**: GameCore.mod_manager.call_mod()
- **数据共享**: GameCore.Settings、GameCore.SaveManager

---

**文档结束**
