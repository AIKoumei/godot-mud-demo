# 主界面UI管理脚本 - MainUI
# 厨房管理系统的主界面控制器，负责管理底部导航和功能模块切换
# 适配底部导航结构，实现模块化界面管理
#
# @class MainUI
# @extends Node
# @description 管理主界面的导航系统和功能模块面板，实现模块间的切换和状态管理
#
# ## 设计理念
# - **模块化设计**：将主界面划分为多个功能模块，便于独立开发和维护
# - **统一导航**：通过底部导航栏实现模块间的统一切换
# - **状态管理**：维护当前激活模块的状态，确保界面一致性
# - **灵活扩展**：支持动态加载和创建功能模块面板
# - **结构适配**：适配CanvasLayer结构，确保界面层级正确
#
# ## 类用法说明
# 1. **初始化**：在主场景中添加MainUI节点
# 2. **模块管理**：通过`switch_module(module_name)`方法切换功能模块
# 3. **导航事件**：通过导航按钮的信号响应模块切换
# 4. **自定义扩展**：可以通过重写相关方法扩展模块管理功能
#
# ## 主要功能和方法
# - **switch_module(module_name)**：切换到指定的功能模块
# - **_init_node_references()**：初始化UI节点引用
# - **_init_panels()**：初始化功能模块面板
# - **_connect_navigation_buttons()**：连接导航按钮信号
# - **_create_module_panel(panel_name, panel_type)**：创建模块面板
#
# ## 模块列表
# - **meal**：点餐模块
# - **task**：任务管理模块
# - **recipe**：食谱管理模块
# - **inventory**：库存管理模块
# - **profile**：个人资料模块
#
# ## 使用示例
# ```gdscript
# # 获取MainUI实例
# var main_ui = get_node("/root/MainUI")
# 
# # 切换到任务管理模块
# main_ui.switch_module("task")
# 
# # 获取当前模块名称
# var current_module = main_ui.current_module
# print("当前模块: ", current_module)
# ```
class_name MainUI extends Node

@export var debugger = true

# 主要UI节点引用
var control_container: Control
var main_content_panel: Control
var bottom_nav_panel: Control
var hbox_container: HBoxContainer

# 导航按钮引用
var meal_btn_check: CheckButton
var task_btn_check: CheckButton
var recipe_btn_check: CheckButton
var inventory_btn_check: CheckButton
var profile_btn_check: CheckButton

# 模块面板引用
var current_panel: Control
var meal_panel: Control
var task_panel: Control
var recipe_panel: Control
var inventory_panel: Control
var profile_panel: Control

# 当前激活的模块名称
var current_module: String = "home"

func _ready() -> void:
	"""初始化UI"""
	# 初始化节点引用
	_init_node_references()
	
	# 初始化面板
	_init_panels()
	
	# 连接导航按钮信号
	_connect_navigation_buttons()
	
	# 默认显示点餐面板
	switch_module("meal")

func _init_node_references() -> void:
	"""初始化所有节点引用变量 - 适配CanvasLayer结构"""
	# 主要容器引用 - 适配新的CanvasLayer -> Control -> MiddleWindowLayer -> MainPanel结构
	if has_node("CanvasLayer/Control/MiddleWindowLayer/MainPanel"):
		# 获取MainPanel节点，它包含了MainContent和BottomNav
		var main_panel = $CanvasLayer/Control/MiddleWindowLayer/MainPanel
		
		# 获取子节点引用
		main_content_panel = main_panel.get_node("MainContent")
		bottom_nav_panel = main_panel.get_node("BottomNav")
		hbox_container = bottom_nav_panel.get_node("HBoxContainer")
		
		# 导航按钮引用
		meal_btn_check = hbox_container.get_node("MealBtn/CheckButton")
		task_btn_check = hbox_container.get_node("TaskBtn/CheckButton")
		recipe_btn_check = hbox_container.get_node("RecipeBtn/CheckButton")
		inventory_btn_check = hbox_container.get_node("InventoryBtn/CheckButton")
		profile_btn_check = hbox_container.get_node("ProfileBtn/CheckButton")
	else:
		print("警告: 无法找到MainPanel容器节点")
		return

# 移除重复的_init_panels函数，保留后面的新版本

