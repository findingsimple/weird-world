class_name Wallet
extends RefCounted
## The blob's money. Owned by [Main], not by a level, so it survives a level restart — a
## ghost strawberry's fine has to come out of something (docs/gdd.md).
##
## Pure logic, unit-tested in tests/unit/core/test_wallet.gd. [GameRules] pays into it;
## [Level] forwards its signal to the [GameEventsBus] for the HUD.

## Emitted whenever the amount actually changes.
signal money_changed(money: int)

var money: int = 0


func _init(starting_money: int = 0) -> void:
	money = maxi(starting_money, 0)


## Pays the blob. Nothing or less is ignored.
func earn(amount: int) -> void:
	if amount <= 0:
		return
	money += amount
	money_changed.emit(money)


## Takes money away — never below zero. The blob cannot go into debt (a designer decision;
## see docs/gdd.md → Open questions if that ever changes).
func pay_fine(amount: int) -> void:
	if amount <= 0:
		return
	_change_to(maxi(money - amount, 0))


## Puts the money back to `amount` — how a level restart forfeits what that attempt earned
## (see [Level]). Never below zero.
func reset_to(amount: int) -> void:
	_change_to(maxi(amount, 0))


## Sets the amount and tells listeners — but only if it really changed. (Not named `_set`:
## that is a Godot built-in for property access.)
func _change_to(new_money: int) -> void:
	if new_money == money:
		return
	money = new_money
	money_changed.emit(money)
