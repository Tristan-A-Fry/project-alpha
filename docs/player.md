# Player Scene and Script Technical Documentation

## Overview

The player system (`player.tscn` and `player.gd`) implements a top-down character controller with 8-directional movement, mouse-aimed shooting, dash mechanics, and comprehensive sprite animations. The player is a modular, reusable scene that can be instantiated in any game scene, providing complete player functionality including movement, combat, and visual feedback.

## Scene File Structure

### Format Specification
```
[gd_scene load_steps=184 format=3 uid="uid://cx8v2laqj5m3n"]
```

**What it does:**
- Declares a Godot scene file using format version 3 (Godot 4.x native format)
- `load_steps=184` indicates the total number of external resources and sub-resources (textures, animations, collision shapes, etc.)
- `uid="uid://cx8v2laqj5m3n"` is a unique identifier embedded in the scene file header for dependency tracking

**Why:**
- Format version 3 provides optimal performance while maintaining human readability
- High load_steps count reflects the extensive sprite animation system (multiple directions × multiple animation types × 8 frames each)
- UID enables Godot to track scene dependencies and detect changes across the project

**How:**
- Godot's scene parser reads the header to determine resource loading order
- 184 resources are loaded in dependency order before the scene can be instantiated
- The scene can be referenced by UID from other scenes (e.g., `main.tscn`)

## External Resources

### Script Resource
```
[ext_resource type="Script" uid="uid://dm4mjrjkevtu7" path="res://scripts/player/player.gd" id="1_player"]
```

**What it does:**
- References the player control script that handles all gameplay logic
- The script is attached to the root CharacterBody2D node
- UID ensures script can be located even if file is moved

**Why:**
- Separates logic (script) from data (scene file)
- Script can be edited independently without modifying scene file
- UID system provides resilience to file system changes

**How:**
- Script is loaded and compiled by Godot's GDScript compiler
- Attached to the Player node via `script = ExtResource("1_player")`
- Script methods are called automatically by Godot's node system

### Collision Shape Resource
```
[ext_resource type="Shape2D" path="res://scenes/player/player_collision.tres" id="2_collision"]
```

**What it does:**
- Defines the player's collision boundary for physics interactions
- Used by the CollisionShape2D node to determine collision detection area

**Why:**
- Separate resource allows collision shape to be reused or easily modified
- Can be edited in the editor without modifying scene structure
- Provides clean separation between collision data and scene hierarchy

**How:**
- Shape2D resource defines the geometric boundary
- CollisionShape2D node references this resource via `shape = ExtResource("2_collision")`
- Physics engine uses this shape for collision detection and response

### Texture Resources (Sprite Sheets)

The scene references 15 external texture resources representing sprite sheets for different animation states:

1. **Idle Animations** (6 directions):
   - `idle_down.png` - Down direction idle
   - `idle_left_down.png` - Down-left diagonal idle
   - `idle_left_up.png` - Up-left diagonal idle
   - `idle_right_down.png` - Down-right diagonal idle
   - `idle_right_up.png` - Up-right diagonal idle
   - `idle_up.png` - Up direction idle

2. **Shoot Animations** (8 directions):
   - `Shooting_down.png` - Down direction shooting
   - `Shooting_left.png` - Left direction shooting
   - `Shooting_left_down.png` - Down-left diagonal shooting
   - `Shooting_left_up.png` - Up-left diagonal shooting
   - `Shooting_right.png` - Right direction shooting
   - `Shooting_right_down.png` - Down-right diagonal shooting
   - `Shooting_right_up.png` - Up-right diagonal shooting
   - `Shooting_up.png` - Up direction shooting

3. **Walk Animations** (7 directions):
   - `Walk_Gun_down.png` - Down direction walking
   - `Walk_Gun_left_down.png` - Down-left diagonal walking
   - `Walk_Gun_left_up.png` - Up-left diagonal walking
   - `Walk_Gun_right_down.png` - Down-right diagonal walking
   - `Walk_Gun_right_up.png` - Up-right diagonal walking
   - `Walk_Gun_up.png` - Up direction walking

**What it does:**
- Each texture is a sprite sheet containing 8 animation frames
- Frames are extracted via AtlasTexture sub-resources
- Animations are assembled into SpriteFrames resource

**Why:**
- Sprite sheets optimize memory usage (single texture per direction)
- AtlasTexture allows efficient frame extraction without creating individual frame files
- Organized by animation type and direction for easy management

