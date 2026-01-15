## 框架基础类
## 供其他框架脚本继承
class_name FrameworkBase

# 版本信息
const VERSION = "v.0.0.1"

# 类名
var class_name: String = "FrameworkBase"

# 初始化标志
var is_initialized: bool = false

## 初始化框架基础类
func _init():
    class_name = get_class()
    print("%s initialized, version: %s" % [class_name, VERSION])

## 初始化方法，供子类重写
func initialize() -> bool:
    if is_initialized:
        return true
    
    print("Initializing %s..." % class_name)
    is_initialized = true
    return true

## 清理方法，供子类重写
func cleanup() -> void:
    if not is_initialized:
        return
    
    print("Cleaning up %s..." % class_name)
    is_initialized = false

## 暂停方法，供子类重写
func pause() -> void:
    print("Pausing %s..." % class_name)

## 恢复方法，供子类重写
func resume() -> void:
    print("Resuming %s..." % class_name)

## 获取类名
func get_class_name() -> String:
    return class_name

## 检查是否已初始化
func is_ready() -> bool:
    return is_initialized
