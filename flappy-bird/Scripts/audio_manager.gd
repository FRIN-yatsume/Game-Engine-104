# 全局音频管理：响应游戏事件播放音效
extends Node

# --- 音频播放器 ---
@onready var swoosh_player: AudioStreamPlayer = $SwooshPlayer
@onready var die_player: AudioStreamPlayer = $DiePlayer
@onready var wing_player: AudioStreamPlayer = $WingPlayer
@onready var point_player: AudioStreamPlayer = $PointPlayer
@onready var hit_player: AudioStreamPlayer = $HitPlayer


func play_wing() -> void:
	wing_player.play()


func play_swoosh() -> void:
	swoosh_player.play()


func play_point_sfx() -> void:
	point_player.play()


func play_point(_score: int) -> void:
	if _score == 0:
		return
	play_point_sfx()


# --- 撞地/撞管：先播放 hit，再播放 die ---
func play_crash_sequence() -> void:
	if hit_player.playing or die_player.playing:
		return

	hit_player.play()
	await get_tree().create_timer(0.3).timeout
	die_player.play()


func _ready() -> void:
	SignalBus.game_started.connect(play_swoosh)
	SignalBus.score_updated.connect(play_point)
	SignalBus.bird_crashed.connect(play_crash_sequence)
