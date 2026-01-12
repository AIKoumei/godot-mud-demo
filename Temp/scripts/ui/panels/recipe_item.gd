extends VBoxContainer

# 料理库列表项脚本

var recipe_data = {}

func set_data(data):
    recipe_data = data
    
    # 更新显示
    $TopHBox/NameLabel.text = data.name
    $TopHBox/CuisineLabel.text = data.category
    
    # 设置难度星数
    var difficulty_str = ""
    for i in range(data.difficulty):
        difficulty_str += "★"
    for i in range(5 - data.difficulty):
        difficulty_str += "☆"
    $TopHBox/DifficultyLabel.text = difficulty_str
    
    $TopHBox/TimeLabel.text = str(data.cooking_time) + "分钟"
    
    # 检查是否可用（库存中有足够的食材）
    _check_availability()

func _check_availability():
    # 检查库存中是否有足够的食材
    var main = get_parent().get_parent().get_parent().get_parent().get_parent().get_parent()
    var data_manager = main.get_node("DataManager")
    var inventory = data_manager.get_inventory()
    
    var inventory_names = []
    for item in inventory:
        inventory_names.append(item.name)
    
    var all_available = true
    for ingredient in recipe_data.ingredients:
        if not inventory_names.has(ingredient):
            all_available = false
            break
    
    $TopHBox/AvailLabel.visible = all_available

func _on_view_pressed():
    # 查看详情按钮点击处理
    var detail_dialog = Dialog.new()
    detail_dialog.title = recipe_data.name + " - 详情"
    
    var scroll = ScrollContainer.new()
    scroll.size_flags_horizontal = SIZE_EXPAND_FILL
    scroll.size_flags_vertical = SIZE_EXPAND_FILL
    detail_dialog.add_child(scroll)
    
    var vbox = VBoxContainer.new()
    scroll.add_child(vbox)
    
    # 基本信息
    var info_vbox = VBoxContainer.new()
    vbox.add_child(info_vbox)
    
    var category_label = Label.new()
    category_label.text = "分类: " + recipe_data.category
    info_vbox.add_child(category_label)
    
    var difficulty_label = Label.new()
    var difficulty_str = "难度: "
    for i in range(recipe_data.difficulty):
        difficulty_str += "★"
    difficulty_label.text = difficulty_str
    info_vbox.add_child(difficulty_label)
    
    var time_label = Label.new()
    time_label.text = "烹饪时间: " + str(recipe_data.cooking_time) + "分钟"
    info_vbox.add_child(time_label)
    
    # 食材列表
    var ingredients_label = Label.new()
    ingredients_label.text = "食材:"
    ingredients_label.add_theme_font_size_override("font_size", 16)
    vbox.add_child(ingredients_label)
    
    var ingredients_list = VBoxContainer.new()
    vbox.add_child(ingredients_list)
    
    for ingredient in recipe_data.ingredients:
        var ingredient_label = Label.new()
        ingredient_label.text = "- " + ingredient
        ingredients_list.add_child(ingredient_label)
    
    # 烹饪步骤
    var steps_label = Label.new()
    steps_label.text = "烹饪步骤:"
    steps_label.add_theme_font_size_override("font_size", 16)
    vbox.add_child(steps_label)
    
    var steps_list = VBoxContainer.new()
    vbox.add_child(steps_list)
    
    for i in range(recipe_data.steps.size()):
        var step_label = Label.new()
        step_label.text = str(i + 1) + ". " + recipe_data.steps[i]
        steps_list.add_child(step_label)
    
    # 添加关闭按钮
    var btn_hbox = HBoxContainer.new()
    btn_hbox.alignment = HBoxContainer.ALIGN_END
    vbox.add_child(btn_hbox)
    
    var close_btn = Button.new()
    close_btn.text = "关闭"
    close_btn.pressed.connect(detail_dialog.hide)
    btn_hbox.add_child(close_btn)
    
    # 设置对话框大小
    detail_dialog.size = Vector2(500, 600)
    
    # 显示对话框
    get_tree().current_scene.add_child(detail_dialog)
    detail_dialog.show()
