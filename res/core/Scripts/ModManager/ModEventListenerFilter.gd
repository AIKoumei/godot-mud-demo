extends Resource
class_name ModEventListenerFilter

# ---------------------------------------------------------
# 枚举（使用 const 字典）
# ---------------------------------------------------------
const ModFilterType := {
	"ANY": "ANY",
	"TARGET": "TARGET",
}

const EventFilterType := {
	"ANY": "ANY",
	"TARGET": "TARGET",
}

const ListenType := {
	"ALWAYS": "ALWAYS",
	"ONCE": "ONCE",
}

# ---------------------------------------------------------
# 属性字段（全部是 String）
# ---------------------------------------------------------
var mod_filter_type: String = ModFilterType.ANY
var mod_name: String = ""

var event_filter_type: String = EventFilterType.ANY
var event_name: String = ""

var listen_type: String = ListenType.ALWAYS


# ---------------------------------------------------------
# Getter / Setter（链式调用）
# ---------------------------------------------------------

# --- mod_filter_type ---
func get_mod_filter_type() -> String:
	return mod_filter_type

func set_mod_filter_type(value: String) -> ModEventListenerFilter:
	mod_filter_type = value
	return self


# --- mod_name ---
func get_mod_name() -> String:
	return mod_name

func set_mod_name(value: String) -> ModEventListenerFilter:
	mod_name = value
	return self


# --- event_filter_type ---
func get_event_filter_type() -> String:
	return event_filter_type

func set_event_filter_type(value: String) -> ModEventListenerFilter:
	event_filter_type = value
	return self


# --- event_name ---
func get_event_name() -> String:
	return event_name

func set_event_name(value: String) -> ModEventListenerFilter:
	event_name = value
	return self


# --- listen_type ---
func get_listen_type() -> String:
	return listen_type

func set_listen_type(value: String) -> ModEventListenerFilter:
	listen_type = value
	return self


# ---------------------------------------------------------
# 匹配逻辑（保持你原来的结构）
# ---------------------------------------------------------
func matches(from_mod: String, incoming_event: String) -> bool:
	# mod 匹配
	if mod_filter_type == ModFilterType.TARGET and mod_name != from_mod:
		return false

	# event 匹配
	if event_filter_type == EventFilterType.TARGET and event_name != incoming_event:
		return false

	return true