func _create_module_panel(panel_name: String, panel_type: PackedScene = null) -> Control:
	"""创建模块面板容器或实例化面板场景"""
	# 尝试实例化面板场景
	var panel
	if panel_type:
		panel = panel_type.instantiate()
	else:
		# 如果场景不存在，创建默认Control节点
		panel = Control.new()
		panel.name = panel_name
		panel.layout_mode = 1
		panel.anchors_preset = 15
		panel.anchor_right = 1.0
		panel.anchor_bottom = 1.0
		panel.grow_horizontal = 2
		panel.grow_vertical = 2
	
	panel.visible = false
	return panel

func _init_panels() -> void:
	"""初始化各个功能模块面板 - 只负责创建容器和基础管理"""
	# 尝试加载各面板场景 (如果存在)
	var meal_panel_scene = null
	var task_panel_scene = null
	var recipe_panel_scene = null
	var inventory_panel_scene = null
	var profile_panel_scene = null
	
	# 尝试加载场景资源 - 根据实际场景结构更新路径
	var scene_paths = {
		"meal": "res://scenes/main/meal/meal_panel.tscn",
		"task": "res://scenes/main/task/task_panel.tscn",
		"recipe": "res://scenes/main/recipe/recipe_panel.tscn",
		"inventory": "res://scenes/main/inventory/inventory_panel.tscn",
		"profile": "res://scenes/main/profile/profile_panel.tscn"
	}
	
	# 检查并加载存在的场景
	if ResourceLoader.exists(scene_paths["meal"]):
		meal_panel_scene = load(scene_paths["meal"])
	if ResourceLoader.exists(scene_paths["task"]):
		task_panel_scene = load(scene_paths["task"])
	if ResourceLoader.exists(scene_paths["recipe"]):
		recipe_panel_scene = load(scene_paths["recipe"])
	if ResourceLoader.exists(scene_paths["inventory"]):
		inventory_panel_scene = load(scene_paths["inventory"])
	if ResourceLoader.exists(scene_paths["profile"]):
		profile_panel_scene = load(scene_paths["profile"])
	
	# 创建各面板
	meal_panel = _create_module_panel("MealPanel", meal_panel_scene)
	task_panel = _create_module_panel("TaskPanel", task_panel_scene)
	recipe_panel = _create_module_panel("RecipePanel", recipe_panel_scene)
	inventory_panel = _create_module_panel("InventoryPanel", inventory_panel_scene)
	profile_panel = _create_module_panel("ProfilePanel", profile_panel_scene)
	
	# 添加所有面板到主内容区
	main_content_panel.add_child(meal_panel)
	main_content_panel.add_child(task_panel)
	main_content_panel.add_child(recipe_panel)
	main_content_panel.add_child(inventory_panel)
	main_content_panel.add_child(profile_panel)

func _connect_navigation_buttons() -> void:
	"""连接底部导航按钮信号"""
	# 点餐按钮
	meal_btn_check.connect("toggled", _on_nav_button_toggled.bind("meal"))
	# 日常任务按钮
	task_btn_check.connect("toggled", _on_nav_button_toggled.bind("task"))
	# 菜谱按钮
	recipe_btn_check.connect("toggled", _on_nav_button_toggled.bind("recipe"))
	# 库存按钮
	inventory_btn_check.connect("toggled", _on_nav_button_toggled.bind("inventory"))
	# 我的按钮
	profile_btn_check.connect("toggled", _on_nav_button_toggled.bind("profile"))

func _on_nav_button_toggled(pressed: bool, module_name: String) -> void:
	"""处理导航按钮点击事件"""
	if pressed:
		switch_module(module_name)

func switch_module(module_name: String) -> void:
	"""切换功能模块 - 只负责面板显隐管理"""
	# 隐藏当前面板
	if current_panel:
		current_panel.visible = false
		
	# 根据模块名称获取对应的面板
	match module_name:
		"meal":
			current_panel = meal_panel
		"task":
			current_panel = task_panel
		"recipe":
			current_panel = recipe_panel
		"inventory":
			current_panel = inventory_panel
		"profile":
			current_panel = profile_panel
	
	# 更新当前模块名称
	current_module = module_name
	# 显示新面板
	current_panel.visible = true
	# 更新面板内容
	_update_panel_content(module_name)

func _update_panel_content(module_name: String) -> void:
	"""根据模块名更新面板内容"""
	# TODO: 由各子面板自行管理内容更新
	# TODO: 可以通过信号或直接调用来通知子面板刷新
	pass

# 当需要全局刷新时调用此方法
func refresh_all_panels() -> void:
	"""刷新所有面板数据"""
	# TODO: 这里可以实现通过信号或直接调用子面板的刷新方法
	pass
