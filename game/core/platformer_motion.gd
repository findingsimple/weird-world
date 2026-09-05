class_name PlatformerMotion
extends RefCounted
## The maths of a platformer body: running, falling and jumping.
##
## Deliberately knows nothing about nodes or input, so it can be unit-tested in
## isolation (see tests/unit/core/test_platformer_motion.gd). [Player] owns one, asks it
## for the next velocity every physics frame, then lets move_and_slide() do the moving.
##
## Godot's y axis points DOWN: falling is positive y, a jump is negative y.

## Gravity and the fall cap never go below this: at 0 the blob would hang in the air forever.
const MIN_FALL_RATE: float = 1.0

## Horizontal speed in pixels per second while running.
var run_speed: float
## Upward speed in pixels per second at the moment of a jump.
var jump_velocity: float
## How much faster falling gets every second, in pixels per second squared.
var gravity: float
## Falling never gets faster than this (pixels per second), so long drops stay controllable.
var max_fall_speed: float


func _init(speed: float, jump: float, fall_acceleration: float, max_fall: float) -> void:
	configure(speed, jump, fall_acceleration, max_fall)


## Sets the tunables, clamping values that would make no sense. Cheap enough to call every
## frame — that is how [Player] keeps its Inspector values live while the game is running.
func configure(speed: float, jump: float, fall_acceleration: float, max_fall: float) -> void:
	run_speed = maxf(speed, 0.0)
	jump_velocity = maxf(jump, 0.0)
	gravity = maxf(fall_acceleration, MIN_FALL_RATE)
	max_fall_speed = maxf(max_fall, MIN_FALL_RATE)


## The velocity for the next physics step.
##
## `input_x` runs from -1 (left) to 1 (right); `jump_pressed` is true only on the frame
## the jump action was pressed; `on_floor` comes from CharacterBody2D.is_on_floor().
##
## On the floor, downward speed is cancelled rather than letting gravity pile up against the
## ground, so landings are exact; an upward kick given from outside (a stomp bounce) is kept,
## so the body leaves the floor next frame. A jump is only possible from the floor (no double
## jumps). This assumes flat ground; slopes would want gravity applied every frame.
func next_velocity(
	velocity: Vector2, input_x: float, jump_pressed: bool, on_floor: bool, delta: float
) -> Vector2:
	var next := velocity
	next.x = clampf(input_x, -1.0, 1.0) * run_speed
	if on_floor:
		next.y = -jump_velocity if jump_pressed else minf(velocity.y, 0.0)
	else:
		next.y = minf(velocity.y + gravity * delta, max_fall_speed)
	return next
