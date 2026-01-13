# Keybind Manager System

## Overview

The Keybind Manager is an autoload singleton system that handles customizable keybindings for the game. It allows players to rebind actions (currently dash) to different keyboard keys or mouse buttons, with persistence across game sessions.

## Why This System Exists

1. **Player Customization**: Players have different preferences for control schemes and may want to use different keys or mouse buttons
2. **Accessibility**: Supports different input devices and configurations
3. **Mouse Button Support**: Standard Godot input handling doesn't easily support binding actions to mouse buttons in a customizable way
4. **Persistence**: Keybinds are saved to disk and persist between game sessions
5. **Conflict Detection**: Prevents multiple actions from being bound to the same key

## Architecture

### Files Involved

- **`scripts/keybind_manager.gd`**: Autoload singleton that manages keybind storage and retrieval
- **`scripts/ui/pause_menu.gd`**: Handles the UI for keybind assignment in the pause menu
- **`scripts/player/player.gd`**: Uses the keybind manager to check for custom keybinds when handling input
- **`project.godot`**: Configures KeybindManager as an autoload singleton

### Data Storage

Keybinds are saved to `user://keybinds.cfg` using Godot's `ConfigFile` class. This file is automatically created in the user's data directory and persists across game sessions.

## How It Works

### 1. Initialization

When the game starts, the `KeybindManager` singleton is automatically loaded (as configured in `project.godot`). In its `_ready()` function, it calls `load_keybinds()` which:

1. Loads default keybinds from `DEFAULT_KEYBINDS` dictionary
2. Attempts to load saved keybinds from `user://keybinds.cfg`
3. If the config file exists, it overwrites defaults with saved values
4. Rebuilds the `keycode_to_action` mapping for conflict detection

### 2. Keybind Storage

Keybinds are stored as a dictionary mapping action names (strings) to keycodes (integers):

```gdscript
keybinds = {
    "dash": KEY_SHIFT  # or custom keycode
}
```

### 3. Mouse Button Encoding

**Critical Design Decision**: Mouse buttons cannot be directly stored alongside keyboard keycodes because keyboard keycodes can have very large values (e.g., KEY_SHIFT = 4194325), and we need a way to distinguish between keyboard keys and mouse buttons.

**Solution**: Mouse buttons are encoded with an offset of 1000:

- Mouse Button 1 (Left) = 1 → Encoded as 1001 (1000 + 1)
- Mouse Button 2 (Right) = 2 → Encoded as 1002 (1000 + 2)
- Mouse Button 3 (Middle) = 3 → Encoded as 1003 (1000 + 3)
- Mouse Button 4 (XBUTTON1) = 8 → Encoded as 1008 (1000 + 8)
- Mouse Button 5 (XBUTTON2) = 9 → Encoded as 1009 (1000 + 9)

This encoding scheme:
- Keeps mouse button values in a predictable range (1000-1019)
- Avoids conflicts with keyboard keycodes (which are typically much larger)
- Allows easy decoding by subtracting 1000

### 4. Keybind Assignment Flow

When a player wants to rebind an action:

1. **Player clicks the keybind button** in the pause menu's Keybinds submenu
2. **`_on_dash_keybind_button_pressed()`** is called, setting `waiting_for_keybind = "dash"`
3. **The button text changes** to "Press any key..."
4. **`_input()` function** waits for the next input event
5. **When a key is pressed**:
   - If it's a keyboard key: Store `event.keycode` directly
   - If it's a mouse button: Encode as `1000 + event.button_index`
6. **Conflict detection** checks if the keycode is already bound to another action
7. **If successful**: Save the keybind, update display, clear waiting state
8. **If conflict**: Display error message, keep waiting state

### 5. Keybind Retrieval

When the player script needs to check if a keybind is pressed:

1. **Get the keycode** from KeybindManager: `keybinds_manager.get_keybind("dash")`
2. **Check the input event**:
   - For keyboard: Compare `event.keycode == dash_keycode`
   - For mouse buttons: Check if `dash_keycode >= 1000`, then decode and compare

### 6. Display Conversion

The `keycode_to_string()` function converts stored keycodes to human-readable strings:

1. **Check for keyboard modifier keys first** (KEY_SHIFT, KEY_CTRL, etc.) - This is critical because KEY_SHIFT (4194325) is > 1000, so we must check keyboard keys before mouse buttons
2. **Check if keycode is in mouse button range** (1000-1019)
3. **Decode mouse button** by subtracting 1000
4. **Match to mouse button constant** and return readable name
5. **Fallback to OS.get_keycode_string()** for regular keyboard keys

**Important**: The order of checks matters! Keyboard keys (especially modifiers like Shift) must be checked before the mouse button range check, otherwise KEY_SHIFT would be incorrectly identified as a mouse button.

