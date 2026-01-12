# Main Scene Technical Documentation

## Overview

The `main.tscn` file is the root scene file for the project, configured as the entry point in `project.godot` (`run/main_scene="res://scenes/main.tscn"`). It serves as the top-level container that instantiates and coordinates game entities, specifically the player character and provides the visual environment.

## Scene File Format

### Format Specification
```
[gd_scene load_steps=5 format=3 uid="uid://bwjq8x7vx3k1v"]
```

**What it does:**
- Declares a Godot scene file using format version 3 (Godot 4.x native format)
- `load_steps=5` indicates the total number of external resources and sub-resources that must be loaded before the scene can be instantiated
- `uid` is a unique identifier used by Godot's resource system for dependency tracking and caching

**Why:**
- Format version 3 is the native binary/text hybrid format for Godot 4.x, providing better performance than format 2 (text-only) while maintaining human readability
- The UID system enables Godot to track resource dependencies and detect when external resources change, triggering automatic re-imports
- Load steps are pre-calculated to optimize scene loading by batching resource fetches

**How:**
- Godot's scene parser reads the header to determine resource loading order
- Resources are loaded in dependency order: external resources first, then sub-resources that reference them

## External Resources

### Player Scene Instance
```
[ext_resource type="PackedScene" uid="uid://cx8v2laqj5m3n" path="res://scenes/player/player.tscn" id="1_player"]
```

**What it does:**
- Declares an external reference to a PackedScene resource (the player character scene)
- Assigns it an internal identifier `1_player` for use within this scene file
- The UID `uid://cx8v2laqj5m3n` is a persistent identifier embedded directly in the player scene file header (not a separate .uid file)

**Why:**
- Using PackedScene instances allows for modular scene composition and reusability
- The UID system ensures that if the player scene is moved or renamed, Godot can still locate it
- Scene instancing separates concerns: player logic/visuals are encapsulated in their own scene file

**How:**
- When the main scene loads, Godot resolves the UID to the actual file path
- The PackedScene is deserialized and instantiated as a child node of the Main node
- The instance maintains a reference to the original PackedScene, allowing for efficient duplication

### Bullet Scene Reference
```
[ext_resource type="PackedScene" uid="uid://bxy8k2v3n4m5p" path="res://scenes/bullets/bullet.tscn" id="2_0wfyh"]
```

**What it does:**
- References the bullet PackedScene that will be dynamically instantiated by the player script during gameplay
- This is not directly instantiated in the scene tree, but passed as a property to the Player node

**Why:**
- The bullet scene is not part of the static scene tree because bullets are created dynamically at runtime
- By passing it as an exported property (`bullet_scene`), the player script can instantiate bullets on-demand
- This pattern (prefab injection) allows for easy swapping of bullet types without modifying code

**How:**
- The reference is stored in the Player node's property table
- When `player.gd` calls `bullet_scene.instantiate()`, Godot creates a new instance of the bullet scene
- The instantiated bullet is added to the scene tree via `get_tree().current_scene.add_child(bullet)`

## Sub-Resources

### Gradient Resource
```
[sub_resource type="Gradient" id="Gradient_0wfyh"]
```

**What it does:**
- Creates a Gradient resource that defines color interpolation stops
- This is an empty gradient (no stops defined in the visible code), likely configured in the editor

**Why:**
- Gradients are used to create smooth color transitions for visual effects
- Sub-resources are embedded within the scene file, making the scene self-contained for simple resources

**How:**
- The gradient is stored as a sub-resource with ID `Gradient_0wfyh`
- It can be referenced by other sub-resources or nodes within the same scene file

### GradientTexture2D Resource
```
[sub_resource type="GradientTexture2D" id="GradientTexture2D_sugp2"]
gradient = SubResource("Gradient_0wfyh")
```

**What it does:**
- Creates a 2D texture resource that samples from the gradient
- References the previously defined Gradient sub-resource
- This texture can be used as a visual element (background, effect, etc.)

