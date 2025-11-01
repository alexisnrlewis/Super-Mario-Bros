extends CharacterBody2D

# -------------------------------
# Player Properties
# -------------------------------
@export var SPEED: float = 300.0
@export var JUMP_VELOCITY: float = -1025.0
@export var GRAVITY: float = 1400.0
@export var STOMP_BOUNCE: float = -500.0 # Player bounce when stomping

var score: int = 0
var has_fire_power: bool = false
var facing_direction: int = 1

@export var fireball_scene: PackedScene

@onready var camera: Camera2D = $Camera2D
@onready var score_label: Label = $UI/ScoreLabel
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

# -------------------------------
# Ready
# -------------------------------
func _ready():
	add_to_group("player")
	_update_score_label()

# -------------------------------
# Physics Process
# -------------------------------
func _physics_process(delta):
	# Horizontal movement
	var input_dir = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	velocity.x = input_dir * SPEED

	if input_dir > 0:
		facing_direction = 1
	elif input_dir < 0:
		facing_direction = -1

	# Animation
	if input_dir != 0:
		animated_sprite.flip_h = facing_direction < 0
		if animated_sprite.sprite_frames.has_animation("run"):
			animated_sprite.play("run")
	else:
		if animated_sprite.sprite_frames.has_animation("idle"):
			animated_sprite.play("idle")
		else:
			animated_sprite.stop()

	# Gravity / Jump
	if not is_on_floor():
		velocity.y += GRAVITY * delta
		# Check if falling for jump animation state (if you have one)
		if animated_sprite.sprite_frames.has_animation("jump"):
			animated_sprite.play("jump")
	elif Input.is_action_just_pressed("ui_up"):
		velocity.y = JUMP_VELOCITY

# Enemy Collisions: Stomp or Death
func _check_enemy_collisions():
	# Loop through all collisions from move_and_slide()
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var enemy = collision.get_collider()
		
		# Ensure the collided object is a valid enemy
		if enemy and enemy.is_in_group("enemy"):
			var normal = collision.get_normal()
			
			# Stomp Check: 
			# Collision normal points mostly up (normal.y is a large negative number, like -1)
			# We use a threshold (e.g., -0.5) to allow for slopes/imperfect landings.
			# Also ensure the player was moving downward/falling before the collision.
			if normal.y < -0.5:
				_stomp_enemy(enemy)
				return # Stomp handled, exit the function
			
			# Side-Hit/Death Check:
			# Not a stomp (normal is mostly horizontal)
			elif normal.y >= -0.5:
				lose_life()
				return # Death handled, exit the function

func _stomp_enemy(enemy: Node):
	# Call enemy's die method if exists
	if enemy.has_method("die"):
		enemy.die()
	else:
		enemy.queue_free()

	# Bounce player
	velocity.y = STOMP_BOUNCE

	# Add points
	score += 100
	_update_score_label()

# Coin / Score
func collect_coin(value: int = 10):
	score += value
	_update_score_label()

func _update_score_label():
	if score_label:
		score_label.text = "Score: %d" % score

# Death / Lose Life
func lose_life():
	if get_tree().paused:
		return

	set_physics_process(false)

	# Remove existing GameOver screens
	for child in get_tree().root.get_children():
		if "GameOverScreen" in str(child):
			child.queue_free()

	# Add new GameOver screen
	var game_over_scene = preload("res://Scenes/game_over.tscn")
	var game_over = game_over_scene.instantiate()
	game_over.name = "GameOverScreen"
	get_tree().root.add_child(game_over)
	get_tree().paused = true
