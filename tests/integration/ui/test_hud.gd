extends GutTest
## Integration tests for the HUD: it must follow the global event bus.

const HUD_SCENE := preload("res://game/ui/hud/hud.tscn")

var _hud: Hud
var _score_label: Label
var _time_label: Label


func before_each() -> void:
	_hud = HUD_SCENE.instantiate()
	add_child_autofree(_hud)
	_score_label = _hud.get_node("%ScoreLabel")
	_time_label = _hud.get_node("%TimeLabel")


func test_score_label_reflects_game_events_score_changed() -> void:
	GameEvents.score_changed.emit(3, 10)
	assert_eq(_score_label.text, "Coins: 3 / 10")


func test_time_label_reflects_game_events_time_changed() -> void:
	GameEvents.time_changed.emit(7)
	assert_eq(_time_label.text, "Time: 7")


func test_setters_format_text() -> void:
	_hud.set_score(1, 2)
	_hud.set_time(9)
	assert_eq(_score_label.text, "Coins: 1 / 2")
	assert_eq(_time_label.text, "Time: 9")
