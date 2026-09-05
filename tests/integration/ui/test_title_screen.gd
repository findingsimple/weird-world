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


func test_subtitle_explains_the_platformer_controls() -> void:
	# The first thing a player reads. It went stale once when the controls changed.
	var subtitle: Label = _screen.get_node("%Subtitle")
	assert_string_contains(subtitle.text, "jump")
	assert_string_contains(subtitle.text, "Esc")
	assert_false("WASD" in subtitle.text, "there is no up/down movement any more")
