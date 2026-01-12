# 测试脚本：验证Main UI和Window Manager的更新是否正确
# 该脚本用于在运行时检查节点引用和场景路径是否正确配置

extends Node

func _ready():
	print("=== 测试Main UI和Window Manager更新 ===")
	
	# 测试1：检查WindowManager是否正确初始化
	if Engine.has_singleton("WindowManager"):
		print("✓ WindowManager单例存在")
		var wm = Engine.get_singleton("WindowManager")
		
		# 测试窗口层级注册
		var layers = wm.get_window_layers()
		if layers.size() > 0:
			print("✓ WindowManager已注册窗口层级:")
			for layer_name in layers:
				print("  - " + layer_name)
		else:
			print("✗ WindowManager未注册任何窗口层级")
	else:
		print("✗ WindowManager单例不存在")
	
	# 测试2：检查ResourceManager中的场景路径
	if Engine.has_singleton("ResourceManager"):
		print("\n✓ ResourceManager单例存在")
		var rm = Engine.get_singleton("ResourceManager")
		
		# 检查主面板场景路径
		var main_panels = rm.get_scene_keys_by_category("main_panels")
		print("主面板场景列表:")
		for panel in main_panels:
			print("  - " + panel)
	else:
		print("\n✗ ResourceManager单例不存在")
	
	print("\n=== 测试完成 ===")
