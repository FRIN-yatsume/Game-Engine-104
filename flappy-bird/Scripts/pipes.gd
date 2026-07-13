# 一对上下水管：处理布局、碰撞、得分与撞碎逻辑
class_name Pipes extends Node2D

const GAP_CENTER_Y: float = 73.0
const WHITE_FLASH_SHADER := preload("res://Shaders/white_flash.gdshader")
const BROKEN_PIPE_TEXTURE := preload("res://flappy-bird-assets-master/sprites/pipe-red.png")

@export_range(0.0, 0.5) var digit_position_ratio: float = 0.2

# --- 运行时状态 ---
var speed: float = 0.0
var loss: int = 1
var gap: float = 134.0
var is_must_break: bool = false
var is_breaking: bool = false
var _hit_pipe: Area2D = null

# --- 节点引用 ---
@onready var top_pipe: Area2D = $TopPipe
@onready var bottom_pipe: Area2D = $BottomPipe
@onready var score_area: Area2D = $ScoreArea
@onready var screen_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D
@onready var top_digit_display: DigitDisplay = $TopPipe/TopDigitDisplay
@onready var bottom_digit_display: DigitDisplay = $BottomPipe/BottomDigitDisplay

var _pipe_texture_size: Vector2 = Vector2(52, 320)
var _half_pipe_height: float = 160.0


func _ready() -> void:
	var top_sprite := top_pipe.get_node("Sprite2D") as Sprite2D
	var top_shape := top_pipe.get_node("CollisionShape2D") as CollisionShape2D
	var bottom_shape := bottom_pipe.get_node("CollisionShape2D") as CollisionShape2D

	if top_sprite.texture != null:
		_pipe_texture_size = top_sprite.texture.get_size()
		_half_pipe_height = _pipe_texture_size.y * 0.5

	# 复制碰撞形状，避免多个水管实例共享同一份 shape 数据
	top_shape.shape = top_shape.shape.duplicate()
	bottom_shape.shape = bottom_shape.shape.duplicate()


# --- 初始化：由 PipeSpawner 传入 loss、空隙和是否 must_break ---
func setup(new_loss: int, new_gap: float, must_break: bool) -> void:
	loss = max(new_loss, 1)
	gap = new_gap
	is_must_break = must_break
	_apply_gap_layout()
	apply_loss_visuals()


func set_speed(new_speed: float) -> void:
	speed = new_speed


# --- 按 loss 档位设置贴图宽度和碰撞宽度（对齐鸟对应 weight 的尺寸） ---
func apply_loss_visuals() -> void:
	var visual_width := Bird.get_visual_width_at(loss)
	var collision_width := Bird.get_collision_width_at(loss)
	var sprite_scale_x := visual_width / _pipe_texture_size.x
	var collision_size := Vector2(collision_width, _pipe_texture_size.y)

	var top_sprite := top_pipe.get_node("Sprite2D") as Sprite2D
	var bottom_sprite := bottom_pipe.get_node("Sprite2D") as Sprite2D
	top_sprite.scale.x = sprite_scale_x
	bottom_sprite.scale.x = sprite_scale_x

	var top_shape := top_pipe.get_node("CollisionShape2D") as CollisionShape2D
	var bottom_shape := bottom_pipe.get_node("CollisionShape2D") as CollisionShape2D
	(top_shape.shape as RectangleShape2D).size = collision_size
	(bottom_shape.shape as RectangleShape2D).size = collision_size
	top_shape.position = Vector2.ZERO
	bottom_shape.position = Vector2.ZERO
	score_area.position.x = collision_width

	if top_digit_display != null:
		top_digit_display.set_value(loss)
	if bottom_digit_display != null:
		bottom_digit_display.set_value(loss)
	_update_digit_display_positions()


func _update_digit_display_positions() -> void:
	var offset := _pipe_texture_size.y * digit_position_ratio
	if top_digit_display != null:
		top_digit_display.position = Vector2(0.0, _half_pipe_height - offset)
	if bottom_digit_display != null:
		bottom_digit_display.position = Vector2(0.0, -_half_pipe_height + offset)


