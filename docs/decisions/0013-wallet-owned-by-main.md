# 0013 — The blob's money lives in a `Wallet` owned by `Main`

- Status: Accepted, 2026-09-05

## Context and problem statement

The designer's rule for ghost strawberries (Milestone 3) is "lose money and restart the
level". That only means something if money survives the restart. Until now money was a
field on `GameRules`, which `Level` creates and which dies with the level — so a restart
would have wiped the very money the fine was taken from. The GDD also says money carries
between levels.

## Decision

1. **`Wallet`** (`RefCounted`, `game/core/wallet.gd`): `money`, `earn(amount)`,
   `pay_fine(amount)`, `money_changed`. A fine never takes money below $0 — the blob cannot
   go into debt (designer's call pending; it is an open question in the GDD).
2. **`Main` owns the wallet** and hands it to every `Level` it starts. `GameRules` takes the
   wallet in its constructor and pays each eaten human into it; it no longer holds money.
3. **"Play again" keeps the money. The title screen starts a new job** with an empty wallet.
4. A `Level` run without a wallet (a test, the scene from the editor) makes its own, so
   scenes stay self-contained.

## Consequences

- Good: a level restart (Milestone 3) is just `Main` building the level scene again with the
  same wallet; nothing in the level has to know about restarts.
- Good: `Wallet` is the smallest possible unit-tested class, and the first place a second
  currency or a shop would go.
- Bad: one more object handed down the tree (`Main` → `Level` → `GameRules`). The style
  guide's "pass dependencies in" rule now has three examples.
- Remember: the wallet outlives the level, so `Level` disconnects from `money_changed` in
  `_exit_tree`. Godot would clean the connection up on free anyway; the explicit disconnect
  says why.

## Alternatives considered

- **A stateful autoload (`GameState.money`)** — the common shortcut; ADR 0010 rules it out
  (global mutable state makes every scene depend on it and the rules untestable).
- **Pass a starting balance into `GameRules` and read the total back on `game_over`** —
  fewer objects, but the money would exist in two places for the length of a level, and
  the HUD's source of truth would move with it.
- **Keep money per level and add it up in `Main`** — the fine could not be applied to a
  total the level does not know about.
