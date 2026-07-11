# 数字显示组件：用贴图拼出多位数字（鸟/水管/食物/分数 UI 共用）
class_name DigitDisplay extends Node2D

var value: int = 0

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


func set_value(new_value: int) -> void:
	value = max(new_value, 0)
	_refresh_digits()


# --- 重建子节点：居中排列各位数字 ---
func _refresh_digits() -> void:
	for child in get_children():
		child.queue_free()

	var value_str := str(value)
	if value_str.is_empty():
		return

	var digit_widths: Array[float] = []
	var total_width := 0.0
	for digit_char in value_str:
		var texture := digit_textures[int(digit_char)]
		var width := float(texture.get_width())
		digit_widths.append(width)
		total_width += width

	var cursor_x := -total_width * 0.5
	for i in range(value_str.length()):
		var digit_int := int(value_str[i])
		var sprite := Sprite2D.new()
		sprite.texture = digit_textures[digit_int]
		sprite.position.x = cursor_x + digit_widths[i] * 0.5
		sprite.centered = true
		add_child(sprite)
		cursor_x += digit_widths[i]
