## ---------------------------------------------------------
## Mod 模板（ModInterface 版本）
##
## 功能说明：
## - 作为创建新 mod 的模板
## - 包含 mod 所需的完整生命周期方法
## - 提供标准化的 mod 结构示例
## - 遵循 Godot 4 最佳实践（强类型 + 无隐式类型）
##
## 依赖：
## - ModInterface（基础接口）
##
## 使用方法：
## 1. 复制 mod_template 目录到 res/mods 下
## 2. 重命名目录为你的 mod 名称
## 3. 修改 ModuleConfig.json 中的配置
## 4. 在 Scripts/ModEntry.gd 中实现你的 mod 逻辑
## 5. 添加所需的资源文件和脚本
##
## 生命周期：
## - _on_mod_load()：模块加载时调用（进入场景树前）
## - _on_mod_init()：模块初始化时调用（进入场景树，_ready）
## - _on_mod_enable()：模块启用时调用
## - _on_mod_disable()：模块禁用时调用
## - _on_mod_unload()：模块卸载时调用
## - _on_mod_event()：接收其他 mod 发送的事件
##
## ---------------------------------------------------------
extends ModInterface


## 生命周期：模块初始化
func _on_mod_init() -> void:
	super._on_mod_init()
	# 你可以在这里读取配置、初始化数据、注册事件等

## 生命周期：模块启用
func _on_mod_enable() -> void:
	super._on_mod_enable()
	# 入口场景已经实例化，可以开始逻辑

## 生命周期：模块禁用（未来支持）
func _on_mod_disable() -> void:
	super._on_mod_disable()
	# 清理 UI、暂停逻辑等

## 生命周期：模块卸载
func _on_mod_unload() -> void:
	super._on_mod_unload()
	# 清理资源、断开信号、保存数据等

## 生命周期：模块加载
func _on_mod_load() -> bool:
	var is_load_succeed = super._on_mod_load()
	# 子类实现
	return is_load_succeed

## 模块间通信
func _on_mod_event(_mod_name: String, event_name: String, event_data: Dictionary) -> void:
	super._on_mod_event(_mod_name, event_name, event_data)


# ---------------------------------------------------------
# 功能逻辑
# ---------------------------------------------------------

# 线程相关变量
var map_gen_thread: Thread = Thread.new() # 地图生成线程
var map_gen_thread_mutex: Mutex = Mutex.new() # 互斥锁（保证数据安全）
var total_location_map_datas: Dictionary = {} # 存储生成的地图高度数据
var cur_location_map_data: Dictionary # 存储生成的地图高度数据
var is_thread_running: bool = false # 标记线程是否运行

func _gen_all_location_map():
	var locations = GameCore.mod_manager.call_mod("LocationManager", "get_all_locations")
	for location in locations:
		var cfg = SimplyMudTownGen.gen_config({"seed":GameCore.Settings.GameSettings.WorldSeed})
		var data = SimplyMudTownGen.generate_town(cfg).to_dict()
		map_gen_thread_mutex.lock()
		cur_location_map_data = {"name":location,"map_data":data.duplicate()}
		total_location_map_datas[location] = cur_location_map_data
		map_gen_thread_mutex.unlock()
		after_one_location_generate_finished.call_deferred(cur_location_map_data.duplicate_deep())
		
	after_gen_all_location_map_finished.call_deferred()
	
	is_thread_running = false


func get_all_map_datas() -> Dictionary:
	return total_location_map_datas


func after_one_location_generate_finished(data):
	emit_mod_event("after_one_location_generate_finished", {
		"location_name":data.get("name", ""),
		"location_map_data":data,
	})


func after_gen_all_location_map_finished():
	if GameCore.debugging and not SaveManager.has_mod_slot_file(GameCore.Settings.GameSettings.GameSlot, "%s/total_location_map_datas.sav" % [mod_name]):
		SaveManager.save_mod_slot_data(GameCore.Settings.GameSettings.GameSlot, "%s/total_location_map_datas"%[mod_name], total_location_map_datas)
	emit_mod_event.call_deferred("after_gen_all_location_map_finished", {
		"location_map_count":total_location_map_datas.size(),
		"location_map_datas":total_location_map_datas
	})


# ---------------------------------------------------------
# 外部访问
# ---------------------------------------------------------
func gen_all_location_map():
	if is_thread_running: return
	if GameCore.debugging and SaveManager.has_mod_slot_file(GameCore.Settings.GameSettings.GameSlot, "%s/total_location_map_datas.sav" % [mod_name]):
		print("从缓存中加载 total_location_map_datas")
		total_location_map_datas = SaveManager.load_mod_slot_data(GameCore.Settings.GameSettings.GameSlot, "%s/total_location_map_datas" % [mod_name])
		for data in total_location_map_datas.values():
			cur_location_map_data = data
			after_one_location_generate_finished(cur_location_map_data)
		after_gen_all_location_map_finished.call_deferred()
		return
	is_thread_running = true
	map_gen_thread.start(_gen_all_location_map)