**Why:**
- GradientTexture2D converts a 1D gradient into a 2D texture that can be rendered
- This is more efficient than generating the texture procedurally at runtime
- Useful for backgrounds, skyboxes, or atmospheric effects

**How:**
- The texture samples the gradient along one axis (typically horizontally or vertically)
- The resulting texture is assigned to the Sprite2D node's texture property

## Node Hierarchy

### Root Node: Main (Node2D)
```
[node name="Main" type="Node2D"]
```

**What it does:**
- Defines the root node of the scene as a `Node2D`, which provides 2D transform capabilities (position, rotation, scale)
- All child nodes inherit the parent's transform space

**Why:**
- Node2D is the base class for all 2D nodes in Godot
- Using Node2D instead of Node allows for potential scene-level transformations (e.g., camera shake, scene rotation)
- The root node name "Main" matches the scene file name, following Godot conventions

**How:**
- When the scene is instantiated, this becomes the root of the scene tree
- Child nodes are positioned relative to this node's origin (0, 0)
- Transform operations on this node affect all descendants

### Player Node Instance
```
[node name="Player" parent="." instance=ExtResource("1_player")]
bullet_scene = ExtResource("2_0wfyh")
```

**What it does:**
- Instantiates the Player scene as a child of the Main node
- Sets the `bullet_scene` exported property to reference the bullet PackedScene
- The `parent="."` syntax means "parent is the current node" (the Main node)

**Why:**
- Scene instancing allows the player to be designed and tested independently
- Property injection (`bullet_scene = ExtResource("2_0wfyh")`) configures the player at the scene level rather than in code
- This separation enables designers to swap bullet types without touching scripts

**How:**
- Godot deserializes the Player PackedScene and creates a node tree
- The instance is attached to the Main node's children list
- The `bullet_scene` property is set before `_ready()` is called, so the player script can access it immediately

**Player Scene Architecture:**
The instantiated player scene contains:
- **CharacterBody2D**: Physics body for movement and collision
- **AnimatedSprite2D**: Handles 8-directional sprite animations (idle, walk, shoot) with 8 frames per animation
- **CollisionShape2D**: Defines the player's collision boundary for physics interactions
- **Camera2D**: Follows the player and provides viewport control with zoom functionality

**Player Script Behavior (`player.gd`):**
- **Movement**: Top-down 8-directional movement using WASD keys, normalized to prevent faster diagonal movement
- **Shooting**: Mouse-aimed projectile system with fire rate limiting (0.2s between shots)
- **Animation System**: Dynamically selects animations based on movement direction and shooting state
  - Uses threshold-based direction detection (0.707 for movement, 0.5 for shooting)
  - Supports 8 directions: up, down, left, right, and 4 diagonals
- **Camera Control**: Mouse wheel zoom with configurable min/max bounds and zoom speed

### Sprite2D Node (Background/Visual Element)
```
[node name="Sprite2D" type="Sprite2D" parent="."]
position = Vector2(365, 100)
texture = SubResource("GradientTexture2D_sugp2")
```

**What it does:**
- Creates a 2D sprite node positioned at world coordinates (365, 100)
- Assigns the gradient texture as its visual representation
- Renders as a child of the Main node, independent of the player

**Why:**
- Provides a visual background or atmospheric element
- Positioned at a fixed world coordinate, not following the player
- The gradient texture creates a smooth color transition effect

**How:**
- Sprite2D renders the texture at its assigned position in world space
- The texture is sampled and drawn during the rendering pass
- Since it's not a child of the Camera2D, it remains static in world space (the camera moves, not the sprite)

## Scene Execution Flow

### Initialization Sequence

1. **Scene Load**: Godot reads `main.tscn` and parses the header
2. **Resource Resolution**: External resources are located via UID lookup
3. **Sub-Resource Creation**: Gradient and GradientTexture2D are instantiated
4. **Node Tree Construction**:
   - Main Node2D root is created
   - Player PackedScene is instantiated and attached
   - Sprite2D is created and positioned
