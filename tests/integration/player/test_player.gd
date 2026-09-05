extends GutTest
## Integration tests for the Player scene: real input actions, real physics, a real floor.

const PLAYER_SCENE := preload("res://game/player/player.tscn")
## The player starts in the air, a little above the floor, and falls onto it.
const START := Vector2(100, 100)
## The floor's top edge. Standing on it puts the player's centre half its box above this line.
const FLOOR_TOP := 120.0
const GROUND_THICKNESS := 16.0
## Bit value of physics layer 3, `world` (see project.godot > [layer_names]).
const WORLD_LAYER := 4
## One physics frame at the project's pinned 60 ticks per second.
const PHYSICS_DT := 1.0 / 60.0

var _player: Player
var _sender: GutInputSender


func before_each() -> void:
	add_child_autofree(_make_ground())
	_player = PLAYER_SCENE.instantiate()
	_player.position = START
	add_child_autofree(_player)
	_sender = GutInputSender.new(Input)


func after_each() -> void:
	_sender.release_all()
	_sender.clear()


## A wide, solid floor on the `world` layer with its top edge at FLOOR_TOP.
func _make_ground() -> StaticBody2D:
	var ground := StaticBody2D.new()
	ground.collision_layer = WORLD_LAYER
	ground.collision_mask = 0
	ground.position = Vector2(START.x, FLOOR_TOP + GROUND_THICKNESS * 0.5)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(400, GROUND_THICKNESS)
	shape.shape = rect
	ground.add_child(shape)
	return ground


## Half the height of the player's collision box, read from the scene so the tests follow it.
func _half_height() -> float:
	var collider: CollisionShape2D = _player.get_node("CollisionShape2D")
	var box := collider.shape as RectangleShape2D
	return box.size.y * 0.5


## Waits until the player has fallen from START onto the floor.
func _land() -> void:
	await wait_physics_frames(30)
	assert_true(_player.is_on_floor(), "player should have landed by now")


func test_falls_and_lands_on_the_floor() -> void:
	await wait_physics_frames(2)
	assert_gt(_player.position.y, START.y, "gravity pulls the player down")
	await _land()
	assert_almost_eq(_player.position.y, FLOOR_TOP - _half_height(), 0.5)


func test_stays_still_on_the_floor_without_input() -> void:
	await _land()
	var resting := _player.position
	await wait_physics_frames(5)
	assert_eq(_player.position.x, resting.x)
	assert_almost_eq(_player.position.y, resting.y, 0.01)


func test_runs_right_while_move_right_held() -> void:
	await _land()
	var resting := _player.position
	_sender.action_down("move_right")
	await wait_physics_frames(10)
	assert_gt(_player.position.x, resting.x)
	assert_almost_eq(_player.position.y, resting.y, 0.01, "running does not leave the floor")


func test_run_speed_is_speed() -> void:
	await _land()
	_sender.action_down("move_right")
	await wait_physics_frames(3)
	assert_almost_eq(_player.velocity.x, _player.speed, 0.001)


func test_jumps_when_jump_pressed_on_the_floor() -> void:
	await _land()
	var resting := _player.position
	_sender.action_down("jump")
	await wait_physics_frames(3)
	assert_lt(_player.position.y, resting.y, "the player went up")
	assert_false(_player.is_on_floor())


func test_cannot_jump_again_in_the_air() -> void:
	await _land()
	_sender.action_down("jump")
	await wait_physics_frames(3)
	_sender.action_up("jump")
	await wait_physics_frames(1)
	var rising := _player.velocity.y
	_sender.action_down("jump")
	await wait_physics_frames(1)
	# Gravity keeps slowing the rise; a second jump would have reset it to -jump_velocity.
	assert_gt(_player.velocity.y, rising, "no double jump")


func test_tunables_drive_the_motion_even_after_ready() -> void:
	# Values far from the defaults, so a swapped or ignored export shows up as a wrong number.
	# Set after the player is in the tree: Inspector edits while playing must work too.
	_player.speed = 200.0
	_player.jump_velocity = 500.0
	_player.gravity = 400.0
	await _land()
	_sender.action_down("move_right")
	await wait_physics_frames(2)
	assert_almost_eq(_player.velocity.x, 200.0, 0.001, "speed")
	_sender.action_down("jump")
	await wait_physics_frames(2)
	var rising := _player.velocity.y
	assert_lt(rising, -480.0, "jump_velocity — the default 330 could never get here")
	# wait_physics_frames(n) is not exactly n Player steps (the awaiter and the player run
	# in different slots of a physics step), so count the steps that really happened.
	var frames_before := Engine.get_physics_frames()
	await wait_physics_frames(3)
	var frames := Engine.get_physics_frames() - frames_before
	var per_frame := (_player.velocity.y - rising) / frames
	assert_almost_eq(per_frame, 400.0 * PHYSICS_DT, 0.05, "gravity per frame")
