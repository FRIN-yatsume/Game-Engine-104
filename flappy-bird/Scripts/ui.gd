class_name UI extends CanvasLayer

# References to containers
@onready var points_container: HBoxContainer = $MarginContainer/PointsContainer
@onready var game_over_box: VBoxContainer = $MarginContainer/GameOverBox
@onready var round_score_container: HBoxContainer = $MarginContainer/GameOverBox/Panel/RoundScoreContainer
@onready var best_score_container: HBoxContainer = $MarginContainer/GameOverBox/Panel/BestScoreContainer
@onready var medal_texture: TextureRect = $MarginContainer/GameOverBox/Panel/MedalTexture


# Preload all the digit textures
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

# Preload medal textures
var medal_textures: Array[Texture2D] = [
	preload("res://flappy-bird-assets-master/medalBronze.png"),
	preload("res://flappy-bird-assets-master/medalSilver.png"),
	preload("res://flappy-bird-assets-master/medalGold.png"),
	preload("res://flappy-bird-assets-master/medalPlatinum.png")
]


func set_container_score(score: int, container: HBoxContainer) -> void:
	# 1. Clear old / previous digits
	for child in container.get_children():
		child.queue_free()
		
	# 2. Convert score to string
	var score_str = str(score)
	
	# 3. Create a texture for each digit character
	for digit_char in score_str:
		var digit_int = int(digit_char)
		
		var texture_rect = TextureRect.new()
		texture_rect.texture = digit_textures[digit_int]
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP
		
		container.add_child(texture_rect)
		
		
func update_gameplay_score(points: int) -> void:
	set_container_score(points,points_container)
	
	
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
		
		
func on_game_over() -> void:
	game_over_box.visible = true	
	# Show round score
	set_container_score(SignalBus.score, round_score_container)	
	# Show best score
	set_container_score(SignalBus.high_score, best_score_container)	
	assign_medal(SignalBus.score)


func _on_button_pressed() -> void:
	get_tree().reload_current_scene()
	
	
func _ready() -> void:
	SignalBus.score_updated.connect(update_gameplay_score)
	
	# Make a fresh start each round
	set_container_score(0, points_container)
	game_over_box.visible = false