**How:**
- Texture2D resources are loaded from disk
- AtlasTexture sub-resources reference these textures with Rect2 regions
- SpriteFrames resource assembles AtlasTextures into animation sequences

## Sub-Resources

### AtlasTexture Sub-Resources

The scene contains approximately 180+ AtlasTexture sub-resources, each defining a single frame from a sprite sheet.

**Format Example:**
```
[sub_resource type="AtlasTexture" id="AtlasTexture_6cv16"]
atlas = ExtResource("2_ugbui")
region = Rect2(0, 0, 48, 64)
```

**What it does:**
- `atlas`: References the source Texture2D (sprite sheet)
- `region`: Defines the rectangular region (x, y, width, height) to extract
- Each AtlasTexture represents one frame of animation

**Why:**
- Allows frame-by-frame animation from sprite sheets
- More efficient than individual texture files
- Enables precise frame timing and sequencing

**How:**
- Rect2 coordinates define pixel boundaries within the sprite sheet
- Frame size: 48×64 pixels (consistent across all animations)
- Frames are arranged horizontally in sprite sheets (8 frames per sheet)

### SpriteFrames Resource

The SpriteFrames resource (`SpriteFrames_lvxji`) contains 21 animation sequences, each with 8 frames.

**Animation Categories:**

1. **Idle Animations** (6 animations):
   - `idle down`, `idle left down`, `idle left up`, `idle right down`, `idle right up`, `idle up`

2. **Shoot Animations** (8 animations):
   - `shoot down`, `shoot left`, `shoot left down`, `shoot left up`, `shoot right`, `shoot right down`, `shoot right up`, `shoot up`

3. **Walk Animations** (7 animations):
   - `walk down`, `walk left down`, `walk left up`, `walk right down`, `walk right up`, `walk up`

**Animation Properties:**
- **Frame Count**: 8 frames per animation
- **Frame Duration**: 1.0 second per frame
- **Speed**: 5.0 (multiplier for playback speed)
- **Loop**: true (all animations loop continuously)

**Why:**
- Organized by action type for easy animation state management
- Consistent frame count and timing across all animations
- Looping ensures smooth animation transitions

**How:**
- SpriteFrames resource groups AtlasTextures into named sequences
- AnimatedSprite2D node references SpriteFrames via `sprite_frames` property
- Script dynamically selects animation based on player state

## Node Hierarchy

### Root Node: Player (CharacterBody2D)
```
[node name="Player" type="CharacterBody2D"]
script = ExtResource("1_player")
```

**What it does:**
- Root node of the player scene
- CharacterBody2D provides physics body for movement and collision
- Script handles all player logic

**Why:**
- CharacterBody2D is ideal for player-controlled characters
- Provides `move_and_slide()` for smooth movement with collision response
- Root node structure allows scene to be instantiated as a single unit

**How:**
- When instantiated, this node becomes the root of the player instance
- Script attached via `script = ExtResource("1_player")`
- Child nodes are positioned relative to this node

### AnimatedSprite2D Node
```
[node name="AnimatedSprite2D" type="AnimatedSprite2D" parent="."]
texture_filter = 1
position = Vector2(10, -3)
sprite_frames = SubResource("SpriteFrames_lvxji")
animation = &"idle left down"
autoplay = "idle down"
```

**What it does:**
- Renders sprite animations for the player character
- Displays current animation frame based on player state
- Positioned with offset (10, -3) for visual alignment

**Properties:**
- `texture_filter = 1`: Linear filtering for smoother sprite rendering
- `position = Vector2(10, -3)`: Visual offset to align sprite with collision shape
- `sprite_frames`: References the SpriteFrames resource containing all animations
- `animation`: Current animation name (dynamically changed by script)
- `autoplay = "idle down"`: Starts with idle down animation

**Why:**
- AnimatedSprite2D efficiently handles frame-by-frame animation
- Visual offset compensates for sprite positioning relative to collision
- Texture filter improves appearance at non-pixel-perfect scales

**How:**
- Script calls `animated_sprite.play(anim_name)` to switch animations
- AnimatedSprite2D automatically cycles through frames based on speed
- Looping animations restart automatically when reaching the end

### CollisionShape2D Node
```
[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
position = Vector2(2, 0)
shape = ExtResource("2_collision")
```

**What it does:**
- Defines the player's collision boundary for physics interactions
- Offset position (2, 0) aligns collision with sprite visual
- Uses external Shape2D resource for collision geometry

