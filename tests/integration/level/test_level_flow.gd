extends GutTest
## Integration tests for a whole level: the world, the humans, eating, winning, quitting,
## pausing. Uses a tiny LevelConfig so the money numbers are easy to check.

const LEVEL_SCENE := preload("res://game/level/level.tscn")
const HUMAN_VALUE := 3
## The designer's number: how many humans level_01 places. Pinned in ONE test
## (test_level_01_has_the_designers_humans); every other test counts what is there.
const HUMANS_IN_LEVEL := 5
## Bit value of physics layer 3, `world` (see project.godot > [layer_names]).
const WORLD_LAYER := 4
## One physics frame at the project's pinned 60 ticks per second.
const PHYSICS_DT := 1.0 / 60.0
## A jump must clear a step between two pieces of ground by at least this many pixels.
const STEP_MARGIN := 4.0
## A human standing on ground has its centre this far above the ground's top edge
## (half its 14 px box), give or take a pixel.
const STANDING_HEIGHT := 7.0
## Level coordinates. Ground whose top edge is outside this is not somewhere to stand.
const VIEWPORT := Rect2(0, 0, 640, 360)

var _level: Level
var _config: LevelConfig
var _sender: GutInputSender


func before_each() -> void:
	_config = LevelConfig.new()
	_config.human_value = HUMAN_VALUE
	_level = _make_level()
	watch_signals(GameEvents)
	add_child_autofree(_level)
	_sender = GutInputSender.new(Input)


func after_each() -> void:
	_sender.release_all()
	_sender.clear()
	get_tree().paused = false


func _make_level() -> Level:
	var level: Level = LEVEL_SCENE.instantiate()
	level.config = _config
	return level


## The collision rect (Level coordinates) of every World body whose top edge is on screen:
## the floor and the platforms, not the off-screen edge walls.
func _ground_pieces() -> Array[Rect2]:
	var pieces: Array[Rect2] = []
	var world: Node2D = _level.get_node("World")
	for child in world.get_children():
		var body := child as StaticBody2D
		var collider: CollisionShape2D = body.get_node("CollisionShape2D")
		var box := collider.shape as RectangleShape2D
		var rect := Rect2(body.position - box.size * 0.5, box.size)
		if VIEWPORT.has_point(Vector2(rect.get_center().x, rect.position.y)):
			pieces.append(rect)
	return pieces


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


## The Human nodes in the level. Anything else under Humans fails the test that asked.
func _humans() -> Array[Human]:
	var humans: Array[Human] = []
	var container: Node2D = _level.get_node("Humans")
	for child in container.get_children():
		var human := child as Human
		assert_not_null(human, "%s under Humans is not a Human" % child.name)
		if human != null:
			humans.append(human)
	return humans


## Where every human stands right now.
func _human_positions() -> Array[Vector2]:
	var positions: Array[Vector2] = []
	for human in _humans():
		positions.append(human.position)
	return positions


## Drops the blob onto a spot and lets the physics server notice the overlap.
func _eat_at(spot: Vector2) -> void:
	_level.get_player().position = spot
	await wait_physics_frames(3)


func test_level_01_has_the_designers_humans() -> void:
	assert_eq(
		_human_positions().size(),
		HUMANS_IN_LEVEL,
		(
			"level_01 should place %d humans. Added one on purpose? Change HUMANS_IN_LEVEL here."
			% HUMANS_IN_LEVEL
		)
	)
	assert_eq(_level.get_humans_left(), HUMANS_IN_LEVEL)


func test_start_emits_game_started_and_shows_initial_hud_values() -> void:
	var total := _human_positions().size()
	assert_signal_emitted(GameEvents, "game_started")
	assert_signal_emitted_with_parameters(GameEvents, "money_changed", [0])
	assert_signal_emitted_with_parameters(GameEvents, "humans_changed", [total, total])
	var hud: Hud = _level.get_node("Hud")
	var money: Label = hud.get_node("%MoneyLabel")
	var humans: Label = hud.get_node("%HumansLabel")
	assert_eq(money.text, "$0")
	assert_eq(humans.text, "Humans left: %d / %d" % [total, total])


func test_every_human_is_paid_the_levels_value() -> void:
	for human in _humans():
		assert_eq(human.value, HUMAN_VALUE, "%s takes its value from the config" % human.name)


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


## Vertical reach only: every platform must be within one jump of the next piece of ground
## below it. Sideways gaps are for playtesting — the blob has to run and jump at once.
func test_every_piece_of_ground_is_within_one_jump_of_a_lower_one() -> void:
	var jump := _jump_height(_level.get_player())
	var pieces := _ground_pieces()
	assert_gt(pieces.size(), 1, "a floor and at least one platform")
	for piece in pieces:
		var nearest_drop := INF
		for other in pieces:
			var drop := other.position.y - piece.position.y
			if drop > 0.0 and drop < nearest_drop:
				nearest_drop = drop
		if nearest_drop == INF:
			continue  # the floor: nothing is below it
		assert_lt(
			nearest_drop + STEP_MARGIN,
			jump,
			(
				"ground with its top at y=%d is too high above the next piece down"
				% int(piece.position.y)
			)
		)


