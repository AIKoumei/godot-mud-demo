# ============================================================
# TownData.gd
# 城镇生成的数据容器
# ============================================================

class_name TownData
extends Resource

@export var width: int = 120
@export var height: int = 80

# 每个格子的类型：outside / inside / wall / gate / road / lot
var cell_type: Array = []

func init_arrays() -> void:
	cell_type = []
	cell_type.resize(width)
	for x in range(width):
		var row: Array = []
		row.resize(height)
		for y in range(height):
			row[y] = "outside"
		cell_type[x] = row
