# 碰撞调试可视化入口：扫描场景中所有 CollisionShape2D 并挂载调试绘制
extends Node

@export var enabled: bool = false

const DEBUG_COLORS: Array[Color] = [
	Color(0, 1, 0, 0.35),
	Color(1, 0.2, 0.2, 0.35),
	Color(0.2, 0.5, 1, 0.35),
	Color(1, 0.8, 0, 0.35),
]

var _color_index: int = 0


func _ready() -> void:
	if not enabled:
		return
	call_deferred("_scan_tree", get_tree().current_scene)
	get_tree().node_added.connect(_on_node_added)


func _on_node_added(node: Node) -> void:
	if node is CollisionShape2D:
		call_deferred("_attach_visual", node)


func _scan_tree(root: Node) -> void:
	if root == null:
		return
	if root is CollisionShape2D:
		_attach_visual(root)
	for child in root.get_children():
		_scan_tree(child)


func _attach_visual(collision_shape: CollisionShape2D) -> void:
	if collision_shape.get_node_or_null("DebugVisual") != null:
		return

	var drawer := Node2D.new()
	drawer.name = "DebugVisual"
	drawer.set_script(load("res://Scripts/collision_debug_draw.gd"))
	drawer.set("debug_color", DEBUG_COLORS[_color_index % DEBUG_COLORS.size()])
	_color_index += 1
	collision_shape.add_child(drawer)
