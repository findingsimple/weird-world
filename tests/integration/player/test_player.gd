extends GutTest
## Integration tests for the Player scene: real input actions, real physics frames.

const PLAYER_SCENE := preload("res://game/player/player.tscn")
const START := Vector2(100, 100)

var _player: Player
var _sender: GutInputSender


func before_each() -> void:
	_player = PLAYER_SCENE.instantiate()
	_player.position = START
	add_child_autofree(_player)
	_sender = GutInputSender.new(Input)


func after_each() -> void:
	_sender.release_all()
	_sender.clear()


func test_moves_right_while_move_right_held() -> void:
	_sender.action_down("move_right")
	await wait_physics_frames(10)
	assert_gt(_player.position.x, START.x)
	assert_almost_eq(_player.position.y, START.y, 0.001)


func test_stays_still_without_input() -> void:
	await wait_physics_frames(5)
	assert_eq(_player.position, START)


func test_diagonal_is_not_faster_than_speed() -> void:
	_sender.action_down("move_right")
	_sender.action_down("move_down")
	await wait_physics_frames(3)
	assert_gt(_player.velocity.length(), 0.0)
	assert_lte(_player.velocity.length(), _player.speed + 0.001)


func test_clamped_to_bounds() -> void:
	_player.bounds = Rect2(90, 90, 20, 20)
	_sender.action_down("move_right")
	await wait_physics_frames(30)
	assert_almost_eq(_player.position.x, 110.0, 0.001)
