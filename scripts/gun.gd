extends Node2D

# Bullet configuration
const BULLET = preload("res://scenes/bullets/bullet.tscn")
@export var fire_rate: float = 0.2  # Time between shots

# References
@onready var muzzle_marker = $MuzzleMarker
@onready var shoot_sound = $ShootSoundPlayer

# Shooting variables
var time_since_last_shot: float = 0.0

func _ready():
	pass

func _process(delta: float) -> void:
	# Get the player's global position (parent node)
	var player_global_pos = get_parent().global_position
	
	# Get mouse position in global coordinates
	var mouse_global_pos = get_global_mouse_position()
	
	# Calculate direction from player to mouse
	var direction_to_mouse = (mouse_global_pos - player_global_pos).normalized()
	
	# Calculate the angle to the mouse
	var angle_to_mouse = direction_to_mouse.angle()
	
	# Set orbit radius (distance from player center)
	var orbit_radius = 30.0  # Adjust this value to change how far the gun orbits
	
	# Position the gun at the orbit radius based on the angle
	# Since gun is a child of player, we use local position
	position = Vector2(cos(angle_to_mouse), sin(angle_to_mouse)) * orbit_radius
	
	# Rotate the gun to face the mouse
	look_at(mouse_global_pos)
	
	# Flip sprite if pointing left (optional, you can remove this if not needed)
	rotation_degrees = wrap(rotation_degrees, 0, 360)
	if rotation_degrees > 90 and rotation_degrees < 270:
		scale.y = -1
	else:
		scale.y = 1
	
	# Update timers
	time_since_last_shot += delta
	
	# Handle shooting with left mouse button
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if time_since_last_shot >= fire_rate:
			shoot()

# Get the direction the gun is facing (based on sprite rotation)
func get_gun_direction() -> Vector2:
	var gun_sprite = get_node_or_null("GunSprite")
	if gun_sprite:
		return Vector2(cos(gun_sprite.rotation), sin(gun_sprite.rotation))
	return Vector2.RIGHT

# Shoot a bullet
func shoot():
	# Play shoot sound
	if shoot_sound:
		shoot_sound.play()
	
	# Create bullet instance
	var bullet = BULLET.instantiate()
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = muzzle_marker.global_position
	bullet.rotation = rotation

	var direction = Vector2.RIGHT.rotated(rotation)
	bullet.set_direction(direction)
	
	# Reset fire rate timer
	time_since_last_shot = 0.0
