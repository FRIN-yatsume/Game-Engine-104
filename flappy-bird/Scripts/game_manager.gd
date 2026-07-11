# 游戏流程管理：连接信号，协调开始、结束与各系统启停
extends Node

# --- 节点引用 ---
@onready var bird: Bird = $"../Bird"
@onready var pipe_spawner: PipeSpawner = $"../PipeSpawner"
@onready var scrolling_ground: Node2D = $"../ScrollingGround"
@onready var fade: FadeEffect = $"../Fade"
@onready var ui: UI = $"../UI"
@onready var background: TextureRect = $"../Background"

var _background_day: Texture2D = preload("res://flappy-bird-assets-master/sprites/background-day.png")
var _background_night: Texture2D = preload("res://flappy-bird-assets-master/sprites/background-night.png")


func on_game_started() -> void:
	pipe_spawner.start_run()


func end_game() -> void:
	if fade != null:
		fade.play()

	scrolling_ground.stop()
	bird.die()
	pipe_spawner.stop_run()
	SignalBus.check_high_score()
	ui.on_game_over()


func _on_sub_cycle_changed(is_night: bool) -> void:
	background.texture = _background_night if is_night else _background_day


func _ready() -> void:
	SignalBus.reset_score()

	SignalBus.game_started.connect(on_game_started)
	SignalBus.bird_crashed.connect(end_game)
	SignalBus.sub_cycle_changed.connect(_on_sub_cycle_changed)
