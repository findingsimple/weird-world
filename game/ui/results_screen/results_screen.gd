class_name ResultsScreen
extends Control
## Shown when a round ends. Emits what the player chose; [Main] does the navigation.

## The player wants another round.
signal retry_pressed
## The player wants to go back to the title screen.
signal title_pressed

@onready var _heading: Label = %Heading
@onready var _score_label: Label = %ScoreLabel
@onready var _retry_button: Button = %RetryButton
@onready var _title_button: Button = %TitleButton


func _ready() -> void:
	_retry_button.pressed.connect(_on_retry_button_pressed)
	_title_button.pressed.connect(_on_title_button_pressed)
	_retry_button.grab_focus()


## Fills in the heading and score. Call after the screen is in the tree.
func show_result(outcome: GameRules.Outcome, score: int) -> void:
	_heading.text = "You win!" if outcome == GameRules.Outcome.WON else "Time's up!"
	_score_label.text = "Coins collected: %d" % score


func _on_retry_button_pressed() -> void:
	retry_pressed.emit()


func _on_title_button_pressed() -> void:
	title_pressed.emit()
