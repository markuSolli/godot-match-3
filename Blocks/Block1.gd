extends Node2D

export(int) var color = 0

onready var sprite = $Sprite
onready var tween = $Tween
onready var pop_timer = $PopTimer

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

func _on_PopTimer_timeout():
	queue_free()
