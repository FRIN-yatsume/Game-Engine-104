# 玩家控制的鸟：处理跳跃、体重变化、碰撞体与贴图缩放
class_name Bird extends CharacterBody2D

# --- 物理常量 ---
const BASE_FLAP_FORCE: float = -400.0
const BASE_GRAVITY: float = 900.0
const MAX_FALL_SPEED: float = 600.0
const DEATH_FALL_SPEED: float = 240.0
const BASE_SPRITE_HALF_HEIGHT: float = 12.0
const DIGIT_MARGIN: float = 10.0

# --- 编辑器可调参数 ---
@export_group("体重与体型")
@export var weight_gravity_factor: float = 0.45 ## 每增加 1 体重，重力增加的倍率（0.45 = 每级 +45% 重力）
@export var visual_scale_per_weight: float = 0.35 ## 每增加 1 体重，贴图与碰撞体放大的倍率（0.35 = 每级 +35% 大小；weight=1 时为原始尺寸）

const DEFAULT_COLLISION_RADIUS: float = 14.0
const FLAP_ANIM := "flap"

# --- 节点引用 ---
@onready var sprite_holder: Node2D = $SpriteHolder
@onready var animated_sprite_2d: AnimatedSprite2D = $SpriteHolder/AnimatedSprite2D
@onready var instructions: Sprite2D = $Instructions
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var digit_display: DigitDisplay = $DigitDisplay

# --- 运行时状态 ---
var weight: int = 1
var gravity: float = BASE_GRAVITY
var is_dead: bool = false
var is_game_started: bool = false

var _base_collision_radius: float = 14.0

# --- 供水管等系统参考的静态尺寸（weight=1 基准） ---
static var reference_texture_width: float = 34.0
static var reference_collision_diameter: float = 28.0


func _ready() -> void:
	# 复制碰撞形状，避免运行时修改污染场景资源；restart 后也能正确重置
	collision_shape_2d.shape = (collision_shape_2d.shape as CircleShape2D).duplicate()
	_base_collision_radius = DEFAULT_COLLISION_RADIUS
	(collision_shape_2d.shape as CircleShape2D).radius = DEFAULT_COLLISION_RADIUS
	reference_collision_diameter = _base_collision_radius * 2.0

	var frame_texture := animated_sprite_2d.sprite_frames.get_frame_texture("flap", 0)
	if frame_texture != null:
		reference_texture_width = frame_texture.get_width()

	if digit_display != null:
		digit_display.top_level = true
	animated_sprite_2d.animation = FLAP_ANIM
	animated_sprite_2d.frame = 2
	animated_sprite_2d.stop()
	apply_weight_effects()


# --- 静态查询：按档位计算宽度（供水管 loss 档位对齐） ---
static func get_visual_width_at(
	value: int,
	per_step: float = 0.35,
) -> float:
	return WeightScale.visual_width(value, reference_texture_width, per_step)


static func get_collision_width_at(
	value: int,
	per_step: float = 0.35,
) -> float:
	return WeightScale.collision_width(value, reference_collision_diameter, per_step)


func get_collision_diameter() -> float:
	return (collision_shape_2d.shape as CircleShape2D).radius * 2.0


# --- 物理更新 ---
func apply_gravity(delta: float) -> void:
	velocity.y += gravity * delta
	if velocity.y > MAX_FALL_SPEED:
		velocity.y = MAX_FALL_SPEED


func _physics_process(delta: float) -> void:
	if not is_dead or gravity > 0.0:
		apply_gravity(delta)
	flap()
	if !is_game_started:
		_update_digit_display_position()
		return
	rotate_while_falling(delta)
	move_and_slide()
	_update_digit_display_position()


# --- 输入与跳跃 ---
func flap() -> void:
	if Input.is_action_just_pressed("flap"):
		if !is_game_started:
			is_game_started = true
			SignalBus.game_started.emit()
			var tween = create_tween()
			tween.tween_property(instructions, "modulate:a", 0.0, 0.5)
			tween.tween_callback(instructions.queue_free)

		if !is_dead:
			animated_sprite_2d.play(FLAP_ANIM)
			velocity.y = get_flap_force()
			rotation = deg_to_rad(-30)

		AudioManager.play_wing()


func get_flap_force() -> float:
	return BASE_FLAP_FORCE


# --- 体重变化 ---
func gain_weight(energy: int) -> void:
	weight += energy
	apply_weight_effects()
	SignalBus.weight_changed.emit(weight)


func lose_weight(loss_amount: int) -> bool:
	weight -= loss_amount
	apply_weight_effects()
	SignalBus.weight_changed.emit(weight)
	return weight > 0


func get_visual_scale() -> float:
	return WeightScale.visual_scale(weight, visual_scale_per_weight)


func get_collision_scale() -> float:
	return get_visual_scale()


# --- 根据体重更新重力、贴图、碰撞体和数字显示 ---
func apply_weight_effects() -> void:
	var effective_weight := maxi(weight, 1)
	gravity = BASE_GRAVITY * (1.0 + (effective_weight - 1) * weight_gravity_factor)

	var visual_scale := get_visual_scale()
	sprite_holder.scale = Vector2.ONE * visual_scale

	if collision_shape_2d.shape is CircleShape2D:
		var circle := collision_shape_2d.shape as CircleShape2D
		circle.radius = _base_collision_radius * visual_scale

	if digit_display != null:
		digit_display.set_value(weight)
		_update_digit_display_position()


func _update_digit_display_position() -> void:
	if digit_display == null:
		return

	var visual_scale := get_visual_scale()
	var offset_y := BASE_SPRITE_HALF_HEIGHT * visual_scale + DIGIT_MARGIN
	digit_display.global_position = global_position + Vector2(0.0, -offset_y)
	digit_display.global_rotation = 0.0


func rotate_while_falling(delta) -> void:
	if velocity.y > 0:
		rotation = lerp_angle(rotation, deg_to_rad(90), 2 * delta)


# --- 死亡与停止 ---
func die() -> void:
	is_dead = true
	gravity = BASE_GRAVITY
	velocity.y = maxf(velocity.y, DEATH_FALL_SPEED)


func stop() -> void:
	is_dead = true
	animated_sprite_2d.stop()
	velocity = Vector2.ZERO
	gravity = 0.0
