class_name Hud
extends CanvasLayer
## Heads-up display: score and time. Listens to [GameEventsBus] so it needs no wiring.
## The public setters exist so the HUD can also be driven (and tested) directly.

@onready var _score_label: Label = %ScoreLabel
@onready var _time_label: Label = %TimeLabel


func _ready() -> void:
	GameEvents.score_changed.connect(set_score)
	GameEvents.time_changed.connect(set_time)


func set_score(score: int, target: int) -> void:
	_score_label.text = "Coins: %d / %d" % [score, target]


func set_time(seconds_left: int) -> void:
	_time_label.text = "Time: %d" % seconds_left
