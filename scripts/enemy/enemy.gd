extends CharacterBody2D

@onready var player_node: CharacterBody2D = get_parent().get_node("Player")
@onready var progress_bar = $TextureProgressBar
@onready var animated_sprite = $AnimatedSprite2D
@onready var hit_sound = $HitSoundPlayer
@onready var hit_area = $HitArea2D


var speed: float = 100.0
var should_chase: bool = false

# Health variables
var current_health: float = 100.0
var max_health: float = 100.0

var is_hurt: bool = false
var hurt_animation_duration: float = 0.5  # How long hurt animation plays
var hurt_timer: float = 0.0

func _ready():
	# Initialize HP bar
	progress_bar.min_value = 0.0
	progress_bar.max_value = max_health
	progress_bar.value = current_health
	progress_bar.exp_edit = false
	
	if hit_area:
		hit_area.collision_mask = 2
		hit_area.body_entered.connect(_on_hit_area_body_entered)

func _physics_process(delta:float) -> void:
	if should_chase:
		var direction = (player_node.global_position - global_position).normalized()
		velocity = lerp(velocity, direction * speed, 8.5 * delta)
		move_and_slide()

		if direction.x > 0:
			animated_sprite.flip_h = false
		elif direction.x < 0:
			animated_sprite.flip_h = true

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body == player_node:
		player_node.take_damage(10.0)
	if player_node.current_health <= 0.0:
		print("Player is dead, reloading scene")
		get_tree().reload_current_scene()

func _on_enter_area_body_entered(body: Node2D) -> void:
	if body == player_node:
		should_chase = true

func _on_exit_area_body_exited(body: Node2D) -> void:
	if body == player_node:
		should_chase = false

# HP Bar functions
func take_damage(amount: float):
	# Decrease health by amount, clamp between 0 and max health
	current_health -= amount
	current_health = clamp(current_health, 0.0, max_health)
	
	# Update progress bar
	progress_bar.value = current_health

	play_hurt_animation()
	if hit_sound:
		hit_sound.play()
	
	# Check if enemy is dead
	if current_health <= 0.0:
		# Disable collision so bullets pass through
		if hit_area:
			hit_area.set_deferred("monitoring", false)
			hit_area.set_deferred("monitorable", false)
		
		# Also disable the main Area2D for player collision
		var main_area = get_node_or_null("Area2D")
		if main_area:
			main_area.set_deferred("monitoring", false)
			main_area.set_deferred("monitorable", false)
		
		if hit_sound and hit_sound.playing:
			# ADD death animation here
			speed = 0
			hit_sound.finished.connect(_on_hit_sound_finished)
		else:
			# Sound not playing or doesn't exist, die immediately
			die()

func _on_hit_sound_finished():
	# Called when hit sound finishes playing
	die()

func _on_hit_area_body_entered(body: Node2D):
	# Check if the body is a bullet (simpler check)
	# Bullets extend CharacterBody2D and should have "Bullet" in their name or scene name
	if body and body.name == "Bullet" or (body.get_script() and "bullet.gd" in body.get_script().resource_path):
		# Apply damage
		take_damage(25.0)  # Adjust damage value as needed
		# Remove the bullet
		body.queue_free()

func set_health(value: float):
	# Set health directly and clamp 0-max range
	current_health = clamp(value, 0.0, max_health)
	progress_bar.value = current_health
	progress_bar.max_value = max_health

func get_health() -> float:
	return current_health

func play_hurt_animation():
	# Play the hurt animation
	if animated_sprite and animated_sprite.sprite_frames:
		if animated_sprite.sprite_frames.has_animation("hurt"):
			animated_sprite.play("hurt")
			is_hurt = true
			hurt_timer = hurt_animation_duration
			# Connect to animation finished signal if you want it to play once
			# For now, the timer will handle returning to normal state

func die():
	# Handle enemy death (remove from scene)
	queue_free()
