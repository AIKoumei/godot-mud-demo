## mod接口定义脚本
## 规范mod开发标准
extends Node
class_name ModInterface

## 模块名称（由 ModManager 注入）
var mod_name: String = ""

## 模块配置（ModuleConfig.json）
var mod_config: Dictionary = {}

## 模块数据（ModuleData.json）
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
	print("[%s] 初始化模块" % mod_name)
	# 子类实现
	pass


## 生命周期：模块启用（入口场景实例化后）
func _on_mod_enable() -> void:
	print("[%s] 模块已启用" % mod_name)
	# 子类实现
	pass


## 生命周期：模块禁用（未来支持）
func _on_mod_disable() -> void:
	print("[%s] 模块已禁用" % mod_name)
	# 子类实现
	pass


## 生命周期：模块加载
func _on_mod_load() -> bool:
	print("[%s] 模块已加载" % mod_name)
	# 子类实现
	return true


## 生命周期：模块卸载（场景被移除前）
func _on_mod_unload() -> void:
	print("[%s] 模块卸载中" % mod_name)
	# 子类实现
	pass


## ---------------------------------------------------------
## 处理游戏事件，供 mod 重写
## ---------------------------------------------------------
func _on_mod_event(_mod_name: String, event_name: String, event_data: Dictionary) -> void:
	print("[Mod:%s] 收到消息: [%s:%s]" % [mod_name, _mod_name, event_name])
	# 子类实现
	pass


## ---------------------------------------------------------
## 事件系统（新增）
## ---------------------------------------------------------

## 发送事件（直接使用自己的 mod_name）
func emit_mod_event(event_name: String, event_data: Dictionary = {}) -> void:
	GameCore.mod_manager.emit_mod_event(mod_name, event_name, event_data)


## 注册事件监听器（传入 ModEventListenerFilter）
func register_event_listener(filter: ModEventListenerFilter) -> void:
	GameCore.mod_manager.register_mod_event_listener(mod_name, filter)


## 注销事件监听器
func unregister_event_listener(filter: ModEventListenerFilter) -> void:
	GameCore.mod_manager.unregister_mod_event_listener(mod_name, filter)


## ---------------------------------------------------------
## 工具函数
## ---------------------------------------------------------
func get_mod_path() -> String:
	return GameCore.mod_manager.loaded_mods[mod_name].path
