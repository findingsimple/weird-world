class_name PopText
extends Node2D
## A little "+$2" (or "-$2") that floats up and fades out where something happened, so a
## young player sees cause and effect at the spot, not just a number changing in a corner.
## Frees itself when the animation ends.

## How far (pixels) the text rises.
@export_range(0.0, 64.0, 1.0) var rise: float = 12.0
## How long (seconds) it stays on screen.
@export_range(0.1, 5.0, 0.1) var duration: float = 0.6

@onready var _label: Label = $Label


## Sets the text and starts floating. Call after the node is in the tree.
func show_text(text: String) -> void:
	_label.text = text
	var tween := create_tween()
	tween.tween_property(self, "position:y", position.y - rise, duration)
	tween.parallel().tween_property(self, "modulate:a", 0.0, duration)
	tween.tween_callback(queue_free)