**Why:**
- Separate collision shape allows independent editing
- Position offset ensures collision aligns with visual representation
- Essential for physics-based movement and collision detection

**How:**
- Shape2D resource defines the geometric boundary
- Physics engine uses this shape for collision queries
- `move_and_slide()` respects this collision boundary

### Camera2D Node
```
[node name="Camera2D" type="Camera2D" parent="."]
```

**What it does:**
- Provides viewport camera that follows the player
- Allows zoom control via mouse wheel
- Defines the visible game area

**Why:**
- Parented to player for automatic following
- Zoom functionality enhances gameplay experience
- Essential for top-down gameplay

**How:**
- Camera2D automatically centers on its parent (player)
- Script adjusts zoom via `camera.zoom` property
- Mouse wheel input triggers zoom changes

## Script Implementation

### Script Overview (`player.gd`)

The player script implements a comprehensive top-down character controller with multiple gameplay systems:

1. **Movement System**: 8-directional WASD movement
2. **Shooting System**: Mouse-aimed projectile shooting
3. **Dash System**: Mouse-aimed dash with cooldown
4. **Animation System**: Dynamic 8-directional sprite animations
5. **Camera System**: Mouse wheel zoom control

### Class Declaration and Exports

```gdscript
extends CharacterBody2D

# Player movement variables for top-down view
@export var speed: float = 200.0

# Camera zoom variables
@export var min_zoom: float = 0.1
@export var max_zoom: float = 3.0
@export var zoom_speed: float = 0.1

# Shooting variables
@export var bullet_scene: PackedScene
@export var bullet_speed: float = 500.0
@export var fire_rate: float = 0.2  # Time between shots

# Dash variables
@export var dash_speed: float = 500.0
@export var dash_duration: float = 0.15  # How long the dash lasts
@export var dash_cooldown: float = 0.5  # Cooldown between dashes
```

**What it does:**
- `extends CharacterBody2D`: Inherits from CharacterBody2D for physics-based movement
- `@export` variables: Exposed to inspector for runtime tuning
- Organized by system (movement, camera, shooting, dash)

**Why:**
- @export allows designers to adjust values without code changes
- Clear organization improves code maintainability
- Default values provide reasonable gameplay out-of-the-box

**How:**
- Godot's inspector displays @export variables
- Values can be modified at runtime or in editor
- Script accesses these variables directly

### Node References

```gdscript
@onready var animated_sprite = $AnimatedSprite2D
@onready var camera = $Camera2D
```

**What it does:**
- `@onready`: Initializes after node enters scene tree
- `$` syntax: Shorthand for `get_node()` path resolution
- Stores references to child nodes for efficient access

**Why:**
- @onready ensures nodes exist before accessing them
- Node path syntax is concise and readable
- Cached references avoid repeated get_node() calls

**How:**
- @onready variables are initialized after `_ready()` but before `_process()`
- `$AnimatedSprite2D` resolves to the child node named "AnimatedSprite2D"
- References are cached for performance

### State Variables

```gdscript
var last_direction: Vector2 = Vector2.DOWN
var mouse_direction: Vector2 = Vector2.DOWN
var time_since_last_shot: float = 0.0
var is_shooting: bool = false
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
```

**What it does:**
- `last_direction`: Stores facing direction for idle animations
- `mouse_direction`: Current mouse cursor direction (normalized)
- Timers: Track time for rate limiting (shooting, dash cooldown)
- Flags: Track state (shooting, dashing)

**Why:**
- State variables enable complex behavior (animations, rate limiting)
- Direction tracking allows proper sprite facing
- Timers prevent input spam and balance gameplay

**How:**
- Updated every frame in `_physics_process()`
- Used for decision-making (animation selection, cooldown checks)
- Reset/updated based on player actions

### Main Update Loop: `_physics_process(delta)`

This function runs every physics frame (typically 60 FPS) and handles all player logic:

#### Timer Updates
```gdscript
time_since_last_shot += delta
dash_cooldown_timer -= delta

if is_dashing:
    dash_timer -= delta
    if dash_timer <= 0.0:
        is_dashing = false
        dash_timer = 0.0
```

**What it does:**
- Increments shooting timer (used for fire rate limiting)
- Decrements dash cooldown timer
- Manages dash duration timer

**Why:**
- Delta-based timers are frame-rate independent
- Cooldown system prevents ability spam
- Dash duration ensures dash is time-limited

