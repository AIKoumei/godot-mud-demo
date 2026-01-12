# 数据管理器 - DataManager
# 封装SQLite/JSON的增删改查方法，提供全局数据访问
# @version v.0.0.1
# @extends Node
# @description 负责管理食材库存、料理库、菜单和任务数据的持久化和访问
#
# ## 设计理念
# - **统一数据访问**：提供统一的接口访问所有应用数据
# - **多种存储方式**：支持SQLite数据库和JSON文件存储
# - **数据结构优化**：使用字典存储数据，键为UID，值为数据对象，提高访问效率
# - **模块化设计**：按数据类型（库存、食谱、菜单、任务）组织管理方法
# - **自动持久化**：提供数据保存和加载的自动化管理
#
# ## 数据类型
# 1. **inventory_data**：食材库存数据，字典格式，键为UID
# 2. **recipe_data**：食谱数据，字典格式，键为UID
# 3. **menu_data**：菜单数据，字典格式，键为UID
# 4. **task_data**：任务数据，字典格式，键为UID（存储单次任务和已实例化的重复任务）
# 5. **schedule_task_data**：计划任务数据，字典格式，键为UID（存储每日、每周重复任务模板）
#
# ## 主要功能
# - **数据持久化**：保存和加载应用数据
# - **UID生成**：生成唯一标识符
# - **数据管理**：对各类数据进行增删改查操作
# - **目录管理**：确保用户数据目录存在
#
# ## 使用示例
# ```gdscript
# # 获取数据管理器实例
# var data_manager = get_node("/root/DataManager")
# 
# # 保存库存数据
# data_manager.save_inventory()
# 
# # 加载所有数据
# data_manager.load_data()
# 
# # 生成唯一ID
# var new_uid = data_manager.generate_uid()
# ```
extends Node

# 数据存储路径 - 使用操作系统的安全用户数据目录
var USER_DATA_DIR = OS.get_user_data_dir() + "/kitchen_hub/"
var db_path = USER_DATA_DIR + "kitchen_hub.db"

# 数据结构 - 使用字典存储，键为UID，值为数据对象
var inventory_data = {}  # 食材库存数据
var recipe_data = {}     # 食谱数据
var menu_data = {}       # 菜单数据
var task_data = {}       # 存储单次任务和已实例化的重复任务
var schedule_task_data = {}  # 存储每日、每周重复任务模板

# 用于生成唯一ID的基础值
var _uid_counter = 0

func _ready():
	"""
	@description 节点就绪时的初始化函数
	@private 内部方法
	- 确保用户数据目录存在
	- 加载所有应用数据
	"""
	# 确保用户数据目录存在
	ensure_user_data_dir_exists()
	# 初始化数据
	load_data()
	
func ensure_user_data_dir_exists():
	"""
	@description 确保用户数据目录存在，如果不存在则创建
	@public
	@returns void
	
	错误处理:
		如果目录创建失败，会推送错误消息
	"""
	# 使用FileAccess API检查和创建目录
	var err = DirAccess.make_dir_recursive_absolute(USER_DATA_DIR)
	if err != OK:
		push_error("Failed to create user_data directory: " + str(err))

func generate_uid() -> int:
	"""
	@description 生成唯一ID
	@public
	@returns int - 唯一的ID值，自增1
	"""
	_uid_counter += 1
	return _uid_counter

func init_daily_tasks():
	"""
	@description 初始化每日任务
	@public
	@returns void
	
	功能说明：
	- 根据日程任务（schedule_task_data）自动创建当日的任务实例
	- 处理每日（daily）和每周（weekly）重复任务模板
	- 自动检测任务是否已存在，避免重复创建同一日期的任务
	- 为创建的任务分配唯一UID并设置正确的时间格式
	
	工作流程：
	1. 获取当前日期和星期几
	2. 遍历所有日程任务模板
	3. 根据任务类型（daily/weekly）判断是否应该创建
	4. 检查是否已经为今天创建过该任务
	5. 如未创建，则生成新任务实例并保存
	"""
	# 获取当前日期和时间
	var current_time = Time.get_time_dict_from_system()
	var today_date = "%04d-%02d-%02d" % [current_time.year, current_time.month, current_time.day]
	var today_weekday = current_time.weekday  # Godot中周日是0，周六是6
	
	print("[DataManager] 初始化每日任务，日期: ", today_date, "，星期: ", today_weekday)
	
	# 遍历所有日程任务
	for task_uid in schedule_task_data.keys():
		var schedule_task = schedule_task_data[task_uid]
		var should_create_task = false
		var task_time_str = "%02d:%02d:%02d" % [schedule_task.task_time_hour, schedule_task.task_time_minute, schedule_task.task_time_second]
		var full_task_time = today_date + " " + task_time_str
		
		# 判断是否应该创建任务
		if schedule_task.schedule_type == "daily":
			# 每日任务：每天都要创建
			should_create_task = true
		elif schedule_task.schedule_type == "weekly":
			# 每周任务：只在特定星期几创建
			# 注意：需要将存储的星期几（1-7）转换为Godot的星期几（0-6）
			var stored_weekday = schedule_task.task_time_day
			var godot_weekday = stored_weekday - 1  # 假设存储的1是周一，转换为Godot的0（周日的0需要特殊处理）
			
			# 处理周日的情况
			if stored_weekday == 7:
				godot_weekday = 0
			
			should_create_task = godot_weekday == today_weekday
		
		# 创建任务实例
		if should_create_task:
			# 检查是否已经为今天创建过该任务
			var task_exists = false
			for existing_task in task_data.values():
				# 检查是否是同一日程任务的实例
				if existing_task.has("schedule_task_uid") and existing_task.schedule_task_uid == task_uid:
					# 检查日期是否为今天
					if existing_task.task_time.begins_with(today_date):
						task_exists = true
						break
			
			# 如果任务不存在，则创建新任务
			if not task_exists:
				# 创建任务副本
				var new_task = schedule_task.duplicate()
				# 生成新的UID
				new_task.uid = generate_uid()
				# 设置为单次任务
				new_task.schedule_type = "once"
				# 设置具体日期时间
				new_task.task_time = full_task_time
				# 设置具体的年月日
				new_task.task_time_year = current_time.year
				new_task.task_time_month = current_time.month
				new_task.task_time_day = current_time.day
				# 标记为日程任务的实例
				new_task.schedule_task_uid = task_uid
				# 设置为未完成
				new_task.completed = false
				
				# 添加到任务列表
				task_data[new_task.uid] = new_task
				print("[DataManager] 创建新任务实例: ", new_task.name, " (ID: ", new_task.uid, ")")
	
	# 保存更新后的任务数据
	if task_data.size() > 0:
		save_tasks()
	
