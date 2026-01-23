extends CanvasLayer
class_name DebugInfoViewer

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
# 节点引用（完全匹配你贴出的场景）
# ---------------------------------------------------------
@onready var btn_show: Button = $Control/VBoxContainer/MenuBar/ShowDebugView
@onready var btn_hide: Button = $Control/VBoxContainer/MenuBar/HideDebugView

@onready var vbox_debug: VBoxContainer = $Control/VBoxContainer/VBoxDebugView

@onready var fps_container: FoldableContainer = $Control/VBoxContainer/VBoxDebugView/FPSViewerContainer
@onready var fps_viewer: Control = $Control/VBoxContainer/VBoxDebugView/FPSViewerContainer/FPSViewer

@onready var dc_container: FoldableContainer = $Control/VBoxContainer/VBoxDebugView/DrawCallsContainer
@onready var dc_viewer: Control = $Control/VBoxContainer/VBoxDebugView/DrawCallsContainer/DrawCallsViewer


# ---------------------------------------------------------
# 初始化
# ---------------------------------------------------------
func _ready() -> void:
	set_process(true)

	# 连接绘图信号
	fps_viewer.connect("draw", Callable(self, "_on_fps_draw"))
	dc_viewer.connect("draw", Callable(self, "_on_dc_draw"))

	# 按钮
	btn_show.pressed.connect(_on_show_pressed)
	btn_hide.pressed.connect(_on_hide_pressed)


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

	# Y 轴刻度
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

	# 曲线
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
