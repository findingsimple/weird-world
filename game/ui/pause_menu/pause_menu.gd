class_name PauseMenu
extends CanvasLayer
## Pauses the game on the `pause` action and shows a Resume button.
##
## The scene sets process_mode to Always so this node keeps receiving input while the
## rest of the tree is paused — that is what lets Esc unpause again.

## When false the pause action is ignored (for example after the round has ended).
var enabled: bool = true

@onready var _resume_button: Button = %ResumeButton


func _ready() -> void:
	visible = false
	_resume_button.pressed.connect(_on_resume_button_pressed)


func _unhandled_input(event: InputEvent) -> void:
	if enabled and event.is_action_pressed("pause"):
		set_paused(not get_tree().paused)
		get_viewport().set_input_as_handled()


## Pauses or resumes the whole scene tree and shows/hides the menu.
func set_paused(paused: bool) -> void:
	get_tree().paused = paused
	visible = paused
	if paused:
		_resume_button.grab_focus()
	GameEvents.pause_toggled.emit(paused)


func _on_resume_button_pressed() -> void:
	set_paused(false)
