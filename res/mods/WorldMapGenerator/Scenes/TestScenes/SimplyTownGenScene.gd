extends Node2D

# ============================================================
# SimplyTownGenScene.gd
# 用于可视化 SimplyTownGen 生成的城镇（节点 + PATH）
# - 点击 Gen 按钮重新生成
# - 使用颜色网格绘制节点图
# ============================================================

@export var cell_size: int = 16

var town_data = null
var color_grid := []
var grid_w := 0
var grid_h := 0


func _ready() -> void:
	# 绑定按钮
	var gen_button := $CanvasLayer/Control/HBoxContainer/GenButton
	gen_button.pressed.connect(_on_gen_pressed)

	_generate_and_render()


# ------------------------------------------------------------
# 点击按钮：重新生成城镇
# ------------------------------------------------------------
func _on_gen_pressed() -> void:
	_generate_and_render()


# ------------------------------------------------------------
# 生成 + 转换为颜色网格 + 请求重绘
# ------------------------------------------------------------
func _generate_and_render() -> void:
	# 1. 生成城镇（你可以在这里调参）
	town_data = SimplyTownGen.generate_town(
		"",      # shape_type（空字符串 = 随机）
		12,      # building_count
		4,       # branch_count
		randi()  # seed
	)

	# 2. 转成颜色网格（包含 PATH）
	color_grid = SimplyTownGen.to_color_grid_with_paths(town_data, 1.0)

	grid_w = color_grid.size()
	grid_h = color_grid[0].size()

	# 3. 重绘
	queue_redraw()


# ------------------------------------------------------------
# 绘制函数：把 color_grid 渲染到屏幕
# ------------------------------------------------------------
func _draw() -> void:
	if color_grid.is_empty():
		return

	for x in range(grid_w):
		for y in range(grid_h):
			var c: Color = color_grid[x][y]
			if c.a > 0.0:
				draw_rect(
					Rect2(
						Vector2(x * cell_size, y * cell_size),
						Vector2(cell_size, cell_size)
					),
					c
				)
