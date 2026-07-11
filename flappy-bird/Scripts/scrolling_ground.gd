# 无限滚动地面：两块地面拼接循环，鸟碰到则游戏结束
extends Node2D

@export var speed: float = -200.0

@onready var ground_1: Area2D = $Ground1
@onready var ground_2: Area2D = $Ground2

var texture_width: float = 0.0


func _ready() -> void:
	var sprite: Sprite2D = $Ground1/Sprite1
	texture_width = sprite.texture.get_width() * sprite.scale.x

	# 第二块地面紧接第一块右侧，形成无缝循环
	ground_2.position.x = ground_1.position.x + texture_width


func _process(delta: float) -> void:
	ground_1.position.x += speed * delta
	ground_2.position.x += speed * delta

	# 移出屏幕左侧后，接到另一块右侧
	if ground_1.position.x < -texture_width:
		ground_1.position.x += 2 * texture_width

	if ground_2.position.x < -texture_width:
		ground_2.position.x += 2 * texture_width


func _on_ground_1_body_entered(body: Node2D) -> void:
	if body.name != "Bird" or not body is Bird:
		return

	var bird := body as Bird
	if bird.is_dead:
		bird.stop()
		return

	SignalBus.bird_crashed.emit()
	stop()
	bird.stop()


func stop() -> void:
	speed = 0
