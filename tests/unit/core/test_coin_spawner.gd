extends GutTest
## Unit tests for CoinSpawner. The RNG is seeded so every run is identical.

const ARENA := Rect2(0, 0, 640, 360)
const MARGIN := 24.0
const FAR_AWAY := Vector2(-1000, -1000)


func _make_spawner(seed_value: int) -> CoinSpawner:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return CoinSpawner.new(rng)


func test_positions_stay_inside_arena_minus_margin() -> void:
	var spawner := _make_spawner(1)
	var inner := ARENA.grow(-MARGIN)
	var outside := 0
	for _i in 200:
		if not inner.has_point(spawner.pick_position(ARENA, MARGIN, FAR_AWAY, 0.0)):
			outside += 1
	assert_eq(outside, 0, "no positions outside %s" % inner)


func test_same_seed_yields_same_sequence() -> void:
	var first := _make_spawner(42)
	var second := _make_spawner(42)
	for _i in 5:
		assert_eq(
			first.pick_position(ARENA, MARGIN, FAR_AWAY, 0.0),
			second.pick_position(ARENA, MARGIN, FAR_AWAY, 0.0)
		)


func test_avoids_point_within_min_distance() -> void:
	var spawner := _make_spawner(7)
	var avoid := ARENA.get_center()
	var too_close := 0
	for _i in 100:
		var candidate := spawner.pick_position(ARENA, MARGIN, avoid, 100.0, 50)
		if candidate.distance_to(avoid) < 100.0:
			too_close += 1
	assert_eq(too_close, 0)


func test_returns_position_when_tries_exhausted() -> void:
	var spawner := _make_spawner(3)
	var tiny := Rect2(100, 100, 10, 10)
	var candidate := spawner.pick_position(tiny, 0.0, tiny.get_center(), 1000.0, 3)
	assert_true(tiny.has_point(candidate), "still inside the arena: %s" % candidate)
