extends BaseComponent
class_name DetectiveComponent

@export var area2d : Area2D

func _on_ready() -> void:
	var root = get_parent()
	if root.name == "Components":
		root = root.get_parent()
	
	area2d = Area2D.new()
	area2d.name = "DynamicArea2D"
	var collisionShape = CollisionShape2D.new()
	collisionShape.shape = RectangleShape2D.new()
	collisionShape.shape.extents = Vector2(400, 400)  # 设置碰撞形状的大小为10x10单位正方形
	area2d.add_child(collisionShape)
	root.call_deferred("add_child", area2d)
	area2d.collision_layer = 0
	area2d.collision_mask = 0
	if "entity" in root:
		if "team" in root.entity:
			#print("？ " + root.name + " " + GlobalEnv.TeamNames[root.entity.team])
			#print(GlobalEnv.TeamTableForEachAsEnemy[root.entity.team])
			for team in GlobalEnv.TeamTableForEachAsEnemy[root.entity.team]:
				area2d.set_collision_mask_value(team, true)
	#if "collision_layer" in root:
		#area2d.collision_layer = root.collision_layer  # 设置与层ID为1的物体交互
	#else:
		#area2d.collision_layer = 0
	#if "collision_mask" in root:
		#area2d.collision_mask = root.collision_mask  # 设置与层ID为1的物体交互
	#else:
		#area2d.collision_mask = 0
	area2d.monitorable = true  # 允许其他物体与之交互并连接信号
	area2d.connect("body_entered", self._on_body_entered)
	area2d.connect("body_exited", self.body_exited)

	self._init_entity()

func _init_entity():
	var root = get_parent()
	if root.name == "Components":
		root = root.get_parent()
	if not "entity" in root:
		return
	root.entity[GlobalEnv.EntityKeyNames.enemies] = {}
	root.entity[GlobalEnv.EntityKeyNames.teammates] = {}


func _on_body_entered(body):
	var root = get_root_node()
	
	if self.verbose:
		print(body.name + " enter " + root.name)
	
	# 有队伍组件的话，标记一下 enemies 和 teammates
	if has_component(self.get_root_node(), "TeamComponent") and has_component(body, "TeamComponent"):
		if not root.entity.team == body.entity.team:
			root.entity.enemies[body.entity.UID] = body.entity.UID
		elif root.entity.team == body.entity.team:
			root.entity.teammates[body.entity.UID] = body.entity.UID


func body_exited(body):
	var root = self.get_root_node()
	
	if self.verbose:
		print(body.name + " exit " + root.name)
	
	# 有队伍组件的话， 删除标记 enemies 和 teammates
	if has_component(self.get_root_node(), "TeamComponent") and has_component(body, "TeamComponent"):
		if not root.entity.team == body.entity.team:
			root.entity.enemies.erase(body.entity.UID)
		elif root.entity.team == body.entity.team:
			root.entity.teammates.erase(body.entity.UID)
