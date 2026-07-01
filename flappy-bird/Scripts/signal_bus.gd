extends Node

signal game_started
signal score_updated(new_score: int)
signal bird_crashed

const SAVE_FILE_PATH = "res://highscore.save"

var score: int = 0
var high_score: int = 0


func _ready() -> void:
	load_high_score()
	
	
func load_high_score() -> void:
	# Check if file exists
	if FileAccess.file_exists(SAVE_FILE_PATH):
		# Now open in READ mode
		var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
		if file:
			high_score = file.get_var()
		else:
			high_score = 0
			
			
func save_high_score() -> void:
	# 1. Open file in write mode
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(high_score)
		
		
func check_high_score() -> void:
	if score > high_score:
		high_score = score
		save_high_score()
		
		
func add_point() -> void:
	score += 1
	score_updated.emit(score)
	
	
func reset_score() -> void:
	score = 0
	score_updated.emit(score)
