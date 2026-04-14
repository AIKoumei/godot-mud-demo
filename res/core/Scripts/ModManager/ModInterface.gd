## mod接口定义脚本
## 规范mod开发标准
extends Node
class_name ModInterface

## 模块名称（由 ModManager 注入）
var mod_name: String = ""

## 模块配置（ModuleConfig.json）
var mod_config: Dictionary = {}

## 模块数据（ModuleConfig.json）
var mod_data: Dictionary = {}


## ---------------------------------------------------------
## 模块初始化（脚本挂载到场景节点时）
## ---------------------------------------------------------
func _ready() -> void:
	_on_mod_init()


func enable_mod() -> void:
	_on_mod_enable()


func disable_mod() -> void:
	_on_mod_disable()


func load_mod() -> bool:
	return _on_mod_load()


func unload_mod() -> void:
	_on_mod_unload()


func on_mod_event(_mod_name: String, event_name: String, event_data: Dictionary) -> void:
	_on_mod_event(_mod_name, event_name, event_data)


## ---------------------------------------------------------
## 生命周期：模块脚本被挂载到场景节点时调用
## ---------------------------------------------------------
func _on_mod_init() -> void:
	prints("[%s] 初始化模块" % mod_name)
	# 子类实现
	pass


## 生命周期：模块启用（入口场景实例化后）
func _on_mod_enable() -> void:
	prints("[%s] 模块已启用" % mod_name)
	# 子类实现
	pass


## 生命周期：模块禁用（未来支持）
func _on_mod_disable() -> void:
	prints("[%s] 模块已禁用" % mod_name)
	# 子类实现
	pass


## 生命周期：模块加载
func _on_mod_load() -> bool:
	prints("[%s] 模块已加载" % mod_name)
	# 子类实现
	return true


## 生命周期：模块卸载（场景被移除前）
func _on_mod_unload() -> void:
	prints("[%s] 模块卸载中" % mod_name)
	# 子类实现
	pass


## ---------------------------------------------------------
## 处理游戏事件，供 mod 重写
## ---------------------------------------------------------
func _on_mod_event(_mod_name: String, event_name: String, event_data: Dictionary) -> void:
	prints("[Mod:%s] 收到消息: [%s:%s]" % [mod_name, _mod_name, event_name])
	# 子类实现
	pass


## ---------------------------------------------------------
## 事件系统（新增）
## ---------------------------------------------------------

## 发送事件（直接使用自己的 mod_name）
func emit_mod_event(event_name: String, event_data: Dictionary = {}) -> void:
	GameCore.mod_manager.emit_mod_event(mod_name, event_name, event_data)



## 注册事件监听器（传入 ModEventListenerFilter）
#listener = register_event_listener(ModEventListenerFilter.new()
#	.set_listen_type(ModEventListenerFilter.ListenType.ALWAYS)
#	.set_mod_filter_type(ModEventListenerFilter.ModFilterType.TARGET)
#	.set_mod_name("SceneManager")
#	.set_event_filter_type(ModEventListenerFilter.EventFilterType.TARGET)
#	.set_event_name("after_change_scene")
#)
#unregister_event_listener(listener)
func register_event_listener(filter: ModEventListenerFilter) -> ModEventListenerFilter:
	GameCore.mod_manager.register_mod_event_listener(mod_name, filter)
	return filter


## 注销事件监听器
func unregister_event_listener(filter: ModEventListenerFilter) -> void:
	GameCore.mod_manager.unregister_mod_event_listener(mod_name, filter)

func after_unregister_event_listener(filter: ModEventListenerFilter) -> void:
	if _listener_to_name.has(filter):
		_listeners.erase(_listener_to_name[filter])
		_listener_to_name.erase(filter)


var _listeners = {}
var _listener_to_name = {}


func get_listener_by_name(filter_name = "") -> ModEventListenerFilter:
	return _listeners.get(filter_name, null)

func register_event_listener_with_name(filter: ModEventListenerFilter, filter_name = "") -> ModEventListenerFilter:
	if _listeners.has(filter_name):
		unregister_event_listener_with_name(filter_name)
	GameCore.mod_manager.register_mod_event_listener(mod_name, filter)
	_listeners[filter_name] = filter
	_listener_to_name[filter] = filter_name
	return filter


## 注销事件监听器
func unregister_event_listener_with_name(filter_name = "") -> void:
	if not _listeners.has(filter_name):
		return
	GameCore.mod_manager.unregister_mod_event_listener(mod_name, _listeners[filter_name])
	_listeners.erase(filter_name)
	_listener_to_name.erase(filter_name)



## ---------------------------------------------------------
## 工具函数
## ---------------------------------------------------------
func get_mod_path() -> String:
	return GameCore.mod_manager.loaded_mods[mod_name].path
