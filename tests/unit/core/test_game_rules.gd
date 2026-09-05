extends GutTest
## Unit tests for GameRules — pure logic, no scene tree needed.
##
## A level has some humans in it. Eating one pays money; eating the last one wins.

const HUMANS := 3
const VALUE := 2

var _rules: GameRules


func before_each() -> void:
	_rules = GameRules.new(HUMANS)
	watch_signals(_rules)


func test_starts_broke_with_every_human_still_around() -> void:
	assert_eq(_rules.money, 0)
	assert_eq(_rules.humans_total, HUMANS)
	assert_eq(_rules.humans_left, HUMANS)
	assert_eq(_rules.outcome, GameRules.Outcome.IN_PROGRESS)
	assert_false(_rules.is_finished())


func test_eating_a_human_pays_and_emits_money_changed() -> void:
	_rules.eat_human(VALUE)
	assert_eq(_rules.money, VALUE)
	assert_signal_emitted_with_parameters(_rules, "money_changed", [VALUE])


func test_eating_a_human_counts_down_and_emits_humans_changed() -> void:
	_rules.eat_human(VALUE)
	assert_eq(_rules.humans_left, HUMANS - 1)
	assert_signal_emitted_with_parameters(_rules, "humans_changed", [HUMANS - 1, HUMANS])


func test_money_adds_up() -> void:
	_rules.eat_human(VALUE)
	_rules.eat_human(5)
	assert_eq(_rules.money, VALUE + 5)


func test_eating_the_last_human_wins_and_emits_finished_once() -> void:
	for _i in HUMANS:
		_rules.eat_human(VALUE)
	assert_eq(_rules.outcome, GameRules.Outcome.WON)
	assert_true(_rules.is_finished())
	assert_signal_emitted_with_parameters(_rules, "finished", [GameRules.Outcome.WON])
	assert_signal_emit_count(_rules, "finished", 1)


func test_not_won_while_a_human_is_left() -> void:
	for _i in HUMANS - 1:
		_rules.eat_human(VALUE)
	assert_eq(_rules.outcome, GameRules.Outcome.IN_PROGRESS)
	assert_signal_not_emitted(_rules, "finished")


func test_eating_after_the_level_is_won_changes_nothing() -> void:
	for _i in HUMANS:
		_rules.eat_human(VALUE)
	_rules.eat_human(VALUE)
	assert_eq(_rules.money, HUMANS * VALUE)
	assert_eq(_rules.humans_left, 0)
	assert_signal_emit_count(_rules, "finished", 1)


func test_a_human_is_never_worth_negative_money() -> void:
	_rules.eat_human(-10)
	assert_eq(_rules.money, 0)
	assert_eq(_rules.humans_left, HUMANS - 1, "it still counts as eaten")


func test_a_level_with_no_humans_is_finished_before_it_starts() -> void:
	var rules := GameRules.new(0)
	assert_eq(rules.humans_total, 0)
	assert_eq(rules.humans_left, 0)
	assert_eq(rules.outcome, GameRules.Outcome.WON)
	assert_true(rules.is_finished())


func test_a_negative_human_count_means_none() -> void:
	var rules := GameRules.new(-3)
	assert_eq(rules.humans_total, 0)
	assert_true(rules.is_finished())
