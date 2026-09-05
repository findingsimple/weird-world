class_name LevelConfig
extends Resource
## Tunable numbers for one level. Saved as a `.tres` file (see levels/level_01.tres) so
## the designer — a kid with a text editor — can change the game without touching code.
##
## To make a new level: right-click levels/ in the Godot FileSystem dock >
## New Resource > LevelConfig, then set it on the Main node's "Level Config" property.
## Where the humans and platforms go is not a number: that is the level scene itself.

## Money the blob earns for eating one human.
@export_range(1, 100) var human_value: int = 1


func is_valid() -> bool:
	return human_value > 0
