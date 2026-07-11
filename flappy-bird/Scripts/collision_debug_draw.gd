# 碰撞体调试绘制：在 CollisionShape2D 上叠加可视化轮廓
extends Node2D

@export var debug_color: Color = Color(0, 1, 0, 0.35)
@export var outline_color: Color = Color(1, 1, 1, 0.9)
@export var outline_width: float = 1.5

var _collision_shape: CollisionShape2D


func _ready() -> void:
	_collision_shape = get_parent() as CollisionShape2D
	z_index = 100


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if _collision_shape == null or _collision_shape.shape == null:
		return

	var shape := _collision_shape.shape
	if shape is CircleShape2D:
		var circle := shape as CircleShape2D
		draw_circle(Vector2.ZERO, circle.radius, debug_color)
		draw_arc(Vector2.ZERO, circle.radius, 0.0, TAU, 48, outline_color, outline_width)
	elif shape is RectangleShape2D:
		var rect_shape := shape as RectangleShape2D
		var half_size := rect_shape.size * 0.5
		var rect := Rect2(-half_size, rect_shape.size)
		draw_rect(rect, debug_color)
		draw_rect(rect, outline_color, false, outline_width)
