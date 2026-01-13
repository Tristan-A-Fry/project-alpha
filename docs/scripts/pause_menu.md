# Pause Menu System

## Overview

The Pause Menu is a comprehensive UI system that allows players to pause the game, navigate between different menu screens (Main, Keybinds, Dev Tools), and configure various game settings. It uses Godot's scene tree pausing mechanism to freeze all gameplay while remaining responsive to player input.

## Why This System Exists

1. **Game Control**: Provides a standard way for players to pause the game and take a break
2. **User Configuration**: Allows players to customize keybinds and adjust game settings
3. **Developer Tools**: Provides in-game debugging tools for testing and development
4. **Navigation System**: Implements a multi-menu system with proper navigation and state management
5. **Input Handling**: Demonstrates proper input handling during paused states using `PROCESS_MODE_ALWAYS`

## Architecture

### Files Involved

- **`scripts/ui/pause_menu.gd`**: Main script controlling the pause menu system
- **`scenes/main.tscn`**: Contains the PauseMenu CanvasLayer node and all UI elements
- **`scripts/keybind_manager.gd`**: Autoload singleton that the pause menu integrates with for keybind management
- **`scripts/player/player.gd`**: Player script that responds to pause state (player movement stops when paused)

### Scene Structure

The pause menu is structured as a CanvasLayer in the main scene:

```
Main Scene
└── PauseMenu (CanvasLayer)
    ├── PausePanel (Panel) - Main pause menu
    │   ├── PausedLabel (Label)
    │   ├── InstructionLabel (Label)
    │   ├── KeybindsButton (Button)
    │   └── DevToolsButton (Button)
    ├── KeybindsMenu (Panel) - Keybind configuration menu
    │   ├── KeybindsLabel (Label)
    │   ├── DashLabel (Label)
    │   ├── DashKeybindButton (Button)
    │   ├── DashResetButton (Button)
    │   ├── KeybindErrorLabel (Label)
    │   └── BackButtonKeybinds (Button)
    └── DevToolsMenu (Panel) - Developer tools menu
        ├── DevToolsLabel (Label)
        ├── PlayerSpeedSlider (HSlider)
        ├── PlayerSpeedLabel (Label)
        ├── ResetSpeedButton (Button)
        ├── BulletVelocitySlider (HSlider)
        ├── BulletVelocityLabel (Label)
        ├── ResetVelocityButton (Button)
        ├── FireRateSlider (HSlider)
        ├── FireRateLabel (Label)
        ├── ResetFireRateButton (Button)
        ├── InfiniteAmmoCheckBox (CheckBox)
        ├── InfiniteHPCheckBox (CheckBox)
        ├── ResetAllButton (Button)
        └── BackButtonDevTools (Button)
```

## How It Works

### 1. Process Mode - Critical for Paused Input

The pause menu uses `PROCESS_MODE_ALWAYS` to ensure it can receive input even when the game is paused:

```gdscript
func _ready():
    process_mode = Node.PROCESS_MODE_ALWAYS
```

**Why this is necessary:**
- When `get_tree().paused = true`, all nodes with default process mode stop processing
- This includes `_input()`, `_unhandled_input()`, and `_process()` functions
- By setting `process_mode = Node.PROCESS_MODE_ALWAYS`, the pause menu continues to process input even when the game is paused
- This allows the menu to respond to ESC key presses and button clicks while the game is frozen

**Process Mode Options:**
- `PROCESS_MODE_INHERIT` (default): Inherits process mode from parent, stops when paused
- `PROCESS_MODE_PAUSABLE`: Explicitly pauses when tree is paused
- `PROCESS_MODE_WHEN_PAUSED`: Only processes when paused (reverse of normal)
- `PROCESS_MODE_ALWAYS`: Always processes, even when paused (what we use)

### 2. Menu State Management

The system uses an enum to track which menu is currently active:

```gdscript
enum MenuState {
    MAIN,
    KEYBINDS,
    DEV_TOOLS
}

var current_menu: MenuState = MenuState.MAIN
```