**How:**
- `delta` is the time since last frame (typically 1/60 second)
- Timers count up (shooting) or down (cooldown, dash duration)
- When timers reach thresholds, state changes occur

#### Mouse Direction Calculation
```gdscript
var mouse_pos = get_global_mouse_position()
mouse_direction = (mouse_pos - global_position).normalized()
```

**What it does:**
- Gets mouse cursor position in world coordinates
- Calculates direction vector from player to mouse
- Normalizes vector to unit length (magnitude = 1.0)

**Why:**
- World coordinates ensure consistent direction calculation
- Normalized vector provides consistent magnitude for movement/shooting
- Used for aiming, shooting, and dashing

**How:**
- `get_global_mouse_position()` converts screen coordinates to world space
- Vector subtraction gives direction (mouse - player)
- `.normalized()` scales vector to length 1.0

#### Movement System

The movement system has two modes: dash movement and normal movement.

**Dash Movement (Priority):**
```gdscript
if is_dashing:
    velocity = mouse_direction * dash_speed
    last_direction = mouse_direction
```

**What it does:**
- Overrides normal movement when dashing
- Moves in mouse direction at dash speed
- Updates facing direction to match dash direction

**Why:**
- Dash takes priority over normal movement (combat mobility)
- Mouse direction allows precise dash targeting
- Higher speed (500.0) provides significant mobility boost

**How:**
- `is_dashing` flag controls which movement system is active
- Velocity is set directly (not accumulated)
- `move_and_slide()` applies velocity in next frame

**Normal Movement:**
```gdscript
else:
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
    
    if input_direction != Vector2.ZERO:
        velocity = input_direction * speed
        last_direction = input_direction
    else:
        velocity = velocity.move_toward(Vector2.ZERO, speed)
```

**What it does:**
- Polls WASD keys to build direction vector
- Normalizes direction to prevent faster diagonal movement
- Applies velocity based on input, or decelerates to zero

**Why:**
- WASD provides intuitive 8-directional movement
- Normalization ensures consistent speed in all directions
- `move_toward()` provides smooth deceleration

**How:**
- Each key press modifies the direction vector components
- Normalization scales vector to unit length
- Velocity is set directly for responsive movement
- `move_toward()` interpolates velocity to zero when no input

**Coordinate System:**
- Y-axis: Negative = up/north, Positive = down/south
- X-axis: Negative = left/west, Positive = right/east
- This matches Godot's 2D coordinate system convention

#### Movement Application
```gdscript
move_and_slide()
```

**What it does:**
- Applies velocity to the CharacterBody2D
- Handles collision detection and sliding along surfaces
- Updates node's global_position based on velocity

**Why:**
- `move_and_slide()` provides smooth movement with collision response
- Automatically handles collision detection
- Standard method for CharacterBody2D movement

**How:**
- Uses current `velocity` property to move the character
- Checks collisions using CollisionShape2D
- Adjusts movement to slide along surfaces if collision detected
- Updates position at end of physics frame

### Input Handling: `_input(event)`

Handles discrete input events (key presses, mouse buttons):

#### Dash Input
```gdscript
if event is InputEventKey:
    if event.keycode == KEY_SHIFT and event.pressed:
        start_dash()
```

**What it does:**
- Detects Left Shift key press events
- Calls `start_dash()` when shift is pressed
- Uses event-based input (fires once per press, not every frame)

**Why:**
- Event-based input prevents repeated triggering
- `event.pressed` ensures dash only triggers on key down (not release)
- KEY_SHIFT detects shift key specifically

**How:**
- `_input()` is called once per input event
- Type checking (`is InputEventKey`) filters keyboard events
- `event.pressed` is true when key is pressed down

#### Camera Zoom
```gdscript
if event is InputEventMouseButton:
    if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
        var new_zoom = camera.zoom.x - zoom_speed
        new_zoom = clamp(new_zoom, min_zoom, max_zoom)
        camera.zoom = Vector2(new_zoom, new_zoom)
    elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
        var new_zoom = camera.zoom.x + zoom_speed
        new_zoom = clamp(new_zoom, min_zoom, max_zoom)
        camera.zoom = Vector2(new_zoom, new_zoom)
```

**What it does:**
- Detects mouse wheel scroll events
- Adjusts camera zoom level based on scroll direction
- Clamps zoom to min/max bounds