## Mouse Button Support - Technical Details

### The Challenge

Godot's input system handles keyboard keys and mouse buttons differently:
- Keyboard keys use `InputEventKey` with a `keycode` property (large integer values)
- Mouse buttons use `InputEventMouseButton` with a `button_index` property (small integer values 1-9)

These two systems don't naturally interoperate, so we needed a way to store both types in the same keycode system.

### The Solution

We encode mouse buttons by adding an offset:

```gdscript
# When binding a mouse button
if event is InputEventMouseButton:
    input_code = 1000 + event.button_index  # Encode
    keybinds_manager.set_keybind("dash", input_code)

# When checking if a mouse button is pressed
var dash_keycode = keybinds_manager.get_keybind("dash")
if dash_keycode >= 1000:  # Is it a mouse button?
    var mouse_button_index = dash_keycode - 1000  # Decode
    if event.button_index == mouse_button_index:
        # Perform action
```

### Why Offset = 1000?

- **Low enough**: To keep values reasonable (1000-1019 range)
- **High enough**: To avoid conflicts with keyboard keycodes (which typically start around 32+)
- **Room for expansion**: Supports up to 19 mouse buttons (1000-1019), more than any standard mouse

### Supported Mouse Buttons

- **MOUSE_BUTTON_LEFT** (1) → "Mouse Left"
- **MOUSE_BUTTON_RIGHT** (2) → "Mouse Right"
- **MOUSE_BUTTON_MIDDLE** (3) → "Mouse Middle"
- **MOUSE_BUTTON_WHEEL_UP** (4) → "Mouse Wheel Up"
- **MOUSE_BUTTON_WHEEL_DOWN** (5) → "Mouse Wheel Down"
- **MOUSE_BUTTON_WHEEL_LEFT** (6) → "Mouse Wheel Left"
- **MOUSE_BUTTON_WHEEL_RIGHT** (7) → "Mouse Wheel Right"
- **MOUSE_BUTTON_XBUTTON1** (8) → "Mouse Button 4" (Side button 1)
- **MOUSE_BUTTON_XBUTTON2** (9) → "Mouse Button 5" (Side button 2)

