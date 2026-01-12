# 测试脚本：验证window_manager与CachePoolManager的集成
# 运行方式：在Godot编辑器中附加到节点并运行

# 导入必要的类
@onready var window_manager = get_node("/root/WindowManager")
@onready var cache_pool_manager = get_node("/root/CachePoolManager")

func _ready():
	print("=== 测试window_manager与CachePoolManager集成 ===")
	
	# 测试1：基本缓存功能
	print("\n1. 测试基本缓存功能：")
	var test_scene = "res://scenes/windows/test_window.tscn"
	
	# 检查初始状态
	var initial_cache_size = window_manager.get_cache_size(test_scene)
	print("初始缓存大小: ", initial_cache_size)
	
	# 打开一个窗口（应该会创建并缓存）
	var window = window_manager.open_window(test_scene)
	if window:
		print("成功打开窗口")
		
		# 关闭窗口（应该会被缓存）
		window_manager.close_window(window)
		print("成功关闭窗口")
		
		# 检查缓存大小
		var cache_size_after_close = window_manager.get_cache_size(test_scene)
		print("关闭后缓存大小: ", cache_size_after_close)
		
		# 检查缓存是否存在
		var is_cached = window_manager.is_window_cached(test_scene)
		print("窗口是否在缓存中: ", is_cached)
	
	# 测试2：获取缓存信息
	print("\n2. 测试获取缓存信息：")
	var cache_info = window_manager.get_cache_info()
	print("缓存总数量: ", cache_info["total_count"])
	print("各场景缓存数量: ", cache_info["scenes"])
	
	# 测试3：清理缓存
	print("\n3. 测试清理缓存：")
	window_manager.clear_cache(test_scene)
	var cache_size_after_clear = window_manager.get_cache_size(test_scene)
	print("清理后缓存大小: ", cache_size_after_clear)
	
	# 测试4：验证与CachePoolManager的直接集成
	print("\n4. 验证与CachePoolManager的直接集成：")
	var cache_pool_stats = cache_pool_manager.get_cache_stats()
	print("CachePoolManager统计信息: ", cache_pool_stats)
	
	print("\n=== 测试完成 ===")