extends Node

# ---------------------------------------------------------
# 参数
# ---------------------------------------------------------
@export var max_history: int = 200
@export var sample_interval: float = 0.1

@export var fps_color: Color = Color(0.2, 1.0, 0.2, 1.0)
@export var dc_color: Color = Color(0.2, 0.6, 1.0, 1.0)

@export var bg_color: Color = Color(0, 0, 0, 0.4)
@export var axis_color: Color = Color(0.8, 0.8, 0.8, 0.8)

# ---------------------------------------------------------
# 数据
# ---------------------------------------------------------
var fps_history: Array[float] = []
var dc_history: Array[int] = []

var _time_accum: float = 0.0
var _last_fps: int = -1
var _last_dc: int = -1

# ---------------------------------------------------------
# 动态节点引用
# ---------------------------------------------------------
var canvas: CanvasLayer
var control: Control
var vbox_root: VBoxContainer
var menu_bar: HBoxContainer
var btn_show: Button
var btn_hide: Button
var vbox_debug: VBoxContainer

var fps_container: FoldableContainer
var fps_viewer: Control

var dc_container: FoldableContainer
var dc_viewer: Control


# ---------------------------------------------------------
# 初始化
# ---------------------------------------------------------
func _ready() -> void:
	_create_canvas_layer()
	_create_ui()
	_set_mouse_filter_recursive(canvas)

	set_process(true)

	fps_viewer.connect("draw", Callable(self, "_on_fps_draw"))
	dc_viewer.connect("draw", Callable(self, "_on_dc_draw"))

	btn_show.pressed.connect(_on_show_pressed)
	btn_hide.pressed.connect(_on_hide_pressed)


# ---------------------------------------------------------
# 创建 CanvasLayer
# ---------------------------------------------------------
func _create_canvas_layer() -> void:
	canvas = CanvasLayer.new()
	canvas.name = "DebugInofViewer"
	canvas.layer = 100
	get_tree().root.get_node_or_null("Main").add_child(canvas)


# ---------------------------------------------------------
# 创建 UI（完全复刻你原来的场景）
# ---------------------------------------------------------
func _create_ui() -> void:
	control = Control.new()
	control.anchor_right = 1.0
	control.anchor_bottom = 1.0
	control.grow_horizontal = Control.GROW_DIRECTION_BOTH
	control.grow_vertical = Control.GROW_DIRECTION_BOTH
	canvas.add_child(control)

	vbox_root = VBoxContainer.new()
	vbox_root.custom_minimum_size = Vector2(256, 0)
	control.add_child(vbox_root)

	menu_bar = HBoxContainer.new()
	vbox_root.add_child(menu_bar)

	btn_show = Button.new()
	btn_show.text = "▶︎ DebugView"
	btn_show.add_theme_font_size_override("font_size", 18)
	menu_bar.add_child(btn_show)

	btn_hide = Button.new()
	btn_hide.text = "◀︎ HideDebugView"
	btn_hide.visible = false
	btn_hide.add_theme_font_size_override("font_size", 18)
	menu_bar.add_child(btn_hide)

	vbox_debug = VBoxContainer.new()
	vbox_debug.visible = false
	vbox_debug.custom_minimum_size = Vector2(256, 0)
	vbox_root.add_child(vbox_debug)

	fps_container = FoldableContainer.new()
	fps_container.title = "FPS"
	vbox_debug.add_child(fps_container)

	fps_viewer = Control.new()
	fps_viewer.custom_minimum_size = Vector2(0, 64)
	fps_container.add_child(fps_viewer)

	dc_container = FoldableContainer.new()
	dc_container.title = "DrawCalls"
	vbox_debug.add_child(dc_container)

	dc_viewer = Control.new()
	dc_viewer.custom_minimum_size = Vector2(0, 64)
	dc_container.add_child(dc_viewer)


