## ModEntry.gd
## 模块入口脚本（每个 mod 必须有）
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
func _on_mod_load() -> void:
	super._on_mod_load()
	# 子类实现

## 模块间通信
func _on_mod_event(_mod_name: String, event_name: String, event_data: Dictionary) -> void:
	print("[Mod:%s] 收到消息: [%s:%s]" % [mod_name, _mod_name, event_name])
