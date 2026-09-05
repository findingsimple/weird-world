extends GutTest
## Integration tests for a whole level: the world, the humans, the strawberries, eating,
## stomping, being caught, winning, quitting, pausing. Uses a LevelConfig with distinctive
## numbers so a value read from the wrong place shows up as the wrong number.
##
## The shared level's two strawberries are WALKING during every test. Tests that teleport the
## blob onto a spot and wait stay clear of their patrol paths (the humans on the floor at
## x=140 and on the platforms; the floor strawberry starts at x=520 walking left).
## Tests that build a second level take the shared one out of the tree first.

const LEVEL_SCENE := preload("res://game/level/level.tscn")
const STRAWBERRY_SCENE := preload("res://game/strawberry/strawberry.tscn")
const HUMAN_VALUE := 3
const STOMP_VALUE := 7
const FINE := 4
## The designer's number: how many humans level_01 places. Pinned in ONE test
## (test_level_01_has_the_designers_humans); every other test counts what is there.
const HUMANS_IN_LEVEL := 5
## Bit values: layer 3 `world`, layer 4 `enemies`.
const WORLD_LAYER := 4
const ENEMIES_LAYER := 8
## One physics frame at the project's pinned 60 ticks per second.
const PHYSICS_DT := 1.0 / 60.0
## A jump must clear a step between two pieces of ground by at least this many pixels.
const STEP_MARGIN := 4.0
## Level coordinates. Ground whose top edge is outside this is not somewhere to stand.
const VIEWPORT := Rect2(0, 0, 640, 360)
## Long enough for the caught pause to end and the bus signal to go out.
const AFTER_CAUGHT := Level.CAUGHT_PAUSE + 0.2

var _level: Level
var _config: LevelConfig
var _sender: GutInputSender


func before_each() -> void:
	_config = LevelConfig.new()
	_config.human_value = HUMAN_VALUE
	_config.stomp_value = STOMP_VALUE
	_config.strawberry_fine = FINE
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


## For tests that build their own level: take the shared one out of the tree so the two do
## not share a physics space or a bus. GUT still frees it afterwards.
func _park_shared_level() -> void:
	remove_child(_level)


## Half the height of a body's rectangular collider.
func _half_height(body: Node2D) -> float:
	var collider: CollisionShape2D = body.get_node("CollisionShape2D")
	var box := collider.shape as RectangleShape2D
	return box.size.y * 0.5


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
	return body.position.y - _half_height(body)


## Which piece of ground `spot` (a body's centre, `half_height` above its feet) stands on.
## Returns an empty Rect2 if none.
func _ground_under(spot: Vector2, half_height: float) -> Rect2:
	for piece in _ground_pieces():
		var on_top := absf(piece.position.y - spot.y - half_height) <= 1.0
		var within := spot.x >= piece.position.x and spot.x <= piece.end.x
		if on_top and within:
			return piece
	return Rect2()


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


## The Strawberry nodes in the level. Anything else under Strawberries fails the test that asked.
func _strawberries() -> Array[Strawberry]:
	var strawberries: Array[Strawberry] = []
	var container: Node2D = _level.get_node("Strawberries")
	for child in container.get_children():
		var strawberry := child as Strawberry
		assert_not_null(strawberry, "%s under Strawberries is not a Strawberry" % child.name)
		if strawberry != null:
			strawberries.append(strawberry)
	return strawberries


## The PopText children of `level` right now.
func _pops(level: Level) -> Array[PopText]:
	var pops: Array[PopText] = []
	for child in level.get_children():
		var pop := child as PopText
		if pop != null:
			pops.append(pop)
	return pops


## Drops the blob onto a spot and lets the physics server notice the overlap.
func _eat_at(spot: Vector2) -> void:
	_level.get_player().position = spot
	await wait_physics_frames(3)


## Puts the blob beside a strawberry (a touch, never a stomp) and waits out the caught pause.
func _get_caught_by(strawberry: Strawberry) -> void:
	_level.get_player().position = strawberry.position + Vector2(-8.0, 0.0)
	await wait_seconds(AFTER_CAUGHT)


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
	assert_almost_eq(player.position.y, _top_of("World/Floor") - _half_height(player), 0.5)


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
	var humans := _humans()
	assert_gt(humans.size(), 0, "the level places humans")
	for human in humans:
		var ground := _ground_under(human.position, _half_height(human))
		assert_true(
			ground.has_area(), "%s at %s is floating or buried" % [human.name, human.position]
		)