**State Flow:**
- `MAIN`: Shows the main pause menu (PausePanel)
- `KEYBINDS`: Shows the keybind configuration menu (KeybindsMenu)
- `DEV_TOOLS`: Shows the developer tools menu (DevToolsMenu)

Only one menu is visible at a time. When switching menus, the current menu is hidden and the target menu is shown.

### 3. Pause/Resume Mechanism

The pause system uses Godot's scene tree pausing:

```gdscript
func toggle_pause():
    is_paused = !is_paused
    
    if is_paused:
        get_tree().paused = true  # Freeze all gameplay
        show_main_menu()
    else:
        get_tree().paused = false  # Resume gameplay
        hide_all_menus()
        current_menu = MenuState.MAIN
```

**How `get_tree().paused` works:**
- When set to `true`, all nodes with default process mode stop processing
- Physics, movement, animations, timers - everything freezes
- Nodes with `PROCESS_MODE_ALWAYS` continue to work (like our pause menu)
- When set to `false`, everything resumes from where it left off

**What gets paused:**
- Player movement and physics
- Bullet movement
- Animations
- Timers and cooldowns
- All game logic in `_process()`, `_physics_process()`, etc.

**What doesn't get paused:**
- Pause menu UI (because of `PROCESS_MODE_ALWAYS`)
- Input handling in the pause menu
- Audio (optional, can be controlled separately)

### 4. ESC Key Handling

ESC key behavior changes based on current menu state:

```gdscript
func _unhandled_input(event):
    if event is InputEventKey:
        if event.keycode == KEY_ESCAPE and event.pressed:
            if current_menu == MenuState.MAIN:
                toggle_pause()  # Pause/unpause the game
            else:
                show_main_menu()  # Go back to main menu
            get_viewport().set_input_as_handled()
```