# --- 布局：must_break 无空隙；普通水管按 gap 留出中间通道 ---
func _apply_gap_layout() -> void:
	if is_must_break:
		top_pipe.position.y = GAP_CENTER_Y - _half_pipe_height
		bottom_pipe.position.y = GAP_CENTER_Y + _half_pipe_height
		score_area.monitoring = false
		score_area.monitorable = false
		score_area.visible = false
	else:
		var half_gap := gap * 0.5
		top_pipe.position.y = GAP_CENTER_Y - half_gap - _half_pipe_height
		bottom_pipe.position.y = GAP_CENTER_Y + half_gap + _half_pipe_height
		score_area.monitoring = true
		score_area.monitorable = true
		score_area.visible = true


# --- 鸟成功减体重后：纯白闪烁并销毁水管 ---
func break_apart() -> void:
	if is_breaking:
		return
	is_breaking = true
	top_pipe.set_deferred("monitoring", false)
	bottom_pipe.set_deferred("monitoring", false)
	score_area.set_deferred("monitoring", false)
	screen_notifier.set_deferred("monitorable", false)

	if _hit_pipe != null:
		_apply_broken_texture(_hit_pipe)
	AudioManager.play_hit_pipe()

	SignalBus.add_point()

	var hit_effects: Node = get_tree().get_first_node_in_group("hit_effects")
	if hit_effects != null:
		hit_effects.trigger_shake()

	_play_break_flash(
		hit_effects.flash_loops if hit_effects != null else 4,
		hit_effects.get_pipe_flash_half_duration() if hit_effects != null else 0.08
	)


func _play_break_flash(flash_loops: int, half_duration: float) -> void:
	var top_sprite := top_pipe.get_node("Sprite2D") as Sprite2D
	var bottom_sprite := bottom_pipe.get_node("Sprite2D") as Sprite2D
	var top_mat := _create_flash_material()
	var bottom_mat := _create_flash_material()
	var original_top := top_sprite.material
	var original_bottom := bottom_sprite.material
	top_sprite.material = top_mat
	bottom_sprite.material = bottom_mat

	if top_digit_display != null:
		top_digit_display.visible = false
	if bottom_digit_display != null:
		bottom_digit_display.visible = false

	var tween := create_tween()
	tween.set_loops(flash_loops)
	tween.tween_method(
		func(amount: float) -> void:
			_set_flash_mix(top_mat, amount)
			_set_flash_mix(bottom_mat, amount),
		0.0,
		1.0,
		half_duration
	)
	tween.tween_method(
		func(amount: float) -> void:
			_set_flash_mix(top_mat, amount)
			_set_flash_mix(bottom_mat, amount),
		1.0,
		0.0,
		half_duration
	)
	tween.finished.connect(func() -> void:
		if is_instance_valid(top_sprite):
			top_sprite.material = original_top
		if is_instance_valid(bottom_sprite):
			bottom_sprite.material = original_bottom
		queue_free()
	)


func _create_flash_material() -> ShaderMaterial:
	var shader_mat := ShaderMaterial.new()
	shader_mat.shader = WHITE_FLASH_SHADER
	shader_mat.set_shader_parameter("mix_amount", 0.0)
	return shader_mat


func _set_flash_mix(shader_mat: ShaderMaterial, amount: float) -> void:
	shader_mat.set_shader_parameter("mix_amount", amount)


func _apply_broken_texture(pipe: Area2D) -> void:
	var sprite := pipe.get_node("Sprite2D") as Sprite2D
	sprite.texture = BROKEN_PIPE_TEXTURE


func _physics_process(delta: float) -> void:
	position.x += speed * delta


# --- 碰撞与信号 ---
func _on_point_scored(body: CharacterBody2D) -> void:
	if is_must_break or is_breaking:
		return
	if body.name == "Bird":
		SignalBus.add_point()


func _on_top_pipe_body_entered(body: Node2D) -> void:
	_handle_pipe_collision(body, top_pipe)


func _on_bottom_pipe_body_entered(body: Node2D) -> void:
	_handle_pipe_collision(body, bottom_pipe)


func _handle_pipe_collision(body: Node2D, hit_pipe: Area2D) -> void:
	if is_breaking:
		return
	if body.name != "Bird":
		return
	if not body is Bird:
		return

	var bird := body as Bird
	if bird.is_dead:
		return

	var hit_effects: Node = get_tree().get_first_node_in_group("hit_effects")
	if hit_effects != null:
		hit_effects.trigger_bird_hit_flash(bird.animated_sprite_2d)

	_hit_pipe = hit_pipe
	if bird.lose_weight(loss):
		break_apart()
	else:
		SignalBus.bird_crashed.emit()


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	if is_breaking:
		return
	queue_free()
