# 窗口层级功能测试脚本
# 用于验证WindowManager的窗口层级功能是否正常工作
# 
# 测试内容：
# 1. 测试默认窗口层级是否为normal（对应MiddleWindowLayer）
# 2. 测试通过properties指定不同窗口层级
# 3. 测试get_windows_in_layer方法是否能正确获取对应层级的窗口
# 4. 测试窗口层级的设置和获取是否正常
#
# 使用方法：
# 1. 在Godot编辑器中创建一个测试场景
# 2. 将此脚本附加到场景中的一个节点
# 3. 运行场景查看测试结果

extends Node

# 测试方法
func _ready():
	# 等待所有节点就绪
	await get_tree().process_frame
	await get_tree().process_frame
	
	# 开始测试
	print("=== 窗口层级功能测试开始 ===")
	
	# 测试1：验证WindowManager单例是否存在
	if not Engine.get_singleton("WindowManager"):
		print("❌ 测试失败：WindowManager单例不存在")
		return
	
	print("✅ 测试通过：WindowManager单例存在")
	
	# 测试2：验证默认窗口层级
	var default_window = WindowManager.open_window("test_window", "test_default", {})
	if default_window:
		var layer = default_window.get_window_layer()
		print("窗口默认层级：", layer)
		if layer == "normal":
			print("✅ 测试通过：默认窗口层级为normal")
		else:
			print("❌ 测试失败：默认窗口层级不是normal，实际为", layer)
		
		# 关闭测试窗口
		default_window.close()
	else:
		print("❌ 测试失败：无法打开默认层级测试窗口")
	
	# 测试3：验证通过properties指定窗口层级
	var custom_window = WindowManager.open_window("test_window", "test_custom", {"window_layer": "popup"})
	if custom_window:
		var layer = custom_window.get_window_layer()
		print("自定义窗口层级：", layer)
		if layer == "popup":
			print("✅ 测试通过：成功设置自定义窗口层级为popup")
		else:
			print("❌ 测试失败：自定义窗口层级设置错误，实际为", layer)
		
		# 关闭测试窗口
		custom_window.close()
	else:
		print("❌ 测试失败：无法打开自定义层级测试窗口")
	
	# 测试4：验证get_windows_in_layer方法
	# 打开多个不同层级的窗口
	var window1 = WindowManager.open_window("test_window", "test_layer1", {"window_layer": "normal"})
	var window2 = WindowManager.open_window("test_window", "test_layer2", {"window_layer": "popup"})
	var window3 = WindowManager.open_window("test_window", "test_layer3", {"window_layer": "normal"})
	
	# 获取normal层级的窗口
	var normal_windows = WindowManager.get_windows_in_layer("normal")
	print("normal层级窗口数量：", normal_windows.size())
	if normal_windows.size() == 2:
		print("✅ 测试通过：get_windows_in_layer方法能正确获取normal层级的窗口")
	else:
		print("❌ 测试失败：get_windows_in_layer方法获取的窗口数量不正确，实际为", normal_windows.size())
	
	# 获取popup层级的窗口
	var popup_windows = WindowManager.get_windows_in_layer("popup")
	print("popup层级窗口数量：", popup_windows.size())
	if popup_windows.size() == 1:
		print("✅ 测试通过：get_windows_in_layer方法能正确获取popup层级的窗口")
	else:
		print("❌ 测试失败：get_windows_in_layer方法获取的窗口数量不正确，实际为", popup_windows.size())
	
	# 关闭所有测试窗口
	if window1: window1.close()
	if window2: window2.close()
	if window3: window3.close()
	
	print("=== 窗口层级功能测试结束 ===")

# 辅助方法：检查窗口是否在正确的层级容器中
func check_window_container(window: Node, expected_layer: String) -> bool:
	if not window or not window.get_parent():
		return false
	
	var parent = window.get_parent()
	var expected_container_name = ""
	
	match expected_layer:
		"normal":
			expected_container_name = "MiddleWindowLayer"
		"popup":
			expected_container_name = "PopupWindowLayer"
		"background":
			expected_container_name = "BackgroundWindowLayer"
		_:
			expected_container_name = "MiddleWindowLayer"  # 默认
	
	return parent.name == expected_container_name
