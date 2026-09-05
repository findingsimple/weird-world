extends GutTest
## Integration tests for a whole round: the world, spawning, collecting, winning, losing, pausing.
## Uses a tiny, fast LevelConfig and a fixed RNG seed so coin positions are repeatable.

const LEVEL_SCENE := preload("res://game/level/level.tscn")
const TARGET := 10
const COIN_VALUE := 5
const DURATION := 0.5
const MAX_COINS := 3
const SPAWN_INTERVAL := 0.05
const SEED := 42
## Bit value of physics layer 3, `world` (see project.godot > [layer_names]).
const WORLD_LAYER := 4
## One physics frame at the project's pinned 60 ticks per second.
const PHYSICS_DT := 1.0 / 60.0
## A jump must clear each platform step by at least this many pixels to count as reachable.
const STEP_MARGIN := 4.0

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


## Top edge (y) of a hand-placed piece of ground: its centre minus half its box height.
func _top_of(node_path: String) -> float:
	var body: StaticBody2D = _level.get_node(node_path)
	var collider: CollisionShape2D = body.get_node("CollisionShape2D")
	var box := collider.shape as RectangleShape2D
	return body.position.y - box.size.y * 0.5


## How many pixels the blob's jump rises, stepped frame by frame the way the engine does it.
func _jump_height(player: Player) -> float:
	var motion := PlatformerMotion.new(
		player.speed, player.jump_velocity, player.gravity, player.max_fall_speed
	)
	var velocity := motion.next_velocity(Vector2.ZERO, 0.0, true, true, PHYSICS_DT)
	var y := 0.0
	while velocity.y < 0.0:
		y += velocity.y * PHYSICS_DT
		velocity = motion.next_velocity(velocity, 0.0, false, false, PHYSICS_DT)
	return -y


func test_start_emits_game_started_and_initial_hud_values() -> void:
	assert_signal_emitted(GameEvents, "game_started")
	assert_signal_emitted_with_parameters(GameEvents, "score_changed", [0, TARGET])
	assert_signal_emitted_with_parameters(GameEvents, "time_changed", [1])


func test_player_drops_in_and_lands_on_the_floor() -> void:
	var player := _level.get_player()
	var start_y := player.position.y
	await wait_physics_frames(30)
	assert_true(player.is_on_floor())
	assert_gt(player.position.y, start_y, "the blob fell before it landed")
	var collider: CollisionShape2D = player.get_node("CollisionShape2D")
	var box := collider.shape as RectangleShape2D
	assert_almost_eq(player.position.y, _top_of("World/Floor") - box.size.y * 0.5, 0.5)


func test_every_piece_of_ground_is_solid_for_the_blob() -> void:
	var world: Node2D = _level.get_node("World")
	assert_gt(world.get_child_count(), 0)
	for child in world.get_children():
		var body := child as StaticBody2D
		assert_not_null(body, "%s should be a StaticBody2D" % child.name)
		assert_eq(body.collision_layer, WORLD_LAYER, "%s should be on the world layer" % child.name)


func test_walls_keep_the_blob_inside_the_level() -> void:
	var player := _level.get_player()
	# 0.6 s at 120 px/s is 72 px: from x=64 that would leave the screen without a wall.
	_sender.action_down("move_left")
	await wait_seconds(0.6)
	assert_gte(player.position.x, 0.0, "the left wall holds")
	_sender.action_up("move_left")
	player.position.x = 600.0
	_sender.action_down("move_right")
	await wait_seconds(0.6)
	assert_lte(player.position.x, 640.0, "the right wall holds")
	assert_true(player.is_on_floor(), "still standing, not falling out of the world")


func test_default_jump_clears_each_platform_step() -> void:
	var jump := _jump_height(_level.get_player())
	var floor_top := _top_of("World/Floor")
	var low_top := _top_of("World/LowPlatform")
	var high_top := _top_of("World/HighPlatform")
	assert_gt(jump, floor_top - low_top + STEP_MARGIN, "the low platform is reachable")
	assert_gt(jump, low_top - high_top + STEP_MARGIN, "the high platform is reachable")


func test_coins_only_spawn_where_the_blob_can_reach() -> void:
	var strip := _level.arena.grow(-_config.arena_margin)
	var floor_top := _top_of("World/Floor")
	assert_lte(strip.end.y, floor_top, "no coin spawns below the floor")
	assert_gte(
		strip.position.y,
		floor_top - _jump_height(_level.get_player()),
		"the top of the coin strip is within one jump"
	)


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
