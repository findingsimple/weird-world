class_name Level
extends Node2D
## One level of Weird World: the ground to stand on, the blob, and the humans it is paid to eat.
##
## Owns a [GameRules] (the logic), tells it how many humans the scene placed and which
## [Wallet] to pay, and forwards the signals to [GameEventsBus] so the HUD and [Main] can
## react. Pausing — and leaving the level from the pause menu — is handled with the child
## [PauseMenu]. The floor, the platforms, the walls, the humans and the blob's start are all
## placed by hand in level.tscn — that is level design.

## Tunables for this level. [Main] sets this before adding the level to the tree.
@export var config: LevelConfig

## The blob's money. [Main] hands in the wallet it owns, so money survives a restart; a
## level run on its own (a test, or the scene from the editor) gets a fresh one.
var wallet: Wallet

var _rules: GameRules

@onready var _player: Player = $Player
@onready var _humans: Node2D = $Humans
@onready var _pause_menu: PauseMenu = $PauseMenu


func _ready() -> void:
	# Runtime guards: assert() is stripped from release builds, so validate for real.
	if config == null or not config.is_valid():
		push_error("Level needs a valid LevelConfig; falling back to defaults")
		config = LevelConfig.new()
	if wallet == null:
		wallet = Wallet.new()
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


func _on_human_eaten(human: Human) -> void:
	_rules.eat_human(human.value)


func _on_pause_menu_quit_pressed() -> void:
	# Leaving is not winning: the level ends as LOST. The money is kept — it is the blob's.
	_pause_menu.enabled = false
	GameEvents.game_over.emit(GameRules.Outcome.LOST, wallet.money)


func _on_wallet_money_changed(money: int) -> void:
	GameEvents.money_changed.emit(money)


func _on_rules_humans_changed(humans_left: int, humans_total: int) -> void:
	GameEvents.humans_changed.emit(humans_left, humans_total)


func _on_rules_finished(outcome: GameRules.Outcome) -> void:
	_pause_menu.enabled = false
	GameEvents.game_over.emit(outcome, wallet.money)
