extends GutTest
## Integration tests for the ghost strawberry: walking, turning, being stomped, catching the blob.
## Real physics on a real floor, like test_player.gd.

const STRAWBERRY_SCENE := preload("res://game/strawberry/strawberry.tscn")
const PLAYER_SCENE := preload("res://game/player/player.tscn")
## The floor's top edge. The strawberry's box is 12 px tall, so it stands with its centre 6 above.
const FLOOR_TOP := 120.0
const GROUND_THICKNESS := 16.0
## Bit values: layer 1 `player`, layer 3 `world`, layer 4 `enemies`.
const PLAYER_LAYER := 1
const WORLD_LAYER := 4
const ENEMIES_LAYER := 8

var _stomped: Array[Strawberry] = []
var _touched: Array[Strawberry] = []
## The blob's vertical velocity at the moment a stomp was reported.
var _blob_velocity_at_stomp: float = 0.0
var _blob: Player


func before_each() -> void:
	_stomped = []
	_touched = []
	_blob_velocity_at_stomp = 0.0
	_blob = null


## A solid piece of `world` ground: `width` wide, its top edge at FLOOR_TOP, centred on `x`.
func _make_ground(x: float, width: float) -> StaticBody2D:
	var ground := StaticBody2D.new()
	ground.collision_layer = WORLD_LAYER
	ground.collision_mask = 0
	ground.position = Vector2(x, FLOOR_TOP + GROUND_THICKNESS * 0.5)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(width, GROUND_THICKNESS)
	shape.shape = rect
	ground.add_child(shape)
	return ground


## A tall thin wall on the `world` layer, centred on `x`, 8 px wide.
func _make_wall(x: float) -> StaticBody2D:
	var wall := StaticBody2D.new()
	wall.collision_layer = WORLD_LAYER
	wall.collision_mask = 0
	wall.position = Vector2(x, FLOOR_TOP - 20.0)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(8, 60)
	shape.shape = rect
	wall.add_child(shape)
	return wall


## A strawberry standing on the ground at `x`, wired to the recording arrays.
func _make_strawberry(x: float) -> Strawberry:
	var strawberry: Strawberry = STRAWBERRY_SCENE.instantiate()
	strawberry.position = Vector2(x, FLOOR_TOP - 6.0)
	strawberry.stomped.connect(_on_stomped)
	strawberry.blob_touched.connect(_on_touched)
	add_child_autofree(strawberry)
	return strawberry


func _make_blob(at: Vector2) -> Player:
	_blob = PLAYER_SCENE.instantiate()
	_blob.position = at
	add_child_autofree(_blob)
	return _blob


func test_is_an_enemy_that_walks_on_the_world_and_only_its_hitbox_sees_the_blob() -> void:
	add_child_autofree(_make_ground(100.0, 400.0))
	var strawberry := _make_strawberry(100.0)
	assert_eq(strawberry.collision_layer, ENEMIES_LAYER, "on the enemies layer")
	assert_eq(strawberry.collision_mask, WORLD_LAYER, "bumps into the world only, never the blob")
	var hitbox: Area2D = strawberry.get_node("Hitbox")
	assert_eq(hitbox.collision_mask, PLAYER_LAYER, "the hitbox looks for the blob only")


func test_walks_left_by_default() -> void:
	add_child_autofree(_make_ground(100.0, 400.0))
	var strawberry := _make_strawberry(100.0)
	await wait_physics_frames(10)
	assert_lt(strawberry.position.x, 100.0)
	assert_eq(strawberry.get_direction(), -1)


func test_turns_around_at_a_wall_and_keeps_going() -> void:
	add_child_autofree(_make_ground(100.0, 400.0))
	add_child_autofree(_make_wall(70.0))
	var strawberry := _make_strawberry(90.0)
	# Its left edge (84) is 10 px from the wall's right edge (74): a quarter of a second.
	await wait_seconds(0.6)
	assert_eq(strawberry.get_direction(), 1, "walking right after hitting the wall")
	assert_gt(strawberry.position.x, 92.0, "made real progress away from the wall, not jittering")
	await wait_physics_frames(5)
	assert_eq(strawberry.get_direction(), 1, "and kept going")


func test_turns_around_at_a_ledge_instead_of_falling() -> void:
	# Ground from x=80 to x=120; the strawberry starts near the left edge, walking left.
	add_child_autofree(_make_ground(100.0, 40.0))
	var strawberry := _make_strawberry(95.0)
	await wait_seconds(0.6)
	assert_eq(strawberry.get_direction(), 1, "turned back")
	assert_almost_eq(strawberry.position.y, FLOOR_TOP - 6.0, 0.5, "still standing on the ground")


func test_the_blob_landing_on_top_stomps_it() -> void:
	add_child_autofree(_make_ground(100.0, 400.0))
	var strawberry := _make_strawberry(100.0)
	_make_blob(Vector2(100.0, FLOOR_TOP - 30.0))
	await wait_physics_frames(20)
	assert_eq(_stomped.size(), 1, "stomped once")
	assert_eq(_touched.size(), 0, "not touched")
	assert_false(is_instance_valid(strawberry), "squished")
	assert_lt(_blob_velocity_at_stomp, 0.0, "the blob was kicked upward at the moment of the stomp")


func test_the_blob_walking_into_the_side_is_caught() -> void:
	add_child_autofree(_make_ground(100.0, 400.0))
	var strawberry := _make_strawberry(100.0)
	_make_blob(Vector2(140.0, FLOOR_TOP - 7.0))
	var sender := GutInputSender.new(Input)
	sender.action_down("move_left")
	await wait_seconds(0.5)
	sender.release_all()
	sender.clear()
	assert_eq(_touched.size(), 1, "touched once")
	assert_eq(_stomped.size(), 0, "not stomped")
	assert_true(is_instance_valid(strawberry), "the strawberry is fine")


func _on_stomped(strawberry: Strawberry) -> void:
	_stomped.append(strawberry)
	if _blob != null:
		_blob_velocity_at_stomp = _blob.velocity.y


func _on_touched(strawberry: Strawberry) -> void:
	_touched.append(strawberry)
