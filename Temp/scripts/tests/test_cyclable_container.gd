# =============================================================================
# CyclableContainer 测试脚本
# 用于测试CyclableContainer对非PackedScene类型item_scene的支持
# =============================================================================

# 导入CyclableContainer类
class_name CyclableContainerTest
extends Node

func run_tests() -> void:
	"""
	运行所有测试
	"""
	print("开始测试CyclableContainer对非PackedScene类型的支持...")
	
	# 创建测试场景
	var test_scene = Node2D.new()
	
	# 创建CyclableContainer实例
	var container = CyclableContainer.new()
	test_scene.add_child(container)
	
	# 测试1: 使用Node类型作为item_scene
	test_node_as_item_scene(container)
	
	# 测试2: 测试类型检查功能
	test_type_checking(container)
	
	# 测试3: 测试信号功能
	test_signals(container)
	
	print("所有测试完成！")

func test_node_as_item_scene(container: CyclableContainer) -> void:
	"""
	测试使用Node类型作为item_scene
	"""
	print("测试1: 使用Node类型作为item_scene")
	
	# 创建一个Button作为item_scene
	var button = Button.new()
	button.text = "测试按钮"
	
	# 设置item_scene
	container.set_item_scene(button)
	
	# 创建测试数据
	var test_data = ["项目1", "项目2", "项目3"]
	
	# 设置数据列表
	container.set_data_list(test_data)
	
	# 验证结果
	print("  - item_scene类型: ", typeof(container.item_scene))
	print("  - 创建的项目数量: ", container._items.size())
	print("  - 测试通过: ", container._items.size() == test_data.size())

func test_type_checking(container: CyclableContainer) -> void:
	"""
	测试类型检查功能
	"""
	print("测试2: 测试类型检查功能")
	
	# 测试无效类型
	container.set_item_scene("这不是一个有效的类型")
	print("  - 无效类型测试完成")
	
	# 重置为有效类型
	var button = Button.new()
	button.text = "有效按钮"
	container.set_item_scene(button)
	print("  - 有效类型重置完成")

func test_signals(container: CyclableContainer) -> void:
	"""
	测试信号功能
	"""
	print("测试3: 测试信号功能")
	
	# 连接场景变更信号
	var signal_received = false
	container.connect("item_scene_changed", func():
		signal_received = true
		print("  - 信号item_scene_changed已收到")
	)
	
	# 触发场景变更
	var new_button = Button.new()
	new_button.text = "新按钮"
	container.set_item_scene(new_button)
	
	# 验证信号是否收到
	print("  - 信号测试通过: ", signal_received)

# 如果直接运行此脚本
func _ready() -> void:
	run_tests()
