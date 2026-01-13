extends CanvasLayer

@onready var progress_bar = $TextureProgressBar 

var max_health = 100.0 
var current_health = 100.0
var player: Node = null
var last_known_health: float = 100.0

func _ready(): 
	# INIT HP BAR - ensure these are set correctly
	progress_bar.min_value = 0.0
	progress_bar.max_value = 100.0  # Explicitly set to 100
	progress_bar.value = 100.0
	progress_bar.exp_edit = false  # Disable exponential editing - prevents health from going to 0 too quickly
	
	print("HPBar initialized - min: ", progress_bar.min_value, " max: ", progress_bar.max_value, " value: ", progress_bar.value)

	#Find player node 
	player = get_tree().get_first_node_in_group("player")
	if not player:
		#Fallback to Player node in current scene 
		var main = get_tree().current_scene
		if main:
			player = main.get_node_or_null("Player")
	
	# Debug: check if player was found
	if not player:
		print("HPBar: Could not find player node!")
	else:
		print("HPBar: Found player node: ", player.name)
		# Initialize from player's actual health
		if "current_health" in player:
			last_known_health = player.current_health
			current_health = player.current_health
			progress_bar.value = current_health
			print("HPBar: Initialized with player health: ", current_health)

func _process(_delta):
	# Only sync if health has actually changed (avoid unnecessary updates)
	if player and "current_health" in player:
		# Use epsilon comparison to avoid floating point precision issues
		if abs(player.current_health - last_known_health) > 0.01:
			set_health(player.current_health)
			last_known_health = player.current_health

func take_damage(amount: float):
	# Decrease health by amount, clamp between 0 and max health (0-100)
	current_health -= amount
	current_health = clamp(current_health, 0.0, max_health)
	
	#update progress bar 
	progress_bar.value = current_health
	print("HPBar: take_damage called - health: ", current_health, " bar value: ", progress_bar.value)

func set_health(value: float):
	# set health directly and clamp 0-100 range
	current_health = clamp(value, 0.0, max_health)
	progress_bar.value = current_health
	print("HPBar: set_health called - value: ", value, " clamped: ", current_health, " bar value: ", progress_bar.value, " bar max: ", progress_bar.max_value)

func get_health() -> float: 
	return current_health
