extends GutTest
## Integration tests for the pause menu: visibility, tree pausing, Resume, and `enabled`.

const PAUSE_SCENE := preload("res://game/ui/pause_menu/pause_menu.tscn")

var _menu: PauseMenu
var _sender: GutInputSender


func before_each() -> void:
	_menu = PAUSE_SCENE.instantiate()
	watch_signals(GameEvents)
	add_child_autofree(_menu)
	_sender = GutInputSender.new(Input)


func after_each() -> void:
	_sender.release_all()
	_sender.clear()
	get_tree().paused = false


func test_starts_hidden_and_unpaused() -> void:
	assert_false(_menu.visible)
	assert_false(get_tree().paused)


func test_set_paused_true_shows_menu_and_pauses_tree() -> void:
	_menu.set_paused(true)
	assert_true(_menu.visible)
	assert_true(get_tree().paused)
	assert_signal_emitted_with_parameters(GameEvents, "pause_toggled", [true])


func test_set_paused_false_hides_menu_and_resumes() -> void:
	_menu.set_paused(true)
	_menu.set_paused(false)
	assert_false(_menu.visible)
	assert_false(get_tree().paused)
	assert_signal_emitted_with_parameters(GameEvents, "pause_toggled", [false])


func test_resume_button_unpauses() -> void:
	_menu.set_paused(true)
	var resume: Button = _menu.get_node("%ResumeButton")
	resume.pressed.emit()
	assert_false(get_tree().paused)
	assert_false(_menu.visible)


func test_title_button_emits_quit_pressed_and_decides_nothing_itself() -> void:
	watch_signals(_menu)
	_menu.set_paused(true)
	var title: Button = _menu.get_node("%TitleButton")
	title.pressed.emit()
	assert_signal_emitted(_menu, "quit_pressed")
	assert_true(get_tree().paused, "the owner, not the menu, decides what leaving means")


func test_pause_action_toggles_when_enabled() -> void:
	_sender.action_down("pause")
	Input.flush_buffered_events()
	assert_true(get_tree().paused)
	assert_true(_menu.visible)


func test_pause_action_ignored_when_disabled() -> void:
	_menu.enabled = false
	_sender.action_down("pause")
	Input.flush_buffered_events()
	assert_false(get_tree().paused)
	assert_false(_menu.visible)
	assert_signal_not_emitted(GameEvents, "pause_toggled")
