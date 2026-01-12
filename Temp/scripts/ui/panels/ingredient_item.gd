extends HBoxContainer

# 食材列表项脚本

var ingredient_data = {}

func set_data(data):
	ingredient_data = data
	
	# 更新显示
	$NameLabel.text = data.name
	$QtyLabel.text = str(data.quantity) + data.unit
	$ExpiryLabel.text = data.expiry_date
	$LocLabel.text = data.location
	
	# 设置状态图标
	_update_status_icon()

func _update_status_icon():
	# 检查库存状态并更新图标
	# 获取当前日期时间字符串（格式：YYYY-MM-DD HH:MM:SS）
	var today_str = Time.get_datetime_string_from_system(false, true)
	var today_parts = today_str.split(" ")[0].split("-")
	var today = {}
	today["year"] = today_parts[0].to_int()
	today["month"] = today_parts[1].to_int()
	today["day"] = today_parts[2].to_int()
	var expiry_date = ingredient_data.expiry_date.split("-")
	var exp_year = expiry_date[0].to_int()
	var exp_month = expiry_date[1].to_int()
	var exp_day = expiry_date[2].to_int()
	
	# 检查是否过期
	var is_expired = exp_year < today.year or 
				   (exp_year == today.year and exp_month < today.month) or 
				   (exp_year == today.year and exp_month == today.month and exp_day < today.day)
	
	# 检查是否低库存
	var is_low_stock = ingredient_data.quantity <= 5
	
	# 更新样式
	if is_expired:
		$NameLabel.add_theme_color_override("font_color", Color(1, 0, 0))
		$StatusIcon.texture = load("res://assets/icons/expired.png") if ResourceLoader.exists("res://assets/icons/expired.png") else null
	elif is_low_stock:
		$NameLabel.add_theme_color_override("font_color", Color(1, 1, 0))
		$StatusIcon.texture = load("res://assets/icons/low_stock.png") if ResourceLoader.exists("res://assets/icons/low_stock.png") else null
	else:
		$NameLabel.add_theme_color_override("font_color", Color(1, 1, 1))
		$StatusIcon.texture = null

func _on_edit_pressed():
	# 编辑按钮点击处理
	var main = get_parent().get_parent().get_parent().get_parent().get_parent().get_parent()
	var dialog = main.get_node("AddIngredientDialog")
	
	# 清空现有内容
	for child in dialog.get_children():
		if child is Control and child.name != "dialog_panel":
			child.queue_free()
	
	# 创建表单
	var form_vbox = VBoxContainer.new()
	dialog.add_child(form_vbox)
	
	# 食材名称
	var name_hbox = HBoxContainer.new()
	form_vbox.add_child(name_hbox)
	var name_label = Label.new()
	name_label.text = "食材名称:"
	name_hbox.add_child(name_label)
	var name_input = LineEdit.new()
	name_input.text = ingredient_data.name
	name_input.name = "name_input"
	name_hbox.add_child(name_input)
	
	# 数量
	var qty_hbox = HBoxContainer.new()
	form_vbox.add_child(qty_hbox)
	var qty_label = Label.new()
	qty_label.text = "数量:"
	qty_hbox.add_child(qty_label)
	var qty_input = LineEdit.new()
	qty_input.text = str(ingredient_data.quantity)
	qty_input.name = "qty_input"
	qty_hbox.add_child(qty_input)
	
	# 单位
	var unit_hbox = HBoxContainer.new()
	form_vbox.add_child(unit_hbox)
	var unit_label = Label.new()
	unit_label.text = "单位:"
	unit_hbox.add_child(unit_label)
	var unit_input = LineEdit.new()
	unit_input.text = ingredient_data.unit
	unit_input.name = "unit_input"
	unit_hbox.add_child(unit_input)
	
	# 类别
	var category_hbox = HBoxContainer.new()
	form_vbox.add_child(category_hbox)
	var category_label = Label.new()
	category_label.text = "类别:"
	category_hbox.add_child(category_label)
	var category_option = OptionButton.new()
	category_option.name = "category_option"
	var categories = ["蔬菜", "肉类", "粮油", "调味品", "蛋制品", "乳制品", "其他"]
	for cat in categories:
		category_option.add_item(cat)
		if cat == ingredient_data.category:
			category_option.selected = categories.find(cat)
	category_hbox.add_child(category_option)
	
	# 保质期
	var expiry_hbox = HBoxContainer.new()
	form_vbox.add_child(expiry_hbox)
	var expiry_label = Label.new()
	expiry_label.text = "保质期:"
	expiry_hbox.add_child(expiry_label)
	var expiry_input = LineEdit.new()
	expiry_input.text = ingredient_data.expiry_date
	expiry_input.placeholder_text = "YYYY-MM-DD"
	expiry_input.name = "expiry_input"
	expiry_hbox.add_child(expiry_input)
	
	# 存放位置
	var loc_hbox = HBoxContainer.new()
	form_vbox.add_child(loc_hbox)
	var loc_label = Label.new()
	loc_label.text = "存放位置:"
	loc_hbox.add_child(loc_label)
	var loc_input = LineEdit.new()
	loc_input.text = ingredient_data.location
	loc_input.name = "loc_input"
	loc_hbox.add_child(loc_input)
	
	# 连接确认信号
	dialog.confirmed.disconnect_all()
	dialog.confirmed.connect(_on_edit_confirmed.bind(dialog))
	
	# 显示对话框
	dialog.title = "编辑食材"
	dialog.show()

func _on_edit_confirmed(dialog):
	# 编辑确认处理
	var name = dialog.get_node("name_input").text
	var quantity = dialog.get_node("qty_input").text.to_int()
	var unit = dialog.get_node("unit_input").text
	var category = dialog.get_node("category_option").get_item_text(dialog.get_node("category_option").selected)
	var expiry_date = dialog.get_node("expiry_input").text
	var location = dialog.get_node("loc_input").text
	
	# 更新数据
	var updated_data = {
		"name": name,
		"quantity": quantity,
		"unit": unit,
		"category": category,
		"expiry_date": expiry_date,
		"location": location
	}
	
	# 找到当前项在数据中的索引
	var main = get_parent().get_parent().get_parent().get_parent().get_parent().get_parent()
	var data_manager = main.get_node("DataManager")
	
	# 更新数据
	var inventory = data_manager.get_inventory()
	var index = -1
	for i in range(inventory.size()):
		if inventory[i].name == ingredient_data.name:
			index = i
			break
	
	if index >= 0:
		data_manager.update_ingredient(index, updated_data)
		set_data(updated_data)
		
		# 刷新列表 - TODO: _refresh_inventory_list方法在main_ui.gd中未实现
		# main._refresh_inventory_list()

func _on_delete_pressed():
	# 删除按钮点击处理
	var confirm_dialog = ConfirmationDialog.new()
	confirm_dialog.title = "确认删除"
	confirm_dialog.dialog_text = "确定要删除食材'" + ingredient_data.name + "'吗？"
	confirm_dialog.connect("confirmed", _on_delete_confirmed)
	get_tree().current_scene.add_child(confirm_dialog)
	confirm_dialog.show()

func _on_delete_confirmed():
	# 删除确认处理
	var main = get_parent().get_parent().get_parent().get_parent().get_parent().get_parent()
	var data_manager = main.get_node("DataManager")
	
	# 找到当前项在数据中的索引
	var inventory = data_manager.get_inventory()
	var index = -1
	for i in range(inventory.size()):
		if inventory[i].name == ingredient_data.name:
			index = i
			break
	
	if index >= 0:
		data_manager.delete_ingredient(index)
		queue_free()