func load_data():
	"""
	@description 加载所有应用数据
	@public
	@returns void
	
	加载内容：
	- 食材库存数据 (inventory_data)
	- 料理库数据 (recipe_data)
	- 菜单数据 (menu_data)
	- 任务数据 (task_data)
	- 日程任务数据 (schedule_task_data)

	工作原理：
	- 检查是否处于开发模式（debugger=true）
	- 开发模式下：直接调用_init_test_data()使用默认测试数据，不读取文件
	- 生产模式下：如果数据文件存在，则加载现有数据；如果不存在，则创建空数据结构并保存
	- 自动将旧格式数据转换为新格式（从数组到字典）
	- 确保所有uid字段为int类型，避免类型错误
	"""
	# 检查是否处于开发模式
	var is_debug_mode = _is_debug_mode()
	
	# 开发模式下直接使用测试数据
	if is_debug_mode:
		print("[DataManager] 开发模式：使用默认测试数据")
		_init_test_data()
		return
	
	# 生产模式：从文件加载数据
	print("[DataManager] 生产模式：从文件加载数据")
	
	# 加载食材库存数据
	if FileAccess.file_exists(USER_DATA_DIR + "inventory.json"):
		var file = FileAccess.open(USER_DATA_DIR + "inventory.json", FileAccess.READ)
		if file:
			var json = file.get_as_text()
			file.close()
			var loaded_data = JSON.parse_string(json)
			# 如果加载的数据是数组，转换为字典格式
			if loaded_data is Array:
				inventory_data = {}
				for item in loaded_data:
					if item.has("uid"):
						# 确保uid为int类型
						var uid_int = _ensure_uid_is_int(item.uid)
						item.uid = uid_int
						inventory_data[uid_int] = item
			else:
				# 确保字典中的键和值的uid都为int类型
				inventory_data = _convert_dict_uids_to_int(loaded_data)
	else:
		# 生产模式：如果文件不存在，使用空字典
		inventory_data = {}
		save_inventory()
	
	# 加载料理库数据
	if FileAccess.file_exists(USER_DATA_DIR + "recipes.json"):
		var file = FileAccess.open(USER_DATA_DIR + "recipes.json", FileAccess.READ)
		if file:
			var json = file.get_as_text()
			file.close()
			var loaded_data = JSON.parse_string(json)
			# 如果加载的数据是数组，转换为字典格式
			if loaded_data is Array:
				recipe_data = {}
				for recipe in loaded_data:
					if recipe.has("uid"):
						# 确保uid为int类型
						var uid_int = _ensure_uid_is_int(recipe.uid)
						recipe.uid = uid_int
						recipe_data[uid_int] = recipe
			else:
				# 确保字典中的键和值的uid都为int类型
				recipe_data = _convert_dict_uids_to_int(loaded_data)
	else:
		# 生产模式：如果文件不存在，使用空字典
		recipe_data = {}
		save_recipes()
	
	# 加载菜单数据
	if FileAccess.file_exists(USER_DATA_DIR + "menu.json"):
		var file = FileAccess.open(USER_DATA_DIR + "menu.json", FileAccess.READ)
		if file:
			var json = file.get_as_text()
			file.close()
			menu_data = JSON.parse_string(json)
	else:
		# 生产模式：如果文件不存在，使用空菜单结构
		menu_data = {"current_week": Time.get_date_string_from_system(), "meals": {}}
		save_menu()
	
	# 加载任务数据
	if FileAccess.file_exists(USER_DATA_DIR + "tasks.json"):
		var file = FileAccess.open(USER_DATA_DIR + "tasks.json", FileAccess.READ)
		if file:
			var json = file.get_as_text()
			file.close()
			var loaded_data = JSON.parse_string(json)
			# 初始化临时任务数据
			task_data = {}
			
			# 处理加载的数据
			if loaded_data is Array:
				for task in loaded_data:
					if task.has("uid"):
						# 转换旧任务格式到新格式
						var new_task = _convert_old_task_format(task)
						# 确保uid为int类型
						var uid_int = _ensure_uid_is_int(new_task.uid)
						new_task.uid = uid_int
						# 根据schedule_type决定存储位置
						if new_task.schedule_type == "daily" or new_task.schedule_type == "weekly":
							schedule_task_data[uid_int] = new_task
						else:
							task_data[uid_int] = new_task
			else:
				for uid in loaded_data.keys():
					var task = loaded_data[uid]
					if task.has("uid"):
						# 检查是否需要转换格式
						if not task.has("schedule_type"):
							task = _convert_old_task_format(task)
						# 确保uid为int类型
						var uid_int = _ensure_uid_is_int(task.uid)
						task.uid = uid_int
						# 根据schedule_type决定存储位置
						if task.schedule_type == "daily" or task.schedule_type == "weekly":
							schedule_task_data[uid_int] = task
						else:
							task_data[uid_int] = task
			
			print("USER_DATA_DIR", USER_DATA_DIR + "tasks.json")
			print("task_data ", task_data)
			print("schedule_task_data ", schedule_task_data)
			
			# 保存转换后的数据
			save_tasks()
			save_schedule_tasks()
	else:
		# 生产模式：如果文件不存在，使用空字典
		task_data = {}
		schedule_task_data = {}
		save_tasks()
		save_schedule_tasks()
	
	# 加载日程任务数据（新版本）
	if FileAccess.file_exists(USER_DATA_DIR + "schedule_tasks.json"):
		var file = FileAccess.open(USER_DATA_DIR + "schedule_tasks.json", FileAccess.READ)
		if file:
			var json = file.get_as_text()
			file.close()
			var loaded_data = JSON.parse_string(json)
			# 如果加载的数据是数组，转换为字典格式
			if loaded_data is Array:
				schedule_task_data = {}
				for task in loaded_data:
					if task.has("uid"):
						# 确保uid为int类型
						var uid_int = _ensure_uid_is_int(task.uid)
						task.uid = uid_int
						schedule_task_data[uid_int] = task
			else:
				# 确保字典中的键和值的uid都为int类型
				schedule_task_data = _convert_dict_uids_to_int(loaded_data)
	
	# 初始化UID计数器，确保生成的UID不会重复
	_init_uid_counter()

