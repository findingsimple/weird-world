class_name TitleScreen
extends Control
## First screen the player sees. Emits [signal start_pressed]; [Main] decides what happens.

## The player pressed Play.
signal start_pressed

@onready var _play_button: Button = %PlayButton


func _ready() -> void:
	_play_button.pressed.connect(_on_play_button_pressed)
	_play_button.grab_focus()


func _on_play_button_pressed() -> void:
	start_pressed.emit()
