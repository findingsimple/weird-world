extends GutTest
## Unit tests for EnemyContact — did the blob stomp the enemy, or just walk into it?
##
## Godot's y axis points DOWN. The enemy's top edge is at ENEMY_TOP; a blob whose feet were
## above that line a frame ago, and is falling, has landed on it.

const ENEMY_TOP := 100.0
## One physics frame at the project's pinned 60 ticks per second.
const DT := 1.0 / 60.0


func test_falling_onto_the_top_is_a_stomp() -> void:
	assert_true(EnemyContact.is_stomp(ENEMY_TOP - 3.0, 120.0, ENEMY_TOP, DT))


func test_the_contact_the_physics_server_reported_late_is_a_stomp() -> void:
	# Measured on 2026-09-05: feet 4.05 px below the top at 163 px/s — reported a frame late.
	assert_true(EnemyContact.is_stomp(ENEMY_TOP + 4.05, 163.0, ENEMY_TOP, DT))


func test_a_fast_fall_reported_late_is_still_a_stomp() -> void:
	# At the fall cap the blob covers ~6.7 px per frame; a frame's lag is not the blob's fault.
	assert_true(EnemyContact.is_stomp(ENEMY_TOP + 10.0, 400.0, ENEMY_TOP, DT))


func test_walking_into_the_side_is_a_touch() -> void:
	# Standing beside it on the same floor: feet 12 px below its top, no vertical speed.
	assert_false(EnemyContact.is_stomp(ENEMY_TOP + 12.0, 0.0, ENEMY_TOP, DT))


func test_sunk_too_deep_for_the_speed_is_a_touch() -> void:
	# 12 px in at 120 px/s (2 px per frame) cannot have come from above this frame.
	assert_false(EnemyContact.is_stomp(ENEMY_TOP + 12.0, 120.0, ENEMY_TOP, DT))


func test_the_side_at_the_fall_cap_is_still_a_touch() -> void:
	# The invariant that keeps side contacts honest: one frame at max_fall_speed (400 / 60 ≈ 6.7
	# px) plus the tolerance must stay under the strawberry's 12 px height. 6.7 + 4 < 12.
	assert_false(EnemyContact.is_stomp(ENEMY_TOP + 12.0, 400.0, ENEMY_TOP, DT))


func test_the_tolerance_boundary_is_exact() -> void:
	# A barely-moving blob: the rewind is ~0, so the tolerance alone decides.
	var creeping := 0.001
	assert_true(
		EnemyContact.is_stomp(ENEMY_TOP + EnemyContact.STOMP_TOLERANCE, creeping, ENEMY_TOP, DT)
	)
	assert_false(
		EnemyContact.is_stomp(
			ENEMY_TOP + EnemyContact.STOMP_TOLERANCE + 0.01, creeping, ENEMY_TOP, DT
		)
	)


func test_rising_past_it_is_a_touch_not_a_stomp() -> void:
	assert_false(EnemyContact.is_stomp(ENEMY_TOP - 3.0, -200.0, ENEMY_TOP, DT))


func test_standing_still_above_it_is_not_a_stomp() -> void:
	assert_false(EnemyContact.is_stomp(ENEMY_TOP - 3.0, 0.0, ENEMY_TOP, DT))
