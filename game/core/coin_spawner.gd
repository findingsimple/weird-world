class_name CoinSpawner
extends RefCounted
## Picks spawn positions for coins. Pure logic: the random generator is injected so tests
## can seed it and get repeatable results.

var _rng: RandomNumberGenerator


func _init(rng: RandomNumberGenerator) -> void:
	_rng = rng


## Returns a random point inside `arena` shrunk by `margin`, trying up to `max_tries`
## times to stay at least `min_distance` away from `avoid` (normally the player).
## If every try is too close, the last candidate is returned anyway — a coin near the
## player is better than no coin.
func pick_position(
	arena: Rect2, margin: float, avoid: Vector2, min_distance: float, max_tries: int = 10
) -> Vector2:
	var inner := arena.grow(-margin).abs()
	var candidate := Vector2.ZERO
	for _try in maxi(max_tries, 1):
		candidate = Vector2(
			_rng.randf_range(inner.position.x, inner.end.x),
			_rng.randf_range(inner.position.y, inner.end.y)
		)
		if candidate.distance_to(avoid) >= min_distance:
			return candidate
	return candidate
