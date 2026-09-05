class_name GameRules
extends RefCounted
## The rules of a Weird World round: score, countdown, win and lose.
##
## Deliberately knows nothing about nodes or scenes, so it can be unit-tested in
## isolation (see tests/unit/core/test_game_rules.gd). The [Level] scene owns one of
## these, calls [method tick] every frame and [method add_score] when a coin is picked up,
## and forwards the signals to the HUD and the rest of the game.

## Emitted every time the score changes.
signal score_changed(score: int)
## Emitted when the number of whole seconds left changes (at most once per second).
signal time_changed(seconds_left: int)
## Emitted exactly once, when the round is won or lost.
signal finished(outcome: Outcome)

enum Outcome { IN_PROGRESS, WON, LOST }

## Rounds shorter than this make no sense; [method _init] clamps to it.
const MIN_DURATION_SECONDS: float = 0.1

var score: int = 0
var target_score: int
var time_remaining: float
var outcome: Outcome = Outcome.IN_PROGRESS

var _last_whole_seconds: int


func _init(target: int, duration_seconds: float) -> void:
	target_score = maxi(target, 1)
	time_remaining = maxf(duration_seconds, MIN_DURATION_SECONDS)
	_last_whole_seconds = seconds_left()


## Adds to the score. Ignored once the round is finished. Wins the round when the
## target is reached.
func add_score(amount: int = 1) -> void:
	if is_finished():
		return
	score += amount
	score_changed.emit(score)
	if score >= target_score:
		_finish(Outcome.WON)


## Advances the countdown by `delta` seconds. Ignored once the round is finished.
## Loses the round when time runs out.
func tick(delta: float) -> void:
	if is_finished():
		return
	time_remaining = maxf(time_remaining - delta, 0.0)
	var whole_seconds := seconds_left()
	if whole_seconds != _last_whole_seconds:
		_last_whole_seconds = whole_seconds
		time_changed.emit(whole_seconds)
	if time_remaining <= 0.0:
		_finish(Outcome.LOST)


func is_finished() -> bool:
	return outcome != Outcome.IN_PROGRESS


## Time left rounded UP to whole seconds, so the HUD never shows 0 while time remains.
func seconds_left() -> int:
	return ceili(time_remaining)


func _finish(result: Outcome) -> void:
	outcome = result
	finished.emit(outcome)
