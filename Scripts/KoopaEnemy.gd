extends CharacterBody2D
class_name KoopaTroopaFly # Add a class_name for clarity

@export var speed: float = 60.0
@export var vertical_speed: float = 30.0
@export var horizontal_distance: float = 100.0
@export var vertical_distance: float = 40.0
@export var gravity: float = 0.0  # Flying Koopa doesn't fall
@export var start_direction: int = 1  # 1 for right, -1 for left

var start_position: Vector2
var direction: int
var vertical_direction: int = 1

func _ready():
	start_position = position
	direction = start_direction
	add_to_group("enemy") # IMPORTANT: Ensure this enemy is in the 'enemy' group

func _physics_process(delta):
	# Horizontal patrol motion
	if abs(position.x - start_position.x) >= horizontal_distance:
		direction *= -1  # Reverse horizontal direction

	# Vertical hover motion
	if abs(position.y - start_position.y) >= vertical_distance:
		vertical_direction *= -1  # Reverse vertical direction

	# Apply movement
	velocity.x = direction * speed
	velocity.y = vertical_direction * vertical_speed

	move_and_slide()

	# Collision Check: Player Death Logic
	_check_player_collision()

	# Optional: Flip sprite when changing direction
	if has_node("Sprite2D"):
		$Sprite2D.flip_h = direction < 0

# NEW FUNCTION: Check if player hit the side
func _check_player_collision():
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		# Check if the colliding object is the player
		if collider.is_in_group("player"):
			var normal = collision.get_normal()
			
			# Death Check: If the collision is mostly horizontal (not a stomp)
			# The collision is a "side-hit" if the normal.y is close to 0 (e.g., -0.5 to 0.5).
			if abs(normal.y) < 0.6: 
				
				# Call the player's death function directly
				if collider.has_method("lose_life"):
					collider.lose_life()
					
				return # Only process one collision
