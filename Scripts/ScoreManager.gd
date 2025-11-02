extends Node

var current_score: int = 0
var main_scene_path: String = "res://Scenes/Game.tscn" # Your main level scene

signal score_changed(new_score: int)

func add_score(points: int):
	current_score += points
	emit_signal("score_changed", current_score)

func reset_game():
	current_score = 0
	get_tree().paused = false
	
	if ResourceLoader.exists(main_scene_path):
		get_tree().change_scene_to_file(main_scene_path)
	else:
		print("ERROR: Main scene path is invalid. Cannot restart game.")
