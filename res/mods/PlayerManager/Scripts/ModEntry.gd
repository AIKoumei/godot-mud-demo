## ---------------------------------------------------------
## PlayerManager 模块
##
## 功能说明：
## - 处理玩家的各种功能逻辑
## - 管理玩家实体的创建、初始化、加载和保存
## - 保存玩家数据（金钱、道具）
## - 处理道具的获取、失去和消耗
## - 预留通过 on mod event 接收 input event 来控制 player entity 与地图的交互
##
## 依赖：
## - ModInterface（基础接口）
## - EntityManager（实体管理）
## - EntityInstanceManager（实体实例管理）
## - WorldMapInstanceManager（世界地图实例管理）
##
## 生命周期：
## - _on_mod_load()：模块加载时调用（进入场景树前）
## - _on_mod_init()：模块初始化时调用（进入场景树，_ready）
## - _on_mod_enable()：模块启用时调用
## - _on_mod_disable()：模块禁用时调用
## - _on_mod_unload()：模块卸载时调用
## - _on_mod_event()：接收其他 mod 发送的事件
##
## ---------------------------------------------------------
extends ModInterface

## 玩家数据结构
var _player_data: Dictionary = {
	"entity_instance_id": "",
	"money": 0,
	"inventory": {}, # {item_id: amount}
	"stats": {
		"level": 1,
		"exp": 0,
		"max_exp": 100,
		"health": 100,
		"max_health": 100,
		"mana": 50,
		"max_mana": 50
	}
}



## 生命周期：模块加载
func _on_mod_load() -> bool:
	var is_load_succeed = super._on_mod_load()
	print("[PlayerManager] 模块已加载")
	
	# 注册事件监听器
	register_event_listener_with_name(ModEventListenerFilter.new()
		.set_listen_type(ModEventListenerFilter.ListenType.ALWAYS)
		.set_mod_filter_type(ModEventListenerFilter.ModFilterType.ANY)
		.set_event_filter_type(ModEventListenerFilter.EventFilterType.TARGET)
		.set_event_name("SavePlayerData")
		, "SavePlayerData"
	)
	
	register_event_listener_with_name(ModEventListenerFilter.new()
		.set_listen_type(ModEventListenerFilter.ListenType.ALWAYS)
		.set_mod_filter_type(ModEventListenerFilter.ModFilterType.ANY)
		.set_event_filter_type(ModEventListenerFilter.EventFilterType.TARGET)
		.set_event_name("LoadPlayerData")
		, "LoadPlayerData"
	)
	
	return is_load_succeed

## 生命周期：模块初始化
func _on_mod_init() -> void:
	super._on_mod_init()
	# 初始化玩家数据
	_init_player_data()

## 生命周期：模块启用
func _on_mod_enable() -> void:
	super._on_mod_enable()
	# 入口场景已经实例化，可以开始逻辑
	print("[PlayerManager] 模块已启用")

## 生命周期：模块禁用（未来支持）
func _on_mod_disable() -> void:
	super._on_mod_disable()
	# 清理 UI、暂停逻辑等
	print("[PlayerManager] 模块已禁用")

## 生命周期：模块卸载
func _on_mod_unload() -> void:
	super._on_mod_unload()
	# 清理资源、断开信号、保存数据等
	save_player_data()
	print("[PlayerManager] 模块已卸载")

## 模块间通信
func _on_mod_event(_mod_name: String, event_name: String, event_data: Dictionary) -> void:
	super._on_mod_event(_mod_name, event_name, event_data)
	
	# 处理保存玩家数据事件
	if event_name == "SavePlayerData":
		save_player_data()
	
	# 处理加载玩家数据事件
	elif event_name == "LoadPlayerData":
		load_player_data()
	
	# 预留处理 input event 的逻辑
	# TODO: 处理 input event 来控制 player entity 与地图的交互

## 初始化玩家数据
func _init_player_data() -> void:
	_player_data = {
		"entity_instance_id": "",
		"money": 0,
		"inventory": {},
		"stats": {
			"level": 1,
			"exp": 0,
			"max_exp": 100,
			"health": 100,
			"max_health": 100,
			"mana": 50,
			"max_mana": 50
		}
	}

