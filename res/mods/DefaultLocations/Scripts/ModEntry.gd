## ---------------------------------------------------------
## DefaultLocations 模块（基础地点数据）
##
## 功能说明：
## - 提供游戏初始地点数据（数码世界与现实世界）
## - 支持从 JSON 文件批量加载地点数据
## - 在 _on_mod_load() 加载 JSON
## - 在 _on_mod_enable() 注册地点和关系（更符合模块生命周期哲学）
##
## 地点数据格式（基于 Locations.json）：
## {
##   "name": "地点名称",
##   "Kanji/Kana": {"content": "日文名称", "url": "链接"},
##   "inhabitants": {"居民1": [{"text": "居民详情", "url": "链接"}]},
##   "url": "参考链接",
##   "introduce": "简介",
##   "description": "详细描述",
##   "type": {"content": "类型", "url": "链接"},
##   "location level type": "层级类型",
##   "version": "1.0.0"
## }
##
## 地点关系数据格式：
## "relationships": {
##   "父地点ID": ["子地点ID1", "子地点ID2", ...]
## }
##
## ---------------------------------------------------------

extends ModInterface

var _locations_data: Dictionary = {}   # 存储解析后的地点数据
var _relationships_data: Dictionary = {}   # 存储解析后的关系数据


# ---------------------------------------------------------
# 生命周期：模块加载（只加载 JSON，不注册）
# ---------------------------------------------------------
func _on_mod_load() -> bool:
	print("[DefaultLocations] 加载基础地点数据...")

	var json_path := "%s/Data/Locations.json" % get_mod_path()
	var file := FileAccess.open(json_path, FileAccess.READ)

	if file == null:
		push_warning("[DefaultLocations] 无法读取地点文件: %s" % json_path)
		return false

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("[DefaultLocations] JSON 格式错误: %s" % json_path)
		return false

	# 解析新的 JSON 结构
	var data_section: Dictionary = parsed.get("data", {})
	_locations_data = data_section.get("locations", {})
	_relationships_data = data_section.get("relationships", {})

	print("[DefaultLocations] JSON 加载完成，共 %d 个地点，%d 个关系" % [_locations_data.size(), _relationships_data.size()])
	return true


# ---------------------------------------------------------
# 生命周期：模块启用（此时依赖模块已启用）
# ---------------------------------------------------------
func _on_mod_enable() -> void:
	print("[DefaultLocations] 注册地点数据...")

	# 直接调用 LocationManager 的批量注册函数
	var json_path := "%s/Data/Locations.json" % get_mod_path()
	var ok = GameCore.mod_manager.call_mod(
		"LocationManager",
		"register_locations_from_json",
		json_path
	)

	if ok == null:
		push_warning("[DefaultLocations] 注册地点失败: LocationManager 模块未启用")
	else:
		print("[DefaultLocations] 地点和关系注册完成")


# ---------------------------------------------------------
# 获取当前 mod 的根目录
# ---------------------------------------------------------
func get_mod_path() -> String:
	return GameCore.mod_manager.loaded_mods[mod_name].path
