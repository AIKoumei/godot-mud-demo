extends Panel

# 菜单安排餐段单元格脚本

var day = ""
var meal_type = ""
var dish_name = ""

func set_data(day_name, type_name, dish):
	day = day_name
	meal_type = type_name
	dish_name = dish
	
	# 更新显示
	$MealTypeLabel.text = meal_type
	$DishLabel.text = dish_name

func _on_meal_slot_gui_input(event):
	# 处理鼠标点击事件
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_show_dish_selection()

func _show_dish_selection():
	# 显示菜式选择对话框
	var main = get_parent().get_parent().get_parent().get_parent().get_parent().get_parent()
	var dialog = main.get_node("MealSelectDialog")
	
	# 清空现有内容
	for child in dialog.get_children():
		if child is Control and child.name != "dialog_panel":
			child.queue_free()
	
	# 创建搜索框
	var search_hbox = HBoxContainer.new()
	dialog.add_child(search_hbox)
	
	var search_label = Label.new()
	search_label.text = "搜索菜式:"
	search_hbox.add_child(search_label)
	
	var search_input = LineEdit.new()
	search_input.name = "search_input"
	search_input.placeholder_text = "输入菜式名称..."
	search_hbox.add_child(search_input)
	
	# 创建推荐按钮
	var recommend_btn = Button.new()
	recommend_btn.text = "库存可用"
	search_hbox.add_child(recommend_btn)
	
	# 创建滚动区域
	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = SIZE_EXPAND_FILL
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	scroll.rect_min_size = Vector2(0, 300)
	dialog.add_child(scroll)
	
	# 创建菜式列表
	var dish_list = VBoxContainer.new()
	dish_list.name = "dish_list"
	scroll.add_child(dish_list)
	
	# 添加快速选择选项
	var quick_options = ["未安排", "外食", "剩菜"]
	for option in quick_options:
		var option_btn = Button.new()
		option_btn.text = option
		option_btn.connect("pressed", _on_dish_selected.bind(option, dialog))
		dish_list.add_child(option_btn)
	
	# 添加分隔线
	var separator = HSeparator.new()
	dish_list.add_child(separator)
	
	# 添加所有菜式
	var data_manager = main.get_node("DataManager")
	var recipes = data_manager.get_recipes()
	
	for recipe in recipes:
		var recipe_btn = Button.new()
		recipe_btn.text = recipe.name
		
		# 检查是否可用
		var available = false
		var inventory = data_manager.get_inventory()
		var inventory_names = []
		for item in inventory:
			inventory_names.append(item.name)
		
		var all_available = true
		for ingredient in recipe.ingredients:
			if not inventory_names.has(ingredient):
				all_available = false
				break
		
		if all_available:
			recipe_btn.text += " ✅"
			recipe_btn.add_theme_color_override("font_color", Color(0, 1, 0))
		
		recipe_btn.connect("pressed", _on_dish_selected.bind(recipe.name, dialog))
		dish_list.add_child(recipe_btn)
	
	# 连接信号
	search_input.text_changed.connect(_filter_dish_list.bind(search_input, dish_list, quick_options))
	recommend_btn.pressed.connect(_show_available_only.bind(dish_list, quick_options))
	
	# 显示对话框
	dialog.show()

func _on_dish_selected(dish, dialog):
	# 选择菜式后的处理
	dish_name = dish
	$DishLabel.text = dish_name
	
	# 更新数据
	var main = get_parent().get_parent().get_parent().get_parent().get_parent().get_parent()
	var data_manager = main.get_node("DataManager")
	var week_label = main.get_node("MainTabs/PlannerPanel/PlannerVBox/HeaderHBox/WeekLabel")
	var week_start = week_label.text.split("-")[0]
	
	data_manager.set_menu_item(week_start, day, meal_type, dish_name)
	
	# 隐藏对话框
	dialog.hide()

func _filter_dish_list(search_input, dish_list, quick_options):
	# 过滤菜式列表
	var search_text = search_input.text.to_lower()
	
	for i in range(dish_list.get_child_count()):
		var child = dish_list.get_child(i)
		if child is Button:
			var text = child.text.to_lower()
			var is_quick = false
			for option in quick_options:
				if option.to_lower() == text:
					is_quick = true
					break
			
			# 快速选项始终显示，其他根据搜索文本过滤
			if is_quick or text.find(search_text) >= 0:
				child.visible = true
			else:
				child.visible = false
		elif child is HSeparator:
			child.visible = true

func _show_available_only(dish_list, quick_options):
	# 只显示库存可用的菜式
	for i in range(dish_list.get_child_count()):
		var child = dish_list.get_child(i)
		if child is Button:
			var text = child.text
			var is_quick = false
			for option in quick_options:
				if option == text:
					is_quick = true
					break
			
			# 快速选项始终显示，其他只显示带有✅的
			if is_quick or text.find("✅") >= 0:
				child.visible = true
			else:
				child.visible = false
		elif child is HSeparator:
			child.visible = true
