# 0014 — Ghost strawberries: patrol, stomp-or-touch, fine and restart

- Status: Accepted, 2026-09-05

## Context and problem statement

The first enemy. The designer's rule: touching one costs money and restarts the level; no
lives, no game over. A platformer enemy needs three decisions that are easy to get wrong
and hard to test if they live in a node: which way it walks and when it turns, whether a
contact was a stomp or a touch, and what a "restart" means for the money — the review
panel showed that "keep the money, respawn the humans" turns the penalty into a farm.

## Decision

1. **`Strawberry`** is a `CharacterBody2D` on physics layer 4 `enemies` (bit value 8),
   masking only `world`, so it walks on the same ground as the blob and never physically
   pushes it. It reuses `PlatformerMotion` with a jump of 0 — gravity and the fall cap for
   free.
2. **`Patrol`** (`RefCounted`) owns the direction and turns at a wall (`is_on_floor()` +
   `is_on_wall()`) or a ledge (a downward `RayCast2D` 8 px ahead of the feet finds no ground).
3. **`EnemyContact.is_stomp(feet_y, velocity_y, top_y, delta)`** (`RefCounted`, static)
   decides: falling, and the feet *a frame ago* (`feet − velocity·Δt`) no lower than the
   enemy's top plus 4 px, is a stomp. The rewind exists because the physics server reports
   the overlap a frame late — measured at 4.05 px of sinking at 163 px/s, which a fixed 4 px
   tolerance called a touch. Invariant, pinned by a unit test: one frame at `max_fall_speed`
   plus the tolerance (≈ 6.7 + 4) must stay under the hitbox height (12), or a side contact
   while falling fast would read as a stomp. Detection is an `Area2D` hitbox masking the
   player layer; the decision is pure maths and the measurement is a unit test.
4. **Signals up.** The strawberry emits `stomped` or `blob_touched`; `Level` decides money.
   Stomp: `Wallet.earn(stomp_value)`, the blob bounces. Touch — **being caught**: the level
   freezes the blob and the strawberries, **resets the wallet to what it held when the level
   started** (that attempt's earnings are forfeited), takes `strawberry_fine`, pops the money
   that actually moved, waits `CAUGHT_PAUSE` (0.6 s) so the pop can be read, then emits
   `GameEvents.blob_caught`; `Main` rebuilds the level scene with the same wallet. While
   caught, nothing in the level pays, fines or finishes (`is_live()`).
5. Every money path goes through the one unit-tested `Wallet`; `Level` guards *when*
   (`is_live()`), `Wallet` guards *how much* (never negative, never a phantom change).

## Consequences

- Good: three new unit-tested classes, no physics in any of them; the node is 40 lines.
- Good: a stomp bounces the blob (`Player.bounce()`), so chaining stomps is possible later.
- Good: getting caught is a real punishment and shows its real cost — and can never be a
  way to earn.
- Bad: "forfeit the attempt" is my reading of "restart the level", recorded in the GDD as a
  question for the designer; the fine and the no-debt floor are defaults too.
- Bad: reachability tests know nothing about strawberries; a strawberry parked in front of
  the only route makes a level unwinnable — playtesting, not tests, catches that.
- Remember: anything under `Strawberries` must be a `Strawberry`; the hitbox masks layer 1
  (`player`) and nothing else. Strawberries pass through each other, so give two on the same
  ground room or opposite start directions. A strawberry needs ~16 px of ground either side
  of its start or it flips every frame and jitters in place. A level running on its own
  (the scene from the editor) stays frozen after a catch — only `Main` rebuilds levels.

## Alternatives considered

- **Physical collision between blob and strawberry** (blob masks `enemies`) — the blob would
  stand on strawberries and push them; the hitbox keeps the two concerns apart.
- **A thin "stomp zone" `Area2D` across the strawberry's top** — the classic geometric answer;
  would replace the velocity rewind with "where did you hit". Kept in reserve if the numeric
  rule ever misjudges a real playtest.
- **Money paths inside `GameRules`** (`stomp_enemy`, `take_fine`) — one object for all money
  movement. `Wallet` already is that object for amounts; `Level` owns the timing.
- **Lives** — the designer said no. Losing money is the cost; restarting is the punishment.
- **Restart in place (reset positions, respawn humans) instead of rebuilding the scene** —
  more code and more state to reset; rebuilding is what `Main` already does for "Play again".
- **Keep the attempt's earnings across the restart** — the first implementation; the panel
  showed it made the fine net-positive.
