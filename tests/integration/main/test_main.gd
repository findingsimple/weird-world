extends GutTest
## Integration tests for Main: the screen flow title -> level -> results -> (level | title),
## including the "always un-pause on a screen swap" invariant.

const MAIN_SCENE := preload("res://game/main.tscn")

var _main: Main
var _screen: Node


func before_each() -> void:
	_main = MAIN_SCENE.instantiate()
	add_child_autofree(_main)
	_screen = _main.get_node("Screen")
	await wait_process_frames(1)


func after_each() -> void:
	get_tree().paused = false


## The live screen: Main frees the old one with queue_free, so skip dying nodes.
func _live_screens() -> Array[Node]:
	var live: Array[Node] = []
	for child in _screen.get_children():
		if not child.is_queued_for_deletion():
			live.append(child)
	return live


func _current_screen() -> Node:
	var live := _live_screens()
	assert_eq(live.size(), 1, "exactly one live screen")
	return live[0] if live.size() == 1 else null


func _start_game() -> Level:
	var title: TitleScreen = _current_screen()
	title.start_pressed.emit()
	await wait_process_frames(2)
	return _current_screen() as Level


func test_starts_on_the_title_screen() -> void:
	assert_true(_current_screen() is TitleScreen)


func test_start_pressed_shows_mains_level_scene_with_mains_config() -> void:
	var level := await _start_game()
	assert_not_null(level)
	assert_eq(level.scene_file_path, _main.level_scene.resource_path)
	assert_same(level.config, _main.level_config)


func test_game_over_shows_results_and_unpauses() -> void:
	await _start_game()
	get_tree().paused = true
	GameEvents.game_over.emit(GameRules.Outcome.WON, 3)
	await wait_process_frames(2)
	var results: ResultsScreen = _current_screen()
	assert_not_null(results)
	assert_false(get_tree().paused, "swapping screens always un-pauses")
	var heading: Label = results.get_node("%Heading")
	assert_eq(heading.text, "You ate everyone!")


func test_retry_starts_a_new_level() -> void:
	await _start_game()
	GameEvents.game_over.emit(GameRules.Outcome.LOST, 0)
	await wait_process_frames(2)
	var results: ResultsScreen = _current_screen()
	results.retry_pressed.emit()
	await wait_process_frames(2)
	assert_true(_current_screen() is Level)


func test_title_pressed_returns_to_title() -> void:
	await _start_game()
	GameEvents.game_over.emit(GameRules.Outcome.LOST, 0)
	await wait_process_frames(2)
	var results: ResultsScreen = _current_screen()
	results.title_pressed.emit()
	await wait_process_frames(2)
	assert_true(_current_screen() is TitleScreen)