# ---------------------------------------------------------
# 玩家实体管理
# ---------------------------------------------------------

## 创建玩家实体
## @param player_id: 玩家实体模板 ID
## @param player_cfg: 玩家配置数据
## @return 返回玩家实体实例 ID
func create_player_entity(player_id: String = "player", player_cfg: Dictionary = {}) -> String:
	# 通过 EntityInstanceManager 暴露的接口创建玩家实体
	player_cfg["entity_id"] = player_id
	var player_entity = GameCore.mod_manager.call_mod(
		"EntityInstanceManager",
		"create_entity",
		player_cfg
	)
	
	if player_entity == null or player_entity.is_empty():
		push_error("[PlayerManager] 创建玩家实体失败")
		return ""
	
	var instance_id = player_entity.get("instance_id", "")
	if instance_id != "":
		_player_data["entity_instance_id"] = instance_id
		print("[PlayerManager] 玩家实体创建成功: %s" % instance_id)
	
	return instance_id

## 初始化玩家实体
## @param instance_id: 玩家实体实例 ID
func init_player_entity(instance_id: String) -> void:
	if instance_id == "":
		push_warning("[PlayerManager] 无效的玩家实体实例 ID")
		return
	
	_player_data["entity_instance_id"] = instance_id
	print("[PlayerManager] 玩家实体初始化成功: %s" % instance_id)

## 加载玩家实体
func load_player_entity() -> void:
	var instance_id = _player_data.get("entity_instance_id", "")
	if instance_id != "":
		init_player_entity(instance_id)

## 保存玩家实体
func save_player_entity() -> void:
	# 玩家实体数据通过 EntityInstanceManager 保存
	# TODO: 实现玩家实体的保存逻辑
	pass

# ---------------------------------------------------------
# 玩家数据管理
# ---------------------------------------------------------

## 获取玩家数据
## @return 返回玩家数据字典
func get_player_data() -> Dictionary:
	return _player_data.duplicate(true)

## 保存玩家数据
func save_player_data() -> void:
	if GameCore.debugging:
		print("[PlayerManager] 保存玩家数据")
	
	SaveManager.save_mod_slot_data(
		GameCore.Settings.GameSettings.GameSlot,
		"%s/player_data" % mod_name,
		_player_data
	)

## 加载玩家数据
func load_player_data() -> void:
	if SaveManager.has_mod_slot_file(
		GameCore.Settings.GameSettings.GameSlot,
		"%s/player_data.sav" % mod_name
	):
		var loaded_data = SaveManager.load_mod_slot_data(
			GameCore.Settings.GameSettings.GameSlot,
			"%s/player_data" % mod_name
		)
		
		if loaded_data != null and not loaded_data.is_empty():
			_player_data = loaded_data
			print("[PlayerManager] 玩家数据加载成功")
			# 加载玩家实体
			load_player_entity()
		else:
			print("[PlayerManager] 玩家数据加载失败，使用默认数据")
			_init_player_data()
	else:
		print("[PlayerManager] 玩家数据文件不存在，使用默认数据")
		_init_player_data()

# ---------------------------------------------------------
# 金钱管理
# ---------------------------------------------------------

## 获取玩家金钱
## @return 返回玩家当前金钱数量
func get_money() -> int:
	return _player_data.get("money", 0)

## 设置玩家金钱
## @param amount: 金钱数量
func set_money(amount: int) -> void:
	_player_data["money"] = max(0, amount)

## 增加玩家金钱
## @param amount: 增加的金钱数量
func add_money(amount: int) -> void:
	if amount > 0:
		_player_data["money"] += amount
		print("[PlayerManager] 获得 %d 金钱" % amount)

## 减少玩家金钱
## @param amount: 减少的金钱数量
## @return 返回是否减少成功
func remove_money(amount: int) -> bool:
	if amount > 0 and _player_data.get("money", 0) >= amount:
		_player_data["money"] -= amount
		print("[PlayerManager] 花费 %d 金钱" % amount)
		return true
	return false

