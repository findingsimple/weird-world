class_name Player
extends CharacterBody2D
## The blob: runs left and right, falls, and jumps when it is standing on something.
##
## The maths lives in [PlatformerMotion] so it can be unit-tested. This node only reads
## input, asks for the next velocity and lets move_and_slide() handle the collisions with
## whatever is on the `world` physics layer. The tunables below are handed to the motion
## every frame, so changing them in the Inspector works even while the game is running.

## Running speed in pixels per second. Try changing it in the Inspector!
@export_range(0.0, 600.0, 1.0) var speed: float = 120.0
## How hard the blob jumps, in pixels per second. Bigger number, higher jump.
@export_range(0.0, 1000.0, 1.0) var jump_velocity: float = 330.0
## How much faster falling gets every second. Try 200 for a blob on the moon.
@export_range(1.0, 3000.0, 1.0) var gravity: float = 980.0
## Falling never gets faster than this, so big drops stay controllable.
@export_range(1.0, 2000.0, 1.0) var max_fall_speed: float = 400.0

var _motion: PlatformerMotion


func _ready() -> void:
	_motion = PlatformerMotion.new(speed, jump_velocity, gravity, max_fall_speed)


func _physics_process(delta: float) -> void:
	_motion.configure(speed, jump_velocity, gravity, max_fall_speed)
	var input_x := Input.get_axis("move_left", "move_right")
	var jump_pressed := Input.is_action_just_pressed("jump")
	velocity = _motion.next_velocity(velocity, input_x, jump_pressed, is_on_floor(), delta)
	move_and_slide()
