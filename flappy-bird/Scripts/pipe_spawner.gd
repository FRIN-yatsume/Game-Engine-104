class_name PipeSpawner extends Node

var pipes: PackedScene = preload("res://Scenes/pipes.tscn")

@export var pipe_speed: int = -150
@export_range (0.0, 1.0) var spawn_margin_top: float = 0.15
@export_range (0.0, 1.0) var spawn_margin_bottom: float = 0.65

@onready var spawn_timer: Timer = $SpawnTimer

func spawn_pipe() -> void:
	var pipe = pipes.instantiate()
	add_child(pipe)
	
	var viewport_size = get_viewport().get_visible_rect().size
	
	# postion pipe at right edge
	pipe.position.x = viewport_size.x
	
	var min_y = viewport_size.y * spawn_margin_top
	var max_y = viewport_size.y * spawn_margin_bottom
	
	pipe.position.y = randf_range(min_y, max_y)
	
	pipe.set_speed(-150)
	
	
func stop() -> void:
	spawn_timer.stop()
	for pipe in get_children():
		if pipe is Pipes:
			pipe.set_speed(0)
			
			
func start_spawning_pipes() -> void:
	spawn_timer.start()
