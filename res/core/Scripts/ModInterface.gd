## mod接口定义脚本
## 规范mod开发标准
extends Node
class_name ModInterface

# 版本信息
const VERSION = "v.0.0.1"

## 模块名称（由 ModManager 注入）
var mod_name: String = ""

## 模块配置（ModuleConfig.json）
var mod_config: Dictionary = {}

## 模块数据（ModuleData.json）
var mod_data: Dictionary = {}



## 模块初始化（脚本挂载到场景节点时）
func _ready() -> void:
	_on_mod_init()

func enable_mod() -> void:
	_on_mod_enable()

func disable_mod() -> void:
	_on_mod_disable()

func load_mod() -> void:
	_on_mod_load()

func unload_mod() -> void:
	_on_mod_unload()

func on_mod_event(_mod_name: String, event_name: String, event_data: Dictionary) -> void:
	_on_mod_event(_mod_name, event_name, event_data)


## 生命周期：模块脚本被挂载到场景节点时调用
func _on_mod_init() -> void:
	print("[ModEntry:%s] 初始化模块" % mod_name)
	# 子类实现
	pass

## 生命周期：模块启用（入口场景实例化后）
func _on_mod_enable() -> void:
	print("[ModEntry:%s] 模块已启用" % mod_name)
	# 子类实现
	pass

## 生命周期：模块禁用（未来支持）
func _on_mod_disable() -> void:
	print("[ModEntry:%s] 模块已禁用" % mod_name)
	# 子类实现
	pass

## 生命周期：模块加载
func _on_mod_load() -> void:
	print("[ModEntry:%s] 模块已加载" % mod_name)
	# 子类实现
	pass

## 生命周期：模块卸载（场景被移除前）
func _on_mod_unload() -> void:
	print("[ModEntry:%s] 模块卸载中" % mod_name)
	# 子类实现
	pass

## 处理游戏事件，供mod重写
func _on_mod_event(_mod_name: String, event_name: String, event_data: Dictionary) -> void:
	print("[Mod:%s] 收到消息: [%s:%s]" % [mod_name, _mod_name, event_name])
	# 子类实现
	pass
