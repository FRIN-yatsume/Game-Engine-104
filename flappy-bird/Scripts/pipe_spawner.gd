# 水管与食物的生成调度器：控制循环节奏、生成时机和 must_break 规则
class_name PipeSpawner extends Node

# --- 场景资源 ---
var pipes_scene: PackedScene = preload("res://Scenes/pipes.tscn")
var food_scene: PackedScene = preload("res://Scenes/food.tscn")

# --- 编辑器可调参数 ---
@export_group("移动与生成位置")
@export var pipe_speed: float = -150.0 ## 水管与食物向左移动的速度（像素/秒，负值表示向左）
@export_range(0.0, 1.0) var spawn_margin_top: float = 0.15 ## 水管/食物生成 Y 轴范围的上边界（相对屏幕高度，0=顶，1=底）
@export_range(0.0, 1.0) var spawn_margin_bottom: float = 0.65 ## 水管/食物生成 Y 轴范围的下边界（相对屏幕高度）

@export_group("循环节奏")
@export var pipe_start_delay: float = 5.0 ## 开局后多少秒开始生成水管
@export var cycle_active_duration: float = 30.0 ## 每个子循环中持续生成水管与食物的时长（秒）
@export var cycle_rest_duration: float = 5.0 ## 每个循环结束后的休息时长（秒，此期间不生成）
@export var pipe_spawn_interval: float = 3.5 ## 相邻两次普通水管生成的时间间隔（秒）
@export var food_spawn_interval: float = 3.5 ## 相邻两次食物生成的时间间隔（秒）
@export var food_between_offset: float = 1.75 ## 水管开始生成后，食物相对水管的生成时间偏移（秒）；循环重置后也用于让食物先于水管
@export var must_break_interval: float = 10.0 ## 每隔多少秒随普通水管生成一对必须撞碎的实心水管（无空隙）
@export_range(0.0, 1.0) var must_break_energy_ratio: float = 0.6 ## must_break 水管的 loss = 前窗口内食物 energy 总和 × 此比例（至少为 1）

@export_group("水管 loss 随机")
@export var loss_min_early: int = 1 ## 循环初期普通水管 loss 数字的下限
@export var loss_max_early: int = 2 ## 循环初期普通水管 loss 数字的上限
@export var loss_min_late: int = 2 ## 循环末期普通水管 loss 数字的下限
@export var loss_max_late: int = 4 ## 循环末期普通水管 loss 数字的上限

@export_group("食物 energy 随机")
@export var energy_min: int = 1 ## 食物增加体重的最小值
@export var energy_max: int = 3 ## 食物增加体重的最大值

@export_group("水管空隙")
@export var gap_collision_multiplier: float = 1.5 ## 普通水管中间空隙 = 鸟当前碰撞直径 × 此倍数（must_break 水管不受此影响）

@export_group("昼夜 - 夜晚参数")
@export var pipe_spawn_interval_night: float = 3.5 ## 夜晚子循环中相邻两次普通水管生成的时间间隔（秒）
@export var food_spawn_interval_night: float = 3.5 ## 夜晚子循环中相邻两次食物生成的时间间隔（秒）
@export var gap_collision_multiplier_night: float = 1.5 ## 夜晚子循环中普通水管中间空隙 = 鸟当前碰撞直径 × 此倍数
@export var loss_min_early_night: int = 1 ## 夜晚子循环初期普通水管 loss 数字的下限
@export var loss_max_early_night: int = 2 ## 夜晚子循环初期普通水管 loss 数字的上限
@export var loss_min_late_night: int = 2 ## 夜晚子循环末期普通水管 loss 数字的下限
@export var loss_max_late_night: int = 4 ## 夜晚子循环末期普通水管 loss 数字的上限
@export var energy_min_night: int = 1 ## 夜晚子循环中食物增加体重的最小值
@export var energy_max_night: int = 3 ## 夜晚子循环中食物增加体重的最大值

# --- 运行时状态 ---
var elapsed_time: float = 0.0
var cycle_time: float = 0.0
var sub_cycle_index: int = 0 ## 0=白天，1=夜晚

var _is_running: bool = false
var _next_food_spawn_time: float = 0.0
var _next_pipe_spawn_time: float = 5.0
var _next_must_break_time: float = 10.0
var _pending_must_break: bool = false
var _must_break_window_energy: int = 0
var _cycle_duration: float = 35.0
var _sub_cycles_per_game_cycle: int = 2
var _bird: Bird


func _ready() -> void:
	_cycle_duration = cycle_active_duration + cycle_rest_duration
	_next_pipe_spawn_time = pipe_start_delay
	_bird = get_parent().get_node("Bird") as Bird


