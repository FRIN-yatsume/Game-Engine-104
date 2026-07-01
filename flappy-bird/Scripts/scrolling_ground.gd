extends Node2D

@export var speed: float = -200.0

@onready var ground_1: Area2D = $Ground1
@onready var ground_2: Area2D = $Ground2

var texture_width: float = 0.0

func _ready() -> void:
	# Get image width
	var sprite: Sprite2D = $Ground1/Sprite1
	texture_width = sprite.texture.get_width() * sprite.scale.x
	
	# Move ground 2 to start of ground 1
	ground_2.position.x = ground_1.position.x + texture_width
	
	
func _process(delta: float) -> void:
	# Move both pieces to the left
	ground_1.position.x += speed * delta
	ground_2.position.x += speed * delta
	
	# Check ground 1
	if ground_1.position.x < -texture_width:
		ground_1.position.x += 2 * texture_width
		
	# Check ground 2
	if ground_2.position.x < -texture_width:
		ground_2.position.x += 2 * texture_width


func _on_ground_1_body_entered(body: Node2D) -> void:
	if body.name == "Bird":
		SignalBus.bird_crashed.emit()
		stop()
		body.stop()
		
		
func stop() -> void:
	speed = 0
