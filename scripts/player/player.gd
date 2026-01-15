extends CharacterBody2D

# Player movement variables for top-down view
@export var speed: float = 400.0

# Camera zoom variables
@export var min_zoom: float = 0.1
@export var max_zoom: float = 3.0
@export var zoom_speed: float = 0.1

@onready var animated_sprite = $AnimatedSprite2D
@onready var camera = $Camera2D
@onready var gun = get_node_or_null("Gun")  # Gun scene node (flexible lookup)

#
# Keybinds Manager
var keybinds_manager: Node = null

# Store last direction for idle animations
var last_direction: Vector2 = Vector2.DOWN
var mouse_direction: Vector2 = Vector2.DOWN

# Shooting variables (tracking flag only - actual shooting handled by gun)
var is_shooting: bool = false

# Dash variables
@export var dash_speed: float = 1000.0
@export var dash_duration: float = 0.3  # How long the dash lasts
@export var dash_cooldown: float = 0.01  # Cooldown between dashes
@export var max_dashes: int = 2
@export var dash_regen_time: float = 3.0
# Track individual dash regeneration - array of timers, one per dash slot
var dash_regen_timers: Array = []  # Array of floats, one timer per dash slot
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var dash_direction: Vector2 = Vector2.ZERO # Store direction of dash start

# Computed property for current_dashes (for compatibility with UI scripts)
var current_dashes: int:
	get:
		var count = 0
		for i in range(max_dashes):
			if i < dash_regen_timers.size() and dash_regen_timers[i] >= dash_regen_time:
				count += 1
		return count

#Health variables
var current_health: float = 100.0
var max_health: float = 100.0

# Dev tools flags
var infinite_hp: bool = false

func _ready():
	keybinds_manager = get_node("/root/KeybindManager") if has_node("/root/KeybindManager") else null
	if not keybinds_manager:
		keybinds_manager = get_node("/root/KeybindManager") if get_tree().root.has_node("/root/KeybindManager") else null
	
	# Initialize gun if it exists
	if not gun:
		push_warning("Player: Gun node not found! Make sure to add the Gun scene as a child of Player.")
	
	# Initialize dash regeneration timers (all start at max, meaning all dashes are available)
	dash_regen_timers.clear()
	for i in range(max_dashes):
		dash_regen_timers.append(dash_regen_time)  # Start at max = dash is available

func _physics_process(delta):
	# Update timers
	dash_cooldown_timer -= delta

	# Update individual dash regeneration timers
	# Ensure array size matches max_dashes
	while dash_regen_timers.size() < max_dashes:
		dash_regen_timers.append(0.0)
	
	# Regenerate each dash independently
	for i in range(max_dashes):
		if dash_regen_timers[i] < dash_regen_time:
			dash_regen_timers[i] += delta
			# Clamp to max regeneration time
			if dash_regen_timers[i] > dash_regen_time:
				dash_regen_timers[i] = dash_regen_time
	
	# Update dash timer
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0.0:
			is_dashing = false
			dash_timer = 0.0
			infinite_hp = false
	
	# Update dash timer
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0.0:
			is_dashing = false
			dash_timer = 0.0
			infinite_hp = false
	
	# Get mouse position in world coordinates
	var mouse_pos = get_global_mouse_position()
	mouse_direction = (mouse_pos - global_position).normalized()
	
	# Get input direction (8-directional movement with WASD) - needed for animations
	# W = North (negative Y), A = West (negative X), S = South (positive Y), D = East (positive X)
	var input_direction = Vector2.ZERO
	
	# Handle movement - dash takes priority over normal movement
	if is_dashing:
		# During dash, move in mouse direction at dash speed
		velocity = dash_direction * dash_speed
		last_direction = dash_direction  # Update facing direction
	else:
		# W = North (move up, negative Y)
		if Input.is_key_pressed(KEY_W):
			input_direction.y -= 1.0
		# S = South (move down, positive Y)
		if Input.is_key_pressed(KEY_S):
			input_direction.y += 1.0
		# A = West (move left, negative X)
		if Input.is_key_pressed(KEY_A):
			input_direction.x -= 1.0
		# D = East (move right, positive X)
		if Input.is_key_pressed(KEY_D):
			input_direction.x += 1.0
	
	# Normalize to prevent faster diagonal movement
	input_direction = input_direction.normalized()
	
	# Set velocity based on input
	if input_direction != Vector2.ZERO:
		velocity = input_direction * speed
		last_direction = input_direction  # Store direction for idle animations
	else:
		velocity = velocity.move_toward(Vector2.ZERO, speed)
	
	# Update animations - use dash direction if dashing, otherwise use input direction
	# var anim_direction = mouse_direction if is_dashing else input_direction
	update_animations(input_direction)
	
	# Move the character (use move_and_collide for top-down, or move_and_slide)
	# For top-down without collisions, we can use move_and_slide which should work fine
	move_and_slide()

