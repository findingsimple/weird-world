extends GutTest
## Integration tests for the title screen: the single entry point into the game.

const TITLE_SCENE := preload("res://game/ui/title_screen/title_screen.tscn")

var _screen: TitleScreen


func before_each() -> void:
	_screen = TITLE_SCENE.instantiate()
	add_child_autofree(_screen)
	watch_signals(_screen)


func test_play_button_emits_start_pressed() -> void:
	var play: Button = _screen.get_node("%PlayButton")
	play.pressed.emit()
	assert_signal_emitted(_screen, "start_pressed")


func test_play_button_has_focus_for_keyboard_users() -> void:
	var play: Button = _screen.get_node("%PlayButton")
	assert_true(play.has_focus())