**Why:**
- Mouse wheel provides intuitive zoom control
- Clamping prevents invalid zoom values
- Uniform zoom (x and y same) maintains aspect ratio

**How:**
- `InputEventMouseButton` detects wheel as a button event
- Zoom is applied uniformly (Vector2 with same x and y values)
- `clamp()` ensures zoom stays within bounds

### Dash System

#### `start_dash()` Function
```gdscript
func start_dash():
    if dash_cooldown_timer > 0.0:
        return
    
    if is_dashing:
        return
    
    is_dashing = true
    dash_timer = dash_duration
    dash_cooldown_timer = dash_cooldown
    last_direction = mouse_direction
```

**What it does:**
- Checks if dash is available (not on cooldown, not already dashing)
- Activates dash state and starts timers
- Updates facing direction to dash direction

**Why:**
- Cooldown prevents dash spam (gameplay balance)
- State check prevents dash interruption
- Timers control dash duration and cooldown period

**How:**
- Early returns prevent dash if conditions aren't met
- Flags and timers track dash state
- Direction is updated for visual feedback

**Execution Flow:**
1. Check cooldown timer (must be <= 0.0)
2. Check dash state (must not already be dashing)
3. Set `is_dashing = true`
4. Start dash duration timer
5. Start cooldown timer
6. Update facing direction

### Shooting System

#### `handle_shooting()` Function
```gdscript
func handle_shooting():
    if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
        last_direction = mouse_direction
        if time_since_last_shot >= fire_rate:
            shoot()
    else:
        is_shooting = false
```

**What it does:**
- Polls left mouse button state (pressed = true while held)
- Updates facing direction to mouse cursor
- Checks fire rate before shooting
- Resets shooting flag when mouse released

**Why:**
- Continuous polling allows held-button shooting
- Fire rate prevents bullet spam
- Direction update ensures character faces target

**How:**
- `Input.is_mouse_button_pressed()` returns true while button held
- Fire rate check: `time_since_last_shot >= fire_rate`
- `shoot()` is called when rate limit allows

#### `shoot()` Function
```gdscript
func shoot():
    if not bullet_scene:
        return
    
    time_since_last_shot = 0.0
    is_shooting = true
    
    var bullet = bullet_scene.instantiate()
    get_tree().current_scene.add_child(bullet)
    
    var spawn_offset = mouse_direction * 20
    bullet.global_position = global_position + spawn_offset
    
    if bullet.has_method("set_direction"):
        bullet.set_direction(mouse_direction)
    elif "direction" in bullet:
        bullet.direction = mouse_direction
    elif "velocity" in bullet:
        bullet.velocity = mouse_direction * bullet_speed
```

**What it does:**
- Creates bullet instance from PackedScene
- Positions bullet in front of player (20 pixel offset)
- Configures bullet direction/speed via multiple methods
- Resets fire rate timer

**Why:**
- Scene instantiation allows dynamic bullet creation
- Spawn offset prevents bullet from spawning inside player
- Multiple configuration methods provide flexibility

**How:**
- `bullet_scene.instantiate()` creates new node instance
- `add_child()` adds bullet to scene tree
- Position offset uses mouse_direction for proper spawning
- Method checking allows different bullet implementations

**Bullet Configuration Methods (in order of preference):**
1. `set_direction()` method (preferred)
2. `direction` property (direct assignment)
3. `velocity` property (fallback)

### Animation System

#### `update_animations(direction: Vector2)` Function

This function dynamically selects the appropriate animation based on player state:

```gdscript
func update_animations(direction: Vector2):
    if not animated_sprite.sprite_frames:
        return
    
    var anim_name: String = ""
    var is_moving = velocity.length() > 0
    var is_shooting_button = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
    
    if is_shooting_button:
        anim_name = get_direction_animation(mouse_direction, "shoot")
        last_direction = mouse_direction
    elif is_moving:
        anim_name = get_direction_animation(direction, "walk")
        last_direction = direction
    else:
        anim_name = get_direction_animation(last_direction, "idle")
    
    if anim_name != "" and animated_sprite.sprite_frames.has_animation(anim_name):
        animated_sprite.play(anim_name)
```

**What it does:**
- Determines current player state (shooting, moving, idle)
- Selects animation name based on state and direction
- Plays selected animation if it exists

**Priority Order:**
1. **Shooting** (highest priority) - If mouse button held, use shoot animation
2. **Moving** - If velocity > 0, use walk animation
3. **Idle** - If not shooting or moving, use idle animation

