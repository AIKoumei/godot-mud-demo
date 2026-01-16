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


# ---------------------------------------------------------
# 外部访问
# ---------------------------------------------------------