Note: Mouse wheel buttons are detected but typically skipped during binding (as they're used for zoom).

## Adding New Keybinds

To add a new bindable action to the system:

### Step 1: Add Default Keybind

In `scripts/keybind_manager.gd`, add to `DEFAULT_KEYBINDS`:

```gdscript
const DEFAULT_KEYBINDS = {
    "dash": KEY_SHIFT,
    "reload": KEY_R,  # New action
    "jump": KEY_SPACE,  # Another example
}
```

### Step 2: Add UI Elements

In `scenes/main.tscn`, add UI elements to the KeybindsMenu:

```gdscene
[node name="ReloadLabel" type="Label" parent="PauseMenu/KeybindsMenu"]
layout_mode = 0
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -300.0
offset_top = -50.0
offset_right = -150.0
offset_bottom = -20.0
grow_horizontal = 2
grow_vertical = 2
theme_override_font_sizes/font_size = 24
text = "Reload"
horizontal_alignment = 1
vertical_alignment = 1

[node name="ReloadKeybindButton" type="Button" parent="PauseMenu/KeybindsMenu"]
layout_mode = 0
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -100.0
offset_top = -50.0
offset_right = 100.0
offset_bottom = -20.0
grow_horizontal = 2
grow_vertical = 2
theme_override_font_sizes/font_size = 20
text = "R"

[node name="ReloadResetButton" type="Button" parent="PauseMenu/KeybindsMenu"]
layout_mode = 0
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = 120.0
offset_top = -50.0
offset_right = 220.0
offset_bottom = -20.0
grow_horizontal = 2
grow_vertical = 2
text = "Reset"
```

### Step 3: Add UI References and Functions

In `scripts/ui/pause_menu.gd`, add:

```gdscript
# Add to @onready variables section
@onready var reload_keybind_button = keybinds_menu.get_node_or_null("ReloadKeybindButton")
@onready var reload_reset_button = keybinds_menu.get_node_or_null("ReloadResetButton")

# Add to _ready() function
if reload_keybind_button:
    reload_keybind_button.pressed.connect(_on_reload_keybind_button_pressed)
if reload_reset_button:
    reload_reset_button.pressed.connect(_on_reload_reset_button_pressed)

# Add functions
func _on_reload_keybind_button_pressed():
    if not keybinds_manager:
        return
    waiting_for_keybind = "reload"
    if reload_keybind_button:
        reload_keybind_button.text = "Press any key..."
    if keybind_error_label:
        keybind_error_label.text = ""

func _on_reload_reset_button_pressed():
    if keybinds_manager:
        keybinds_manager.reset_keybind("reload")
        update_reload_keybind_display()
        if keybind_error_label:
            keybind_error_label.text = ""

func update_reload_keybind_display():
    if not keybinds_manager or not reload_keybind_button:
        return
    var reload_keycode = keybinds_manager.get_keybind("reload")
    var key_string = keybinds_manager.keycode_to_string(reload_keycode)
    reload_keybind_button.text = key_string

# Update update_keybind_display() to also update reload display
func update_keybind_display():
    # ... existing dash code ...
    update_reload_keybind_display()  # Add this
```

### Step 4: Use Keybind in Game Logic

In the script that handles the action (e.g., `scripts/player/player.gd`):

```gdscript
func _input(event):
    # Get custom keybind
    var reload_keycode = KEY_R  # Default
    if keybinds_manager:
        reload_keycode = keybinds_manager.get_keybind("reload")
    
    # Check keyboard key
    if event is InputEventKey:
        if event.keycode == reload_keycode and event.pressed:
            start_reload()
    
    # Check mouse button
    if event is InputEventMouseButton and event.pressed:
        if reload_keycode >= 1000:  # Is it a mouse button?
            var mouse_button_index = reload_keycode - 1000
            if event.button_index == mouse_button_index:
                start_reload()
```

### Step 5: Update Display When Showing Menu

In `show_keybinds_menu()` function:

```gdscript
func show_keybinds_menu():
    # ... existing code ...
    update_reload_keybind_display()  # Add this
```

## Important Implementation Notes

### Input Handling in Pause Menu

The pause menu uses `_input()` (not `_unhandled_input()`) for keybind assignment because:
- Mouse button events might not reach `_unhandled_input()` when UI is active
- `_input()` receives all input events, including those consumed by UI
- When `waiting_for_keybind != ""`, we mark events as handled to prevent them from propagating

### Process Mode

The pause menu CanvasLayer uses `process_mode = Node.PROCESS_MODE_ALWAYS` so it can receive input events even when the game is paused (`get_tree().paused = true`).

### Conflict Detection

The system maintains a reverse mapping (`keycode_to_action`) to detect when a key is already bound to a different action. When setting a keybind:
1. Check if keycode exists in `keycode_to_action`
2. If it does and maps to a different action, return an error
3. Otherwise, update the mappings

### Keycode Display Order

The `keycode_to_string()` function must check keyboard keys BEFORE mouse buttons because:
- KEY_SHIFT = 4194325 (which is > 1000)
- Without the order check, KEY_SHIFT would be incorrectly identified as a mouse button
- Special keyboard keys (modifiers) are checked first with a `match` statement
- Then mouse buttons are checked (range 1000-1019)
- Finally, regular keyboard keys use `OS.get_keycode_string()`

## File Structure

```
scripts/
  keybind_manager.gd          # Core keybind management system
  ui/
    pause_menu.gd             # UI handling for keybind assignment
  player/
    player.gd                 # Example usage of keybinds
docs/
  scripts/
    keybind_manager.md        # This file
```

## Future Enhancements

Potential improvements to the system:

1. **Multiple Keybind Support**: Allow binding multiple keys to the same action (e.g., W or Up Arrow for move forward)
2. **Keybind Profiles**: Save/load different keybind configurations
3. **Keybind Categories**: Organize keybinds by category (Movement, Combat, UI, etc.)
4. **Controller Support**: Extend the system to support gamepad buttons
5. **Key Combination Support**: Support modifier+key combinations (Ctrl+R, Shift+Click, etc.)
6. **Keybind Validation**: Warn about problematic keybinds (e.g., binding ESC to an action)

## Troubleshooting

### Mouse Buttons Not Working

- Ensure you're using `_input()` not `_unhandled_input()` for keybind assignment
- Check that `process_mode = Node.PROCESS_MODE_ALWAYS` is set on the CanvasLayer
- Verify mouse buttons are being encoded correctly (1000 + button_index)

### Shift Key Showing as "Mouse Button 4193325"

- This happens if keyboard keys aren't checked before mouse button range check
- Ensure `keycode_to_string()` checks KEY_SHIFT in the match statement before checking for mouse buttons
- The order matters: Keyboard keys → Mouse buttons → OS.get_keycode_string()

### Keybinds Not Persisting

- Check that `user://keybinds.cfg` exists and is writable
- Verify `save_keybinds()` is being called after setting keybinds
- Check file permissions in the user data directory

### Conflict Detection Not Working

- Ensure `rebuild_keycode_mapping()` is called after loading keybinds
- Check that `keycode_to_action` dictionary is being maintained correctly
- Verify old keycode mappings are removed when updating a keybind