func test_level_01_places_ghost_strawberries_that_patrol_their_own_ground() -> void:
	var strawberries := _strawberries()
	assert_gt(strawberries.size(), 0, "the level has at least one ghost strawberry")
	var home: Dictionary = {}
	for strawberry in strawberries:
		var ground := _ground_under(strawberry.position, _half_height(strawberry))
		assert_true(ground.has_area(), "%s starts on a piece of ground" % strawberry.name)
		home[strawberry.name] = ground
	# Long enough for both to reach a wall or a ledge and come back.
	await wait_seconds(1.5)
	for strawberry in strawberries:
		assert_true(strawberry.is_on_floor(), "%s is still standing" % strawberry.name)
		assert_true(
			VIEWPORT.has_point(strawberry.position), "%s is still on screen" % strawberry.name
		)
		var ground_now := _ground_under(strawberry.position, _half_height(strawberry))
		var ground_home: Rect2 = home[strawberry.name]
		assert_eq(
			ground_now, ground_home, "%s is still on the ground it started on" % strawberry.name
		)


func test_every_strawberry_is_an_enemy_that_masks_only_the_world() -> void:
	for strawberry in _strawberries():
		assert_eq(strawberry.collision_layer, ENEMIES_LAYER, "%s is on enemies" % strawberry.name)
		assert_eq(
			strawberry.collision_mask, WORLD_LAYER, "%s bumps into the world only" % strawberry.name
		)


func test_eating_a_human_pays_its_value() -> void:
	var total := _human_positions().size()
	await _eat_at(_human_positions()[0])
	assert_eq(_level.wallet.money, HUMAN_VALUE)
	assert_eq(_level.get_humans_left(), total - 1)
	assert_signal_emitted_with_parameters(GameEvents, "money_changed", [HUMAN_VALUE])
	assert_signal_emit_count(GameEvents, "money_changed", 2, "once at start, once per human")
	assert_signal_emitted_with_parameters(GameEvents, "humans_changed", [total - 1, total])


func test_eating_pops_the_money_at_the_spot() -> void:
	var spot := _human_positions()[0]
	await _eat_at(spot)
	var pops := _pops(_level)
	assert_eq(pops.size(), 1, "one pop for one human")
	if pops.size() == 1:
		var label: Label = pops[0].get_node("Label")
		assert_eq(label.text, "+$%d" % HUMAN_VALUE)
		assert_almost_eq(pops[0].position.x, spot.x, 0.01, "at the human's x")
		assert_lte(pops[0].position.y, spot.y, "at (or floating up from) the human's y")


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


func test_stomping_a_strawberry_pays_stomp_value_and_squishes_it() -> void:
	var strawberry := _strawberries()[0]
	var count := _strawberries().size()
	_level.get_player().position = Vector2(strawberry.position.x, strawberry.top_y() - 20.0)
	await wait_physics_frames(20)
	assert_eq(_level.wallet.money, STOMP_VALUE, "the config's stomp value, not a default")
	assert_eq(_strawberries().size(), count - 1, "one strawberry fewer")
	assert_signal_not_emitted(GameEvents, "blob_caught")
	var pops := _pops(_level)
	assert_eq(pops.size(), 1, "one pop for one stomp")
	if pops.size() == 1:
		var label: Label = pops[0].get_node("Label")
		assert_eq(label.text, "+$%d" % STOMP_VALUE)


func test_a_stomp_after_the_level_is_won_pays_nothing() -> void:
	for spot in _human_positions():
		await _eat_at(spot)
	var won_with := _level.wallet.money
	var strawberry := _strawberries()[0]
	_level.get_player().position = Vector2(strawberry.position.x, strawberry.top_y() - 20.0)
	await wait_physics_frames(20)
	assert_eq(_level.wallet.money, won_with, "the results screen and the wallet agree")


func test_being_caught_forfeits_this_attempts_earnings_then_takes_the_fine() -> void:
	_park_shared_level()
	var level := _make_level()
	level.wallet = Wallet.new(10)
	add_child_autofree(level)
	_level = level  # so the helpers below look at this level
	await _eat_at(_human_positions()[0])
	assert_eq(level.wallet.money, 10 + HUMAN_VALUE, "earned this attempt")
	await _get_caught_by(_strawberries()[0])
	assert_eq(level.wallet.money, 10 - FINE, "back to the start of the attempt, minus the fine")
	assert_signal_emitted_with_parameters(GameEvents, "blob_caught", [10 - FINE])
	assert_signal_emit_count(GameEvents, "blob_caught", 1)
	var pause_menu: PauseMenu = level.get_node("PauseMenu")
	assert_false(pause_menu.enabled, "no pausing while the level restarts")


