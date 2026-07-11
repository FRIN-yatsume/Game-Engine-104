# 可拾取的食物：增加鸟体重，体型随 energy 变化
class_name Food extends Area2D

# --- 视觉常量 ---
const BASE_SCALE: float = 0.7
const SCALE_PER_ENERGY: float = 0.18
const DIGIT_MARGIN: float = 4.0
const DIGIT_OFFSET_UP: float = 20
const IDLE_ANIM := "idle"

@export var pickup_padding: float = 1.05

# --- 运行时状态 ---
var energy: int = 1
var speed: float = 0.0
var is_collected: bool = false

# --- 节点引用 ---
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $Sprite2D/AnimationPlayer
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var digit_display: DigitDisplay = $DigitDisplay


func _ready() -> void:
	collision_shape_2d.shape = (collision_shape_2d.shape as CircleShape2D).duplicate()
	animation_player.play(IDLE_ANIM)
	apply_energy_visuals()


func setup(new_energy: int) -> void:
	energy = max(new_energy, 1)
	apply_energy_visuals()


func set_speed(new_speed: float) -> void:
	speed = new_speed


# --- 缩放与碰撞 ---
func get_visual_scale() -> float:
	return BASE_SCALE + (energy - 1) * SCALE_PER_ENERGY


func _get_frame_size() -> Vector2:
	if sprite_2d.texture == null or sprite_2d.hframes <= 0 or sprite_2d.vframes <= 0:
		return Vector2(48.0, 48.0)
	return Vector2(
		float(sprite_2d.texture.get_width()) / float(sprite_2d.hframes),
		float(sprite_2d.texture.get_height()) / float(sprite_2d.vframes)
	)


func _get_collision_radius() -> float:
	if sprite_2d.texture == null:
		return 8.0 * get_visual_scale() * pickup_padding
	var frame_size := _get_frame_size()
	var tex_size: float = max(frame_size.x, frame_size.y)
	return tex_size * get_visual_scale() * 0.5 * pickup_padding


func apply_energy_visuals() -> void:
	var visual_scale := get_visual_scale()
	sprite_2d.scale = Vector2.ONE * visual_scale

	if collision_shape_2d.shape is CircleShape2D:
		var circle := collision_shape_2d.shape as CircleShape2D
		circle.radius = _get_collision_radius()

	if digit_display != null:
		digit_display.set_value(energy)
		_update_digit_display_position()


func _update_digit_display_position() -> void:
	if digit_display == null or sprite_2d.texture == null:
		return

	var visual_scale := get_visual_scale()
	var sprite_half_height := _get_frame_size().y * visual_scale * 0.5
	digit_display.position = Vector2(0.0, -(sprite_half_height + DIGIT_MARGIN + DIGIT_OFFSET_UP))


# --- 拾取与移动 ---
func collect() -> void:
	if is_collected:
		return
	is_collected = true
	queue_free()


func _physics_process(delta: float) -> void:
	position.x += speed * delta
	_try_collect_nearby_bird()


func _collect_from(bird: Bird) -> void:
	bird.gain_weight(energy)
	SignalBus.food_collected.emit(energy)
	AudioManager.play_point_sfx()
	collect()


func _try_collect_nearby_bird() -> void:
	if is_collected:
		return

	for body in get_overlapping_bodies():
		if body is Bird:
			var bird := body as Bird
			if not bird.is_dead:
				_collect_from(bird)
				return


func _on_body_entered(body: Node2D) -> void:
	if is_collected:
		return
	if body.name != "Bird":
		return
	if not body is Bird:
		return

	var bird := body as Bird
	if bird.is_dead:
		return

	_collect_from(bird)


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
