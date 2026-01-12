# 资源管理器 - ResourceManager
# 厨房管理系统的资源管理中心，负责统一管理和提供场景资源
# 集中管理所有场景资源路径，实现资源的高效加载和实例化
# @description 提供统一的资源加载、缓存和管理机制，确保资源正确加载且不重复加载
# @design 采用单例模式，确保全局唯一实例，集中管理所有游戏资源
# @usage 通过自动加载的全局节点访问：get_node("/root/ResourceManager")
# @main_functions load_scene, instantiate_scene, get_scene_keys_by_category
# @state_query get_all_scene_keys, get_all_categories
# @version v.0.0.1
#
# @class ResourceManager
# @extends Node
# @description 提供统一的资源加载和实例化接口，简化资源管理和维护
#
# ## 设计理念
# - **集中管理**：所有场景资源路径集中定义，便于统一维护
# - **类型安全**：通过常量字典定义资源路径，减少拼写错误
# - **高效加载**：提供资源加载和实例化的便捷方法
# - **分类组织**：按功能类别组织资源，便于查找和管理
# - **统一接口**：为其他组件提供一致的资源访问接口
#
# ## 类用法说明
# 1. **获取资源管理器实例**：通常在项目根节点添加ResourceManager节点
# 2. **加载场景**：使用`load_scene(scene_name)`方法加载场景资源
# 3. **实例化场景**：使用`instantiate_scene(scene_name, parent)`方法实例化场景
# 4. **资源引用**：通过常量字典SCENES访问资源路径
#
# ## 主要功能和方法
# - **load_scene(scene_name)**：加载指定名称的场景资源
# - **instantiate_scene(scene_name, parent)**：实例化指定名称的场景
#
# ## 资源组织
# - **SCENES**：所有场景资源的路径字典
# - **SCENE_CATEGORIES**：按功能类别组织的场景资源
# - **ALL_SCENE_KEYS**：所有场景资源键的数组
#
# ## 使用示例
# ```gdscript
# # 获取资源管理器实例
# var resource_manager = get_node("/root/ResourceManager")
# 
# # 加载场景资源
# var main_scene = resource_manager.load_scene("main")
# 
# # 实例化场景
# var task_panel = resource_manager.instantiate_scene("task_panel", $PanelsContainer)
# ```

extends Node

# 场景资源路径字典
# 键：资源名称，值：资源路径（使用res://开头的绝对路径）
const SCENES := {
	# 基础组件场景
	"ingredient_item": "res://scenes/IngredientItem.tscn",
	"meal_slot": "res://scenes/MealSlot.tscn",
	"recipe_item": "res://scenes/RecipeItem.tscn",
	"date_pick_button": "res://scenes/base_components/date_picker/DatePickButton.tscn",
	"date_picker": "res://scenes/base_components/date_picker/DatePicker.tscn",
	"month_picker": "res://scenes/base_components/date_picker/MonthPicker.tscn",
	"year_picker": "res://scenes/base_components/date_picker/YearPicker.tscn",
	# 面板组件场景
	"base_panel": "res://scenes/panels/base_panel.tscn",
	"confirm_panel": "res://scenes/panels/confirm_panel.tscn",
	"window_top_bar_panel": "res://scenes/panels/window_top_bar_panel.tscn",
	
	# 窗口组件场景
	"base_window": "res://scenes/windows/BaseWindow.tscn",
	"date_picker_window": "res://scenes/windows/DatePickerWindow.tscn",
	"date_picker_simple_window": "res://scenes/windows/DatePickerSimpleWindow.tscn",
	"month_picker_window": "res://scenes/windows/MonthPickerWindow.tscn",
	"year_picker_window": "res://scenes/windows/YearPickerWindow.tscn",
	
	# 主界面场景
	"main": "res://scenes/main/main.tscn",
	
	# 主界面模块面板场景
	"home_panel": "res://scenes/main/home/home_panel.tscn",
	"inventory_panel": "res://scenes/main/inventory/inventory_panel.tscn",
	"meal_panel": "res://scenes/main/meal/meal_panel.tscn",
	"profile_panel": "res://scenes/main/profile/profile_panel.tscn",
	"recipe_panel": "res://scenes/main/recipe/recipe_panel.tscn",
	
	# 任务管理相关场景
	"task_edit_item": "res://scenes/main/task/task_edit_item.tscn",
	"task_edit_panel": "res://scenes/main/task/task_edit_panel.tscn",
	"task_item": "res://scenes/main/task/task_item.tscn",
	"task_panel": "res://scenes/main/task/task_panel.tscn",
	
	# 测试场景
	"test_main": "res://scenes/test/test_main.tscn",
	"test_window_open_button": "res://scenes/test/test_WindowOpenButton.tscn"
}