func _convert_old_task_format(task: Dictionary) -> Dictionary:
	"""
	@description 将旧的任务格式转换为新格式
	@private 内部方法
	@param task: Dictionary - 旧格式的任务对象，可能包含next_time字段
	@returns Dictionary - 转换后的新格式任务对象，包含schedule_type和详细的时间分割字段
	
	转换规则：
	- 识别每日任务并设置schedule_type为"daily"
	- 其他任务设置schedule_type为"once"
	- 将next_time解析为单独的年月日时分秒字段
	- 确保task_time格式完整
	"""
	var new_task = task.duplicate()
	
	# 设置schedule_type
	if task.has("next_time"):
		if task.next_time == "每日":
			new_task.schedule_type = "daily"
			# 设置默认的时间分割字段（每天早上9点）
			new_task.task_time_year = 0  # 0表示每年
			new_task.task_time_month = 0  # 0表示每月
			new_task.task_time_day = 0  # 0表示每天
			new_task.task_time_hour = 9
			new_task.task_time_minute = 0
			new_task.task_time_second = 0
			# task_time保持为计划开始时间（这里用今天的日期）
			new_task.task_time = Time.get_date_string_from_system() + " 09:00:00"
		else:
			# 假设不是每日的就是单次任务
			new_task.schedule_type = "once"
			# 解析next_time为分割的时间字段
			var time_parts = task.next_time.split(" ")
			var date_parts = time_parts[0].split("-")
			new_task.task_time_year = date_parts[0].to_int()
			new_task.task_time_month = date_parts[1].to_int()
			new_task.task_time_day = date_parts[2].to_int()
			# 如果有时间部分
			if time_parts.size() > 1:
				var time_components = time_parts[1].split(":")
				new_task.task_time_hour = time_components[0].to_int() if time_components.size() > 0 else 0
				new_task.task_time_minute = time_components[1].to_int() if time_components.size() > 1 else 0
				new_task.task_time_second = time_components[2].to_int() if time_components.size() > 2 else 0
			else:
				new_task.task_time_hour = 0
				new_task.task_time_minute = 0
				new_task.task_time_second = 0
			# 确保task_time包含完整的时间
			new_task.task_time = task.next_time
			if not task.next_time.find(" ") >= 0:
				new_task.task_time += " 00:00:00"
	
	return new_task

func _init_uid_counter() -> void:
	"""
	@description 初始化UID计数器，确保生成的UID不会重复
	@private 内部方法
	@returns void

	检查所有数据中的最大UID值，并将计数器设置为该值
	确保所有uid都被正确转换为int类型进行比较
	"""
	var max_uid = 0
	
	# 检查库存数据中的UID
	for uid in inventory_data.keys():
		var uid_int = _ensure_uid_is_int(uid)
		if uid_int > max_uid:
			max_uid = uid_int
	
	# 检查菜谱数据中的UID
	for uid in recipe_data.keys():
		var uid_int = _ensure_uid_is_int(uid)
		if uid_int > max_uid:
			max_uid = uid_int
	
	# 检查任务数据中的UID
	for uid in task_data.keys():
		var uid_int = _ensure_uid_is_int(uid)
		if uid_int > max_uid:
			max_uid = uid_int
	
	# 检查日程任务数据中的UID
	for uid in schedule_task_data.keys():
		var uid_int = _ensure_uid_is_int(uid)
		if uid_int > max_uid:
			max_uid = uid_int
	
	_uid_counter = max_uid

func _ensure_uid_is_int(uid) -> int:
	"""
	@description 确保uid为int类型
	@private 内部方法
	@param uid: Variant - 可能是字符串、数字或浮点数的uid值
	@returns int - 转换后的int类型uid，如果转换失败则返回0
	"""
	if uid is String:
		return uid.to_int()
	elif uid is int:
		return uid
	elif uid is float:
		return int(uid)
	else:
		return 0

func _convert_dict_uids_to_int(data_dict) -> Dictionary:
	"""
	@description 将字典中的键和值的uid字段转换为int类型
	@private 内部方法
	@param data_dict: Dictionary - 需要转换的字典数据，键可能是字符串或数字
	@returns Dictionary - 转换后的字典，所有键和值中的uid字段均为int类型
	"""
	var result = {}
	for key in data_dict.keys():
		var value = data_dict[key]
		# 确保键是int类型
		var int_key = _ensure_uid_is_int(key)
		# 确保值中的uid字段是int类型
		if value is Dictionary and value.has("uid"):
			value.uid = _ensure_uid_is_int(value.uid)
		result[int_key] = value
	return result

func _is_debug_mode() -> bool:
	"""
	@description 检查是否处于开发模式
	@private 内部方法
	@returns bool - 如果MainUI中的debugger标志为true则返回true，否则返回false
	"""
	# 尝试获取MainUI节点
	var main_ui = get_node_or_null("../MainUI")
	if not main_ui:
		# 如果找不到MainUI节点，尝试通过场景树查找
		for node in get_tree().get_nodes_in_group("main_ui"):
			main_ui = node
			break
		
		# 如果仍然找不到，检查根节点
		if not main_ui and get_tree().root and get_tree().root.get_child_count() > 0:
			for child in get_tree().root.get_children():
				if child is Node and "debugger" in child:
					main_ui = child
					break
	
	# 检查是否有debugger属性并返回其值
	if main_ui and "debugger" in main_ui:
		return main_ui.debugger
	
	# 默认返回false（生产模式）
	return false

