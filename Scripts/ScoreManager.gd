extends Node
class_name ScoreManager # Add this line
# Add the score manager node to the 'score_manager' group in the editor

var score: int = 0
var score_label: Label = null

func register_label(label: Label) -> void:
	score_label = label
	_update_score_display()

func add_coin(value: int = 1) -> void:
	score += value
	_update_score_display()

func add_enemy(value: int = 5) -> void:
	score += value
	_update_score_display()

func reset_score() -> void:
	score = 0
	_update_score_display()

func _update_score_display() -> void:
	if score_label:
		score_label.text = "Score: %d" % score
