class_name LevelConfig
extends Resource
## Tunable numbers for one level. Saved as a `.tres` file (see levels/level_01.tres) so
## the designer — a kid with a text editor — can change the game without touching code.
##
## To make a new level: right-click levels/ in the Godot FileSystem dock >
## New Resource > LevelConfig, then set it on the Main node's "Level Config" property.
## Where the humans, platforms and strawberries go is not a number: that is the level scene.

## Money the blob earns for eating one human.
@export_range(1, 100) var human_value: int = 1
## Money the blob earns for squishing a ghost strawberry from above.
@export_range(0, 100) var stomp_value: int = 2
## Money the blob pays for walking into a ghost strawberry. The level restarts too.
@export_range(0, 100) var strawberry_fine: int = 2


func is_valid() -> bool:
	return human_value > 0 and stomp_value >= 0 and strawberry_fine >= 0