func _init_test_data() -> void: 
	"""
	@description 初始化测试数据
	@private 内部方法
	@returns void
	
	功能：用于开发和测试环境，创建示例数据
	创建内容：
	- 食材库存示例数据（大米、鸡蛋、西红柿等）
	- 料理库示例数据（番茄炒蛋、炒饭等）
	- 菜单示例结构
	- 单次任务示例
	- 日程任务模板示例
	"""
	print("[DataManager] 初始化测试数据")
	
	# 初始化食材库存数据
	inventory_data = {}
	# 添加食材示例数据
	var inventory_items = [
		{"name": "大米", "type": "主食", "quantity": 5000, "unit": "g", "expiry_date": "2025-12-31", "category": "主食类", "in_stock": true},
		{"name": "鸡蛋", "type": "蛋类", "quantity": 30, "unit": "个", "expiry_date": "2025-11-10", "category": "蛋类", "in_stock": true},
		{"name": "西红柿", "type": "蔬菜", "quantity": 5, "unit": "个", "expiry_date": "2025-11-08", "category": "蔬菜类", "in_stock": true},
		{"name": "鸡胸肉", "type": "肉类", "quantity": 1000, "unit": "g", "expiry_date": "2025-11-07", "category": "肉类", "in_stock": true},
		{"name": "牛奶", "type": "乳制品", "quantity": 2, "unit": "盒", "expiry_date": "2025-11-15", "category": "乳制品", "in_stock": true}
	]
	
	for item in inventory_items:
		item.uid = generate_uid()
		inventory_data[item.uid] = item
	
	# 初始化料理库数据
	recipe_data = {}
	# 添加料理示例数据
	var recipes = [
		{
			"name": "番茄炒蛋",
			"type": "家常菜",
			"difficulty": "简单",
			"time_cost": "15分钟",
			"description": "经典家常菜，酸甜可口",
			"instructions": ["鸡蛋打散", "西红柿切块", "下锅翻炒"],
			"ingredients": [
				{"uid": "", "name": "鸡蛋", "quantity": 3, "unit": "个"},
				{"uid": "", "name": "西红柿", "quantity": 2, "unit": "个"},
				{"uid": "", "name": "食用油", "quantity": 10, "unit": "ml"},
				{"uid": "", "name": "盐", "quantity": 3, "unit": "g"}
			],
			"image_path": "",
			"nutrition_info": {"calories": 320, "protein": 25, "carbs": 15, "fat": 20}
		},
		{
			"name": "炒饭",
			"type": "主食",
			"difficulty": "简单",
			"time_cost": "10分钟",
			"description": "简单快捷的主食选择",
			"instructions": ["米饭打散", "下锅翻炒", "加入调料"],
			"ingredients": [
				{"uid": "", "name": "大米", "quantity": 150, "unit": "g"},
				{"uid": "", "name": "鸡蛋", "quantity": 1, "unit": "个"},
				{"uid": "", "name": "葱花", "quantity": 5, "unit": "g"},
				{"uid": "", "name": "食用油", "quantity": 15, "unit": "ml"}
			],
			"image_path": "",
			"nutrition_info": {"calories": 450, "protein": 12, "carbs": 60, "fat": 18}
		}
	]
	
	for recipe in recipes:
		recipe.uid = generate_uid()
		recipe_data[recipe.uid] = recipe
	
	# 初始化菜单数据
	menu_data = {
		"current_week": Time.get_date_string_from_system(),
		"meals": {
			"周一": {"早餐": "炒饭", "午餐": "番茄炒蛋", "晚餐": "", "备注": ""},
			"周二": {"早餐": "", "午餐": "", "晚餐": "", "备注": ""},
			"周三": {"早餐": "", "午餐": "", "晚餐": "", "备注": ""},
			"周四": {"早餐": "", "午餐": "", "晚餐": "", "备注": ""},
			"周五": {"早餐": "", "午餐": "", "晚餐": "", "备注": ""},
			"周六": {"早餐": "", "午餐": "", "晚餐": "", "备注": ""},
			"周日": {"早餐": "", "午餐": "", "晚餐": "", "备注": ""}
		}
	}
	
	# 初始化任务数据（单次任务和已实例化的重复任务）
	task_data = {}
	# 初始化日程任务数据（每日、每周重复任务模板）
	schedule_task_data = {}
	
	# 当前日期和时间
	var today = Time.get_date_string_from_system()
	var current_time = Time.get_datetime_dict_from_system()
	
	# 添加单次任务示例数据
	var once_tasks = [
		{
			"name": "做饭", 
			"type": "日常", 
			"schedule_type": "once",
			"task_time": today + " 18:00:00",
			"task_time_year": current_time.year,
			"task_time_month": current_time.month,
			"task_time_day": current_time.day,
			"task_time_hour": 18,
			"task_time_minute": 0,
			"task_time_second": 0,
			"completed": false, 
			"linked": {"type": "", "uid": ""}
		},
		{
			"name": "整理冰箱", 
			"type": "家务", 
			"schedule_type": "once",
			"task_time": today + " 12:00:00",
			"task_time_year": current_time.year,
			"task_time_month": current_time.month,
			"task_time_day": current_time.day,
			"task_time_hour": 12,
			"task_time_minute": 0,
			"task_time_second": 0,
			"completed": false, 
			"linked": {"type": "", "uid": ""}
		},
		{
			"name": "去超市购物", 
			"type": "购物", 
			"schedule_type": "once",
			"task_time": today + " 14:00:00",
			"task_time_year": current_time.year,
			"task_time_month": current_time.month,
			"task_time_day": current_time.day,
			"task_time_hour": 14,
			"task_time_minute": 0,
			"task_time_second": 0,
			"completed": false, 
			"linked": {"type": "", "uid": ""}
		}
	]
	
	for task in once_tasks:
		task.uid = generate_uid()
		task_data[task.uid] = task
	
	# 添加日程任务示例数据
	var schedule_tasks = [
		{
			"name": "每日买菜", 
			"type": "购物", 
			"schedule_type": "daily",
			"task_time": today + " 09:00:00",
			"task_time_year": 0,
			"task_time_month": 0,
			"task_time_day": 0,
			"task_time_hour": 9,
			"task_time_minute": 0,
			"task_time_second": 0,
			"completed": false, 
			"linked": {"type": "", "uid": ""}
		},
		{
			"name": "每周购物", 
			"type": "购物", 
			"schedule_type": "weekly",
			"task_time": today + " 10:00:00",
			"task_time_year": 0,
			"task_time_month": 0,
			"task_time_day": 6,  # 周六
			"task_time_hour": 10,
			"task_time_minute": 0,
			"task_time_second": 0,
			"completed": false, 
			"linked": {"type": "", "uid": ""}
		},
		{
			"name": "每日晚餐", 
			"type": "日常", 
			"schedule_type": "daily",
			"task_time": today + " 19:00:00",
			"task_time_year": 0,
			"task_time_month": 0,
			"task_time_day": 0,
			"task_time_hour": 19,
			"task_time_minute": 0,
			"task_time_second": 0,
			"completed": false, 
			"linked": {"type": "", "uid": ""}
		}
	]
	
	for task in schedule_tasks:
		task.uid = generate_uid()
		schedule_task_data[task.uid] = task
	
	# 初始化UID计数器
	_init_uid_counter()
	
	# 保存初始化的测试数据
	save_inventory()
	save_recipes()
	save_menu()
	save_tasks()
	save_schedule_tasks()

