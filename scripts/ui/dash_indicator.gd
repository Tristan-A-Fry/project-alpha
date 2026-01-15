extends CanvasLayer

# Preload the dash square scene (you'll create this)
const DASH_SQUARE_SCENE = preload("res://scenes/ui/dash_square.tscn")

# Container to hold all dash squares
@onready var dash_container = $DashContainer

# Spacing between dash squares
@export var dash_spacing: float = 150.0

# References to dynamically created dash squares
var dash_squares: Array = []  # Array of dictionaries: {sprite: Node, progress_bar: Node}

var player: Node = null
var last_known_max_dashes: int = 0

func _ready():
	# Find player node
	player = get_tree().get_first_node_in_group("player")
	if not player:
		var main = get_tree().current_scene
		if main:
			player = main.get_node_or_null("Player")
	
	if not player:
		print("DashIndicator: Could not find player node!")
		return
	
	# Wait a frame to ensure player is fully initialized
	await get_tree().process_frame
	create_dash_squares()

func create_dash_squares():
	if not player or "max_dashes" not in player:
		print("DashIndicator: Player or max_dashes not found!")
		return
	
	var max_dashes = player.max_dashes
	print("DashIndicator: Creating dash squares. max_dashes = ", max_dashes, ", current squares = ", dash_squares.size())
	
	# Clear existing squares if max_dashes changed
	if dash_squares.size() != max_dashes:
		clear_dash_squares()
	
	# Create squares if needed
	if dash_squares.size() < max_dashes:
		for i in range(dash_squares.size(), max_dashes):
			print("DashIndicator: Creating dash square ", i)
			create_dash_square(i)
	
	print("DashIndicator: Total dash squares created: ", dash_squares.size())

func clear_dash_squares():
	for dash_data in dash_squares:
		if is_instance_valid(dash_data.instance):
			dash_data.instance.queue_free()
	dash_squares.clear()

func create_dash_square(index: int):
	if not DASH_SQUARE_SCENE:
		push_error("DashIndicator: Dash square scene not found!")
		return
	
	# Instantiate the dash square scene
	var dash_square_instance = DASH_SQUARE_SCENE.instantiate()
	dash_container.add_child(dash_square_instance)
	
	# Position it horizontally (since Node2D doesn't work with HBoxContainer auto-layout)
	var x_position = index * dash_spacing
	dash_square_instance.position = Vector2(x_position, 0)
	
	# Get reference to TextureProgressBar (it serves as both sprite and progress bar)
	var progress_bar = dash_square_instance.get_node_or_null("TextureProgressBar")
	
	if not progress_bar:
		push_warning("DashIndicator: Dash square scene missing TextureProgressBar node!")
		return
	
	# Store references (progress_bar is used for both visual and progress)
	var dash_data = {
		"sprite": progress_bar,
		"progress_bar": progress_bar,
		"instance": dash_square_instance
	}
	dash_squares.append(dash_data)
	print("DashIndicator: Created dash square ", index, " at position ", dash_square_instance.position, ". Total: ", dash_squares.size())
	
	# Initialize progress bar
	progress_bar.min_value = 0.0
	progress_bar.max_value = 100.0
	progress_bar.value = 100.0  # Start at 100% (filled)
	progress_bar.visible = true

func _process(delta):
	if not player:
		return
	
	# Check if max_dashes changed (for dynamic updates)
	if "max_dashes" in player:
		if player.max_dashes != last_known_max_dashes:
			last_known_max_dashes = player.max_dashes
			create_dash_squares()
	
	# Update display and regeneration progress from player's dash_regen_timers array
	if "dash_regen_timers" in player and "dash_regen_time" in player:
		var regen_time = player.dash_regen_time
		update_regen_progress(regen_time)
	else:
		# Fallback to old method if dash_regen_timers doesn't exist
		if "dash_regen_time" in player:
			var regen_time = player.dash_regen_time
			update_regen_progress(regen_time, delta)

func update_regen_progress(regen_time: float, delta: float = 0.0):
	# Read regeneration timers directly from player script
	if not player or "dash_regen_timers" not in player:
		return
	
	var dash_regen_timers = player.dash_regen_timers
	
	# Update each dash square based on player's regeneration timers
	for i in range(dash_squares.size()):
		var dash_data = dash_squares[i]
		if not dash_data or not is_instance_valid(dash_data.progress_bar):
			continue
		
		# Get this dash's regeneration timer from player
		if i < dash_regen_timers.size():
			var regen_timer = dash_regen_timers[i]
			
			# Calculate progress percentage
			var progress_percent = (regen_timer / regen_time) * 100.0
			dash_data.progress_bar.value = progress_percent
			dash_data.progress_bar.visible = true
		else:
			# Dash slot doesn't exist in player's array yet
			dash_data.progress_bar.value = 0.0
			dash_data.progress_bar.visible = true

func update_display():
	# Display is now handled by update_regen_progress which reads directly from player
	# This function is kept for compatibility but may not be needed
	pass
