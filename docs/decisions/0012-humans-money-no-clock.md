# 0012 — Hand-placed humans, money, no clock; eating everyone ends the level

- Status: Accepted, 2026-09-05. Its forecast that "lives and losing arrive with Milestone 3"
  did not come true: the designer chose a fine and a restart instead — see 0013 and 0014.

## Context and problem statement

The template's round was "collect randomly spawned coins before a timer runs out". Weird
World's design (`docs/gdd.md`) is "a blob eats humans for money, no clock, beat the ghost
cake". Milestone 2 had to replace the template's loop with the game's own before any enemy
work, and decide what ends a level while there is no boss yet.

## Decision

1. **`Human` replaces `Coin`**: same shape (an `Area2D` on the `pickups` layer that emits a
   signal and frees itself), new name, new sprite, a nervous fidget instead of a bob.
2. **Humans are hand-placed in `level.tscn`**, like the platforms. `CoinSpawner`, the
   `SpawnTimer`, the `arena` rectangle and every spawn tunable are deleted. `LevelConfig`
   keeps one number, `human_value`.
3. **`GameRules` has no clock.** It is told how many humans the level placed, pays
   `human_value` per human, and finishes `WON` when the last one is eaten. `Outcome.LOST`
   stays in the enum for Milestone 3 (lives); nothing produces it yet.
4. The bus contract changes accordingly: `money_changed(money)` and
   `humans_changed(left, total)` replace `score_changed`/`time_changed`;
   `game_over(outcome, money)`.
5. The old `player.svg` — a little person — becomes `human.svg`. The blob gets a placeholder
   drawn after the designer's cover; redrawing it is the designer's job.

## Consequences

- Good: the test suite runs faster (no timeout tests awaiting real time); the level ends
  when the player finishes, not when a timer says so.
- Good: level design is one file — move a human, add a human — and two tests guard it:
  every human must stand on a piece of `world` ground, and the human count is pinned
  (`HUMANS_IN_LEVEL`) so adding one is a deliberate, test-visible act.
- Bad: "eat everyone" is a stand-in goal. Milestone 4 makes the ghost cake the exit;
  until then a level with a human somewhere unreachable can never be finished — the
  standing-on-ground test catches floating humans but not unreachable ones.
- Remember: `Level` counts humans in `_ready`. Spawning humans at runtime later (a
  "humans keep arriving" mode) means telling `GameRules` about them.
- The clock was also the only guarantee a level *ends*. In its place: the pause menu has a
  **Title screen** button (`quit_pressed`, signal up to `Level`, which ends the level as
  `LOST` with the money so far — leaving is not winning); a level with no humans is
  finished the moment it starts; a non-`Human` node under `Humans` is reported and ignored
  rather than counted, so a mistake cannot make a level unwinnable.
- Money is per level for now: `GameRules` starts at 0 and `game_over` reports what this
  level earned. The GDD's "money carries between levels" needs `Main` to keep a running
  total and pass it in — a small seam, added when there is a second level to carry it to.

## Alternatives considered

- **Keep the timer as a score-attack bonus** — fights the "explore and eat" fantasy
  (GDD); noted as a "later" idea, not a rule.
- **Keep the spawner, spawn humans in the reachable strip** — would have kept the
  template's arena concept alive for one more milestone for no design reason.
- **Rename in place (`Coin` → `Human` via sed)** — the class is 30 lines; a fresh
  feature folder with the right words in the docstrings is clearer for the audience.
