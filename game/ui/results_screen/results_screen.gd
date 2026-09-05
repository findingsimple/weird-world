class_name ResultsScreen
extends Control
## Shown when a level ends. Emits what the player chose; [Main] does the navigation.

## The player wants to play the level again.
signal retry_pressed
## The player wants to go back to the title screen.
signal title_pressed

@onready var _heading: Label = %Heading
@onready var _money_label: Label = %MoneyLabel
@onready var _retry_button: Button = %RetryButton
@onready var _title_button: Button = %TitleButton


func _ready() -> void:
	_retry_button.pressed.connect(_on_retry_button_pressed)
	_title_button.pressed.connect(_on_title_button_pressed)
	_retry_button.grab_focus()


## Fills in the heading and the blob's total money. Call after the screen is in the tree.
## LOST means the player left the level early (the pause menu); there is no other way to lose.
func show_result(outcome: GameRules.Outcome, money: int) -> void:
	_heading.text = (
		"You ate everyone!" if outcome == GameRules.Outcome.WON else "You clocked off early!"
	)
	_money_label.text = "Money: $%d" % money


func _on_retry_button_pressed() -> void:
	retry_pressed.emit()


func _on_title_button_pressed() -> void:
	title_pressed.emit()
