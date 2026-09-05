class_name Player
extends CharacterBody2D
## The player character: reads the move_* input actions and slides around the arena.

## Movement speed in pixels per second. Try changing it in the Inspector!
@export var speed: float = 120.0

## Area the player is kept inside, in the player's parent's coordinate space ([Level] sets it
## from its arena and the level config). An empty rect means no limit.
var bounds: Rect2 = Rect2()


func _physics_process(_delta: float) -> void:
	velocity = get_input_direction() * speed
	move_and_slide()
	if bounds.has_area():
		position = position.clamp(bounds.position, bounds.end)


## Direction the player wants to move, already normalised so diagonals are not faster.
static func get_input_direction() -> Vector2:
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")
