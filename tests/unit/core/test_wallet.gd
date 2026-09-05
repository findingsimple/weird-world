extends GutTest
## Unit tests for Wallet — the blob's money, which outlives any one level.

var _wallet: Wallet


func before_each() -> void:
	_wallet = Wallet.new()
	watch_signals(_wallet)


func test_starts_empty() -> void:
	assert_eq(_wallet.money, 0)


func test_can_start_with_money() -> void:
	assert_eq(Wallet.new(7).money, 7)


func test_earning_adds_and_emits_money_changed() -> void:
	_wallet.earn(3)
	assert_eq(_wallet.money, 3)
	assert_signal_emitted_with_parameters(_wallet, "money_changed", [3])


func test_earnings_add_up() -> void:
	_wallet.earn(3)
	_wallet.earn(4)
	assert_eq(_wallet.money, 7)


func test_earning_nothing_or_less_changes_nothing() -> void:
	_wallet.earn(0)
	_wallet.earn(-5)
	assert_eq(_wallet.money, 0)
	assert_signal_not_emitted(_wallet, "money_changed")


func test_a_fine_takes_money_away_and_emits() -> void:
	_wallet.earn(5)
	_wallet.pay_fine(2)
	assert_eq(_wallet.money, 3)
	assert_signal_emitted_with_parameters(_wallet, "money_changed", [3])


func test_the_blob_cannot_go_into_debt() -> void:
	_wallet.earn(1)
	_wallet.pay_fine(10)
	assert_eq(_wallet.money, 0, "a fine stops at zero (docs/gdd.md)")


func test_a_fine_of_nothing_or_less_changes_nothing() -> void:
	_wallet.earn(5)
	_wallet.pay_fine(0)
	_wallet.pay_fine(-2)
	assert_eq(_wallet.money, 5)
	assert_signal_emit_count(_wallet, "money_changed", 1, "only the earning emitted")


func test_starting_money_is_never_negative() -> void:
	assert_eq(Wallet.new(-3).money, 0)
