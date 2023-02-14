extends CanvasLayer

onready var score_label = $LeftBar/ScoreLabel

func update_score(var value: int):
	score_label.update_text(value)