# 场景分类字典
# @description 定义场景的分类，用于资源管理和组织，方便按功能类型查找和管理相关场景
# 键：类别名称，值：该类别下的场景资源键字典（键和值相同，便于查找和遍历）
# @example SCENE_CATEGORIES["base_components"] 包含所有基础组件场景
const SCENE_CATEGORIES := {
	"base_components": {
		"ingredient_item": "ingredient_item",
		"meal_slot": "meal_slot",
		"recipe_item": "recipe_item",
		"date_pick_button": "date_pick_button",
		"date_picker": "date_picker",
		"month_picker": "month_picker",
		"year_picker": "year_picker"
	},
	"panel_components": {
		"base_panel": "base_panel",
		"confirm_panel": "confirm_panel",
		"window_top_bar_panel": "window_top_bar_panel"
	},
	"window_components": {
		"base_window": "base_window",
		"date_picker_window": "date_picker_window",
		"date_picker_simple_window": "date_picker_simple_window",
		"month_picker_window": "month_picker_window",
		"year_picker_window": "year_picker_window"
	},
	"main_interface": {
		"main": "main"
	},
	"main_panels": {
		"home_panel": "home_panel",
		"inventory_panel": "inventory_panel",
		"meal_panel": "meal_panel",
		"profile_panel": "profile_panel",
		"recipe_panel": "recipe_panel"
	},
	"task_management": {
		"task_edit_item": "task_edit_item",
		"task_edit_panel": "task_edit_panel",
		"task_item": "task_item",
		"task_panel": "task_panel"
	},
	"test_scenes": {
		"test_main": "test_main",
		"test_window_open_button": "test_window_open_button"
	}
}

# 所有场景资源键的数组
# 包含SCENES字典中所有的键
var ALL_SCENE_KEYS := SCENES.keys()


# 加载场景资源
# @param scene_name: 场景名称（对应SCENES字典中的键）
# @return PackedScene: 加载的场景资源，失败返回null
# @description 根据场景名称加载场景资源
# @details 提供便捷的场景加载接口，简化资源路径管理
# @public
func load_scene(scene_name: String) -> PackedScene:
	if SCENES.has(scene_name):
		return load(SCENES[scene_name]) as PackedScene
	else:
		push_error("ResourceManager: Scene '" + scene_name + "' not found in SCENES dictionary")
		return null

# 实例化场景
# @param scene_name: 场景名称（对应SCENES字典中的键）
# @param parent: 父节点（可选）
# @return Node: 实例化的节点，失败返回null
# @description 根据场景名称加载并实例化场景
# @details 提供一站式的场景实例化服务，可选择指定父节点
# @public
func instantiate_scene(scene_name: String, parent: Node = null) -> Node:
	var scene: PackedScene = load_scene(scene_name)
	if scene:
		var instance: Node = scene.instantiate()
		if parent:
			parent.add_child(instance)
		return instance
	return null

# 获取指定类别的所有场景键
# @param category_name: 类别名称（对应SCENE_CATEGORIES字典中的键）
# @return Array: 该类别下的场景资源键数组，类别不存在时返回空数组
# @description 根据分类获取相关场景键列表
# @details 方便按功能分类管理和访问场景资源
# @public
func get_scene_keys_by_category(category_name: String) -> Array:
	if SCENE_CATEGORIES.has(category_name):
		return SCENE_CATEGORIES[category_name].keys().duplicate()
	else:
		push_warning("ResourceManager: Category '" + category_name + "' not found in SCENE_CATEGORIES")
		return []

# 获取所有场景键
# @return Array: 所有场景资源键的数组
# @description 获取系统中定义的所有场景资源键
# @details 返回完整的场景资源列表，用于全局资源扫描或统计
# @public
func get_all_scene_keys() -> Array:
	return ALL_SCENE_KEYS.duplicate()

# 获取所有类别名称
# @return Array: 所有类别名称的数组
# @description 获取系统中定义的所有场景分类
# @details 返回场景资源的所有分类，用于资源组织和管理
# @public
func get_all_categories() -> Array:
	return SCENE_CATEGORIES.keys().duplicate()
