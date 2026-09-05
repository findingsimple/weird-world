extends GutTest
## Integration tests for the HUD: it must follow the global event bus.

const HUD_SCENE := preload("res://game/ui/hud/hud.tscn")

var _hud: Hud
var _money_label: Label
var _humans_label: Label


func before_each() -> void:
	_hud = HUD_SCENE.instantiate()
	add_child_autofree(_hud)
	_money_label = _hud.get_node("%MoneyLabel")
	_humans_label = _hud.get_node("%HumansLabel")


func test_money_label_follows_game_events_money_changed() -> void:
	GameEvents.money_changed.emit(3)
	assert_eq(_money_label.text, "$3")


func test_humans_label_follows_game_events_humans_changed() -> void:
	GameEvents.humans_changed.emit(2, 5)
	assert_eq(_humans_label.text, "Humans left: 2 / 5")


func test_setters_format_text() -> void:
	_hud.set_money(12)
	_hud.set_humans(0, 5)
	assert_eq(_money_label.text, "$12")
	assert_eq(_humans_label.text, "Humans left: 0 / 5")
