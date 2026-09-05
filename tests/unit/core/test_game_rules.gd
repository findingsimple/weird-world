extends GutTest
## Unit tests for GameRules — pure logic, no scene tree needed.

const TARGET := 3
const DURATION := 5.0

var _rules: GameRules


func before_each() -> void:
	_rules = GameRules.new(TARGET, DURATION)
	watch_signals(_rules)


func test_starts_with_zero_score_full_time_in_progress() -> void:
	assert_eq(_rules.score, 0)
	assert_eq(_rules.target_score, TARGET)
	assert_eq(_rules.time_remaining, DURATION)
	assert_eq(_rules.outcome, GameRules.Outcome.IN_PROGRESS)
	assert_false(_rules.is_finished())


func test_add_score_increments_and_emits_score_changed() -> void:
	_rules.add_score()
	assert_eq(_rules.score, 1)
	assert_signal_emitted_with_parameters(_rules, "score_changed", [1])


func test_add_score_accepts_custom_amount() -> void:
	_rules.add_score(2)
	assert_eq(_rules.score, 2)


func test_reaching_target_sets_won_and_emits_finished() -> void:
	_rules.add_score(TARGET)
	assert_eq(_rules.outcome, GameRules.Outcome.WON)
	assert_true(_rules.is_finished())
	assert_signal_emitted_with_parameters(_rules, "finished", [GameRules.Outcome.WON])


func test_add_score_ignored_after_finished() -> void:
	_rules.add_score(TARGET)
	_rules.add_score()
	assert_eq(_rules.score, TARGET)
	assert_signal_emit_count(_rules, "finished", 1)


func test_tick_reduces_time_and_clamps_at_zero() -> void:
	_rules.tick(1.5)
	assert_almost_eq(_rules.time_remaining, 3.5, 0.0001)
	_rules.tick(100.0)
	assert_eq(_rules.time_remaining, 0.0)


func test_time_changed_emitted_once_per_second_boundary() -> void:
	_rules.tick(0.25)
	_rules.tick(0.25)
	# 4.5 s left still rounds up to 5 — no change yet.
	assert_signal_not_emitted(_rules, "time_changed")
	_rules.tick(0.5)
	# Exactly 4.0 s left: the whole-second value changed once.
	assert_signal_emit_count(_rules, "time_changed", 1)
	assert_signal_emitted_with_parameters(_rules, "time_changed", [4])


func test_time_out_sets_lost_and_emits_finished() -> void:
	_rules.tick(DURATION)
	assert_eq(_rules.outcome, GameRules.Outcome.LOST)
	assert_signal_emitted_with_parameters(_rules, "finished", [GameRules.Outcome.LOST])


func test_tick_after_win_does_not_change_outcome() -> void:
	_rules.add_score(TARGET)
	_rules.tick(DURATION * 2)
	assert_eq(_rules.outcome, GameRules.Outcome.WON)
	assert_eq(_rules.time_remaining, DURATION)


func test_seconds_left_rounds_up() -> void:
	_rules.tick(0.1)
	assert_eq(_rules.seconds_left(), 5)
	_rules.tick(4.8)
	assert_eq(_rules.seconds_left(), 1)


func test_init_clamps_invalid_target_and_duration() -> void:
	var rules := GameRules.new(0, -1.0)
	assert_eq(rules.target_score, 1)
	assert_eq(rules.time_remaining, GameRules.MIN_DURATION_SECONDS)
