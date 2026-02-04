## res://mods/MudEntityInteractionSystem/Scripts/ModEntry.gd
## --------------------------------------------------------------------------
## MudEntityInteractionSystem (MEIS)
## 
## 功能：
## - 基于 Dictionary 实体的动作权限管理与执行引擎
## - 支持 Action Overriding (逻辑重写) 与 Middleware Pipeline (过程拦截)
## - 支持通过 config.json 自动化注册 Mod 资源
## 
## config.json 结构示例:
## {
##   "metadata": {
##     "name": "潜行包",                      // Mod 逻辑名称
##     "version": "1.0.0"                    // 版本信息
##   },
##   "data": {
##     "actions": {                          // 定义具体动作
##       "stealth_move": {
##         "script_path": "stealth_move.gd", // 脚本相对路径
##         "name": "潜行"                    // UI 显示名称
##       },
##       "fast_open": {
##         "script_path": "fast_open.gd",
##         "name": "快速解锁",
##         "action_overrides": "open"        // 声明重写逻辑：当发起 open 时，若实体拥有此动作则强制指向 fast_open
##       }
##     },
##     "action_groups": {                    // 定义动作组，用于批量挂载
##       "thief_set": {
##         "stealth_move": true,
##         "fast_open": true
##       }
##     }
##   }
## }
## --------------------------------------------------------------------------
extends ModInterface

# --- 资源存储 ---
var _registered_actions: Dictionary = {}  # { action_id: MudEntityAction }
var _action_groups: Dictionary     = {}  # { group_id: [action_id, ...] }
var _middlewares: Array            = []  # [Callable]

# --------------------------------------------------------------------------
# 1. 模块通信入口 (Module Interface)
# --------------------------------------------------------------------------

func call_mod(func_name: String, data: Dictionary):
	match func_name:
		# 引擎核心
		"execute":               return execute_action(data.get("action_id", ""), data.get("source", {}), data.get("target", {}))
		"get_available_actions": return get_available_actions(data.get("source", {}), data.get("target", {}))
		"add_middleware":        _middlewares.append(data.get("middleware"))
		
		# 资源管理
		"register_mod_actions":  return scan_and_register_mod(data.get("path", ""), data.get("mod_id", "unknown"))
		
		# 实体权限操作 (单个)
		"mount_action":          return mount_action(data.get("entity", {}), data.get("action_id", ""))
		"unmount_action":        return unmount_action(data.get("entity", {}), data.get("action_id", ""))
		
		# 实体权限操作 (批量)
		"mount_group":           mount_action_group(data.get("entity", {}), data.get("group_id", ""))
		"unmount_group":         unmount_action_group(data.get("entity", {}), data.get("group_id", ""))
		
	push_warning("[MEIS] 未知指令: %s" % func_name)
	return null

# --------------------------------------------------------------------------
# 2. 交互引擎核心 (Core Engine)
# --------------------------------------------------------------------------

## 执行一个动作
func execute_action(action_id: String, source: Dictionary, target: Dictionary) -> Dictionary:
	# 1. 处理 Action Overriding (逻辑重写)
	var final_id = action_id
	var overrides = _get_attr(source, "action_overrides", {})
	if overrides.has(action_id):
		final_id = overrides[action_id]
	
	# 2. 查找动作实现
	var action = _registered_actions.get(final_id)
	if not action:
		return {"status": "error", "msg": "未找到动作逻辑: " + final_id}

	# 3. 进入管道并执行
	return _run_pipeline(action, source, target)


## 获取实体当前对目标可用的动作列表
func get_available_actions(source: Dictionary, target: Dictionary) -> Array:
	var result = []
	var actions_map = _get_attr(source, "actions", {})
	
	for aid in actions_map:
		# 必须权限开启且逻辑已注册
		if actions_map[aid] == true and _registered_actions.has(aid):
			var act = _registered_actions[aid]
			if act.can_perform(source, target):
				result.append({
					"id": act.action_id, 
					"label": act.action_label
				})
	return result


## 执行中间件管道
func _run_pipeline(action: MudEntityAction, source: Dictionary, target: Dictionary) -> Dictionary:
	# TODO: 未来可扩展为支持 next() 调用链的异步模式
	for mw in _middlewares:
		if mw is Callable:
			if not mw.call(action, source, target):
				return {"status": "blocked", "msg": "操作被系统拦截"}
				
	return action.execute(source, target)

# --------------------------------------------------------------------------
# 3. 实体字典操作 (Entity Dictionary Helpers)
# --------------------------------------------------------------------------

## 安全获取实体属性
func _get_attr(entity: Dictionary, key: String, default = null):
	return entity.get("data", {}).get("attributes", {}).get(key, default)


## 挂载单个动作权限
func mount_action(entity: Dictionary, action_id: String) -> bool:
	if action_id == "": return false
	
	# 确保嵌套字典结构路径存在
	if not entity.has("data"): entity["data"] = {}
	if not entity.data.has("attributes"): entity.data["attributes"] = {}
	if not entity.data.attributes.has("actions"): entity.data.attributes["actions"] = {}
	
	entity.data.attributes.actions[action_id] = true
	return true


## 卸载单个动作权限
func unmount_action(entity: Dictionary, action_id: String) -> bool:
	var actions = _get_attr(entity, "actions")
	if actions is Dictionary and actions.has(action_id):
		actions.erase(action_id)
		return true
	return false


## 批量挂载
func mount_action_group(entity: Dictionary, group_id: String) -> void:
	if _action_groups.has(group_id):
		for aid in _action_groups[group_id]:
			mount_action(entity, aid)


## 批量卸载
func unmount_action_group(entity: Dictionary, group_id: String) -> void:
	if _action_groups.has(group_id):
		for aid in _action_groups[group_id]:
			unmount_action(entity, aid)

# --------------------------------------------------------------------------
# 4. 资源注册 (Resource Registration)
# --------------------------------------------------------------------------

## 扫描目录并根据 config.json 注册动作
func scan_and_register_mod(dir_path: String, mod_id: String) -> bool:
	var config_path = dir_path.path_join("config.json")
	if not FileAccess.file_exists(config_path):
		push_error("[MEIS] Mod [%s] 缺失 config.json" % mod_id)
		return false
	
	var json_data = JSON.parse_string(FileAccess.get_file_as_string(config_path))
	if not json_data or not json_data.has("data"): 
		return false
	
	var data = json_data.data
	
	# A. 注册 Actions
	var act_cfg = data.get("actions", {})
	for aid in act_cfg:
		_load_action_resource(aid, act_cfg[aid], dir_path)
	
	# B. 注册 Groups
	var grp_cfg = data.get("action_groups", {})
	for gid in grp_cfg:
		_action_groups[gid] = grp_cfg[gid].keys()
	
	print("[MEIS] Mod [%s] 动作资源加载完毕" % mod_id)
	return true


## 内部方法：加载脚本资源并实例化
func _load_action_resource(aid: String, info: Dictionary, dir_path: String):
	var script_path = dir_path.path_join(info.get("script_path", ""))
	if not FileAccess.file_exists(script_path):
		push_error("[MEIS] 动作脚本不存在: %s" % script_path)
		return

	var script = load(script_path)
	if script:
		var inst = script.new() as MudEntityAction
		inst.action_id = aid
		inst.action_label = info.get("name", aid)
		
		# 存储 Overriding 元数据供外部可能的扩展查询
		if info.has("action_overrides"):
			inst.set_meta("overrides", info["action_overrides"])
			
		_registered_actions[aid] = inst
