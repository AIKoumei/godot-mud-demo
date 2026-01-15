extends BaseSkill



func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	# Add the gravity.
	#if not is_on_floor():
		#velocity += get_gravity() * delta
	
	if not self.entity.team == GlobalEnv.Teams.Player:
		return
	
	var distance = self.entity.direction * self.entity.movement_speed * delta
	velocity.x = distance.x
	velocity.y = distance.y

	move_and_slide()
	update_entity()


func _on_ready() -> void:
	EntityManager.regist_entity(self.entity, self)


func _on_area_2d_body_entered(body: Node2D) -> void:
	#print("_on_area_2d_body_entered")
	#print(body.name)
	hit(body)
