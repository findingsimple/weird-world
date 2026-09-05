class_name Level
extends Node2D
## One level of Weird World: the ground to stand on, the blob, the humans it is paid to eat,
## and the ghost strawberries in the way.
##
## Owns a [GameRules] (the logic), tells it how many humans the scene placed and which
## [Wallet] to pay, and forwards the signals to [GameEventsBus] so the HUD and [Main] can
## react. Pausing — and leaving the level from the pause menu — is handled with the child
## [PauseMenu]. The floor, the platforms, the walls, the humans, the strawberries and the
## blob's start are all placed by hand in level.tscn — that is level design.
##
## Getting caught by a strawberry (docs/gdd.md): the world freezes, the money goes back to
## what it was when the level started minus the fine — that attempt's earnings are forfeited —
## a "-$" pop shows the real loss, and after [constant CAUGHT_PAUSE] the level asks [Main] to
## build it again with the same wallet. A level running on its own (the scene from the editor)
## simply stays frozen; there is nobody to rebuild it.

const POP_TEXT_SCENE := preload("res://game/ui/pop_text/pop_text.tscn")
## How long the world stays frozen after the blob is caught, so the "-$" pop can be read
## before Main rebuilds the level. Matches PopText's default duration.
const CAUGHT_PAUSE: float = 0.6

## Tunables for this level. [Main] sets this before adding the level to the tree.
@export var config: LevelConfig

## The blob's money. [Main] hands in the wallet it owns, so money survives a restart; a
## level run on its own (a test, or the scene from the editor) gets a fresh one.
var wallet: Wallet

var _rules: GameRules
## What the wallet held when this attempt began; a restart goes back to it.
var _money_at_start: int = 0
## Set once a strawberry catches the blob: from then on nothing in this level pays, fines,
## or finishes — a rebuild is on its way.
var _caught: bool = false

@onready var _player: Player = $Player
@onready var _humans: Node2D = $Humans
@onready var _strawberries: Node2D = get_node_or_null("Strawberries")
@onready var _pause_menu: PauseMenu = $PauseMenu


func _ready() -> void:
	# Runtime guards: assert() is stripped from release builds, so validate for real.
	if config == null or not config.is_valid():
		push_error("Level needs a valid LevelConfig; falling back to defaults")
		config = LevelConfig.new()
	if wallet == null:
		wallet = Wallet.new()
	_money_at_start = wallet.money
	var humans := _valid_humans()
	if humans.is_empty():
		push_error("Level has no humans to eat; it ends as soon as it starts")

	_rules = GameRules.new(humans.size(), wallet)
	_rules.humans_changed.connect(_on_rules_humans_changed)
	_rules.finished.connect(_on_rules_finished)
	wallet.money_changed.connect(_on_wallet_money_changed)

	for human in humans:
		human.value = config.human_value
		human.eaten.connect(_on_human_eaten)
	for strawberry in _valid_strawberries():
		strawberry.stomped.connect(_on_strawberry_stomped)
		strawberry.blob_touched.connect(_on_strawberry_blob_touched)
	_pause_menu.quit_pressed.connect(_on_pause_menu_quit_pressed)

	GameEvents.game_started.emit(config)
	GameEvents.money_changed.emit(wallet.money)
	GameEvents.humans_changed.emit(_rules.humans_left, _rules.humans_total)
	if _rules.is_finished():
		_on_rules_finished(_rules.outcome)


## The wallet outlives this level; stop it talking to a node that is going away.
func _exit_tree() -> void:
	if wallet != null and wallet.money_changed.is_connected(_on_wallet_money_changed):
		wallet.money_changed.disconnect(_on_wallet_money_changed)


func get_rules() -> GameRules:
	return _rules


func get_player() -> Player:
	return _player


## Humans still to eat, as the rules count them.
func get_humans_left() -> int:
	return _rules.humans_left


