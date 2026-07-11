# 全局信号总线与分数/最高分持久化
extends Node

# --- 游戏事件信号 ---
signal game_started
signal score_updated(new_score: int)
signal bird_crashed
signal weight_changed(new_weight: int)
signal food_collected(energy: int)
signal sub_cycle_changed(is_night: bool)

const SAVE_FILE_PATH = "res://highscore.save"

# --- 分数状态 ---
var score: int = 0
var high_score: int = 0


func _ready() -> void:
	load_high_score()


# --- 最高分读写 ---
func load_high_score() -> void:
	if FileAccess.file_exists(SAVE_FILE_PATH):
		var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
		if file:
			high_score = file.get_var()
		else:
			high_score = 0


func save_high_score() -> void:
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(high_score)


func check_high_score() -> void:
	if score > high_score:
		high_score = score
		save_high_score()


# --- 当前局分数 ---
func add_point() -> void:
	score += 1
	score_updated.emit(score)


func reset_score() -> void:
	score = 0
	score_updated.emit(score)
