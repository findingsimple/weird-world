# Game design document

A lightweight GDD: one page that answers "what are we making and why is it fun?"
before any code. Copy this file to `docs/gdd.md` for your game, keep it current, and
link it from the README. The example below is filled in for Weird World.

Tip: write the **Core loop** and **Rules** sections first. If you can't write them in
a few lines, the game is not clear yet.

---

## Title

Weird World

## One-liner

Grab enough coins before the clock runs out.

## Pillars

The 2–3 things the game must always be. Every decision is checked against them.

1. **Instant** — playable in five seconds, no tutorial.
2. **Readable** — you always know the score, the target, and the time.
3. **Tweakable** — every number that matters lives in one resource file.

## Core loop

What the player does over and over.

```
see a coin -> move to it -> collect (+1) -> see the next coin -> ...
                                     \-> time runs out -> results -> play again
```

## Player verbs

What the player can *do*.

- Move (8 directions)
- Pause

## Rules, win and lose

- A round lasts `duration_seconds` (30).
- Coins spawn every `spawn_interval` (0.8 s) up to `max_coins` (5) at a time, never
  within `min_spawn_distance_from_player` (48 px) of the player and never closer than
  `arena_margin` (24 px) to the edge.
- Touching a coin scores `coin_value` (1).
- **Win**: score reaches `target_score` (10) before time is up.
- **Lose**: time reaches zero first.

## Controls

| Action | Keys |
| --- | --- |
| Move | WASD / arrow keys |
| Pause / resume | Esc |
| Menus | mouse, or Enter on the focused button |

## Scope

**MVP (shipped)**

- Title screen → round → results screen (retry / title)
- Coins, score, countdown, win/lose
- Pause
- Web build

**Later / ideas**

- A second coin type worth more
- An enemy that ends the round on contact
- Several levels with increasing targets
- Sound effects and music
- Best-score memory

## Art and audio direction

- Pixel-art look at 640×360, integer scaling, nearest-neighbour filtering.
- Placeholder sprites are hand-written SVGs (text, tiny, Claude-editable). Swap for a
  CC0 pack (Kenney) later — see `ASSETS.md`.
- No audio yet.

## Levels and progression

One level (`game/core/levels/level_01.tres`). Adding a level is adding a `.tres` file
and choosing it on the `Main` node.

## Open questions

- Should coins disappear after a while, to keep the player moving?
- Is 30 seconds right for a kid? (Playtest: try 20 and 45.)
- Gamepad support?
