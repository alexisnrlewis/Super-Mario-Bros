extends CharacterBody2D

@export var SPEED: float = 80.0
var is_dying: bool = false

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	add_to_group("enemy")
	set_physics_process(true)

func _physics_process(delta):
	if is_dying:
		return

	# Move horizontally
	velocity.x = SPEED
	move_and_slide()

	# Flip direction on wall collision
	if is_on_wall():
		SPEED = -SPEED
		animated_sprite.flip_h = SPEED < 0

func die():
	if is_dying:
		return
	is_dying = true

	# Play death animation
	if animated_sprite and animated_sprite.sprite_frames.has_animation("die"):
		animated_sprite.play("die")
	
	# Disable collisions immediately
	collision_layer = 0
	collision_mask = 0
	
	# Remove after 0.5 seconds
	await get_tree().create_timer(0.5).timeout
	queue_free()
