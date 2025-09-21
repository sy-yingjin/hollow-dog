extends CharacterBody2D

const speed = 100
const jumpSpeed = -350

# Layer config
# Godot physics layers are 1-indexed in the UI. Layer 8 => bit 7 => value 1 << 7 = 128
const ACID_LAYER_INDEX := 8
const ACID_LAYER_BIT := 1 << (ACID_LAYER_INDEX - 1) # 128

@onready var animated_sprite = $AnimatedSprite2D

# Hazard collision setup
const HAZARD_NODE_NAMES = ["damage-thorns", "damage-bush", "damage-broken"] # acid handled via overlap so player can fall through

var is_dead: bool = false
var game_over_layer: CanvasLayer

func show_game_over():
	if game_over_layer:
		return
	game_over_layer = CanvasLayer.new()
	# Root fullscreen container
	var root = Control.new()
	root.anchor_left = 0
	root.anchor_top = 0
	root.anchor_right = 1
	root.anchor_bottom = 1
	root.offset_left = 0
	root.offset_top = 0
	root.offset_right = 0
	root.offset_bottom = 0
	game_over_layer.add_child(root)

	# Dark overlay
	var panel = ColorRect.new()
	panel.color = Color(0,0,0,0.6)
	panel.anchor_left = 0
	panel.anchor_top = 0
	panel.anchor_right = 1
	panel.anchor_bottom = 1
	root.add_child(panel)

	# Center container to center contents automatically
	var center = CenterContainer.new()
	center.anchor_left = 0
	center.anchor_top = 0
	center.anchor_right = 1
	center.anchor_bottom = 1
	center.offset_left = 0
	center.offset_top = 0
	center.offset_right = 0
	center.offset_bottom = 0
	root.add_child(center)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	# In Godot 4, VBoxContainer uses theme constant 'separation' instead of a 'spacing' property.
	vbox.add_theme_constant_override("separation", 16)
	center.add_child(vbox)

	var label = Label.new()
	label.text = "GAME OVER"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(1,0.85,0.2))
	label.add_theme_font_size_override("font_size", 48)
	vbox.add_child(label)

	var retry_btn = Button.new()
	retry_btn.text = "Retry"
	retry_btn.focus_mode = Control.FOCUS_ALL
	retry_btn.pressed.connect(restart_level)
	vbox.add_child(retry_btn)

	# Parent to the current scene so it is naturally freed on a scene reload
	get_tree().current_scene.add_child(game_over_layer)
	retry_btn.grab_focus()

func restart_level():
	# Remove overlay explicitly (usually unnecessary after scene change, but safe)
	if game_over_layer and is_instance_valid(game_over_layer):
		game_over_layer.queue_free()
	# Reset death flag (in case code runs before scene fully switches)
	is_dead = false
	# Load the main scene fresh
	var main_scene_path = ProjectSettings.get_setting("application/run/main_scene")
	get_tree().change_scene_to_file(main_scene_path)

func _ready():
	# Ensure we do NOT collide physically with acid (layer 8), so player falls through.
	if (collision_mask & ACID_LAYER_BIT) != 0:
		collision_mask &= ~ACID_LAYER_BIT
	# Optionally, ensure our own collision layer does not include acid; only mask matters for blocking.
	pass

func die():
	if is_dead:
		return
	is_dead = true
	show_game_over()

func _is_in_acid() -> bool:
	# Use a small rectangle at/just below the player's feet to detect overlap with acid layer (layer 8 / bit 128).
	var space = get_world_2d().direct_space_state
	var params = PhysicsShapeQueryParameters2D.new()
	var rect_shape := RectangleShape2D.new()
	# Derive collision shape size if available
	var feet_height := 4.0
	var body_half_width := 6.0
	var body_half_height := 12.0
	var col_shape: CollisionShape2D = get_node_or_null("CollisionShape2D")
	if col_shape and col_shape.shape is RectangleShape2D:
		var rs: RectangleShape2D = col_shape.shape
		body_half_width = rs.size.x * 0.5
		body_half_height = rs.size.y * 0.5
	# Thin rectangle slightly below feet
	rect_shape.size = Vector2(body_half_width * 1.8, feet_height)
	params.shape = rect_shape
	# Position: global position plus downward offset (collision shape is centered, so feet at -12.5 + half_height?)
	var feet_y_offset = col_shape.position.y + body_half_height
	params.transform = Transform2D(0.0, global_position + Vector2(0, feet_y_offset + 1))
	params.collision_mask = ACID_LAYER_BIT  # acid layer
	params.collide_with_areas = true
	params.collide_with_bodies = true
	var result = space.intersect_shape(params, 1)
	return result.size() > 0

# Drop down variables
var platform_drop_timer = 0.0

func _physics_process(delta):
	if is_dead:
		return
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

	# Acid overlap check (non-blocking). If player passes through acid tiles, trigger death.
	if _is_in_acid():
		die()
		return

	# After movement, inspect slide collisions for hazards
	for i in range(get_slide_collision_count()):
		var col = get_slide_collision(i)
		if not col:
			continue
		var collider = col.get_collider()
		if collider and collider.name in HAZARD_NODE_NAMES:
			die()
			break
