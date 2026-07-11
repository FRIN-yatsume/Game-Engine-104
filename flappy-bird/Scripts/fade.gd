# 游戏结束时的淡出动画效果
class_name FadeEffect extends Node

@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	animation_player.play("fade")


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	queue_free()