# 食材库存相关方法
func get_inventory(filter_category = "全部", filter_status = "全部"):
	"""
	获取符合筛选条件的库存物品列表

	参数:
		filter_category: 分类筛选条件，默认为"全部"
		filter_status: 状态筛选条件，默认为"全部"

	返回:
		符合条件的库存物品数组
	"""
	var filtered = []
	for item in inventory_data.values():
		var category_match = filter_category == "全部" or item.category == filter_category
		var status_match = filter_status == "全部"
		
		if filter_status != "全部":
			# 获取当前日期时间字符串（格式：YYYY-MM-DD HH:MM:SS）
			var today_str = Time.get_datetime_string_from_system(false, true)
			var today_parts = today_str.split(" ")[0].split("-")
			var today = {}
			today.year = today_parts[0].to_int()
			today.month = today_parts[1].to_int()
			today.day = today_parts[2].to_int()
			var expiry_date = item.expiry_date.split("-")
			var exp_year = expiry_date[0].to_int()
			var exp_month = expiry_date[1].to_int()
			var exp_day = expiry_date[2].to_int()
			
			if filter_status == "低库存" and item.quantity <= 5:
				status_match = true
			elif filter_status == "过期" and (exp_year < today.year or 
					(exp_year == today.year and exp_month < today.month) or 
					(exp_year == today.year and exp_month == today.month and exp_day < today.day)):
				status_match = true
			elif filter_status == "正常" and item.quantity > 5 and not (
					exp_year < today.year or 
					(exp_year == today.year and exp_month < today.month) or 
					(exp_year == today.year and exp_month == today.month and exp_day < today.day)):
				status_match = true
		
		if category_match and status_match:
			filtered.append(item)
	return filtered

func add_ingredient(ingredient):
	"""
	添加新的食材到库存

	参数:
		ingredient: 食材对象，包含name、quantity、unit、category、expiry_date、location等属性
	"""
	# 确保食材有唯一UID
	if not ingredient.has("uid"):
		ingredient.uid = generate_uid()
	# 使用UID作为键，将食材添加到字典中
	inventory_data[ingredient.uid] = ingredient
	save_inventory()

func update_ingredient(uid, ingredient):
	"""
	更新指定UID的食材信息

	参数:
		uid: 食材的唯一ID
		ingredient: 更新后的食材对象
	"""
	# 直接通过UID在字典中查找和更新
	if inventory_data.has(uid):
		# 确保保留原UID
		ingredient.uid = uid
		inventory_data[uid] = ingredient
		save_inventory()

func delete_ingredient(uid):
	"""
	删除指定UID的食材

	参数:
		uid: 食材的唯一ID
	"""
	# 直接通过UID在字典中删除
	if inventory_data.has(uid):
		inventory_data.erase(uid)
		save_inventory()

func search_inventory(keyword):
	"""
	根据关键字搜索库存中的食材

	参数:
		keyword: 搜索关键字

	返回:
		包含关键字的食材数组
	"""
	var results = []
	for item in inventory_data.values():
		if item.name.find(keyword) >= 0:
			results.append(item)
	return results

