extends GutTest
## Integration tests for the Coin scene: overlap detection through the physics server.

const COIN_SCENE := preload("res://game/coin/coin.tscn")
const PLAYER_SCENE := preload("res://game/player/player.tscn")

var _coin: Coin
var _collected: Array[Coin] = []


func before_each() -> void:
	_collected = []
	_coin = COIN_SCENE.instantiate()
	_coin.position = Vector2(50, 50)
	_coin.collected.connect(_on_coin_collected)
	add_child_autofree(_coin)


func test_emits_collected_when_player_overlaps() -> void:
	var player: Player = PLAYER_SCENE.instantiate()
	player.position = _coin.position
	add_child_autofree(player)
	await wait_physics_frames(3)
	assert_eq(_collected.size(), 1)


func test_is_freed_after_collection() -> void:
	var player: Player = PLAYER_SCENE.instantiate()
	player.position = _coin.position
	add_child_autofree(player)
	await wait_physics_frames(3)
	assert_false(is_instance_valid(_coin))


func test_ignores_non_player_bodies() -> void:
	# A CharacterBody2D on the player layer that is NOT a Player. (A StaticBody2D would be
	# a vacuous test: areas never report static bodies as overlapping here.)
	var impostor := CharacterBody2D.new()
	impostor.collision_layer = 1
	var shape := CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	impostor.add_child(shape)
	impostor.position = _coin.position
	add_child_autofree(impostor)
	await wait_physics_frames(3)
	# Positive control: the physics server really does see the overlap...
	assert_true(_coin.has_overlapping_bodies(), "impostor overlaps the coin")
	# ...and the coin's `is Player` check is what rejects it.
	assert_eq(_collected.size(), 0)
	assert_true(is_instance_valid(_coin))


func _on_coin_collected(coin: Coin) -> void:
	_collected.append(coin)
