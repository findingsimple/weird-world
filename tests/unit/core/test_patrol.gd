extends GutTest
## Unit tests for Patrol — which way a ghost strawberry walks, and when it turns around.

var _patrol: Patrol


func before_each() -> void:
	_patrol = Patrol.new()


func test_starts_walking_left() -> void:
	assert_eq(_patrol.direction, -1)


func test_can_start_walking_right() -> void:
	assert_eq(Patrol.new(1).direction, 1)


func test_keeps_going_with_ground_ahead_and_no_wall() -> void:
	_patrol.step(false, true)
	assert_eq(_patrol.direction, -1)


func test_turns_at_a_wall() -> void:
	_patrol.step(true, true)
	assert_eq(_patrol.direction, 1)


func test_turns_at_a_ledge() -> void:
	_patrol.step(false, false)
	assert_eq(_patrol.direction, 1)


func test_turns_back_again_at_the_next_wall() -> void:
	_patrol.step(true, true)
	_patrol.step(true, true)
	assert_eq(_patrol.direction, -1)


func test_with_no_ground_on_either_side_it_flips_every_step() -> void:
	# Why a strawberry needs ~16 px of ground each side: on a sliver it would jitter in place.
	_patrol.step(false, false)
	_patrol.step(false, false)
	assert_eq(_patrol.direction, -1, "back where it started after two flips")


func test_a_nonsense_starting_direction_becomes_left() -> void:
	assert_eq(Patrol.new(0).direction, -1)
	assert_eq(Patrol.new(7).direction, 1, "any positive number means right")
