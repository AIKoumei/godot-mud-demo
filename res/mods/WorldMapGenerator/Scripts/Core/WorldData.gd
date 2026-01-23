# ============================================================
# WorldData.gd
# 世界数据容器（强类型）
# ============================================================

class_name WorldData
extends Resource

@export var width: int = 0
@export var height: int = 0

var heightmap: Array = []
var temperature: Array = []
var humidity: Array = []
var water_amount: Array = []
var river: Array = []
var biome: Array = []
var region_id: Array = []

func init_arrays() -> void:
	heightmap = []
	temperature = []
	humidity = []
	water_amount = []
	river = []
	biome = []
	region_id = []

	heightmap.resize(width)
	temperature.resize(width)
	humidity.resize(width)
	water_amount.resize(width)
	river.resize(width)
	biome.resize(width)
	region_id.resize(width)

	for x: int in range(width):
		var row_h: Array = []
		var row_t: Array = []
		var row_wet: Array = []
		var row_water: Array = []
		var row_river: Array = []
		var row_biome: Array = []
		var row_region: Array = []

		row_h.resize(height)
		row_t.resize(height)
		row_wet.resize(height)
		row_water.resize(height)
		row_river.resize(height)
		row_biome.resize(height)
		row_region.resize(height)

		for y: int in range(height):
			row_h[y] = 0.0
			row_t[y] = 0.0
			row_wet[y] = 0.0
			row_water[y] = 0.0
			row_river[y] = false
			row_biome[y] = ""
			row_region[y] = -1

		heightmap[x] = row_h
		temperature[x] = row_t
		humidity[x] = row_wet
		water_amount[x] = row_water
		river[x] = row_river
		biome[x] = row_biome
		region_id[x] = row_region
