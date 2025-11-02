extends CharacterBody2D

# -------------------------------
# Player Properties
# -------------------------------
@export var SPEED: float = 300.0
@export var JUMP_VELOCITY: float = -1025.0
@export var GRAVITY: float = 1400.0
@export var STOMP_BOUNCE: float = -500.0
@export var ENEMY_STOMP_POINTS: int = 100 

var score: int = 0
var has_fire_power: bool = false
var facing_direction: int = 1
# CRITICAL: Stores the path of the current level for restart
# User confirmed this path
var current_scene_path: String = "res://Scenes/Game.tscn" 

@export var fireball_scene: PackedScene # Unused for now

@onready var camera: Camera2D = $Camera2D
@onready var score_label: Label = $UI/ScoreLabel 
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

# -------------------------------
# Ready
# -------------------------------
func _ready():
	add_to_group("player")
	_update_score_label()
	
	# Store level path for restart logic (use dynamic path if available, otherwise use default)
	if get_tree().current_scene: 
		var dynamic_path = get_tree().current_scene.scene_file_path
		if not dynamic_path.is_empty():
			current_scene_path = dynamic_path
			print("DEBUG: Scene Path Captured: ", current_scene_path)
		else:
			print("DEBUG: Warning: Dynamic path empty. Using default path: ", current_scene_path)
	else:
		print("DEBUG: Warning: Could not capture current scene. Using default path: ", current_scene_path)


# -------------------------------
# Physics Process (Movement Loop)
# -------------------------------
func _physics_process(delta):
	# 1. Handle Horizontal movement and direction
	var input_dir = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	velocity.x = input_dir * SPEED

	if input_dir > 0:
		facing_direction = 1
	elif input_dir < 0:
		facing_direction = -1

	# 2. Handle Animation (Horizontal)
	if input_dir != 0:
		animated_sprite.flip_h = facing_direction < 0
		if animated_sprite.sprite_frames.has_animation("run"):
			animated_sprite.play("run")
	else:
		if is_on_floor() and animated_sprite.sprite_frames.has_animation("idle"):
			animated_sprite.play("idle")
		elif animated_sprite.sprite_frames.has_animation("idle"):
			animated_sprite.stop()

	# 3. Handle Gravity / Jump
	if not is_on_floor():
		velocity.y += GRAVITY * delta
		if animated_sprite.sprite_frames.has_animation("jump"):
			animated_sprite.play("jump")
	elif Input.is_action_just_pressed("ui_up"):
		velocity.y = JUMP_VELOCITY

	# Apply the final calculated velocity
	move_and_slide()

	# 4. Collision Check (Must happen after movement)
	_check_enemy_collisions() 

# -------------------------------
# Collision and Score Logic
# -------------------------------
func _check_enemy_collisions():
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var enemy = collision.get_collider()
		
		if enemy and enemy.is_in_group("enemy"):
			var normal = collision.get_normal()
			
			# Stomp Check: Collision from a high angle (normal.y < -0.5 is up)
			if normal.y < -0.5:
				_stomp_enemy(enemy)
				return 
			
			# Side-Hit/Death Check:
			elif normal.y >= -0.5:
				lose_life()
				return 

func _stomp_enemy(enemy: Node):
	if enemy.has_method("die"):
		enemy.die()
	else:
		enemy.queue_free()

	velocity.y = STOMP_BOUNCE
	score += ENEMY_STOMP_POINTS
	_update_score_label()

func collect_coin(value: int = 10):
	score += value
	_update_score_label()

func _update_score_label():
	if score_label:
		score_label.text = "Score: %d" % score

# -------------------------------
# Game Over Logic (Dynamically created UI)
# -------------------------------

# The function connected to the dynamically created button
func _on_restart_game_pressed():
	print("DEBUG: Restart Button Pressed! Attempting to reload: ", current_scene_path)
	get_tree().paused = false 
	if not current_scene_path.is_empty():
		get_tree().change_scene_to_file(current_scene_path)
	else:
		print("DEBUG: ERROR: current_scene_path is empty. Cannot restart.")
	# The game over UI will automatically be destroyed when the scene changes

# Death / Lose Life (CRITICAL TRIGGER)
func lose_life():
	if get_tree().paused:
		return

	# Stop player physics immediately
	set_physics_process(false)

	# Clean up previous Game Over screens (for safety)
	for child in get_tree().root.get_children():
		if "GameOverScreen" in str(child):
			child.queue_free()

	# 💥 DYNAMIC GAME OVER UI CREATION 💥
	
	# 1. CanvasLayer (Root container for the UI)
	var game_over_canvas = CanvasLayer.new()
	game_over_canvas.name = "GameOverScreen"
	# CRITICAL FIX: Ensure the UI processes input even when the game is paused
	game_over_canvas.process_mode = Node.PROCESS_MODE_ALWAYS 
	get_tree().root.add_child(game_over_canvas)
	
	# 2. Control Node (for centering everything on screen and capturing input)
	var control = Control.new()
	control.anchor_right = 1.0
	control.anchor_bottom = 1.0
	control.mouse_filter = Control.MOUSE_FILTER_STOP # Stops input from reaching paused game objects
	
	# 3. Panel/Background (Semi-transparent white)
	var panel = ColorRect.new()
	# Set to WHITE, 70% opacity for backsplash
	panel.color = Color(1, 1, 1, 0.7) 
	
	var panel_width = 500
	var panel_height = 250
	panel.set_size(Vector2(panel_width, panel_height)) 
	
	# *** CHANGE: Positioning for Down and Left Center ***
	var horizontal_anchor = 0.35 # 35% from left (Left of center)
	var vertical_anchor = 0.80  # 80% from top (Near bottom)
	
	panel.anchor_left = horizontal_anchor
	panel.anchor_right = horizontal_anchor
	panel.anchor_top = vertical_anchor
	panel.anchor_bottom = vertical_anchor
	
	# Offset the position to center the panel around the new anchor point
	panel.position.x -= panel_width / 2
	panel.position.y -= panel_height / 2
	
	# Attach nodes in the correct hierarchy: panel -> control -> canvas
	control.add_child(panel) 
	game_over_canvas.add_child(control)
	
	# 4. Score Label
	var ui_label = Label.new()
	ui_label.text = "GAME OVER\nFINAL SCORE: %d" % score
	# Set font to BLACK
	ui_label.add_theme_color_override("font_color", Color("000000")) 
	ui_label.add_theme_font_size_override("font_size", 32) 
	ui_label.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER)
	ui_label.set_vertical_alignment(VERTICAL_ALIGNMENT_CENTER)
	
	# Center within the panel, adjusted for new panel size
	ui_label.set_anchors_preset(Control.PRESET_CENTER)
	ui_label.set_position(Vector2(-150, -80)) # Adjusted Y position higher
	ui_label.set_size(Vector2(300, 80))
	panel.add_child(ui_label)
	
	# 5. Restart Button
	var restart_button = Button.new()
	restart_button.text = "RESTART LEVEL"
	# Font is already black
	restart_button.add_theme_color_override("font_color", Color("000000"))
	restart_button.set_size(Vector2(250, 50)) # Slightly larger button
	
	# Center within the panel, placed below the score
	restart_button.set_anchors_preset(Control.PRESET_CENTER)
	restart_button.set_position(Vector2(-125, 40)) # Adjusted Y position lower
	panel.add_child(restart_button)
	
	# 6. Connect Button to the function created above
	var error = restart_button.pressed.connect(_on_restart_game_pressed)
	if error != OK:
		print("DEBUG: ERROR: Failed to connect restart button signal: ", error)
	
	# 7. Pause the game
	get_tree().paused = true

