extends Node2D

@export var enemy_prefab: PackedScene
@export var target: Node2D  # The player node

# Spawner configuration
@export var initial_spawn_count: int = 10
@export var spawn_distance: float = 500.0  # Distance from player
@export var spawn_distance_variance: float = 50.0  # Random variation in distance

func _ready():
	# Wait a frame to ensure everything is initialized 
	call_deferred("spawn_initial_enemies")

func spawn_initial_enemies():
	if not target:
		# Try to find player if target not set
		target = get_tree().get_first_node_in_group("player")
		if not target:
			target = get_parent().get_node_or_null("Player")
	
	if not target:
		push_warning("EnemySpawner: Target (player) not found!")
		return
	
	if not enemy_prefab:
		push_warning("EnemySpawner: Enemy prefab not set!")
		return
	
	# Get player position
	var player_pos = target.global_position
	
	# Spawn enemies at random positions around the player
	for i in range(initial_spawn_count):
		spawn_enemy_at_random_position(player_pos)

func spawn_enemy_at_random_position(player_pos: Vector2):
	# Generate random angle (0 to 360 degrees)
	var random_angle = randf() * TAU  # TAU = 2 * PI (full circle)
	
	# Generate random distance with variance
	var distance = spawn_distance + randf_range(-spawn_distance_variance, spawn_distance_variance)
	
	# Calculate spawn position using trigonometry
	var spawn_pos = player_pos + Vector2(cos(random_angle), sin(random_angle)) * distance
	
	# Create enemy instance
	var enemy = enemy_prefab.instantiate()
	get_parent().add_child(enemy)  # Add to main scene (parent of spawner)
	enemy.global_position = spawn_pos
	
	# Note: The enemy script will automatically find the player via get_parent().get_node("Player")
	# So we don't need to set player manually

func _on_timer_timeout() -> void:
	# Optional: Spawn more enemies over time if you add a Timer node
	if not target or not enemy_prefab:
		return
	
	var player_pos = target.global_position
	spawn_enemy_at_random_position(player_pos)
