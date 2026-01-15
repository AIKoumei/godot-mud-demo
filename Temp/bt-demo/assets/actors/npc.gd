extends BaseActor



func _physics_process(delta: float) -> void:
	#_physics_process_components(delta)
	# Add the gravity.
	#if not is_on_floor():
		#velocity += get_gravity() * delta
		
	update_entity()
	
	if not self.entity.team == GlobalEnv.Teams.Player:
		return
	
	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	direction = Input.get_axis("ui_up", "ui_down")
	if direction:
		velocity.y = direction * SPEED
	else:
		velocity.y = move_toward(velocity.y, 0, SPEED)

	move_and_slide()


#func _on_ready() -> void:
	#EntityManager.regist_entity(self.entity, self)
