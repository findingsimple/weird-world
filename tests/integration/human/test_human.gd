extends GutTest
## Integration tests for the Human scene: overlap detection through the physics server.

const HUMAN_SCENE := preload("res://game/human/human.tscn")
const PLAYER_SCENE := preload("res://game/player/player.tscn")

var _human: Human
var _eaten: Array[Human] = []


func before_each() -> void:
	_eaten = []
	_human = HUMAN_SCENE.instantiate()
	_human.position = Vector2(50, 50)
	_human.eaten.connect(_on_human_eaten)
	add_child_autofree(_human)


func test_emits_eaten_when_the_player_overlaps() -> void:
	var player: Player = PLAYER_SCENE.instantiate()
	player.position = _human.position
	add_child_autofree(player)
	await wait_physics_frames(3)
	assert_eq(_eaten.size(), 1)


func test_is_freed_after_being_eaten() -> void:
	var player: Player = PLAYER_SCENE.instantiate()
	player.position = _human.position
	add_child_autofree(player)
	await wait_physics_frames(3)
	assert_false(is_instance_valid(_human))


func test_fidgets_the_sprite_but_never_the_hitbox() -> void:
	var start := _human.position
	await wait_process_frames(10)
	var sprite: Sprite2D = _human.get_node("Sprite2D")
	assert_ne(sprite.position.x, 0.0, "the sprite wiggles")
	assert_lte(absf(sprite.position.x), _human.fidget_amplitude, "within its stated range")
	assert_eq(_human.position, start, "the human itself stays put")
	var collider: CollisionShape2D = _human.get_node("CollisionShape2D")
	assert_eq(collider.position, Vector2.ZERO, "the hitbox stays put")


func test_ignores_non_player_bodies() -> void:
	# A CharacterBody2D on the player layer that is NOT a Player. (A StaticBody2D would be
	# a vacuous test: areas never report static bodies as overlapping here.)
	var impostor := CharacterBody2D.new()
	impostor.collision_layer = 1
	var shape := CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	impostor.add_child(shape)
	impostor.position = _human.position
	add_child_autofree(impostor)
	await wait_physics_frames(3)
	# Positive control: the physics server really does see the overlap...
	assert_true(_human.has_overlapping_bodies(), "impostor overlaps the human")
	# ...and the human's `is Player` check is what rejects it.
	assert_eq(_eaten.size(), 0)
	assert_true(is_instance_valid(_human))


func _on_human_eaten(human: Human) -> void:
	_eaten.append(human)
