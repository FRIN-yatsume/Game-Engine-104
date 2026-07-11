# 撞击反馈：纯白闪烁、屏幕震动与可调参数
class_name HitEffects extends Node

const WHITE_FLASH_SHADER := preload("res://Shaders/white_flash.gdshader")

@export_group("水管撞碎反馈")
@export_range(1.0, 20.0) var flash_frequency: float = 6.25 ## 水管撞碎时纯白闪烁频率（每秒完整亮→暗切换次数）；越大闪烁越快
@export_range(1, 10) var flash_loops: int = 4 ## 水管撞碎时纯白闪烁循环次数；越大水管消失前闪的次数越多

@export_group("鸟撞水管反馈")
@export_range(1.0, 20.0) var bird_flash_frequency: float = 8.0 ## 鸟撞击水管时纯白闪烁频率（每秒完整亮→暗切换次数）；越大闪烁越快
@export_range(1, 10) var bird_flash_loops: int = 2 ## 鸟撞击水管时纯白闪烁循环次数；鸟不会消失，闪完后恢复原样

@export_group("屏幕震动")
@export_range(0.0, 20.0) var shake_intensity: float = 3.0 ## 水管撞碎时屏幕震动最大偏移（像素）；0 为关闭
@export_range(0.0, 0.5) var shake_duration: float = 0.1 ## 水管撞碎时屏幕震动持续时间（秒）

var _camera: Camera2D
var _shake_tween: Tween
var _bird_flash_tween: Tween


func _ready() -> void:
	add_to_group("hit_effects")
	_camera = get_parent().get_parent().get_node("Camera2D") as Camera2D


func get_pipe_flash_half_duration() -> float:
	return 0.5 / maxf(flash_frequency, 0.01)


func get_bird_flash_half_duration() -> float:
	return 0.5 / maxf(bird_flash_frequency, 0.01)


func trigger_bird_hit_flash(sprite: CanvasItem) -> void:
	if sprite == null:
		return

	if _bird_flash_tween != null and _bird_flash_tween.is_valid():
		_bird_flash_tween.kill()

	_bird_flash_tween = _play_white_flash(sprite, bird_flash_frequency, bird_flash_loops)


func trigger_shake() -> void:
	if _camera == null or shake_duration <= 0.0 or shake_intensity <= 0.0:
		return

	if _shake_tween != null and _shake_tween.is_valid():
		_shake_tween.kill()

	_shake_tween = create_tween()
	var steps := maxi(int(shake_duration / 0.016), 3)
	var step_time := shake_duration / float(steps)

	for _i in steps:
		var offset := Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
		_shake_tween.tween_property(_camera, "offset", offset, step_time)

	_shake_tween.tween_property(_camera, "offset", Vector2.ZERO, 0.0)


func _play_white_flash(sprite: CanvasItem, frequency: float, loops: int) -> Tween:
	var shader_mat := _create_flash_material()
	var original_material := sprite.material
	sprite.material = shader_mat

	var half_duration := 0.5 / maxf(frequency, 0.01)
	var tween := create_tween()
	tween.set_loops(loops)
	tween.tween_method(
		func(amount: float) -> void:
			_set_flash_mix(shader_mat, amount),
		0.0,
		1.0,
		half_duration
	)
	tween.tween_method(
		func(amount: float) -> void:
			_set_flash_mix(shader_mat, amount),
		1.0,
		0.0,
		half_duration
	)
	tween.finished.connect(func() -> void:
		if is_instance_valid(sprite):
			sprite.material = original_material
	)
	return tween


func _create_flash_material() -> ShaderMaterial:
	var shader_mat := ShaderMaterial.new()
	shader_mat.shader = WHITE_FLASH_SHADER
	shader_mat.set_shader_parameter("mix_amount", 0.0)
	return shader_mat


func _set_flash_mix(shader_mat: ShaderMaterial, amount: float) -> void:
	shader_mat.set_shader_parameter("mix_amount", amount)