5. **Property Injection**: `bullet_scene` is assigned to the Player instance
6. **Script Initialization**: `_ready()` is called on all nodes with scripts (Player, Camera2D)
7. **First Frame**: `_process()` and `_physics_process()` begin execution

### Runtime Behavior

**Player Movement Loop:**
- `_physics_process(delta)` runs every physics frame (typically 60 FPS)
- Input polling checks WASD keys and builds a normalized direction vector
- Velocity is calculated and applied via `move_and_slide()`
- Animation state machine selects appropriate sprite frames based on direction and action

**Shooting System:**
- Mouse position is converted to world coordinates via `get_global_mouse_position()`
- Direction vector is calculated from player position to mouse position
- Fire rate timer prevents shooting faster than `fire_rate` (0.2s)
- On shoot: bullet scene is instantiated, positioned with offset, and added to scene tree
- Bullet's `set_direction()` method is called to configure trajectory

**Camera System:**
- Camera2D follows the player (inherited behavior when parented)
- `_input()` handles mouse wheel events for zoom control
- Zoom is clamped between `min_zoom` (0.1) and `max_zoom` (3.0)
- Zoom changes are applied uniformly to both X and Y axes

## Technical Considerations

### Resource Loading Performance
- **Load Steps**: The scene declares 5 load steps, which are pre-calculated for optimal loading
- **UID System**: Persistent UIDs enable Godot to cache resources and detect changes efficiently
- **PackedScene Caching**: Once loaded, PackedScenes are cached in memory, making subsequent instantiations fast

### Memory Management
- **Bullet Lifecycle**: Bullets have a `lifetime` property (3.0s) and call `queue_free()` to prevent memory leaks
- **Scene Tree**: Dynamic bullet instances are added/removed from the scene tree, managed by Godot's node system
- **Sub-Resources**: Gradient and GradientTexture2D are embedded in the scene file, reducing external dependencies

### Coordinate Systems
- **World Space**: Main node and Sprite2D use world coordinates
- **Local Space**: Player's child nodes (AnimatedSprite2D, CollisionShape2D) use local coordinates relative to player
- **Screen Space**: Camera2D converts world coordinates to viewport coordinates for rendering

### Physics Integration
- **CharacterBody2D**: Player uses CharacterBody2D for movement without automatic physics simulation
- **Collision Layers**: Bullets use `collision_layer = 2` to separate them from player collisions
- **Movement Method**: `move_and_slide()` handles collision response and sliding along surfaces

## Dependencies

### Direct Dependencies
- `res://scenes/player/player.tscn` - Player character scene
- `res://scenes/bullets/bullet.tscn` - Bullet projectile scene
- `res://scripts/player/player.gd` - Player control script (via player scene)
- `res://scripts/bullets/bullet.gd` - Bullet behavior script (via bullet scene)

### Indirect Dependencies
- Player sprite textures (AtlasTexture resources from sprite sheets)
- Player collision shape resource (`player_collision.tres`)
- Various animation frame textures (loaded by player scene)

## Scene Configuration Notes

- **Viewport Size**: Configured in `project.godot` as 1920x1080
- **Main Scene**: This scene is set as the entry point in project settings
- **Engine Version**: Godot 4.5 with C# support enabled (though this scene uses GDScript)
- **Rendering**: Forward Plus rendering pipeline with default texture filtering

## UID System: Creation and Management

### How UIDs Are Created

**Godot automatically generates UIDs** - you do not create them manually. The UID system is fully automated by the engine.

#### Automatic Generation Process

1. **On Resource Creation**: When you create a new script, scene, or resource file in Godot, the engine automatically generates a unique identifier
2. **On Import**: When external assets (images, audio, etc.) are imported, Godot generates UIDs during the import process
3. **Hash-Based Algorithm**: UIDs are generated using a hash-based algorithm that combines:
   - File path (relative to project root)
   - File content hash (for scripts and scenes)
   - Timestamp (for some resource types)
   - Random component (to ensure uniqueness)

