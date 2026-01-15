extends CharacterBody2D

class_name BaseSkill

@export var entity = EntityManager.create_skill_instance_entity()


func init_by_skill_id(skill_id):
	var skill_configs = SkillUtil.load_skill_configs(skill_id)
	EntityManager.apply_entity(self.entity, skill_configs)
	self.name = self.entity.skill_type


func init_by_onwer_entity(owner_entity):
	var onwer_node = EntityManager.get_related_node_by_entity_uid(owner_entity.UID)
	self.entity.team = owner_entity.team
	self.entity.position = onwer_node.position
	self.entity.direction = Vector2.RIGHT.rotated(onwer_node.global_rotation)
	for team in GlobalEnv.TeamTableForEachAsEnemy:
		self.set_collision_mask_value(team, true)
	self.position = self.entity.position
	self.rotation = self.entity.direction.angle()


func hit(target) -> void:
	pass # Replace with function body.


# ##############################################################################
# funcs
# ##############################################################################


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#if self.entity.active_status == GlobalEnv.STATIC_ActiveStatus.Pause:
		#self.process_mode = Node.PROCESS_MODE_DISABLED
		#return
	#if self.entity.active_status == GlobalEnv.STATIC_ActiveStatus.Dead:
		#self.drop_to_trush()
		#return 
	## check if dead	
	#if self.entity.hp <= 0:
		#self.entity.active_status = GlobalEnv.STATIC_ActiveStatus.Dead
	#elif self.entity.lifetime <= 0:
		#self.entity.active_status = GlobalEnv.STATIC_ActiveStatus.Dead
	## pass time
	#self.entity.lifetime = max(0, self.entity.lifetime - delta)
	## skip if in freaze status
	#if self.entity.active_status == GlobalEnv.STATIC_ActiveStatus.Freaze:
		#return


func _physics_process(delta: float) -> void:
	if self.entity.active_status == GlobalEnv.STATIC_ActiveStatus.Pause:
		self.process_mode = Node.PROCESS_MODE_DISABLED
		return
	if self.entity.active_status == GlobalEnv.STATIC_ActiveStatus.Dead:
		self.drop_to_trush()
		return 
	# check if dead	
	if self.entity.hp <= 0:
		self.entity.active_status = GlobalEnv.STATIC_ActiveStatus.Dead
	elif self.entity.lifetime <= 0:
		self.entity.active_status = GlobalEnv.STATIC_ActiveStatus.Dead
	# pass time
	self.entity.lifetime = max(0, self.entity.lifetime - delta)
	# skip if in freaze status
	if self.entity.active_status == GlobalEnv.STATIC_ActiveStatus.Freaze:
		return
		
	self.update_movement(delta)
	self.update_entity()


func update_movement(delta: float) -> void:
	var direction = self.entity.direction.normalized() * self.entity.movement_speed * delta
	self.velocity.x = direction.x
	self.velocity.y = direction.y
	self.move_and_slide()


func update_entity() -> void:
	self.entity.position = self.global_position
	self.entity.direction = Vector2.RIGHT.rotated(self.global_rotation)


# ##############################################################################
# lifecycle funcs
# ##############################################################################


func drop_to_trush():
	self.process_mode = Node.PROCESS_MODE_DISABLED
	SkillManager.drop_to_trush(self)


func empty():
	self.entity.team = GlobalEnv.Teams.__Empty__
	self.collision_mask = 0
	self.collision_layer = 0
	
	
func active():
	self.entity.active_status = GlobalEnv.STATIC_ActiveStatus.Active
	self.process_mode = Node.PROCESS_MODE_INHERIT
	NodeUtil.active_node(self)
	NodeUtil.show_node(self)


# ##############################################################################
# end
# ##############################################################################
