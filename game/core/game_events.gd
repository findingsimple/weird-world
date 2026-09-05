class_name GameEventsBus
extends Node
## Global event bus, autoloaded as `GameEvents` (see project.godot > [autoload]).
##
## It holds no state and has no methods: it only declares signals that any part of the
## game may emit or listen to. Use it to broadcast things that cross screen boundaries
## (a round starting or ending). Inside a single scene prefer direct signals — "signal up,
## call down" — so that scenes stay self-contained and testable.
##
## Example:
## [codeblock]
## GameEvents.score_changed.connect(_on_score_changed)
## GameEvents.score_changed.emit(3, 10)
## [/codeblock]

## A new round started with the given configuration.
signal game_started(config: LevelConfig)
## The score changed. `target` is the score needed to win.
signal score_changed(score: int, target: int)
## Whole seconds left changed (emitted at most once per second).
signal time_changed(seconds_left: int)
## The round ended, either by reaching the target or by running out of time.
signal game_over(outcome: GameRules.Outcome, score: int)
## The game was paused or resumed.
signal pause_toggled(is_paused: bool)
