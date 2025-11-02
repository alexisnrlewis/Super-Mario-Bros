extends CanvasLayer
# -------------------------------
# Game Over Screen Script
# -------------------------------

# --- Node References (Adjust these paths based on your scene tree) ---
# NOTE: The paths below match the user's provided script.
# CRITICAL: Ensure the path "Panel/FinalScoreLabel" exactly matches your scene!
@onready var final_score_label: Label = $"Panel/FinalScoreLabel" 
@onready var restart_button: Button = $"Panel/RestartButton" 

# Variable to hold the level path for reloading
var current_scene_path: String = ""
var final_score: int = 0

func _ready():
	# Store the path of the current level scene before it's unloaded
	if get_tree().current_scene:
		current_scene_path = get_tree().current_scene.scene_file_path
	
	# Connect the restart button's signal
	if restart_button:
		restart_button.pressed.connect(_on_restart_button_pressed)
	
	# The score variable is now set, and all nodes are ready, so display the score.
	_update_score_display()

# This function is called by player.gd to set the final score
func set_final_score(score_value: int):
	final_score = score_value
	# DEBUG: Check if the score is actually being passed to this script.
	print("Game Over Script received final score: ", final_score)
	
	# If the label is ready when the score is passed, update it immediately.
	# Otherwise, _ready() will ensure it gets displayed later.
	_update_score_display()

func _update_score_display():
	# DEBUG: Check if the label reference is valid.
	if final_score_label:
		final_score_label.text = "FINAL SCORE: " + str(final_score)
	else:
		# If you see this error, your path $"Panel/FinalScoreLabel" is wrong.
		print("ERROR: final_score_label is NULL. Check path in GameOver.tscn.")

# This function runs when the player clicks the Restart button
func _on_restart_button_pressed():
	# 1. Unpause the game (CRITICAL)
	get_tree().paused = false 
	
	# 2. Reload the current level (This resets all objects and the player)
	if current_scene_path:
		get_tree().change_scene_to_file(current_scene_path)
	
	# 3. Removes the Game Over screen
	queue_free()
