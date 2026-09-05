extends GutTest
## Integration tests for a whole round: spawning, collecting, winning, losing, pausing.
## Uses a tiny, fast LevelConfig and a fixed RNG seed so coin positions are repeatable.

const LEVEL_SCENE := preload("res://game/level/level.tscn")
const TARGET := 10
const COIN_VALUE := 5
const DURATION := 0.5
const MAX_COINS := 3
const SPAWN_INTERVAL := 0.05
const SEED := 42

var _level: Level
var _config: LevelConfig
var _sender: GutInputSender


func before_each() -> void:
	_config = _make_config()
	_level = _make_level(_config)
	watch_signals(GameEvents)
	add_child_autofree(_level)
	_sender = GutInputSender.new(Input)


func after_each() -> void:
	_sender.release_all()
	_sender.clear()
	get_tree().paused = false


func _make_config() -> LevelConfig:
	var config := LevelConfig.new()
	config.target_score = TARGET
	config.coin_value = COIN_VALUE
	config.duration_seconds = DURATION
	config.spawn_interval = SPAWN_INTERVAL
	config.max_coins = MAX_COINS
	return config


func _make_level(config: LevelConfig) -> Level:
	var level: Level = LEVEL_SCENE.instantiate()
	level.config = config
	level.rng_seed = SEED
	return level


func _first_coin_position(level: Level) -> Vector2:
	var coins: Node2D = level.get_node("Coins")
	var first: Node2D = coins.get_child(0)
	return first.position


func test_start_emits_game_started_and_initial_hud_values() -> void:
	assert_signal_emitted(GameEvents, "game_started")
	assert_signal_emitted_with_parameters(GameEvents, "score_changed", [0, TARGET])
	assert_signal_emitted_with_parameters(GameEvents, "time_changed", [1])


func test_player_is_confined_to_the_arena_minus_margin() -> void:
	assert_eq(_level.get_player().bounds, _level.arena.grow(-_config.arena_margin))


func test_coins_spawn_over_time_up_to_max_coins() -> void:
	# 0.3 s is six spawn intervals: enough to reach the cap, which is then never exceeded.
	await wait_seconds(0.3)
	assert_eq(_level.get_coin_count(), MAX_COINS)


func test_collecting_a_coin_adds_its_value() -> void:
	_level.spawn_coin_at(_level.get_player().position)
	await wait_physics_frames(3)
	assert_eq(_level.get_rules().score, COIN_VALUE)
	assert_signal_emitted_with_parameters(GameEvents, "score_changed", [COIN_VALUE, TARGET])


func test_reaching_target_emits_game_over_won() -> void:
	_level.spawn_coin_at(_level.get_player().position)
	_level.spawn_coin_at(_level.get_player().position)
	await wait_physics_frames(3)
	assert_signal_emitted_with_parameters(GameEvents, "game_over", [GameRules.Outcome.WON, TARGET])


func test_timeout_emits_game_over_lost() -> void:
	await wait_seconds(DURATION + 0.3)
	assert_signal_emitted_with_parameters(GameEvents, "game_over", [GameRules.Outcome.LOST, 0])


func test_round_end_stops_spawning_ticking_and_pausing() -> void:
	await wait_seconds(DURATION + 0.3)
	assert_signal_emitted(GameEvents, "game_over")
	var coins_at_end := _level.get_coin_count()
	await wait_seconds(0.2)
	assert_eq(_level.get_coin_count(), coins_at_end, "no coins spawn after the round ends")
	assert_false(_level.is_processing(), "the clock stops")
	var pause_menu: PauseMenu = _level.get_node("PauseMenu")
	assert_false(pause_menu.enabled, "pausing is disabled after the round ends")


func test_same_seed_spawns_coins_in_the_same_places() -> void:
	var twin := _make_level(_make_config())
	add_child_autofree(twin)
	await wait_seconds(0.15)
	assert_gt(_level.get_coin_count(), 0)
	assert_eq(_first_coin_position(_level), _first_coin_position(twin))


func test_pause_action_pauses_tree_and_emits_pause_toggled() -> void:
	_sender.action_down("pause")
	Input.flush_buffered_events()
	assert_true(get_tree().paused)
	assert_signal_emitted_with_parameters(GameEvents, "pause_toggled", [true])
