class_name LevelConfig
extends Resource
## Tunable settings for one round. Saved as a `.tres` file (see levels/level_01.tres) so
## designers — or a curious kid — can change the game without touching code.
##
## To make a new level: right-click levels/ in the Godot FileSystem dock >
## New Resource > LevelConfig, then set it on the Main node's "Level Config" property.

## Coins needed to win.
@export_range(1, 999) var target_score: int = 10
## Length of the round in seconds.
@export_range(1.0, 600.0, 0.5) var duration_seconds: float = 30.0
## Seconds between coin spawns.
@export_range(0.05, 10.0, 0.05) var spawn_interval: float = 0.8
## Never more than this many coins on screen at once.
@export_range(1, 100) var max_coins: int = 5
## Score gained per coin.
@export_range(1, 100) var coin_value: int = 1
## Coins never spawn (and the player cannot move) closer than this to the arena edge.
@export_range(0.0, 200.0) var arena_margin: float = 24.0
## Coins try not to spawn closer than this to the player.
@export_range(0.0, 400.0) var min_spawn_distance_from_player: float = 48.0


func is_valid() -> bool:
	return (
		target_score > 0
		and duration_seconds > 0.0
		and spawn_interval > 0.0
		and max_coins > 0
		and coin_value > 0
		and arena_margin >= 0.0
		and min_spawn_distance_from_player >= 0.0
	)
