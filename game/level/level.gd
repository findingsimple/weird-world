class_name Level
extends Node2D
## One round of Weird World: the ground to stand on, the player, the coins, the clock.
##
## Owns a [GameRules] (the logic) and a [CoinSpawner] (where coins appear), spawns coins
## on a timer, and forwards the rules' signals to [GameEventsBus] so the HUD and [Main]
## can react. Pausing is handled by the child [PauseMenu]. The floor, the platforms and
## the player's start are placed by hand in level.tscn — that is level design.

## Tunables for this round. [Main] sets this before adding the level to the tree.
@export var config: LevelConfig
## The coin to spawn.
@export var coin_scene: PackedScene
## Where coins may appear, in Level's local coordinates (shrunk by the config's `arena_margin`).
## level.tscn sets it to the strip above the floor that the blob can actually jump to; the
## default is the whole 640x360 viewport.
@export var arena: Rect2 = Rect2(0, 0, 640, 360)
## Random seed for coin positions. 0 means "different every time"; tests set a fixed seed.
@export var rng_seed: int = 0

var _rules: GameRules
var _spawner: CoinSpawner

@onready var _player: Player = $Player
@onready var _coins: Node2D = $Coins
@onready var _spawn_timer: Timer = $SpawnTimer
@onready var _pause_menu: PauseMenu = $PauseMenu
@onready var _arena_edge: ReferenceRect = $ArenaEdge


func _ready() -> void:
	# Runtime guards: assert() is stripped from release builds, so validate for real.
	if config == null or not config.is_valid():
		push_error("Level needs a valid LevelConfig; falling back to defaults")
		config = LevelConfig.new()
	if coin_scene == null:
		push_error("Level needs a coin scene; the round cannot start")
		return

	var rng := RandomNumberGenerator.new()
	if rng_seed == 0:
		rng.randomize()
	else:
		rng.seed = rng_seed
	_spawner = CoinSpawner.new(rng)

	var spawn_area := arena.grow(-config.arena_margin)
	_arena_edge.position = spawn_area.position
	_arena_edge.size = spawn_area.size

	_rules = GameRules.new(config.target_score, config.duration_seconds)
	_rules.score_changed.connect(_on_rules_score_changed)
	_rules.time_changed.connect(_on_rules_time_changed)
	_rules.finished.connect(_on_rules_finished)

	_spawn_timer.wait_time = config.spawn_interval
	_spawn_timer.timeout.connect(_on_spawn_timer_timeout)

	GameEvents.game_started.emit(config)
	GameEvents.score_changed.emit(_rules.score, _rules.target_score)
	GameEvents.time_changed.emit(_rules.seconds_left())
	_spawn_timer.start()


func _process(delta: float) -> void:
	_rules.tick(delta)


func get_rules() -> GameRules:
	return _rules


func get_player() -> Player:
	return _player


func get_coin_count() -> int:
	return _coins.get_child_count()


## Spawns a coin at an exact position. The timer uses [method _spawn_coin]; tests use this.
func spawn_coin_at(spawn_position: Vector2) -> Coin:
	var coin: Coin = coin_scene.instantiate()
	coin.value = config.coin_value
	coin.position = spawn_position
	coin.collected.connect(_on_coin_collected)
	_coins.add_child(coin)
	return coin


func _spawn_coin() -> void:
	if get_coin_count() >= config.max_coins:
		return
	var spawn_position := _spawner.pick_position(
		arena, config.arena_margin, _player.position, config.min_spawn_distance_from_player
	)
	spawn_coin_at(spawn_position)


func _on_spawn_timer_timeout() -> void:
	_spawn_coin()


func _on_coin_collected(coin: Coin) -> void:
	_rules.add_score(coin.value)


func _on_rules_score_changed(score: int) -> void:
	GameEvents.score_changed.emit(score, _rules.target_score)


func _on_rules_time_changed(seconds_left: int) -> void:
	GameEvents.time_changed.emit(seconds_left)


func _on_rules_finished(outcome: GameRules.Outcome) -> void:
	_spawn_timer.stop()
	set_process(false)
	_pause_menu.enabled = false
	GameEvents.game_over.emit(outcome, _rules.score)
