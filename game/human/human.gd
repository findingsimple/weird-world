class_name Human
extends Area2D
## A human: the blob's paycheck. Fidgets nervously, and gets eaten when the blob touches it.

## Emitted just before the human frees itself.
signal eaten(human: Human)

## Money this human is worth. [Level] sets every human to the level config's `human_value`
## when the level starts, so a value typed here is overwritten — humans that pay differently
## (a chef?) are a future feature and start with a change in [Level].
@export var value: int = 1
## How far (pixels) the sprite fidgets from side to side.
@export var fidget_amplitude: float = 1.0
## How fast the sprite fidgets.
@export var fidget_speed: float = 6.0

var _time: float = 0.0

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_time += delta
	_sprite.position.x = sin(_time * fidget_speed) * fidget_amplitude


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		eaten.emit(self)
		queue_free()
