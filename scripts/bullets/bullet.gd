extends CharacterBody2D

@export var speed: float = 500.0
@export var lifetime: float = 3.0  # How long bullet exists before auto-removing

var direction: Vector2 = Vector2.RIGHT
var age: float = 0.0

@onready var sprite = $Sprite2D

func _ready():
	# Rotate sprite to face movement direction
	if direction.length() > 0:
		rotation = direction.angle()

func set_direction(new_direction: Vector2):
	direction = new_direction.normalized()
	# Update rotation when direction is set
	if direction.length() > 0:
		rotation = direction.angle()

func _physics_process(delta):
	age += delta
	
	# Remove bullet after lifetime
	if age >= lifetime:
		queue_free()
		return
	
	# Move bullet in direction
	velocity = direction * speed
	move_and_slide()
	
	# Check for collisions (you can add collision detection here later)