# ---------------------------------------------------------
# 道具管理
# ---------------------------------------------------------

## 获取玩家背包
## @return 返回玩家背包字典
func get_inventory() -> Dictionary:
	return _player_data.get("inventory", {}).duplicate(true)

## 获取道具数量
## @param item_id: 道具 ID
## @return 返回道具数量
func get_item_amount(item_id: String) -> int:
	return _player_data.get("inventory", {}).get(item_id, 0)

## 添加道具
## @param item_id: 道具 ID
## @param amount: 道具数量
func add_item(item_id: String, amount: int) -> void:
	if item_id == "" or amount <= 0:
		return
	
	if not _player_data.has("inventory"):
		_player_data["inventory"] = {}
	
	var current_amount = _player_data["inventory"].get(item_id, 0)
	_player_data["inventory"][item_id] = current_amount + amount
	print("[PlayerManager] 获得 %d 个 %s" % [amount, item_id])

## 移除道具
## @param item_id: 道具 ID
## @param amount: 道具数量
## @return 返回是否移除成功
func remove_item(item_id: String, amount: int) -> bool:
	if item_id == "" or amount <= 0:
		return false
	
	var current_amount = _player_data.get("inventory", {}).get(item_id, 0)
	if current_amount >= amount:
		_player_data["inventory"][item_id] = current_amount - amount
		
		# 如果道具数量为 0，从背包中移除
		if _player_data["inventory"][item_id] <= 0:
			_player_data["inventory"].erase(item_id)
		
		print("[PlayerManager] 失去 %d 个 %s" % [amount, item_id])
		return true
	
	return false

## 消耗道具
## @param item_id: 道具 ID
## @param amount: 道具数量
## @return 返回是否消耗成功
func consume_item(item_id: String, amount: int) -> bool:
	# 消耗道具逻辑与移除道具相同
	return remove_item(item_id, amount)

# ---------------------------------------------------------
# 玩家属性管理
# ---------------------------------------------------------

## 获取玩家属性
## @param stat_name: 属性名称
## @return 返回属性值
func get_player_stat(stat_name: String) -> int:
	return _player_data.get("stats", {}).get(stat_name, 0)

## 设置玩家属性
## @param stat_name: 属性名称
## @param value: 属性值
func set_player_stat(stat_name: String, value: int) -> void:
	if not _player_data.has("stats"):
		_player_data["stats"] = {}
	
	_player_data["stats"][stat_name] = value

## 增加玩家属性
## @param stat_name: 属性名称
## @param value: 增加的值
func add_player_stat(stat_name: String, value: int) -> void:
	if not _player_data.has("stats"):
		_player_data["stats"] = {}
	
	var current_value = _player_data["stats"].get(stat_name, 0)
	_player_data["stats"][stat_name] = current_value + value

# ---------------------------------------------------------
# 外部访问
# ---------------------------------------------------------

## 获取玩家实体实例 ID
func get_player_entity_instance_id() -> String:
	return _player_data.get("entity_instance_id", "")

## 获取玩家实体
## @return 通过 EntityInstanceManager 获取的玩家实体数据
func get_player_entity() -> Dictionary:
	var instance_id = _player_data.get("entity_instance_id", "")
	if instance_id == "":
		return {}
	
	# 通过 EntityInstanceManager 获取玩家实体
	return GameCore.mod_manager.call_mod(
		"EntityInstanceManager",
		"get_entity",
		instance_id
	)

## 检查玩家是否有足够的金钱
## @param amount: 需要的金钱数量
## @return 返回是否有足够的金钱
func has_enough_money(amount: int) -> bool:
	return _player_data.get("money", 0) >= amount

## 检查玩家是否有足够的道具
## @param item_id: 道具 ID
## @param amount: 需要的道具数量
## @return 返回是否有足够的道具
func has_enough_item(item_id: String, amount: int) -> bool:
	return _player_data.get("inventory", {}).get(item_id, 0) >= amount
