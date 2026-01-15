extends Area2D


class_name BaseSceneItem


@export var entity = EntityManager.create_entity()


# ##############################################################################
# funcs
# ##############################################################################


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	EntityManager.regist_entity(self.entity, self)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _physics_process(delta: float) -> void:
	self.update_entity()


# ##############################################################################
# funcs
# ##############################################################################

## 用于 item 被放入 pool 的时候清空/重置状态
func empty():
	pass


func reactive():
	pass


func init_entity():
	pass


func update_entity() -> void:
	self.entity.position = self.global_position
	self.entity.direction = Vector2.RIGHT.rotated(self.global_rotation)


# ##############################################################################
# END
# ##############################################################################
