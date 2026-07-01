extends Node

@onready var swoosh_player: AudioStreamPlayer = $SwooshPlayer
@onready var die_player: AudioStreamPlayer = $DiePlayer
@onready var wing_player: AudioStreamPlayer = $WingPlayer
@onready var point_player: AudioStreamPlayer = $PointPlayer
@onready var hit_player: AudioStreamPlayer = $HitPlayer


func play_wing() -> void:
	wing_player.play()
	


func play_swoosh() -> void:
	swoosh_player.play()
	
		
func play_point(_score: int) -> void:
	if _score == 0:
		return
	point_player.play()
	
	
func play_crash_sequence() -> void:
	if hit_player.playing or die_player.playing:
		return
		
	# 1. Play crash sound
	hit_player.play()
	
	# 2. Wait then play die sound
	await get_tree().create_timer(0.3).timeout
	die_player.play()
	
	
func _ready() -> void:
	SignalBus.game_started.connect(play_swoosh)
	SignalBus.score_updated.connect(play_point)
	SignalBus.bird_crashed.connect(play_crash_sequence)
