class_name Main
extends Node
## Entry point (project.godot > run/main_scene). Owns the flow between screens:
## title -> level -> results -> (level | title). Exactly one screen lives under $Screen.

const TITLE_SCENE := preload("res://game/ui/title_screen/title_screen.tscn")
const LEVEL_SCENE := preload("res://game/level/level.tscn")
const RESULTS_SCENE := preload("res://game/ui/results_screen/results_screen.tscn")

## Settings for the round. Swap the resource here to play a different level.
@export var level_config: LevelConfig

@onready var _screen: Node = $Screen


func _ready() -> void:
	GameEvents.game_over.connect(_on_game_over)
	_show_title()


func _show_title() -> void:
	var title: TitleScreen = TITLE_SCENE.instantiate()
	title.start_pressed.connect(_start_game)
	_replace_screen(title)


func _start_game() -> void:
	var level: Level = LEVEL_SCENE.instantiate()
	level.config = level_config
	_replace_screen(level)


func _show_results(outcome: GameRules.Outcome, score: int) -> void:
	var results: ResultsScreen = RESULTS_SCENE.instantiate()
	results.retry_pressed.connect(_start_game)
	results.title_pressed.connect(_show_title)
	_replace_screen(results)
	results.show_result(outcome, score)


## Frees whatever is showing and adds `screen`. Always un-pauses: no screen should start
## frozen because the previous one was paused.
func _replace_screen(screen: Node) -> void:
	get_tree().paused = false
	for child in _screen.get_children():
		child.queue_free()
	_screen.add_child(screen)


func _on_game_over(outcome: GameRules.Outcome, score: int) -> void:
	# Deferred: game_over can arrive mid-physics-callback, and swapping scenes there is unsafe.
	_show_results.call_deferred(outcome, score)
