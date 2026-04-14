extends RefCounted
class_name _GameSettings


@export var WorldSeed = randi()

# save file slot
@export var GameSlot = 0

# 玩家出生地图
@export var PlayerSpawnMapId = ""
@export var PlayerSpawnMapPosition = Vector2i.ZERO