func test_being_caught_pops_the_real_loss_and_freezes_the_world() -> void:
	_park_shared_level()
	var level := _make_level()
	level.wallet = Wallet.new(10)
	add_child_autofree(level)
	_level = level
	await _eat_at(_human_positions()[0])
	var strawberry := _strawberries()[0]
	level.get_player().position = strawberry.position + Vector2(-8.0, 0.0)
	await wait_physics_frames(3)
	# Caught: the loss is (10 + 3) -> 6, i.e. $7, and shown as such, not as the nominal fine.
	assert_eq(level.wallet.money, 10 - FINE)
	var pops := _pops(level)
	assert_gte(pops.size(), 1, "a pop for the loss")
	var loss_shown := false
	for pop in pops:
		var label: Label = pop.get_node("Label")
		if label.text == "-$%d" % (HUMAN_VALUE + FINE):
			loss_shown = true
	assert_true(loss_shown, "the pop shows the money actually lost")
	assert_false(level.is_live())
	var frozen_at := level.get_player().position
	var strawberry_at := strawberry.position
	await wait_physics_frames(10)
	assert_eq(level.get_player().position, frozen_at, "the blob is frozen")
	assert_eq(strawberry.position, strawberry_at, "the strawberry is frozen")
	assert_signal_not_emitted(GameEvents, "blob_caught", "the restart waits for the pop to be read")
	await wait_seconds(AFTER_CAUGHT)
	assert_signal_emitted(GameEvents, "blob_caught")


func test_a_fine_never_takes_the_blob_below_zero() -> void:
	_park_shared_level()
	var level := _make_level()
	level.wallet = Wallet.new(1)
	add_child_autofree(level)
	_level = level
	await _get_caught_by(_strawberries()[0])
	assert_eq(level.wallet.money, 0)
	assert_signal_emitted_with_parameters(GameEvents, "blob_caught", [0])


func test_two_strawberries_at_once_fine_the_blob_once() -> void:
	_park_shared_level()
	var level := _make_level()
	level.wallet = Wallet.new(10)
	var container: Node2D = level.get_node("Strawberries")
	var first: Strawberry = container.get_child(0)
	var twin: Strawberry = STRAWBERRY_SCENE.instantiate()
	twin.position = first.position
	container.add_child(twin)
	add_child_autofree(level)
	_level = level
	await _get_caught_by(first)
	assert_eq(level.wallet.money, 10 - FINE, "one fine, not two")
	assert_signal_emit_count(GameEvents, "blob_caught", 1)


func test_nothing_pays_or_finishes_after_the_blob_is_caught() -> void:
	_park_shared_level()
	var level := _make_level()
	add_child_autofree(level)
	_level = level
	var spots := _human_positions()
	var strawberry := _strawberries()[0]
	level.get_player().position = strawberry.position + Vector2(-8.0, 0.0)
	await wait_physics_frames(3)
	assert_false(level.is_live())
	# Force the blob onto every human despite the freeze: nothing may change.
	for spot in spots:
		level.get_player().position = spot
		await wait_physics_frames(2)
	assert_eq(level.get_humans_left(), spots.size(), "no human was eaten")
	assert_signal_not_emitted(GameEvents, "game_over", "the level did not finish")


func test_a_level_given_a_wallet_adds_to_it_and_shows_it() -> void:
	_park_shared_level()
	var level := _make_level()
	var wallet := Wallet.new(5)
	level.wallet = wallet
	add_child_autofree(level)
	_level = level
	var hud: Hud = level.get_node("Hud")
	var money: Label = hud.get_node("%MoneyLabel")
	assert_eq(money.text, "$5", "the HUD shows what the blob already had")
	await _eat_at(_human_positions()[0])
	assert_eq(wallet.money, 5 + HUMAN_VALUE)
	assert_same(level.get_rules().wallet, wallet, "the rules pay into the wallet they were given")


func test_a_level_out_of_the_tree_stops_relaying_its_wallet() -> void:
	var wallet := _level.wallet
	var relayed_so_far: int = get_signal_emit_count(GameEvents, "money_changed")
	remove_child(_level)
	wallet.earn(1)
	assert_signal_emit_count(
		GameEvents, "money_changed", relayed_so_far, "nothing relayed after _exit_tree"
	)


func test_a_level_with_no_humans_ends_as_soon_as_it_starts() -> void:
	_park_shared_level()
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
	_park_shared_level()
	var level := _make_level()
	var container: Node2D = level.get_node("Humans")
	var real_humans := container.get_child_count()
	container.add_child(Node2D.new())
	add_child_autofree(level)
	assert_push_error("is not a Human", "the mistake is reported, not hidden")
	assert_eq(
		level.get_rules().humans_total, real_humans, "a stray node cannot make a level unwinnable"
	)


func test_a_stray_node_under_strawberries_is_ignored() -> void:
	_park_shared_level()
	var level := _make_level()
	var container: Node2D = level.get_node("Strawberries")
	container.add_child(Node2D.new())
	add_child_autofree(level)
	assert_push_error("is not a Strawberry", "the mistake is reported, not hidden")
	assert_true(level.is_live(), "the level plays on")


func test_a_level_without_a_strawberries_node_still_plays() -> void:
	_park_shared_level()
	var level := _make_level()
	var container: Node2D = level.get_node("Strawberries")
	level.remove_child(container)
	container.free()
	add_child_autofree(level)
	assert_push_error("no Strawberries node")
	_level = level
	await _eat_at(_human_positions()[0])
	assert_eq(level.wallet.money, HUMAN_VALUE, "eating still works without enemies")


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
