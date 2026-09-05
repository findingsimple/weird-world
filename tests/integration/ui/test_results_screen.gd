extends GutTest
## Integration tests for the results screen.

const RESULTS_SCENE := preload("res://game/ui/results_screen/results_screen.tscn")

var _screen: ResultsScreen


func before_each() -> void:
	_screen = RESULTS_SCENE.instantiate()
	add_child_autofree(_screen)
	watch_signals(_screen)


func test_show_result_for_a_win() -> void:
	_screen.show_result(GameRules.Outcome.WON, 10)
	var heading: Label = _screen.get_node("%Heading")
	var score: Label = _screen.get_node("%ScoreLabel")
	assert_eq(heading.text, "You win!")
	assert_eq(score.text, "Coins collected: 10")


func test_show_result_for_a_loss() -> void:
	_screen.show_result(GameRules.Outcome.LOST, 4)
	var heading: Label = _screen.get_node("%Heading")
	assert_eq(heading.text, "Time's up!")


func test_buttons_emit_navigation_signals() -> void:
	var retry: Button = _screen.get_node("%RetryButton")
	var title: Button = _screen.get_node("%TitleButton")
	retry.pressed.emit()
	title.pressed.emit()
	assert_signal_emitted(_screen, "retry_pressed")
	assert_signal_emitted(_screen, "title_pressed")