**Why:**
- Priority system ensures correct animation (shooting overrides movement)
- Direction-based selection provides 8-directional animations
- State checking prevents animation conflicts

**How:**
- Checks input state (mouse button) and movement state (velocity)
- Calls `get_direction_animation()` to determine animation name
- Plays animation via `animated_sprite.play()`

#### `get_direction_animation(dir: Vector2, anim_type: String) -> String`

This function converts a direction vector and animation type into an animation name:

```gdscript
func get_direction_animation(dir: Vector2, anim_type: String) -> String:
    var prefix = anim_type  # "walk", "idle", or "shoot"
    
    if dir.length() < 0.1:
        dir = last_direction if last_direction.length() > 0.1 else Vector2.DOWN
    
    if anim_type == "shoot":
        return get_shoot_direction_animation(dir)
    
    var threshold = 0.707  # Cos/Sin of 45 degrees
    var abs_x = abs(dir.x)
    var abs_y = abs(dir.y)
    
    if abs_y > abs_x * threshold:
        if dir.y < 0:
            return prefix + " up"
        else:
            return prefix + " down"
    else:
        if dir.y < 0:
            if dir.x < 0:
                return prefix + " left up"
            else:
                return prefix + " right up"
        else:
            if dir.x < 0:
                return prefix + " left down"
            else:
                return prefix + " right down"
```

**What it does:**
- Takes direction vector and animation type
- Converts to 6-directional animation name (for walk/idle)
- Uses threshold-based direction detection

**Direction Detection:**
- **Threshold**: 0.707 (cosine/sine of 45 degrees)
- **Vertical detection**: If `abs_y > abs_x * threshold`, treat as primarily vertical
- **Horizontal/diagonal**: Otherwise, check quadrant (upper/lower, left/right)

**Animation Names (walk/idle):**
- `"walk up"` / `"idle up"`
- `"walk down"` / `"idle down"`
- `"walk left up"` / `"idle left up"`
- `"walk left down"` / `"idle left down"`
- `"walk right up"` / `"idle right up"`
- `"walk right down"` / `"idle right down"`

**Why:**
- 6-directional animations (not 8) for walk/idle
- Threshold prevents jittery animation switching
- Handles zero-length vectors (uses last_direction as fallback)

**How:**
- Compares absolute x and y components
- Threshold determines if direction is "more vertical" or "more horizontal"
- Quadrant checking determines diagonal direction

#### `get_shoot_direction_animation(dir: Vector2) -> String`

Handles 8-directional shooting animations (includes pure left/right):

```gdscript
func get_shoot_direction_animation(dir: Vector2) -> String:
    var abs_x = abs(dir.x)
    var abs_y = abs(dir.y)
    var threshold = 0.5  # Threshold for pure directions
    
    if abs_x < threshold:
        if dir.y < 0:
            return "shoot up"
        else:
            return "shoot down"
    elif abs_y < threshold:
        if dir.x < 0:
            return "shoot left"
        else:
            return "shoot right"
    else:
        if dir.y < 0:
            if dir.x < 0:
                return "shoot left up"
            else:
                return "shoot right up"
        else:
            if dir.x < 0:
                return "shoot left down"
            else:
                return "shoot right down"
```

**What it does:**
- Converts direction to 8-directional shoot animation name
- Detects pure vertical (up/down), pure horizontal (left/right), and diagonals
- Uses lower threshold (0.5) for more precise direction detection

**Animation Names (shoot):**
- `"shoot up"` - Pure up
- `"shoot down"` - Pure down
- `"shoot left"` - Pure left
- `"shoot right"` - Pure right
- `"shoot left up"` - Up-left diagonal
- `"shoot left down"` - Down-left diagonal
- `"shoot right up"` - Up-right diagonal
- `"shoot right down"` - Down-right diagonal

**Why:**
- Shooting has 8 directions (includes pure left/right)
- Lower threshold (0.5 vs 0.707) allows pure horizontal detection
- More precise aiming provides better visual feedback

**How:**
- Checks if x or y component is below threshold (pure direction)
- Otherwise treats as diagonal and checks quadrant
- Returns appropriate animation name string

## Technical Architecture

### Scene-Script Relationship

**Scene File Responsibilities:**
- Defines node hierarchy and structure
- Configures visual components (sprite, animations)
- Sets up collision geometry
- References external resources

