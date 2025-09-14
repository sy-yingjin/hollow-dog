extends CharacterBody2D

const speed = 10

@onready var animated_sprite = $AnimatedSprite2D

func _physics_process(delta):
	
	# get the input direction: -1, 0, 1
	var direction = Input.get_axis("move_left", "move_right")
	
	if direction > 0:
		# facing right
		animated_sprite.flip_h = false
	elif direction < 0:
		# flip sprite to face left 
		animated_sprite.flip_h = true
		
	# select animation state
	if direction == 0:
		animated_sprite.play("idle")
	else:
		animated_sprite.play("walk")
	
	# apply movement
	if direction:
		velocity.x = direction * speed
		
