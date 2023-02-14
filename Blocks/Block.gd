tool

extends Node2D

var shapes = [
	preload("res://Textures/square.png"),
	preload("res://Textures/triangle.png"),
	preload("res://Textures/star.png")
	]
var colors = [
	Color(0.16, 0.17, 0.76),
	Color(0.16, 0.81, 0.22),
	Color(0.95, 0.53, 0.13),
	Color(0.89, 0.20, 0.89),
	Color(0.87, 0.13, 0.13)
]

export(int, 0, 2) var shape = 0 setget set_shape
export(int, 0, 4) var color = 0 setget set_color

onready var sprite = $Sprite
onready var tween = $Tween
onready var pop_timer = $PopTimer

func set_shape(var value: int):
	shape = value
	$Sprite.texture = shapes[value]

func set_color(var value: int):
	color = value
	$Sprite.modulate = colors[value]

func set_random_color():
	set_color(randi() % colors.size())

func swap_block(var pos: Vector2, var time: float):
	tween.interpolate_property(self, "global_position", global_position, pos, time, Tween.TRANS_SINE, Tween.EASE_OUT)
	tween.start()

func invalid_swap(var pos: Vector2):
	tween.interpolate_property(self, "global_position", global_position, pos, 0.15, Tween.TRANS_LINEAR)
	tween.interpolate_property(self, "global_position", pos, global_position, 0.15, Tween.TRANS_LINEAR, 0.15)
	tween.start()

func fall_block(var pos: Vector2, var time: float):
	tween.interpolate_property(self, "global_position", global_position, pos, time, Tween.TRANS_QUAD)
	tween.start()

func pop_block():
	tween.interpolate_property(self, "scale", scale, Vector2.ZERO, 0.12, Tween.TRANS_LINEAR)
	tween.start()
	pop_timer.start(0.12)

func spawn_block():
	tween.interpolate_property(self, "scale", Vector2.ZERO, scale, 0.12, Tween.TRANS_LINEAR)
	tween.start()

func _on_PopTimer_timeout():
	queue_free()
