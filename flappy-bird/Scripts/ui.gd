# 全局 UI：分数显示、游戏结束面板、奖牌与调试时间
class_name UI extends CanvasLayer

@export var show_debug_time: bool = true

# --- 节点引用 ---
@onready var points_container: HBoxContainer = $MarginContainer/PointsContainer
@onready var game_over_box: VBoxContainer = $MarginContainer/GameOverBox
@onready var round_score_container: HBoxContainer = $MarginContainer/GameOverBox/Panel/RoundScoreContainer
@onready var best_score_container: HBoxContainer = $MarginContainer/GameOverBox/Panel/BestScoreContainer
@onready var medal_texture: TextureRect = $MarginContainer/GameOverBox/Panel/MedalTexture
@onready var debug_time_label: Label = $DebugTimeLabel

var _pipe_spawner: PipeSpawner

# --- 数字贴图 0-9 ---
var digit_textures: Array[Texture2D] = [
	preload("res://flappy-bird-assets-master/sprites/0.png"),
	preload("res://flappy-bird-assets-master/sprites/1.png"),
	preload("res://flappy-bird-assets-master/sprites/2.png"),
	preload("res://flappy-bird-assets-master/sprites/3.png"),
	preload("res://flappy-bird-assets-master/sprites/4.png"),
	preload("res://flappy-bird-assets-master/sprites/5.png"),
	preload("res://flappy-bird-assets-master/sprites/6.png"),
	preload("res://flappy-bird-assets-master/sprites/7.png"),
	preload("res://flappy-bird-assets-master/sprites/8.png"),
	preload("res://flappy-bird-assets-master/sprites/9.png")
]

# --- 奖牌贴图 ---
var medal_textures: Array[Texture2D] = [
	preload("res://flappy-bird-assets-master/medalBronze.png"),
	preload("res://flappy-bird-assets-master/medalSilver.png"),
	preload("res://flappy-bird-assets-master/medalGold.png"),
	preload("res://flappy-bird-assets-master/medalPlatinum.png")
]


# --- 用贴图数字填充指定容器 ---
func set_container_score(score: int, container: HBoxContainer) -> void:
	for child in container.get_children():
		child.queue_free()

	var score_str = str(score)

	for digit_char in score_str:
		var digit_int = int(digit_char)

		var texture_rect = TextureRect.new()
		texture_rect.texture = digit_textures[digit_int]
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP

		container.add_child(texture_rect)


func update_gameplay_score(points: int) -> void:
	set_container_score(points, points_container)


# --- 根据分数显示对应奖牌 ---
func assign_medal(score: int) -> void:
	medal_texture.visible = false

	if score >= 40:
		medal_texture.texture = medal_textures[3]
		medal_texture.visible = true
	elif score >= 30:
		medal_texture.texture = medal_textures[2]
		medal_texture.visible = true
	elif score >= 20:
		medal_texture.texture = medal_textures[1]
		medal_texture.visible = true
	elif score >= 10:
		medal_texture.texture = medal_textures[0]
		medal_texture.visible = true


# --- 游戏结束面板 ---
func on_game_over() -> void:
	game_over_box.visible = true
	set_container_score(SignalBus.score, round_score_container)
	set_container_score(SignalBus.high_score, best_score_container)
	assign_medal(SignalBus.score)


func _on_button_pressed() -> void:
	get_tree().reload_current_scene()


# --- 调试：显示 PipeSpawner 的总时间与循环时间 ---
func _process(_delta: float) -> void:
	if not show_debug_time:
		return
	_update_debug_time_label()


func _update_debug_time_label() -> void:
	if debug_time_label == null:
		return

	if _pipe_spawner == null:
		debug_time_label.text = "T: --"
		return

	debug_time_label.text = (
		"T:%.2f S:%d C:%.2f" % [
			_pipe_spawner.elapsed_time,
			_pipe_spawner.sub_cycle_index,
			_pipe_spawner.cycle_time
		]
	)


func _ready() -> void:
	_pipe_spawner = get_parent().get_node("PipeSpawner") as PipeSpawner
	SignalBus.score_updated.connect(update_gameplay_score)

	set_container_score(0, points_container)
	game_over_box.visible = false
	if debug_time_label != null:
		debug_time_label.visible = show_debug_time
	if show_debug_time:
		_update_debug_time_label()