#### UID Storage Methods

Godot uses different storage strategies depending on resource type:

**1. Embedded UIDs (Scenes and Resources)**
- **Scene files** (`.tscn`): UID is stored directly in the file header
  ```
  [gd_scene load_steps=5 format=3 uid="uid://bwjq8x7vx3k1v"]
  ```
- **Resource files** (`.tres`): UID is embedded in the resource definition
  ```
  [gd_resource type="TileSet" format=3 uid="uid://dxehuv4p1c51b"]
  ```
- **Why embedded**: These files are self-contained and the UID is part of their serialized format

**2. Separate .uid Files (Scripts)**
- **Script files** (`.gd`, `.cs`): UID is stored in a companion `.uid` file
  - Example: `player.gd` has a corresponding `player.gd.uid` file containing `uid://dm4mjrjkevtu7`
- **Why separate**: Scripts are plain text files that may be edited outside Godot; the separate `.uid` file ensures the identifier persists even if the script is modified externally

#### UID Format

UIDs follow a consistent format:
```
uid://[13-character base64-like string]
```

The identifier consists of:
- Prefix: `uid://` (protocol identifier)
- Body: 13 characters using base64-like encoding (a-z, 0-9, and some special characters)
- Example: `uid://bwjq8x7vx3k1v`

#### UID Persistence and Behavior

**Persistence:**
- UIDs are **persistent** - once assigned, they remain constant for the lifetime of the resource
- UIDs survive file moves and renames (Godot tracks them via the UID cache)
- UIDs are stored in Godot's internal cache: `.godot/uid_cache.tmp`

**When UIDs Change:**
- **Never automatically** - Godot never changes an existing UID
- **Only on deletion**: If you delete a resource and recreate it, a new UID is generated
- **Manual regeneration**: You can force regeneration by deleting the `.uid` file (for scripts) or removing the UID from the file (for scenes/resources), but this breaks all references

**UID Resolution:**
- Godot maintains a UID-to-path mapping in `.godot/uid_cache.tmp`
- When a resource is referenced by UID, Godot:
  1. Looks up the UID in the cache
  2. Resolves it to the current file path
  3. Loads the resource from that path
  4. If the path doesn't exist, Godot searches the project for a matching UID

#### Manual UID Management (Not Recommended)

**Can you manually create/edit UIDs?**
- **Technically yes**, but **strongly discouraged**
- You can edit the UID in scene/resource files or create `.uid` files manually
- **Risks:**
  - Breaking all references to that resource
  - Causing "resource not found" errors
  - Corrupting the UID cache
  - Creating duplicate UIDs (which Godot will reject)

**When Manual Intervention Might Be Needed:**
- **Version control conflicts**: If two developers create resources with the same path, UIDs might conflict
- **Project migration**: When moving projects between Godot versions
- **Cache corruption**: If `.godot/uid_cache.tmp` becomes corrupted, Godot will regenerate it

#### Best Practices

1. **Never manually edit UIDs** - Let Godot manage them automatically
2. **Commit .uid files to version control** - They're essential for project consistency
3. **Don't delete .uid files** - Unless you want to break all references
4. **Let Godot regenerate cache** - If you see UID errors, let Godot rebuild the cache rather than manually fixing UIDs

## Extension Points

The scene architecture supports several extension patterns:

1. **Additional Entities**: New nodes can be added as children of Main for enemies, collectibles, etc.
2. **Bullet Variants**: Different bullet scenes can be swapped via the `bullet_scene` property
3. **Background Layers**: Additional Sprite2D nodes can be added for parallax or layered backgrounds
4. **UI Overlay**: A CanvasLayer node could be added for HUD elements that don't move with the camera
5. **Audio**: AudioStreamPlayer2D nodes can be added for spatial sound effects