# --- 主循环：推进时间并按计划生成食物/水管 ---
func _process(delta: float) -> void:
	if not _is_running:
		return

	elapsed_time += delta
	cycle_time += delta

	# 子循环结束：重置 cycle_time，切换昼夜，并重新排期（食物先于水管）
	if cycle_time >= _cycle_duration:
		cycle_time = 0.0
		sub_cycle_index = (sub_cycle_index + 1) % _sub_cycles_per_game_cycle
		SignalBus.sub_cycle_changed.emit(sub_cycle_index == 1)
		_resync_spawn_schedule_after_cycle()

	# 休息期内不生成
	if cycle_time >= cycle_active_duration:
		return

	while _next_food_spawn_time <= elapsed_time:
		spawn_food()
		_next_food_spawn_time += _current_food_spawn_interval()

	while _next_pipe_spawn_time <= elapsed_time:
		var must_break := _pending_must_break
		_pending_must_break = false
		var fixed_loss := -1
		if must_break:
			fixed_loss = _calc_must_break_loss()
			_must_break_window_energy = 0
		spawn_pipe(must_break, fixed_loss)
		_next_pipe_spawn_time += _current_pipe_spawn_interval()

		if _next_pipe_spawn_time >= _next_must_break_time:
			_pending_must_break = true
			_next_must_break_time += must_break_interval


# --- 循环重置后：确保食物先于水管出现 ---
func _resync_spawn_schedule_after_cycle() -> void:
	_next_food_spawn_time = elapsed_time
	_next_pipe_spawn_time = elapsed_time + food_between_offset


# --- 游戏开始/结束 ---
func start_run() -> void:
	_is_running = true
	elapsed_time = 0.0
	cycle_time = 0.0
	sub_cycle_index = 0
	_must_break_window_energy = 0
	_next_food_spawn_time = 0.0
	_next_pipe_spawn_time = pipe_start_delay
	_next_must_break_time = must_break_interval
	_pending_must_break = false
	SignalBus.sub_cycle_changed.emit(false)


func stop_run() -> void:
	_is_running = false
	for child in get_children():
		if child is Pipes:
			child.set_speed(0.0)
		elif child is Food:
			child.set_speed(0.0)


# --- 生成食物 ---
func spawn_food() -> void:
	if cycle_time >= cycle_active_duration:
		return

	# 开局水管出现前，或水管出现后与其交错时，才实际生成食物
	if elapsed_time >= pipe_start_delay + food_between_offset or elapsed_time < pipe_start_delay:
		var food := food_scene.instantiate() as Food
		add_child(food)

		var viewport_size := get_viewport().get_visible_rect().size
		food.position.x = viewport_size.x
		food.position.y = randf_range(
			viewport_size.y * spawn_margin_top,
			viewport_size.y * spawn_margin_bottom
		)

		var energy := _roll_energy()
		food.setup(energy)
		food.set_speed(pipe_speed)
		_must_break_window_energy += energy


# --- 生成水管 ---
func spawn_pipe(must_break: bool = false, fixed_loss: int = -1) -> void:
	if cycle_time >= cycle_active_duration:
		return

	var pipe := pipes_scene.instantiate() as Pipes
	add_child(pipe)

	var viewport_size := get_viewport().get_visible_rect().size
	pipe.position.x = viewport_size.x

	var min_y := viewport_size.y * spawn_margin_top
	var max_y := viewport_size.y * spawn_margin_bottom
	pipe.position.y = randf_range(min_y, max_y)

	var loss_value := fixed_loss if must_break and fixed_loss > 0 else _roll_loss()
	var gap_value := 0.0 if must_break else _gap_for_bird()
	pipe.setup(loss_value, gap_value, must_break)
	pipe.set_speed(pipe_speed)


# --- 辅助计算 ---
func _calc_must_break_loss() -> int:
	return maxi(1, int(round(_must_break_window_energy * must_break_energy_ratio)))


func _roll_loss() -> int:
	var progress := clampf(cycle_time / cycle_active_duration, 0.0, 1.0)
	var bounds := _current_loss_bounds()
	var min_loss := lerpf(float(bounds.x), float(bounds.z), progress)
	var max_loss := lerpf(float(bounds.y), float(bounds.w), progress)
	return randi_range(int(round(min_loss)), int(round(max_loss)))


func _roll_energy() -> int:
	var bounds := _current_energy_bounds()
	return randi_range(bounds.x, bounds.y)


func _current_food_spawn_interval() -> float:
	return food_spawn_interval_night if sub_cycle_index == 1 else food_spawn_interval


func _current_pipe_spawn_interval() -> float:
	return pipe_spawn_interval_night if sub_cycle_index == 1 else pipe_spawn_interval


func _current_gap_multiplier() -> float:
	return gap_collision_multiplier_night if sub_cycle_index == 1 else gap_collision_multiplier


func _current_loss_bounds() -> Vector4i:
	if sub_cycle_index == 1:
		return Vector4i(
			loss_min_early_night,
			loss_max_early_night,
			loss_min_late_night,
			loss_max_late_night
		)
	return Vector4i(loss_min_early, loss_max_early, loss_min_late, loss_max_late)


func _current_energy_bounds() -> Vector2i:
	if sub_cycle_index == 1:
		return Vector2i(energy_min_night, energy_max_night)
	return Vector2i(energy_min, energy_max)


func _gap_for_bird() -> float:
	return _bird.get_collision_diameter() * _current_gap_multiplier()
