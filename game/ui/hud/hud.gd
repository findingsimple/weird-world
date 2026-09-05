class_name Hud
extends CanvasLayer
## Heads-up display: money earned and humans left. Listens to [GameEventsBus] so it needs
## no wiring. The public setters exist so the HUD can also be driven (and tested) directly.

@onready var _money_label: Label = %MoneyLabel
@onready var _humans_label: Label = %HumansLabel


func _ready() -> void:
	GameEvents.money_changed.connect(set_money)
	GameEvents.humans_changed.connect(set_humans)


func set_money(money: int) -> void:
	_money_label.text = "$%d" % money


func set_humans(humans_left: int, humans_total: int) -> void:
	_humans_label.text = "Humans left: %d / %d" % [humans_left, humans_total]