func _input(event):
	# Handle dash input (custom keybind - supports keyboard and mouse)
	var dash_keycode = KEY_SHIFT  # Default
	if keybinds_manager:
		dash_keycode = keybinds_manager.get_keybind("dash")
	
	# Check if it's a keyboard key
	if event is InputEventKey:
		if event.keycode == dash_keycode and event.pressed:
			start_dash()
	
	# Check if it's a mouse button
	if event is InputEventMouseButton and event.pressed:
		# Check if dash_keycode is a mouse button (encoded with offset 1000)
		if dash_keycode >= 1000:
			var mouse_button_index = dash_keycode - 1000
			if event.button_index == mouse_button_index:
				start_dash()
	
	# Handle mouse wheel zoom
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			# Zoom in
			var new_zoom = camera.zoom.x - zoom_speed
			new_zoom = clamp(new_zoom, min_zoom, max_zoom)
			camera.zoom = Vector2(new_zoom, new_zoom)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			# Zoom out
			var new_zoom = camera.zoom.x + zoom_speed
			new_zoom = clamp(new_zoom, min_zoom, max_zoom)
			camera.zoom = Vector2(new_zoom, new_zoom)
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:  #TESTING - Right click to take damage
			take_damage(10.0)

func start_dash():
	# Check if dash is on cooldown
	if dash_cooldown_timer > 0.0:
		return
	
	# Check if already dashing
	if is_dashing:
		return
	
	# Find the rightmost available dash (highest index that is full/available)
	var dash_to_use: int = -1
	for i in range(max_dashes - 1, -1, -1):  # Iterate backwards from rightmost
		# Ensure array is large enough
		if i >= dash_regen_timers.size():
			continue
		# Check if this dash is available (timer >= regen_time means it's ready)
		if dash_regen_timers[i] >= dash_regen_time:
			dash_to_use = i
			break
	
	# Check if we have any dash available
	if dash_to_use == -1:
		return
	
	var input_direction = Vector2.ZERO

	if Input.is_key_pressed(KEY_W):
		input_direction.y -= 1.0
	if Input.is_key_pressed(KEY_S):
		input_direction.y += 1.0
	if Input.is_key_pressed(KEY_A):
		input_direction.x -= 1.0
	if Input.is_key_pressed(KEY_D):
		input_direction.x += 1.0
	
	input_direction = input_direction.normalized()
	if input_direction == Vector2.ZERO:
		input_direction = Vector2.DOWN
	
	dash_direction = input_direction

	# Consume the rightmost available dash (reset its timer to 0)
	dash_regen_timers[dash_to_use] = 0.0
	
	# Start dash
	is_dashing = true
	dash_timer = dash_duration
	dash_cooldown_timer = dash_cooldown
	last_direction = mouse_direction  # Face dash direction
	infinite_hp = true

# TESTING
func take_damage(amount: float):
	if infinite_hp:
		return
	current_health -= amount
	current_health = clamp(current_health, 0.0, max_health)



func update_animations(direction: Vector2):
	if not animated_sprite.sprite_frames:
		return
	
	if mouse_direction.x < 0:
		animated_sprite.flip_h = true
	else:
		animated_sprite.flip_h = false
	
	var anim_name: String = ""
	var is_moving = velocity.length() > 0
	# var is_shooting_button = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	
	# If shooting (mouse button held), use shoot animation based on mouse direction
	# Character faces mouse direction regardless of movement direction
	if is_dashing:
		anim_name = "dash"

	elif is_moving:
		anim_name = get_direction_animation(direction, "walk")
		last_direction = direction
	else:
		anim_name = get_direction_animation(last_direction, "idle")
	
	if anim_name != "" and animated_sprite.sprite_frames.has_animation(anim_name):
		if animated_sprite.animation != anim_name:
			animated_sprite.play(anim_name)
	else:
		# Debug: print if animation doesn't exist
		if anim_name == "dash":
			print("Warning: 'dash' animation not found in sprite_frames!")

func get_direction_animation(dir: Vector2, anim_type: String) -> String:
	var prefix = anim_type  # "walk", "idle", or "shoot"
	
	# Normalize direction
	if dir.length() < 0.1:
		dir = last_direction if last_direction.length() > 0.1 else Vector2.DOWN
	
	# For shoot animations, we have more directions (including pure left/right)
	# if anim_type == "shoot":
	# 	return get_shoot_direction_animation(dir)
	
	# Threshold for determining if it's more vertical or horizontal
	var threshold = 0.707  # Cos/Sin of 45 degrees (normalized diagonal)
	var abs_x = abs(dir.x)
	var abs_y = abs(dir.y)
	
	# Check vertical direction first (up/down)
	if abs_y > abs_x * threshold:
		# Primarily vertical
		if dir.y < 0:
			return prefix + " up"
		else:
			return prefix + " down"
	else:
		# Primarily horizontal or diagonal
		if dir.y < 0:  # Upper half (up directions)
			if dir.x < 0:
				return prefix + " left up"
			else:
				return prefix + " right up"
		else:  # Lower half (down directions)
			if dir.x < 0:
				return prefix + " left down"
			else:
				return prefix + " right down"
