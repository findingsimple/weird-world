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


func test_money_carries_from_one_level_to_the_next() -> void:
	var level := await _start_game()
	var wallet := level.wallet
	wallet.earn(4)
	GameEvents.game_over.emit(GameRules.Outcome.WON, wallet.money)
	# (the results screen reads the wallet itself; the number on the bus is advisory)
	await wait_process_frames(2)
	var results: ResultsScreen = _current_screen()
	results.retry_pressed.emit()
	await wait_process_frames(2)
	var next := _current_screen() as Level
	assert_not_null(next)
	assert_same(next.wallet, wallet, "the same wallet is handed to the next level")
	assert_eq(next.wallet.money, 4)


func test_the_title_screen_starts_a_new_job_with_an_empty_wallet() -> void:
	var level := await _start_game()
	level.wallet.earn(4)
	GameEvents.game_over.emit(GameRules.Outcome.LOST, 4)
	await wait_process_frames(2)
	var results: ResultsScreen = _current_screen()
	results.title_pressed.emit()
	await wait_process_frames(2)
	var fresh := await _start_game()
	assert_eq(fresh.wallet.money, 0)


func test_blob_caught_rebuilds_the_level_with_the_same_wallet() -> void:
	var level := await _start_game()
	var wallet := level.wallet
	var first_id := level.get_instance_id()
	wallet.earn(4)
	GameEvents.blob_caught.emit(wallet.money)
	await wait_process_frames(2)
	var rebuilt := _current_screen() as Level
	assert_not_null(rebuilt, "a level is showing again")
	assert_ne(rebuilt.get_instance_id(), first_id, "a fresh level, not the old one")
	assert_same(rebuilt.wallet, wallet, "with the blob's own wallet")
	assert_eq(rebuilt.wallet.money, 4, "the money survived the restart")


func test_a_real_catch_rebuilds_the_level_with_this_attempts_earnings_forfeited() -> void:
	var level := await _start_game()
	var wallet := level.wallet
	var first_id := level.get_instance_id()
	var fine := _main.level_config.strawberry_fine
	# Eat one human through the real overlap, then walk into a strawberry's side.
	var humans: Node2D = level.get_node("Humans")
	var human_count := humans.get_child_count()  # read now: the level is freed by the rebuild
	var human: Human = humans.get_child(0)
	level.get_player().position = human.position
	await wait_physics_frames(3)
	assert_gt(wallet.money, 0, "earned something this attempt")
	var strawberries: Node2D = level.get_node("Strawberries")
	var strawberry: Strawberry = strawberries.get_child(0)
	level.get_player().position = strawberry.position + Vector2(-8.0, 0.0)
	await wait_seconds(Level.CAUGHT_PAUSE + 0.3)
	var rebuilt := _current_screen() as Level
	assert_not_null(rebuilt, "a level is showing again")
	assert_ne(rebuilt.get_instance_id(), first_id, "a fresh level, not the old one")
	assert_same(rebuilt.wallet, wallet, "with the blob's own wallet")
	assert_eq(
		wallet.money,
		maxi(0 - fine, 0),
		"back to the attempt's start ($0) minus the fine, never below 0"
	)
	assert_eq(rebuilt.get_humans_left(), human_count, "every human is back")


func test_the_results_screen_shows_the_wallet_not_a_stale_number() -> void:
	var level := await _start_game()
	level.wallet.earn(4)
	GameEvents.game_over.emit(GameRules.Outcome.WON, 1)
	await wait_process_frames(2)
	var results: ResultsScreen = _current_screen()
	var money: Label = results.get_node("%MoneyLabel")
	assert_eq(money.text, "Money: $4", "the wallet's total, whatever the bus carried")


func test_title_pressed_returns_to_title() -> void:
	await _start_game()
	GameEvents.game_over.emit(GameRules.Outcome.LOST, 0)
	await wait_process_frames(2)
	var results: ResultsScreen = _current_screen()
	results.title_pressed.emit()
	await wait_process_frames(2)
	assert_true(_current_screen() is TitleScreen)
