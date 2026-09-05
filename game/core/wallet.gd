class_name Wallet
extends RefCounted
## The blob's money. Owned by [Main], not by a level, so it survives a level restart — a
## ghost strawberry's fine has to come out of something (docs/gdd.md).
##
## Pure logic, unit-tested in tests/unit/core/test_wallet.gd. [GameRules] pays into it;
## [Level] forwards its signal to the [GameEventsBus] for the HUD.

## Emitted whenever the amount changes.
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
	money = maxi(money - amount, 0)
	money_changed.emit(money)