# ---------------------------------------------------------
# 鼠标过滤：除了 Button 以外全部 IGNORE
# ---------------------------------------------------------
func _set_mouse_filter_recursive(node: Node) -> void:
	if node is Control and not (node is Button):
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE

	for child in node.get_children():
		_set_mouse_filter_recursive(child)


# ---------------------------------------------------------
# 显隐按钮逻辑
# ---------------------------------------------------------
func _on_show_pressed() -> void:
	vbox_debug.visible = true
	btn_show.visible = false
	btn_hide.visible = true


func _on_hide_pressed() -> void:
	vbox_debug.visible = false
	btn_show.visible = true
	btn_hide.visible = false


# ---------------------------------------------------------
# 采样 FPS + DrawCalls
# ---------------------------------------------------------
func _process(delta: float) -> void:
	_time_accum += delta

	if _time_accum >= sample_interval:
		_time_accum = 0.0
		_record_metrics()

	fps_viewer.queue_redraw()
	dc_viewer.queue_redraw()


func _record_metrics() -> void:
	var fps: int = Engine.get_frames_per_second()
	var dc: int = Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)

	fps_history.append(float(fps))
	dc_history.append(dc)

	if fps_history.size() > max_history:
		fps_history.pop_front()
		dc_history.pop_front()

	if fps != _last_fps:
		_last_fps = fps
		fps_container.title = "FPS (%d)" % fps

	if dc != _last_dc:
		_last_dc = dc
		dc_container.title = "DrawCalls (%d)" % dc

		var color: Color
		if dc < 500:
			color = Color(0.2, 0.6, 1.0)      # 蓝色
		elif dc < 750:
			color = Color(0.2, 1.0, 0.2)      # 绿色
		elif dc < 1000:
			color = Color(1.0, 0.6, 0.2)      # 橙色
		else:
			color = Color(1.0, 0.2, 0.2)      # 红色

		dc_container.add_theme_color_override("font_color", color)



# ---------------------------------------------------------
# FPS 绘图
# ---------------------------------------------------------
func _on_fps_draw() -> void:
	_draw_graph(fps_viewer, fps_history, fps_color)


# ---------------------------------------------------------
# DrawCalls 绘图
# ---------------------------------------------------------
func _on_dc_draw() -> void:
	_draw_graph(dc_viewer, dc_history, dc_color)


# ---------------------------------------------------------
# 通用绘图函数
# ---------------------------------------------------------
func _draw_graph(viewer: Control, data: Array, color: Color) -> void:
	var rect := viewer.get_rect()
	viewer.draw_rect(rect, bg_color, true)

	if data.size() < 2:
		return

	var graph_rect := Rect2(40, 10, rect.size.x - 50, rect.size.y - 20)

	var max_value: float = max(data.max(), 1.0)

	var steps := 3
	for i in range(steps + 1):
		var t: float = float(i) / float(steps)
		var y: float = graph_rect.position.y + graph_rect.size.y * (1.0 - t)
		var value: int = int(max_value * t)

		viewer.draw_line(
			Vector2(graph_rect.position.x - 6, y),
			Vector2(graph_rect.position.x, y),
			axis_color,
			1.5
		)

		viewer.draw_string(
			ThemeDB.fallback_font,
			Vector2(5, y + 5),
			str(value),
			HORIZONTAL_ALIGNMENT_LEFT,
			-1.0,
			14,
			axis_color
		)

	var points: Array[Vector2] = []
	var count: int = data.size()

	for i in range(count):
		var t: float = float(i) / float(max_history - 1)
		var x: float = graph_rect.position.x + t * graph_rect.size.x

		var v: float = float(data[i])
		var y_norm: float = v / max_value
		var y: float = graph_rect.position.y + graph_rect.size.y * (1.0 - y_norm)

		points.append(Vector2(x, y))

	for i in range(points.size() - 1):
		viewer.draw_line(points[i], points[i + 1], color, 2.0)
