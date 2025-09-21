extends CharacterBody2D

const speed = 100
const jumpSpeed = -350

@onready var animated_sprite = $AnimatedSprite2D

# Drop down variables
var platform_drop_timer = 0.0

func _physics_process(delta):
	# Get the gravity from the project settings to be synced with RigidBody nodes.
	var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
	
	# Handle platform drop timer
	if platform_drop_timer > 0:
		platform_drop_timer -= delta
	
	# Check for drop down input (ui_down action now includes S and Down Arrow in project settings)
	if Input.is_action_just_pressed("ui_down") and is_on_floor():
		platform_drop_timer = 0.18  # Slightly longer grace window
		velocity.y = max(velocity.y, 120) # Force a clear downward movement so one-way lets us go through
		# Nudge the body a tiny bit down so it stops counting as on_floor this frame
		global_position.y += 1.5
		
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
	
	# While dropping, temporarily ignore floor by tricking is_on_floor for a few frames
	if platform_drop_timer > 0:
		# Godot will treat us as falling so one-way polygons won't block upward normal
		pass
		
	move_and_slide()
