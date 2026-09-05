class_name Patrol
extends RefCounted
## Which way a ghost strawberry walks, and when it turns around: at a wall, or at a ledge.
##
## Pure logic, unit-tested in tests/unit/core/test_patrol.gd. [Strawberry] owns one, tells
## it what its senses report every physics frame, and reads [member direction].

## -1 walks left, 1 walks right. Never 0.
var direction: int = -1


func _init(start_direction: int = -1) -> void:
	direction = 1 if start_direction > 0 else -1


## Call once per physics frame with what the body senses: is it pushing against a wall,
## and is there ground just ahead of its feet? Turns around when either says "stop".
func step(on_wall: bool, ground_ahead: bool) -> void:
	if on_wall or not ground_ahead:
		direction = -direction
