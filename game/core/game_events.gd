class_name GameEventsBus
extends Node
## Global event bus, autoloaded as `GameEvents` (see project.godot > [autoload]).
##
## It holds no state and has no methods: it only declares signals that any part of the
## game may emit or listen to. Use it to broadcast things that cross screen boundaries
## (a level starting or ending). Inside a single scene prefer direct signals — "signal up,
## call down" — so that scenes stay self-contained and testable.
##
## Example:
## [codeblock]
## GameEvents.money_changed.connect(_on_money_changed)
## GameEvents.money_changed.emit(3)
## [/codeblock]

## A new level started with the given configuration.
signal game_started(config: LevelConfig)
## The blob's money changed.
signal money_changed(money: int)
## How many humans are left, out of how many the level started with. Emitted once when the
## level starts, then every time a human is eaten.
signal humans_changed(humans_left: int, humans_total: int)
## A ghost strawberry caught the blob: the fine is already paid, and the level restarts.
signal blob_caught(money_left: int)
## The level ended. `money` is the blob's total.
signal game_over(outcome: GameRules.Outcome, money: int)
## The game was paused or resumed.
signal pause_toggled(is_paused: bool)
