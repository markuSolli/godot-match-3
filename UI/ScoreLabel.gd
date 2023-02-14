extends Label

onready var tween = $Tween

func update_text(var value):
	text = str(value)
	tween.interpolate_property(self, "rect_scale", rect_scale, Vector2(.8, .8), 0.2, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	tween.interpolate_property(self, "rect_scale", Vector2(.8, .8), rect_scale, 0.2, Tween.TRANS_LINEAR, Tween.EASE_IN, 0.25)
	tween.start()