## True while the level is being played: not finished, and the blob not caught.
func is_live() -> bool:
	return not _caught and not _rules.is_finished()


## The Human instances under Humans. Anything else there is a mistake: it is reported and
## ignored, so a stray node can never make the level unwinnable.
func _valid_humans() -> Array[Human]:
	var humans: Array[Human] = []
	for child in _humans.get_children():
		var human := child as Human
		if human == null:
			push_error("%s under Humans is not a Human; ignoring it" % child.name)
			continue
		humans.append(human)
	return humans


## The Strawberry instances under Strawberries; anything else is reported and ignored. A
## level without a Strawberries node has no enemies, which is allowed.
func _valid_strawberries() -> Array[Strawberry]:
	var strawberries: Array[Strawberry] = []
	if _strawberries == null:
		push_error("Level has no Strawberries node; no enemies in this level")
		return strawberries
	for child in _strawberries.get_children():
		var strawberry := child as Strawberry
		if strawberry == null:
			push_error("%s under Strawberries is not a Strawberry; ignoring it" % child.name)
			continue
		strawberries.append(strawberry)
	return strawberries


## Stops the blob and the strawberries where they are. Humans keep fidgeting; that is fine.
func _freeze_actors() -> void:
	_player.process_mode = Node.PROCESS_MODE_DISABLED
	for strawberry in _valid_strawberries():
		strawberry.process_mode = Node.PROCESS_MODE_DISABLED


## Shows a floating "+$2" / "-$2" for a real change in money, at a global position. A change
## of nothing (a $0 fine, a full wallet) shows nothing — the pop never claims what did not happen.
func _pop_change(delta: int, at_global: Vector2) -> void:
	if delta == 0:
		return
	var text := ("+$%d" if delta > 0 else "-$%d") % absi(delta)
	var pop: PopText = POP_TEXT_SCENE.instantiate()
	pop.position = to_local(at_global)
	add_child(pop)
	pop.show_text(text)


func _on_human_eaten(human: Human) -> void:
	if not is_live():
		return
	var before := wallet.money
	_rules.eat_human(human.value)
	_pop_change(wallet.money - before, human.global_position)


func _on_strawberry_stomped(strawberry: Strawberry) -> void:
	if not is_live():
		return
	var before := wallet.money
	wallet.earn(config.stomp_value)
	_pop_change(wallet.money - before, strawberry.global_position)


func _on_strawberry_blob_touched(strawberry: Strawberry) -> void:
	if not is_live():
		return
	_caught = true
	_pause_menu.enabled = false
	# This runs inside a physics callback, where Godot forbids disabling collision objects;
	# a frame later is fine. is_live() is already false, so nothing pays in the meantime.
	_freeze_actors.call_deferred()
	# This attempt's earnings are forfeited, then the fine is taken (docs/gdd.md).
	var before := wallet.money
	wallet.reset_to(_money_at_start)
	wallet.pay_fine(config.strawberry_fine)
	_pop_change(wallet.money - before, strawberry.global_position)
	# Let the pop be read, then ask Main to build the level again with the same wallet.
	await get_tree().create_timer(CAUGHT_PAUSE).timeout
	if is_inside_tree():
		GameEvents.blob_caught.emit(wallet.money)


func _on_pause_menu_quit_pressed() -> void:
	# Leaving is not winning: the level ends as LOST. The money is kept — it is the blob's.
	_pause_menu.enabled = false
	GameEvents.game_over.emit(GameRules.Outcome.LOST, wallet.money)


func _on_wallet_money_changed(money: int) -> void:
	GameEvents.money_changed.emit(money)


func _on_rules_humans_changed(humans_left: int, humans_total: int) -> void:
	GameEvents.humans_changed.emit(humans_left, humans_total)


func _on_rules_finished(outcome: GameRules.Outcome) -> void:
	if _caught:
		return
	_pause_menu.enabled = false
	GameEvents.game_over.emit(outcome, wallet.money)
