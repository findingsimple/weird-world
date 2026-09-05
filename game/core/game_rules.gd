class_name GameRules
extends RefCounted
## The rules of a Weird World level: eat humans for money; eat them all to finish the level.
##
## Deliberately knows nothing about nodes or scenes, so it can be unit-tested in isolation
## (see tests/unit/core/test_game_rules.gd). The [Level] scene owns one of these, tells it
## how many humans it placed, calls [method eat_human] when the blob touches one, and
## forwards the signals to the HUD and the rest of the game.
##
## There is no clock (docs/gdd.md). Losing arrives with lives in Milestone 3; until then
## [enum Outcome].LOST exists but nothing here produces it.

## Emitted every time the money changes.
signal money_changed(money: int)
## Emitted every time a human is eaten: how many are left, out of how many there were.
signal humans_changed(humans_left: int, humans_total: int)
## Emitted exactly once, when the level is won (or, from Milestone 3, lost).
signal finished(outcome: Outcome)

enum Outcome { IN_PROGRESS, WON, LOST }

var money: int = 0
var humans_total: int
var humans_left: int
var outcome: Outcome = Outcome.IN_PROGRESS


## `humans` is how many the level placed. A level with nothing to eat is finished before it
## starts — no signal is emitted for that (nobody has connected yet), so the owner checks
## [method is_finished] after wiring up.
func _init(humans: int) -> void:
	humans_total = maxi(humans, 0)
	humans_left = humans_total
	if humans_left == 0:
		outcome = Outcome.WON


## The blob ate a human worth `value`. Ignored once the level is finished. Wins the level
## when the last human is gone.
func eat_human(value: int) -> void:
	if is_finished():
		return
	money += maxi(value, 0)
	humans_left = maxi(humans_left - 1, 0)
	money_changed.emit(money)
	humans_changed.emit(humans_left, humans_total)
	if humans_left == 0:
		_finish(Outcome.WON)


func is_finished() -> bool:
	return outcome != Outcome.IN_PROGRESS


func _finish(result: Outcome) -> void:
	outcome = result
	finished.emit(outcome)
