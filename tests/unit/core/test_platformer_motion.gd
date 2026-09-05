extends GutTest
## Unit tests for PlatformerMotion — pure maths, no scene tree needed.
##
## Godot's y axis points DOWN: falling is positive y, jumping is negative y.

const RUN := 100.0
const JUMP := 250.0
const GRAVITY := 1000.0
const MAX_FALL := 400.0
## One step. GRAVITY * DT is a round 100 px/s, which keeps the expected numbers readable.
const DT := 0.1

var _motion: PlatformerMotion


func before_each() -> void:
	_motion = PlatformerMotion.new(RUN, JUMP, GRAVITY, MAX_FALL)


func test_stands_still_on_the_floor_without_input() -> void:
	var v := _motion.next_velocity(Vector2.ZERO, 0.0, false, true, DT)
	assert_eq(v, Vector2.ZERO)


func test_runs_right_at_run_speed() -> void:
	var v := _motion.next_velocity(Vector2.ZERO, 1.0, false, true, DT)
	assert_eq(v.x, RUN)


func test_runs_left_at_run_speed() -> void:
	var v := _motion.next_velocity(Vector2.ZERO, -1.0, false, true, DT)
	assert_eq(v.x, -RUN)


func test_input_beyond_one_is_clamped() -> void:
	var v := _motion.next_velocity(Vector2.ZERO, 5.0, false, true, DT)
	assert_eq(v.x, RUN)


func test_falls_faster_each_step_in_the_air() -> void:
	var v1 := _motion.next_velocity(Vector2.ZERO, 0.0, false, false, DT)
	var v2 := _motion.next_velocity(v1, 0.0, false, false, DT)
	assert_almost_eq(v1.y, GRAVITY * DT, 0.0001)
	assert_almost_eq(v2.y, 2.0 * GRAVITY * DT, 0.0001)


func test_fall_speed_settles_at_the_cap() -> void:
	# 4 steps of 100 px/s reach the cap; every later step must hold it there.
	var v := Vector2.ZERO
	for _step in 30:
		v = _motion.next_velocity(v, 0.0, false, false, DT)
		assert_lte(v.y, MAX_FALL)
	assert_eq(v.y, MAX_FALL)


func test_falling_faster_than_the_cap_is_pulled_back_to_it() -> void:
	var v := _motion.next_velocity(Vector2(0.0, 900.0), 0.0, false, false, DT)
	assert_eq(v.y, MAX_FALL)


func test_jump_from_the_floor_sets_upward_velocity() -> void:
	var v := _motion.next_velocity(Vector2.ZERO, 0.0, true, true, DT)
	assert_eq(v.y, -JUMP)


func test_jump_in_the_air_is_ignored() -> void:
	var falling := Vector2(0.0, 50.0)
	var v := _motion.next_velocity(falling, 0.0, true, false, DT)
	assert_almost_eq(v.y, falling.y + GRAVITY * DT, 0.0001, "no double jump: gravity still wins")


func test_landing_zeroes_vertical_velocity() -> void:
	var v := _motion.next_velocity(Vector2(0.0, 300.0), 0.0, false, true, DT)
	assert_eq(v.y, 0.0)


func test_an_upward_kick_while_on_the_floor_is_kept() -> void:
	# A stomp bounce sets an upward velocity while the body still counts as on the floor.
	var kicked := Vector2(0.0, -150.0)
	var v := _motion.next_velocity(kicked, 0.0, false, true, DT)
	assert_eq(v.y, -150.0, "the kick survives the frame instead of being zeroed")


func test_running_does_not_change_falling() -> void:
	var v := _motion.next_velocity(Vector2.ZERO, 1.0, false, false, DT)
	assert_eq(v.x, RUN)
	assert_almost_eq(v.y, GRAVITY * DT, 0.0001)


func test_configure_replaces_the_tunables() -> void:
	_motion.configure(RUN * 2.0, JUMP * 2.0, GRAVITY * 2.0, MAX_FALL * 2.0)
	assert_eq(_motion.run_speed, RUN * 2.0)
	assert_eq(_motion.jump_velocity, JUMP * 2.0)
	assert_eq(_motion.gravity, GRAVITY * 2.0)
	assert_eq(_motion.max_fall_speed, MAX_FALL * 2.0)


func test_nonsense_values_are_clamped() -> void:
	# No running and no jumping are legitimate designs; no gravity or no falling are not —
	# the blob would hang in the air forever — so those two get a small positive floor.
	var motion := PlatformerMotion.new(-1.0, -1.0, 0.0, -5.0)
	assert_eq(motion.run_speed, 0.0)
	assert_eq(motion.jump_velocity, 0.0)
	assert_eq(motion.gravity, PlatformerMotion.MIN_FALL_RATE)
	assert_eq(motion.max_fall_speed, PlatformerMotion.MIN_FALL_RATE)