func save_inventory():
	"""
	保存食材库存数据到JSON文件

	实现细节：
	- 使用JSON.stringify()将inventory_data序列化为JSON字符串
	- 将数据写入inventory.json文件
	- 写入成功后关闭文件
	"""
	# 使用JSON.stringify()将对象序列化为JSON字符串
	var file = FileAccess.open(USER_DATA_DIR + "inventory.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(inventory_data))
		file.close()

# 料理库相关方法
func get_recipes(filter_cuisine = "全部", filter_difficulty = "全部"):
	"""
	获取符合筛选条件的菜谱列表

	参数:
		filter_cuisine: 菜系筛选条件，默认为"全部"
		filter_difficulty: 难度筛选条件，默认为"全部"

	返回:
		符合条件的菜谱数组
	"""
	var filtered = []
	for recipe in recipe_data.values():
		var cuisine_match = filter_cuisine == "全部" or recipe.category == filter_cuisine
		var difficulty_match = filter_difficulty == "全部"
		
		if filter_difficulty != "全部":
			if filter_difficulty == "简单" and recipe.difficulty <= 2:
				difficulty_match = true
			elif filter_difficulty == "中等" and recipe.difficulty == 3:
				difficulty_match = true
			elif filter_difficulty == "复杂" and recipe.difficulty >= 4:
				difficulty_match = true
		
		if cuisine_match and difficulty_match:
			filtered.append(recipe)
	return filtered

func add_recipe(recipe):
	"""
	添加新的菜谱

	参数:
		recipe: 菜谱对象，包含name、category、difficulty、cooking_time、ingredients、steps等属性
	"""
	# 确保菜谱有唯一UID
	if not recipe.has("uid"):
		recipe.uid = generate_uid()
	# 使用UID作为键，将菜谱添加到字典中
	recipe_data[recipe.uid] = recipe
	save_recipes()

func update_recipe(uid, recipe):
	"""
	更新指定UID的菜谱信息

	参数:
		uid: 菜谱的唯一ID
		recipe: 更新后的菜谱对象
	"""
	# 直接通过UID在字典中查找和更新
	if recipe_data.has(uid):
		# 确保保留原UID
		recipe.uid = uid
		recipe_data[uid] = recipe
		save_recipes()

func delete_recipe(uid):
	"""
	删除指定UID的菜谱

	参数:
		uid: 菜谱的唯一ID
	"""
	# 直接通过UID在字典中删除
	if recipe_data.has(uid):
		recipe_data.erase(uid)
		save_recipes()

func search_recipes(keyword):
	"""
	根据关键字搜索菜谱

	参数:
		keyword: 搜索关键字

	返回:
		包含关键字的菜谱数组
	"""
	var results = []
	for recipe in recipe_data.values():
		if recipe.name.find(keyword) >= 0:
			results.append(recipe)
	return results

func get_available_recipes():
	"""
	获取所有可用的菜谱（基于当前库存有足够的配料）

	返回:
		当前可制作的菜谱数组
	"""
	var available = []
	var inventory_names = []
	for item in inventory_data.values():
		inventory_names.append(item.name)
	
	for recipe in recipe_data.values():
		var all_available = true
		for ingredient in recipe.ingredients:
			if not inventory_names.has(ingredient):
				all_available = false
				break
		if all_available:
			available.append(recipe)
	return available

func save_recipes():
	"""
	保存料理库数据到JSON文件

	实现细节：
	- 使用JSON.stringify()将recipe_data序列化为JSON字符串
	- 将数据写入recipes.json文件
	- 写入成功后关闭文件
	"""
	# 使用JSON.stringify()将对象序列化为JSON字符串
	var file = FileAccess.open(USER_DATA_DIR + "recipes.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(recipe_data))
		file.close()

# 菜单安排相关方法
func get_menu_by_week(week_start_date):
	"""
	获取指定周的菜单安排
	
	参数:
		week_start_date: 周起始日期字符串 (格式: YYYY-MM-DD)
	
	返回:
		指定周的菜单数据
	"""
	return menu_data.get("meals", {}).get(week_start_date, {})

func set_menu_item(week_start_date, day, meal_type, dish_name):
	"""
	设置指定周指定日期的餐单项目
	
	参数:
		week_start_date: 周起始日期字符串
		day: 星期几 (如: "Monday", "Tuesday")
		meal_type: 餐类型 (如: "早餐", "午餐", "晚餐")
		dish_name: 菜品名称
	"""
	if not menu_data.has("meals"):
		menu_data["meals"] = {}
	if not menu_data["meals"].has(week_start_date):
		menu_data["meals"][week_start_date] = {}
	if not menu_data["meals"][week_start_date].has(day):
		menu_data["meals"][week_start_date][day] = {}
	menu_data["meals"][week_start_date][day][meal_type] = dish_name
	save_menu()

func generate_shopping_list(week_start_date):
	"""
	根据指定周的菜单生成购物清单

	参数:
	week_start_date: 周起始日期字符串

	返回:
	需要购买的食材列表，考虑了当前库存
	"""
	var menu_items = get_menu_by_week(week_start_date)
	var shopping_list = {}
	
	# 统计菜单中需要的食材
	for day in menu_items.keys():
		for meal_type in menu_items[day].keys():
			var dish_name = menu_items[day][meal_type]
			if dish_name != "未安排" and dish_name != "外食" and dish_name != "剩菜":
				for recipe in recipe_data.values():
					if recipe.name == dish_name:
						for ingredient in recipe.ingredients:
							if shopping_list.has(ingredient.name):
								shopping_list[ingredient.name] += ingredient.quantity
							else:
								shopping_list[ingredient.name] = ingredient.quantity
	
	# 扣除现有库存
	var inventory_map = {}
	for item in inventory_data.values():
		inventory_map[item.name] = item.quantity
	
	var final_list = []
	for ingredient in shopping_list.keys():
		var needed = shopping_list[ingredient]
		var in_stock = inventory_map.get(ingredient, 0)
		if needed > in_stock:
			final_list.append({"name": ingredient, "quantity": needed - in_stock})
	
	return final_list

func save_menu():
	"""
	保存菜单数据到JSON文件
	
	实现细节：
	- 使用JSON.stringify()将menu_data序列化为JSON字符串
	- 将数据写入menu.json文件
	- 写入成功后关闭文件
	"""
	# 使用JSON.stringify()将对象序列化为JSON字符串
	var file = FileAccess.open(USER_DATA_DIR + "menu.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(menu_data))
		file.close()

# 任务清单相关方法
func get_tasks(filter_type = "全部", filter_status = "全部", include_schedule_tasks = false):
	"""
	获取符合筛选条件的任务列表

	参数:
		filter_type: 任务类型筛选条件，默认为"全部"
		filter_status: 任务状态筛选条件，默认为"全部"
		include_schedule_tasks: 是否包含日程任务（每日、每周任务模板）

	返回:
		符合条件的任务数组
	"""
	var filtered = []
	var tasks_to_process = []
	
	# 添加普通任务（单次任务和已实例化的重复任务）
	tasks_to_process.append_array(task_data.values())
	
	# 如果需要，添加日程任务（每日、每周任务模板）
	if include_schedule_tasks:
		tasks_to_process.append_array(schedule_task_data.values())
	
	# 遍历所有要处理的任务
	for task in tasks_to_process:
		var type_match = filter_type == "全部" or task.type == filter_type
		var status_match = filter_status == "全部"
		
		if filter_status == "已完成" and task.completed:
			status_match = true
		elif filter_status == "未完成" and not task.completed:
			status_match = true
		
		if type_match and status_match:
			filtered.append(task)
	print("filtered ", filtered)
	return filtered

func add_task(task_info):
	"""
	添加新的任务到任务清单

	参数:
		task_info: 任务对象，包含name、type、schedule_type、next_time等属性
	
	返回值:
		Dictionary - 添加的任务对象（包含生成的UID）
	"""
	# 确保任务有唯一UID
	if not task_info.has("uid"):
		task_info.uid = generate_uid()
	
	# 根据schedule_type决定存储位置
	if task_info.has("schedule_type") and (task_info.schedule_type == "daily" or task_info.schedule_type == "weekly"):
		# 添加到日程任务字典
		schedule_task_data[task_info.uid] = task_info
		save_schedule_tasks()
	else:
		# 如果没有schedule_type或不是daily/weekly，则默认为once并添加到普通任务
		if not task_info.has("schedule_type"):
			task_info.schedule_type = "once"
		# 添加到普通任务字典
		task_data[task_info.uid] = task_info
		save_tasks()
	
	return task_info

func update_task(uid, task_updates):
	"""
	更新指定UID的任务信息

	参数:
		uid: 任务的唯一ID
		task_updates: 更新后的任务对象
	"""
	var is_schedule_task = false
	var target_data = null
	
	# 查找任务存在的位置
	if task_data.has(uid):
		target_data = task_data
	elif schedule_task_data.has(uid):
		target_data = schedule_task_data
		is_schedule_task = true
	else:
		print("[DataManager] 任务不存在: ", uid)
		return
	
	# 处理next_time到task_time的转换
	if task_updates.has("next_time"):
		task_updates.task_time = task_updates.next_time
		task_updates.erase("next_time")
	if task_updates.has("next_time_year"):
		task_updates.task_time_year = task_updates.next_time_year
		task_updates.erase("next_time_year")
	if task_updates.has("next_time_month"):
		task_updates.task_time_month = task_updates.next_time_month
		task_updates.erase("next_time_month")
	if task_updates.has("next_time_day"):
		task_updates.task_time_day = task_updates.next_time_day
		task_updates.erase("next_time_day")
	if task_updates.has("next_time_hour"):
		task_updates.task_time_hour = task_updates.next_time_hour
		task_updates.erase("next_time_hour")
	if task_updates.has("next_time_minute"):
		task_updates.task_time_minute = task_updates.next_time_minute
		task_updates.erase("next_time_minute")
	if task_updates.has("next_time_second"):
		task_updates.task_time_second = task_updates.next_time_second
		task_updates.erase("next_time_second")
	
	# 确保保留原UID
	task_updates.uid = uid
	target_data[uid] = task_updates
	
	# 保存更新后的数据
	if is_schedule_task:
		save_schedule_tasks()
	else:
		save_tasks()

func delete_task(uid):
	"""
	删除指定UID的任务

	参数:
		uid: 任务的唯一ID
	
	返回值:
		bool - 删除是否成功
	"""
	var is_schedule_task = false
	
	# 查找任务存在的位置
	if task_data.has(uid):
		# 从字典中删除任务
		task_data.erase(uid)
	elif schedule_task_data.has(uid):
		# 从日程任务字典中删除
		schedule_task_data.erase(uid)
		is_schedule_task = true
	else:
		print("[DataManager] 任务不存在: ", uid)
		return false
	
	# 保存更新后的数据
	if is_schedule_task:
		save_schedule_tasks()
	else:
		save_tasks()
	
	return true

func search_tasks(keyword):
	"""
	根据关键字搜索任务

	参数:
		keyword: 搜索关键字

	返回:
		包含关键字的任务数组
	"""
	var results = []
	for task in task_data.values():
		if task.name.find(keyword) >= 0:
			results.append(task)
	return results

func mark_task_completed(uid, completed):
	"""
	标记任务为已完成或未完成

	参数:
		uid: 任务的唯一ID
		completed: 布尔值，表示任务是否完成
	"""
	# 直接通过UID在字典中查找和更新
	if task_data.has(uid):
		task_data[uid].completed = completed
		save_tasks()

func save_tasks():
	"""
	保存任务数据到JSON文件
	- 保存单次任务和已实例化的重复任务

	实现细节：
	- 使用JSON.stringify()将task_data序列化为JSON字符串
	- 将数据写入tasks.json文件
	- 写入成功后关闭文件
	"""
	# 使用JSON.stringify()将对象序列化为JSON字符串
	var file = FileAccess.open(USER_DATA_DIR + "tasks.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(task_data))
		file.close()

func save_schedule_tasks():
	"""
	保存日程任务数据到文件
	- 保存每日、每周重复任务模板
	"""
	var file = FileAccess.open(USER_DATA_DIR + "schedule_tasks.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(schedule_task_data))
		file.close()
		print("[DataManager] 日程任务数据保存成功")
	else:
		print("[DataManager] 保存日程任务数据失败")

# 通用数据管理方法
func initialize() -> void:
	"""
	初始化数据管理器
	
	执行顺序:
	1. 确保用户数据目录存在
	2. 加载所有应用数据
	3. 初始化每日任务
	
	返回值:
		void - 无返回值
	"""
	# 初始化数据管理器
	ensure_user_data_dir_exists()
	load_data()
	
	# 初始化每日任务（根据日程任务创建当天的任务实例）
	init_daily_tasks()

func export_data() -> Dictionary:
	"""
	导出所有应用数据为单个字典

	返回值:
		Dictionary - 包含所有应用数据的字典，结构如下：
		{
			"inventory": 库存数据字典,
			"recipes": 菜谱数据字典,
			"menu": 菜单数据字典,
			"tasks": 任务数据字典,
			"schedule_tasks": 日程任务数据字典
		}
	"""
	return {
			"inventory": inventory_data,
			"recipes": recipe_data,
			"menu": menu_data,
			"tasks": task_data,
			"schedule_tasks": schedule_task_data
		}

func import_data(data: Dictionary) -> bool:
	"""
	导入数据

	参数:
		data: 要导入的数据对象，包含inventory、recipes、menu、tasks、schedule_tasks等字段

	返回值:
		bool - 导入是否成功
	
	注意：确保所有导入数据中的uid字段都转换为int类型
	"""
	if data.has("inventory"):
		if data["inventory"] is Array:
			inventory_data = {}
			for item in data["inventory"]:
				if item.has("uid"):
					# 确保uid为int类型
					var uid_int = _ensure_uid_is_int(item.uid)
					item.uid = uid_int
					inventory_data[uid_int] = item
		else:
			# 确保字典中的键和值的uid都为int类型
			inventory_data = _convert_dict_uids_to_int(data["inventory"])
		save_inventory()
	
	if data.has("recipes"):
		if data["recipes"] is Array:
			recipe_data = {}
			for recipe in data["recipes"]:
				if recipe.has("uid"):
					# 确保uid为int类型
					var uid_int = _ensure_uid_is_int(recipe.uid)
					recipe.uid = uid_int
					recipe_data[uid_int] = recipe
		else:
			# 确保字典中的键和值的uid都为int类型
			recipe_data = _convert_dict_uids_to_int(data["recipes"])
		save_recipes()
	
	if data.has("menu"):
		menu_data = data["menu"]
		save_menu()
	
	if data.has("tasks"):
		# 处理任务数据
		task_data = {}
		if data["tasks"] is Array:
			for task in data["tasks"]:
				if task.has("uid"):
					# 确保uid为int类型
					var uid_int = _ensure_uid_is_int(task.uid)
					task.uid = uid_int
					# 检查是否需要根据schedule_type拆分到不同的数据结构
					if task.has("schedule_type") and (task.schedule_type == "daily" or task.schedule_type == "weekly"):
						schedule_task_data[uid_int] = task
					else:
						# 如果是旧格式，确保有schedule_type字段
						if not task.has("schedule_type"):
							task.schedule_type = "once"
						task_data[uid_int] = task
		else:
			for uid in data["tasks"].keys():
				var task = data["tasks"][uid]
				if task.has("uid"):
					# 确保uid为int类型
					var uid_int = _ensure_uid_is_int(task.uid)
					task.uid = uid_int
					# 检查是否需要根据schedule_type拆分到不同的数据结构
					if task.has("schedule_type") and (task.schedule_type == "daily" or task.schedule_type == "weekly"):
						schedule_task_data[uid_int] = task
					else:
						# 如果是旧格式，确保有schedule_type字段
						if not task.has("schedule_type"):
							task.schedule_type = "once"
						task_data[uid_int] = task
	
	# 单独处理日程任务数据（新版本）
	if data.has("schedule_tasks"):
		if data["schedule_tasks"] is Array:
			schedule_task_data = {}
			for task in data["schedule_tasks"]:
				if task.has("uid"):
					# 确保uid为int类型
					var uid_int = _ensure_uid_is_int(task.uid)
					task.uid = uid_int
					schedule_task_data[uid_int] = task
		else:
			# 确保字典中的键和值的uid都为int类型
			schedule_task_data = _convert_dict_uids_to_int(data["schedule_tasks"])
	
	# 保存导入的数据
	save_tasks()
	save_schedule_tasks()
	
	# 重新初始化UID计数器
	_init_uid_counter()
	
	return true

func backup_data() -> void:
	"""
	创建所有应用数据的备份
	
	实现细节:
	1. 创建备份目录（如果不存在）
	2. 使用系统时间生成唯一的备份文件名（格式: backup_YYYY-MM-DD_HH-MM-SS.json）
	3. 导出当前所有数据并保存到备份文件
	
	备份位置:
		USER_DATA_DIR + "backup/" 目录
	
	返回值:
		void - 无返回值
	"""
	var backup_dir = USER_DATA_DIR + "backup/"
	DirAccess.make_dir_recursive_absolute(backup_dir)
	var timestamp = Time.get_datetime_string_from_system(true, true).replace(":", "-")
	var backup_file = backup_dir + "backup_" + timestamp + ".json"
	
	var file = FileAccess.open(backup_file, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(export_data()))
		file.close()

func restore_data(backup_path: String) -> void:
	"""
	从备份文件恢复应用数据
	
	参数:
		backup_path: 备份文件的完整路径
	
	处理流程:
	1. 检查备份文件是否存在
	2. 打开并读取备份文件内容
	3. 解析JSON数据
	4. 导入数据到应用中
	
	错误处理:
	- 如果备份文件不存在，不会进行任何操作
	- 如果文件打开失败，不会进行任何操作
	- 依赖JSON.parse_string()进行错误处理
	
	返回值:
		void - 无返回值
	"""
	if FileAccess.file_exists(backup_path):
		var file = FileAccess.open(backup_path, FileAccess.READ)
		if file:
			var json = file.get_as_text()
			file.close()
			var data = JSON.parse_string(json)
			import_data(data)

# 餐单相关补充方法
func get_current_week_menu() -> Dictionary:
	"""
	获取当前周的菜单安排
	
	功能:
	- 调用get_menu_by_week方法获取menu_data中current_week指定的周菜单
	
	返回值:
		Dictionary - 当前周的菜单数据
	"""
	return get_menu_by_week(menu_data.current_week)

func update_meal_plan(day: String, meal_type: String, recipe_name: String) -> void:
	"""
	更新当前周指定日期的餐单计划
	
	参数:
		day: 星期几（如："Monday"、"Tuesday"等）
		meal_type: 餐类型（如："早餐"、"午餐"、"晚餐"）
		recipe_name: 菜品名称
	
	功能:
	- 调用set_menu_item方法更新当前周的指定餐单项目
	- 更新后会自动保存到文件
	
	返回值:
		void - 无返回值
	"""
	set_menu_item(menu_data.current_week, day, meal_type, recipe_name)

# 食材管理补充方法
func update_inventory_quantity(item_name: String, quantity_change: float) -> void:
	"""
	更新指定食材的数量

	参数:
		item_name: 食材名称
		quantity_change: 数量变化值（正数为增加，负数为减少）

	功能:
	1. 查找指定名称的食材
	2. 更新食材数量
	3. 确保数量不为负数
	4. 保存更新后的库存数据

	注意事项:
	- 如果未找到指定名称的食材，则不执行任何操作
	- 数量更新后会自动保存到文件

	返回值:
		void - 无返回值
	"""
	for uid in inventory_data.keys():
		var item = inventory_data[uid]
		if item.name == item_name:
			item.quantity += quantity_change
			if item.quantity < 0:
				item.quantity = 0
			inventory_data[uid] = item  # 更新字典中的值
			save_inventory()
			break

func check_inventory_low() -> Array:
	"""
	检查低库存食材

	功能:
	- 遍历库存，找出数量小于等于5的食材

	返回值:
		Array - 低库存食材数组
	"""
	var low_items = []
	for item in inventory_data.values():
		if item.quantity <= 5:
			low_items.append(item)
	return low_items

func check_expiring_items(days_ahead: int = 7) -> Array:
	"""
	检查即将过期的食材

	参数:
		days_ahead: 检查未来多少天内过期的食材，默认为7天

	实现细节:
	1. 获取当前日期
	2. 遍历库存中每个食材的过期日期
	3. 简单比较日期，判断是否在指定天数内过期

	注意事项:
	- 使用简单的日期比较方法，实际项目中应使用Date对象进行更准确计算
	- 当days_ahead >= 30时，也会检查下个月同一年的过期食材

	返回值:
		Array - 即将过期的食材数组
	"""
	var expiring_items = []
	var today_str = Time.get_datetime_string_from_system(false, true)
	var today_parts = today_str.split(" ")[0].split("-")
	var today = {}
	today["year"] = today_parts[0].to_int()
	today["month"] = today_parts[1].to_int()
	today["day"] = today_parts[2].to_int()
	
	for item in inventory_data.values():
		var expiry_date = item.expiry_date.split("-")
		var exp_year = expiry_date[0].to_int()
		var exp_month = expiry_date[1].to_int()
		var exp_day = expiry_date[2].to_int()
		
		# 简单的日期比较，实际应该使用Date对象进行准确计算
		if exp_year == today["year"] and exp_month == today["month"] and (exp_day - today["day"]) <= days_ahead:
			expiring_items.append(item)
		elif exp_year == today["year"] and exp_month == today["month"] + 1 and days_ahead >= 30:
			expiring_items.append(item)
		
	return expiring_items

# 任务管理补充方法
func get_today_tasks() -> Array:
	"""
	获取今日的任务列表

	功能:
	- 筛选出需要今日完成的任务
	- 包括设置为"每日"的任务和指定日期为今天的任务

	返回值:
		Array - 今日任务数组
	"""
	var today_tasks = []
	var today = Time.get_datetime_string_from_system(false, true).split(" ")[0]
	
	for task in task_data.values():
		# 同时支持旧的next_time和新的task_time字段，确保兼容性
		var task_time_value = task.get("task_time", task.get("next_time", ""))
		if task_time_value == "每日" or task_time_value == today:
			today_tasks.append(task)
		
	return today_tasks

func get_upcoming_tasks(days_ahead: int = 7) -> Array:
	"""
	获取即将到来的任务列表

	参数:
		days_ahead: 检查未来多少天内的任务，默认为7天

	功能:
	- 筛选出未完成且即将到来的任务
	- 包括设置为"每日"的任务和当前年份的任务

	实现细节:
	- 使用简单的字符串比较方法判断年份
	- 实际项目中应使用Date对象进行更准确的日期比较

	返回值:
		Array - 即将到来的任务数组
	"""
	var upcoming_tasks = []
	var today_str = Time.get_datetime_string_from_system(false, true)
	var today_parts = today_str.split(" ")[0].split("-")
	var today = {}
	today["year"] = today_parts[0].to_int()
	today["month"] = today_parts[1].to_int()
	today["day"] = today_parts[2].to_int()
	
	# 这里简化实现，实际应该使用Date对象进行准确的日期比较
	for task in task_data.values():
		# 同时支持旧的next_time和新的task_time字段，确保兼容性
		var task_time_value = task.get("task_time", task.get("next_time", ""))
		if not task.completed and (task_time_value == "每日" or task_time_value.begins_with(str(today["year"]))):
			upcoming_tasks.append(task)
			
	return upcoming_tasks