**Script Responsibilities:**
- Implements gameplay logic
- Handles input processing
- Manages state (movement, shooting, dashing)
- Controls animations dynamically

**Why This Separation:**
- **Modularity**: Scene can be modified without code changes
- **Reusability**: Scene can be instantiated multiple times
- **Maintainability**: Logic and data are separated
- **Editor Integration**: Visual components editable in editor

### State Management

The player uses a state machine approach with flags and timers:

**States:**
- **Movement State**: Normal movement vs Dash movement
- **Action State**: Idle vs Moving vs Shooting
- **Animation State**: Determined by action state and direction

**State Variables:**
- `is_dashing`: Boolean flag for dash state
- `is_shooting`: Boolean flag for shooting state
- `velocity.length() > 0`: Determines movement state
- Timers: Track state durations and cooldowns

**State Transitions:**
- Dash: Triggered by input → Timer-based duration → Cooldown period
- Shooting: Triggered by input → Continuous while button held → Released
- Movement: Triggered by input → Continuous while key held → Released

### Coordinate Systems

**World Coordinates:**
- Player position: `global_position` (Vector2)
- Mouse position: `get_global_mouse_position()` (Vector2)
- Directions calculated in world space

**Local Coordinates:**
- Child nodes positioned relative to player
- Sprite offset: Vector2(10, -3)
- Collision offset: Vector2(2, 0)

**Why:**
- World coordinates ensure consistency across scene hierarchy
- Local coordinates simplify child node positioning
- Offsets align visual and collision representations

### Performance Considerations

**Frame Rate Independence:**
- All timers use `delta` parameter
- Movement speed is pixels/second (not pixels/frame)
- Ensures consistent gameplay across frame rates

**Efficient Node Access:**
- `@onready` variables cache node references
- Avoids repeated `get_node()` calls
- Direct property access is faster

**Animation System:**
- SpriteFrames resource efficiently stores animations
- AtlasTexture minimizes memory usage
- Animation selection is O(1) string comparison

### Input Handling Architecture

**Event-Based Input (`_input()`):**
- Dash input: Discrete events (key press)
- Camera zoom: Discrete events (mouse wheel)

**Polling-Based Input (`_physics_process()`):**
- Movement: Continuous polling (key held)
- Shooting: Continuous polling (mouse held)
- Mouse position: Continuous polling

**Why Different Approaches:**
- Event-based: For discrete actions (dash, zoom)
- Polling-based: For continuous actions (movement, shooting)
- Polling provides responsive continuous input

## Animation System Details

### Animation Organization

**Total Animations**: 21 unique animations
- 6 idle animations (6 directions)
- 8 shoot animations (8 directions)
- 7 walk animations (7 directions)

**Frame Structure:**
- 8 frames per animation
- 48×64 pixels per frame
- 1.0 second per frame duration
- 5.0 speed multiplier
- All animations loop

### Animation Selection Logic

**Priority System:**
1. **Shooting** (if mouse button held) → Use shoot animation in mouse direction
2. **Moving** (if velocity > 0) → Use walk animation in movement direction
3. **Idle** (otherwise) → Use idle animation in last facing direction

**Direction Resolution:**
- Shooting: 8 directions (includes pure left/right)
- Walk/Idle: 6 directions (diagonals only, no pure horizontal)

**Why Different Direction Counts:**
- Shooting animations include pure left/right sprites
- Walk/Idle animations don't have pure left/right variants
- Script adapts to available animations

## Extension Points

The player system can be extended in several ways:

1. **Additional Abilities**: Add new ability functions similar to dash/shoot
2. **Animation States**: Add new animation types (jump, hurt, etc.)
3. **Movement Modes**: Implement different movement styles (crouch, sprint)
4. **Combat Systems**: Add melee attacks, weapon switching, etc.
5. **Status Effects**: Implement buffs/debuffs (speed boost, slow, etc.)
6. **Audio Integration**: Add footstep sounds, dash sounds, etc.

## Summary

The player system is a comprehensive character controller combining:
- **Scene Structure**: Complex node hierarchy with animations and collision
- **Script Logic**: Multi-system gameplay implementation (movement, combat, dash)
- **Animation System**: Dynamic 8-directional sprite animations
- **Input Handling**: Hybrid event/polling input architecture
- **State Management**: Flag and timer-based state tracking

It provides a robust, extensible foundation for top-down gameplay with smooth movement, responsive combat, and polished visual feedback.