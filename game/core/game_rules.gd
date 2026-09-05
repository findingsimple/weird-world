class_name GameRules
extends RefCounted
## The rules of a Weird World level: eat every human; each one pays into the blob's [Wallet].
##
## Deliberately knows nothing about nodes or scenes, so it can be unit-tested in isolation
## (see tests/unit/core/test_game_rules.gd). The [Level] scene owns one of these, tells it
## how many humans it placed and which wallet to pay, calls [method eat_human] when the blob
## touches a human, and forwards the signals to the HUD and the rest of the game.
##
## There is no clock (docs/gdd.md). [enum Outcome].LOST is what leaving a level early means;
## nothing in the rules produces it.

## Emitted every time a human is eaten: how many are left, out of how many there were.
signal humans_changed(humans_left: int, humans_total: int)
## Emitted exactly once, when the level is won.
signal finished(outcome: Outcome)

enum Outcome { IN_PROGRESS, WON, LOST }

## Where the money goes. Owned by whoever outlives this level (see [Main]).
var wallet: Wallet
var humans_total: int
var humans_left: int
var outcome: Outcome = Outcome.IN_PROGRESS


## `humans` is how many the level placed; `money_goes_to` is the wallet each one pays into.
## A level with nothing to eat is finished before it starts — no signal is emitted for that
## (nobody has connected yet), so the owner checks [method is_finished] after wiring up.
func _init(humans: int, money_goes_to: Wallet) -> void:
	wallet = money_goes_to
	if wallet == null:
		# Release builds strip assert(); a missing wallet is a bug, but the level must still run.
		push_error("GameRules needs a Wallet; using a fresh one that nobody else can see")
		wallet = Wallet.new()
	humans_total = maxi(humans, 0)
	humans_left = humans_total
	if humans_left == 0:
		outcome = Outcome.WON


## The blob ate a human worth `value`. Ignored once the level is finished. Wins the level
## when the last human is gone.
func eat_human(value: int) -> void:
	if is_finished():
		return
	wallet.earn(value)
	humans_left = maxi(humans_left - 1, 0)
	humans_changed.emit(humans_left, humans_total)
	if humans_left == 0:
		_finish(Outcome.WON)


func is_finished() -> bool:
	return outcome != Outcome.IN_PROGRESS


func _finish(result: Outcome) -> void:
	outcome = result
	finished.emit(outcome)