func test_every_human_stands_on_something() -> void:
	var pieces := _ground_pieces()
	var spots := _human_positions()
	assert_gt(spots.size(), 0, "the level places humans")
	for spot in spots:
		var grounded := false
		for piece in pieces:
			var on_top := absf(piece.position.y - spot.y - STANDING_HEIGHT) <= 1.0
			var within := spot.x >= piece.position.x and spot.x <= piece.end.x
			if on_top and within:
				grounded = true
		assert_true(grounded, "human at %s is floating or buried" % spot)


func test_eating_a_human_pays_its_value() -> void:
	var total := _human_positions().size()
	await _eat_at(_human_positions()[0])
	assert_eq(_level.wallet.money, HUMAN_VALUE)
	assert_eq(_level.get_humans_left(), total - 1)
	assert_signal_emitted_with_parameters(GameEvents, "money_changed", [HUMAN_VALUE])
	assert_signal_emit_count(GameEvents, "money_changed", 2, "once at start, once per human")
	assert_signal_emitted_with_parameters(GameEvents, "humans_changed", [total - 1, total])


func test_eating_every_human_wins_the_level_exactly_once() -> void:
	var spots := _human_positions()
	for spot in spots:
		await _eat_at(spot)
	assert_eq(_level.get_humans_left(), 0)
	assert_signal_emitted_with_parameters(
		GameEvents, "game_over", [GameRules.Outcome.WON, spots.size() * HUMAN_VALUE]
	)
	assert_signal_emit_count(GameEvents, "game_over", 1)
	var pause_menu: PauseMenu = _level.get_node("PauseMenu")
	assert_false(pause_menu.enabled, "pausing is disabled after the level ends")


func test_level_is_not_won_while_a_human_is_left() -> void:
	var spots := _human_positions()
	for i in spots.size() - 1:
		await _eat_at(spots[i])
	assert_eq(_level.get_humans_left(), 1)
	assert_signal_not_emitted(GameEvents, "game_over")


func test_a_level_given_a_wallet_adds_to_it_and_shows_it() -> void:
	var level := _make_level()
	var wallet := Wallet.new(5)
	level.wallet = wallet
	add_child_autofree(level)
	var hud: Hud = level.get_node("Hud")
	var money: Label = hud.get_node("%MoneyLabel")
	assert_eq(money.text, "$5", "the HUD shows what the blob already had")
	var humans: Node2D = level.get_node("Humans")
	var first: Human = humans.get_child(0)
	level.get_player().position = first.position
	await wait_physics_frames(3)
	assert_eq(wallet.money, 5 + HUMAN_VALUE)
	assert_same(level.get_rules().wallet, wallet, "the rules pay into the wallet they were given")


func test_a_level_with_no_humans_ends_as_soon_as_it_starts() -> void:
	var empty := _make_level()
	var container: Node2D = empty.get_node("Humans")
	for child in container.get_children():
		container.remove_child(child)
		child.free()
	add_child_autofree(empty)
	# GUT fails a test on any engine error it did not expect; this one is the point.
	assert_push_error("no humans")
	assert_signal_emitted_with_parameters(GameEvents, "game_over", [GameRules.Outcome.WON, 0])


func test_a_stray_node_under_humans_is_ignored_not_counted() -> void:
	var level := _make_level()
	var container: Node2D = level.get_node("Humans")
	var real_humans := container.get_child_count()
	container.add_child(Node2D.new())
	add_child_autofree(level)
	assert_push_error("is not a Human", "the mistake is reported, not hidden")
	assert_eq(
		level.get_rules().humans_total, real_humans, "a stray node cannot make a level unwinnable"
	)


func test_quitting_from_the_pause_menu_ends_the_level_with_the_money_so_far() -> void:
	await _eat_at(_human_positions()[0])
	var pause_menu: PauseMenu = _level.get_node("PauseMenu")
	pause_menu.set_paused(true)
	var title: Button = pause_menu.get_node("%TitleButton")
	title.pressed.emit()
	assert_signal_emitted_with_parameters(
		GameEvents, "game_over", [GameRules.Outcome.LOST, HUMAN_VALUE]
	)
	assert_false(pause_menu.enabled, "no pausing once the level is over")


func test_pause_action_pauses_tree_and_emits_pause_toggled() -> void:
	_sender.action_down("pause")
	Input.flush_buffered_events()
	assert_true(get_tree().paused)
	assert_signal_emitted_with_parameters(GameEvents, "pause_toggled", [true])