**Behavior:**
- **Main menu + ESC**: Toggles pause (pauses if unpaused, unpauses if paused)
- **Submenu + ESC**: Returns to main pause menu (doesn't unpause)
- **Waiting for keybind + ESC**: Cancels keybind assignment

### 5. Menu Navigation System

The pause menu implements a simple state machine for navigation:

#### Main Menu

The main pause menu is displayed when `show_main_menu()` is called:

```gdscript
func show_main_menu():
    current_menu = MenuState.MAIN
    if pause_panel:
        pause_panel.visible = true
    if keybinds_menu:
        keybinds_menu.visible = false
    if dev_tools_menu:
        dev_tools_menu.visible = false
```

**UI Elements:**
- "PAUSED" label
- "Press ESC to resume" instruction
- "Keybinds" button → Navigates to KeybindsMenu
- "Dev Tools" button → Navigates to DevToolsMenu

#### Keybinds Menu

Accessed via the "Keybinds" button from the main menu:

```gdscript
func show_keybinds_menu():
    current_menu = MenuState.KEYBINDS
    if pause_panel:
        pause_panel.visible = false
    if keybinds_menu:
        keybinds_menu.visible = true
    if dev_tools_menu:
        dev_tools_menu.visible = false
    
    # Update keybind display when showing the menu
    update_keybind_display()
    if keybind_error_label:
        keybind_error_label.text = ""
```

**UI Elements:**
- "KEYBINDS" label
- Dash keybind configuration (label, button, reset button)
- Error label for conflict messages
- "Back" button → Returns to main menu

**Keybind Assignment Flow:**
1. User clicks the keybind button (e.g., "DashKeybindButton")
2. Button text changes to "Press any key..."
3. `waiting_for_keybind` is set to the action name (e.g., "dash")
4. `_input()` function waits for next input event
5. User presses a key or mouse button
6. Keybind is saved via KeybindManager
7. Display is updated to show the new keybind
8. `waiting_for_keybind` is cleared

#### Dev Tools Menu

Accessed via the "Dev Tools" button from the main menu:

```gdscript
func show_dev_tools_menu():
    current_menu = MenuState.DEV_TOOLS
    if pause_panel:
        pause_panel.visible = false
    if keybinds_menu:
        keybinds_menu.visible = false
    if dev_tools_menu:
        dev_tools_menu.visible = true
```

**UI Elements:**
- "DEV TOOLS" label
- Player Move Speed slider + label + reset button
- Bullet Velocity slider + label + reset button
- Fire Rate slider + label + reset button
- Infinite Ammo checkbox
- Infinite HP checkbox
- Reset All to Defaults button
- "Back" button → Returns to main menu

## Input Handling

### Dual Input System

The pause menu uses two input functions for different purposes:

#### `_input()` - Keybind Assignment

Used for handling keybind assignment because it receives ALL input events, including mouse buttons:

```gdscript
func _input(event):
    # Handle keybind assignment (use _input to catch mouse buttons)
    if waiting_for_keybind != "":
        # ... handle keybind assignment ...
```

**Why `_input()` for keybinds:**
- Mouse button events might not reach `_unhandled_input()` when UI is active
- `_input()` receives all input events, including those consumed by UI
- Ensures mouse buttons can be bound even when clicking UI elements
- Must mark events as handled with `get_viewport().set_input_as_handled()`

#### `_unhandled_input()` - ESC Key Handling

Used for ESC key handling because it's simpler and doesn't interfere with other input:

```gdscript
func _unhandled_input(event):
    # Only handle ESC key
    if event is InputEventKey:
        if event.keycode == KEY_ESCAPE and event.pressed:
            # Handle ESC key
```

**Why `_unhandled_input()` for ESC:**
- ESC key is typically unhandled by other systems
- Simpler logic - only handles ESC key
- Doesn't interfere with keybind assignment
- Events are marked as handled to prevent propagation

### Input Event Handling

When waiting for a keybind assignment:

1. **Keyboard keys**: Stored as `event.keycode` directly
2. **Mouse buttons**: Encoded as `1000 + event.button_index` (see keybind_manager.md for details)
3. **ESC key**: Cancels keybind assignment and returns to display
4. **Mouse wheel**: Ignored (used for zoom in gameplay)

**Event Handling Order:**
1. Check if waiting for keybind → Handle in `_input()`
2. Check for ESC key → Handle in `_unhandled_input()`
3. Other events → Pass through normally

## Dev Tools Integration

### Player Reference

The pause menu finds the player node in `_ready()`:

```gdscript
player = get_tree().get_first_node_in_group("player")
if not player:
    var main = get_tree().current_scene
    if main:
        player = main.get_node_or_null("Player")
```

**Why find the player:**
- Dev tools need to modify player properties in real-time
- Player properties (speed, bullet_speed, fire_rate) are accessed directly
- Infinite ammo/HP flags are set on the player object

### Slider Controls

Each slider (speed, bullet velocity, fire rate) has:

1. **Value changed signal**: Connected to update function
2. **Label update**: Label text is updated to show current value
3. **Reset button**: Resets slider to default value
4. **Direct property modification**: Changes player properties immediately

**Example - Player Speed:**

```gdscript
# Connect signal
if player_speed_slider:
    player_speed_slider.value_changed.connect(_on_player_speed_changed)
    player_speed_slider.value = player.speed

# Handle value change
func _on_player_speed_changed(value: float):
    if player and "speed" in player:
        player.speed = value
    _update_player_speed_label()

# Update label
func _update_player_speed_label():
    if player_speed_label and player_speed_slider:
        player_speed_label.text = "Player Move Speed: %.0f" % player_speed_slider.value
```

### Checkbox Controls

Checkboxes (Infinite Ammo, Infinite HP) toggle boolean flags on the player:

```gdscript
func _on_infinite_ammo_toggled(pressed: bool):
    if player:
        if "infinite_ammo" not in player:
            player.set("infinite_ammo", pressed)
        else:
            player.infinite_ammo = pressed
```

**Dynamic property creation:**
- Properties are created on the player if they don't exist
- Uses `player.set()` to create properties dynamically
- Otherwise uses direct property access

### Reset Functionality

Three levels of reset:

1. **Individual resets**: Each slider has its own reset button
2. **Reset All button**: Resets all sliders and checkboxes to defaults
3. **Defaults**: Stored as constants in the script

**Reset All Implementation:**

```gdscript
func reset_all_to_defaults():
    reset_player_speed()
    reset_bullet_velocity()
    reset_fire_rate()
    if infinite_ammo_checkbox:
        infinite_ammo_checkbox.button_pressed = false
    if infinite_hp_checkbox:
        infinite_hp_checkbox.button_pressed = false
```

## Keybind Integration

### KeybindManager Integration

The pause menu integrates with the KeybindManager autoload:

1. **Reference retrieval**: Gets KeybindManager in `_ready()`
2. **Keybind assignment**: Uses KeybindManager to save keybinds
3. **Keybind display**: Uses KeybindManager to convert keycodes to strings
4. **Keybind reset**: Uses KeybindManager to reset keybinds

**Keybind Assignment Flow:**

```gdscript
# When button is clicked
func _on_dash_keybind_button_pressed():
    waiting_for_keybind = "dash"
    dash_keybind_button.text = "Press any key..."

# In _input() when key is pressed
if waiting_for_keybind != "":
    var result = keybinds_manager.set_keybind(waiting_for_keybind, input_code)
    if result.success:
        waiting_for_keybind = ""
        update_keybind_display()
    else:
        # Show error message
        keybind_error_label.text = result.error
```

### Keybind Display

The keybind button text is updated to show the current keybind:

```gdscript
func update_keybind_display():
    if not keybinds_manager or not dash_keybind_button:
        return
    
    var dash_keycode = keybinds_manager.get_keybind("dash")
    var key_string = keybinds_manager.keycode_to_string(dash_keycode)
    dash_keybind_button.text = key_string
```

**When display is updated:**
- When keybinds menu is shown
- After keybind is assigned
- After keybind is reset
- After keybind assignment is cancelled

## Adding New Menu Screens

To add a new menu screen (e.g., Settings, Audio):

### Step 1: Add Menu State

In `scripts/ui/pause_menu.gd`:

```gdscript
enum MenuState {
    MAIN,
    KEYBINDS,
    DEV_TOOLS,
    SETTINGS  # New menu
}
```

### Step 2: Add UI Panel

In `scenes/main.tscn`, add a new Panel node to PauseMenu:

```gdscene
[node name="SettingsMenu" type="Panel" parent="PauseMenu"]
visible = false
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
theme_override_styles/panel = SubResource("StyleBoxFlat_pause_bg")

[node name="SettingsLabel" type="Label" parent="PauseMenu/SettingsMenu"]
# ... label configuration ...

[node name="BackButtonSettings" type="Button" parent="PauseMenu/SettingsMenu"]
# ... button configuration ...
text = "Back"
```

### Step 3: Add Reference and Show Function

In `scripts/ui/pause_menu.gd`:

```gdscript
# Add to @onready variables
@onready var settings_menu = $SettingsMenu

# Add show function
func show_settings_menu():
    current_menu = MenuState.SETTINGS
    if pause_panel:
        pause_panel.visible = false
    if keybinds_menu:
        keybinds_menu.visible = false
    if dev_tools_menu:
        dev_tools_menu.visible = false
    if settings_menu:
        settings_menu.visible = true

# Update hide_all_menus()
func hide_all_menus():
    if pause_panel:
        pause_panel.visible = false
    if keybinds_menu:
        keybinds_menu.visible = false
    if dev_tools_menu:
        dev_tools_menu.visible = false
    if settings_menu:
        settings_menu.visible = false

# Update show_main_menu() and other show functions to hide settings_menu
func show_main_menu():
    current_menu = MenuState.MAIN
    if pause_panel:
        pause_panel.visible = true
    if keybinds_menu:
        keybinds_menu.visible = false
    if dev_tools_menu:
        dev_tools_menu.visible = false
    if settings_menu:
        settings_menu.visible = false
```

### Step 4: Add Navigation Button

Add a button to the main pause menu:

```gdscene
[node name="SettingsButton" type="Button" parent="PauseMenu/PausePanel"]
# ... button configuration ...
text = "Settings"
```

Connect it in `_ready()`:

```gdscript
var settings_button = pause_panel.get_node_or_null("SettingsButton")
if settings_button:
    settings_button.pressed.connect(show_settings_menu)
```

### Step 5: Add Back Button Connection

In `_ready()`:

```gdscript
var back_settings = settings_menu.get_node_or_null("BackButtonSettings")
if back_settings:
    back_settings.pressed.connect(show_main_menu)
```

## Important Implementation Details

### Process Mode Configuration

**Critical**: The CanvasLayer must have `process_mode = Node.PROCESS_MODE_ALWAYS` to receive input when paused.

In the scene file:
```gdscene
[node name="PauseMenu" type="CanvasLayer" parent="."]
process_mode = 2  # PROCESS_MODE_ALWAYS
```

In the script:
```gdscript
func _ready():
    process_mode = Node.PROCESS_MODE_ALWAYS
```

**Why both?**
- Scene file sets the initial value
- Script ensures it's set at runtime (defensive programming)
- `process_mode = 2` is the enum value for `PROCESS_MODE_ALWAYS`

### Input Handling Separation

**Why `_input()` for keybinds and `_unhandled_input()` for ESC:**

1. **Keybind assignment**: Needs to capture all input, including mouse buttons that might be consumed by UI
2. **ESC key**: Simple, doesn't need to capture all input, cleaner separation
3. **Order matters**: `_input()` is called before `_unhandled_input()`, so keybind assignment gets priority

### Menu Visibility Management

Only one menu is visible at a time:

- When showing a menu: Hide all others, show target menu
- When hiding menus: Hide all menus
- State is tracked with `current_menu` enum

**Pattern used:**

```gdscript
func show_menu_X():
    current_menu = MenuState.X
    pause_panel.visible = false
    keybinds_menu.visible = false
    dev_tools_menu.visible = false
    menu_X.visible = true  # Show target menu
```

### Player Property Access

Dev tools modify player properties directly:

- **Properties must exist**: Properties like `speed`, `bullet_speed`, `fire_rate` must exist on the player
- **Dynamic properties**: Infinite ammo/HP properties are created if they don't exist
- **No persistence**: Changes don't persist after game closes (by design)
- **Real-time updates**: Changes apply immediately when sliders/checkboxes change

## Troubleshooting

### Menu Not Responding to Input

**Problem**: Menu doesn't respond to ESC or button clicks when paused

**Solutions:**
- Ensure `process_mode = Node.PROCESS_MODE_ALWAYS` is set
- Check that CanvasLayer has process_mode set in scene file
- Verify the script is attached to the CanvasLayer node

### ESC Key Not Working

**Problem**: ESC key doesn't pause/unpause the game

**Solutions:**
- Check that `_unhandled_input()` is implemented
- Verify ESC key isn't being consumed by another system
- Ensure `get_viewport().set_input_as_handled()` is called
- Check that `current_menu` state is being managed correctly

### Mouse Buttons Not Working for Keybinds

**Problem**: Mouse buttons can't be bound as keybinds

**Solutions:**
- Ensure `_input()` is used (not `_unhandled_input()`) for keybind assignment
- Check that mouse button events are being encoded correctly (1000 + button_index)
- Verify `get_viewport().set_input_as_handled()` is called
- Check that `waiting_for_keybind` state is being set correctly

### Dev Tools Not Working

**Problem**: Sliders don't affect player properties

**Solutions:**
- Verify player node is found in `_ready()`
- Check that player properties exist (speed, bullet_speed, fire_rate)
- Ensure signal connections are working
- Check that property names match between player script and pause menu

### Menu State Issues

**Problem**: Wrong menu shows, or multiple menus show at once

**Solutions:**
- Ensure only one menu is visible at a time in show functions
- Check that `current_menu` state is being updated correctly
- Verify all menus are hidden in `hide_all_menus()`
- Check that menu visibility is properly toggled in show functions

## Future Enhancements

Potential improvements to the pause menu system:

1. **Animated Transitions**: Add fade or slide animations between menus
2. **Menu Stacking**: Support nested menu navigation (return to previous menu)
3. **Menu History**: Track menu navigation history
4. **Keyboard Navigation**: Support arrow keys and Enter for menu navigation
5. **Menu Presets**: Save/load menu configurations
6. **Accessibility**: Add screen reader support and high contrast modes
7. **Mobile Support**: Add touch-friendly controls for mobile devices
8. **Menu Themes**: Support different visual themes for menus
