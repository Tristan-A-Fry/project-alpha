extends Node

const CONFIG_PATH = "user://keybinds.cfg"

# Offset for mouse button encoding (to avoid conflicts with keycodes)
const MOUSE_BUTTON_OFFSET = 1000

# Default keybinds
const DEFAULT_KEYBINDS = {
	"dash" : KEY_SHIFT,
}

# Current keybinds (action_name: keycode)
var keybinds: Dictionary = {}

# Mapping of keycodes to action names for conflict detection
var keycode_to_action: Dictionary = {}

func _ready():
	load_keybinds()

func get_keybind(action: String) -> int:
	if action in keybinds:
		return keybinds[action]
	if action in DEFAULT_KEYBINDS:
		return DEFAULT_KEYBINDS[action]
	return 0

func set_keybind(action: String, keycode: int) -> Dictionary:
	# Returns {"success": bool, "error": String, "conflict_action": String}

	#Check for conflicts
	if keycode in keycode_to_action:
		var conflict_action = keycode_to_action[keycode]
		if conflict_action != action:
			return {"success": false, "error": "Keycode already in use by action: " + conflict_action, "conflict_action": conflict_action}

	# Remove old keycode mapping
	if action in keybinds:
		var old_keycode = keybinds[action]
		if old_keycode in keycode_to_action and keycode_to_action[old_keycode] == action:
			keycode_to_action.erase(old_keycode)

	# Add new keycode mapping
	keybinds[action] = keycode
	keycode_to_action[keycode] = action

	save_keybinds()
	return {"success": true, "error": ""}

func reset_keybind(action: String):
	if action in DEFAULT_KEYBINDS:
		set_keybind(action, DEFAULT_KEYBINDS[action])

func load_keybinds():
	keybinds = DEFAULT_KEYBINDS.duplicate()
	keycode_to_action.clear()

	var config = ConfigFile.new()
	var err = config.load(CONFIG_PATH)
	if err != OK:
		# File does not exist, use defaults
		rebuild_keycode_mapping()
		return
	
	#Load saved keybinds
	for action in DEFAULT_KEYBINDS.keys():
		if config.has_section_key("keybinds", action):
			var keycode = config.get_value("keybinds", action, DEFAULT_KEYBINDS[action])
			keybinds[action] = keycode
	
	rebuild_keycode_mapping()

func save_keybinds():
	var config = ConfigFile.new()
	for action in keybinds.keys():
		config.set_value("keybinds", action, keybinds[action])
	config.save(CONFIG_PATH)

func rebuild_keycode_mapping():
	keycode_to_action.clear()
	for action in keybinds.keys():
		keycode_to_action[keybinds[action]] = action

func keycode_to_string(keycode: int) -> String:
	if keycode == 0:
		return "None"
	
	# Special handling for modifier keys FIRST (before mouse button check)
	# These need to be checked before mouse button offset check since KEY_SHIFT (4194325) > 1000
	match keycode:
		KEY_SHIFT:
			return "Shift"
		KEY_CTRL:
			return "Ctrl"
		KEY_ALT:
			return "Alt"
		KEY_META:
			return "Meta"
		KEY_ENTER:
			return "Enter"
		KEY_TAB:
			return "Tab"
		KEY_BACKSPACE:
			return "Backspace"
		KEY_DELETE:
			return "Delete"
		KEY_SPACE:
			return "Space"
		KEY_ESCAPE:
			return "Escape"
	
	# Check if it's a mouse button (encoded with offset)
	# Only treat as mouse button if in range 1000-1099 (valid mouse button range)
	if keycode >= MOUSE_BUTTON_OFFSET and keycode < MOUSE_BUTTON_OFFSET + 20:
		var mouse_button = keycode - MOUSE_BUTTON_OFFSET
		match mouse_button:
			MOUSE_BUTTON_LEFT:
				return "Mouse Left"
			MOUSE_BUTTON_RIGHT:
				return "Mouse Right"
			MOUSE_BUTTON_MIDDLE:
				return "Mouse Middle"
			MOUSE_BUTTON_WHEEL_UP:
				return "Mouse Wheel Up"
			MOUSE_BUTTON_WHEEL_DOWN:
				return "Mouse Wheel Down"
			MOUSE_BUTTON_WHEEL_LEFT:
				return "Mouse Wheel Left"
			MOUSE_BUTTON_WHEEL_RIGHT:
				return "Mouse Wheel Right"
			MOUSE_BUTTON_XBUTTON1:
				return "Mouse Button 4"
			MOUSE_BUTTON_XBUTTON2:
				return "Mouse Button 5"
			_:
				return "Mouse Button " + str(mouse_button)
	
	# Regular keyboard key
	var key_string = OS.get_keycode_string(keycode)
	if key_string == "":
		return "Key " + str(keycode)
	return key_string

# Helper function to encode mouse button
static func encode_mouse_button(button_index: int) -> int:
	return MOUSE_BUTTON_OFFSET + button_index

# Helper function to check if a keycode is a mouse button
static func is_mouse_button(keycode: int) -> bool:
	return keycode >= MOUSE_BUTTON_OFFSET
