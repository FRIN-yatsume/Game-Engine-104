extends Node

@onready var bird: Bird = $"../Bird"
@onready var pipe_spawner: PipeSpawner = $"../PipeSpawner"
@onready var scrolling_ground: Node2D = $"../ScrollingGround"
@onready var fade: FadeEffect = $"../Fade"
@onready var ui: UI = $"../UI"


func on_game_started() -> void:
	pipe_spawner.start_spawning_pipes()
	
	
func end_game() -> void:
	if fade != null:
		fade.play()
		
	scrolling_ground.stop()
	bird.die()
	pipe_spawner.stop()
	SignalBus.check_high_score()
	ui.on_game_over()
	

func _ready() -> void:
	SignalBus.reset_score()
	
	SignalBus.game_started.connect(on_game_started)
	SignalBus.bird_crashed.connect(end_game)
