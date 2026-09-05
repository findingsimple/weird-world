class_name Coin
extends Area2D
## A collectible coin. Bobs up and down, and disappears when the player touches it.

## Emitted just before the coin frees itself.
signal collected(coin: Coin)

## Score this coin is worth. [Level] sets it from the level config.
@export var value: int = 1
## How far (pixels) the sprite bobs.
@export var bob_amplitude: float = 2.0
## How fast the sprite bobs.
@export var bob_speed: float = 4.0

var _time: float = 0.0

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_time += delta
	_sprite.position.y = sin(_time * bob_speed) * bob_amplitude


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		collected.emit(self)
		queue_free()
