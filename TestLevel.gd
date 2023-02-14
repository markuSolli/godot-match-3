extends Node2D

var score = 0

onready var UI = $UI

func _process(_delta):
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()

func _on_Grid_award_points(var value: int):
	score += value
	UI.update_score(score)
