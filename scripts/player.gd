extends CharacterBody2D

const speed = 100
const jumpSpeed = -350

@onready var animated_sprite = $AnimatedSprite2D

func _physics_process(delta):
	# Get the gravity from the project settings to be synced with RigidBody nodes.
	var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
		
	# add gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# get the input direction: -1, 0, 1
	var direction = Input.get_axis("move_left", "move_right")
	
	if direction > 0:
		# facing right
		animated_sprite.flip_h = false
	elif direction < 0:
		# flip sprite to face left 
		animated_sprite.flip_h = true
		
		# do jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jumpSpeed
		
	# select animation state
	if is_on_floor():
		if direction == 0:
			animated_sprite.play("idle")
		else:
			animated_sprite.play("walk")
	else:
		if velocity.y < 0:
			# upward jump
			animated_sprite.play("jump")
		else:
			# falling
			animated_sprite.play("fall")
		
	# apply movement
	if direction:
		velocity.x = direction * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		
	move_and_slide()
		
