# Weird World — game design document

One page that answers "what are we making and why is it fun?" Keep it current: when a
rule changes in code, change it here in the same commit.

Concept and characters by the game's designer (the original "book" lives in
`docs/design/`). This document turns that concept into rules a computer can follow.

---

## Title

Weird World

## One-liner

A hungry blob runs and jumps through a weird world, eating humans for money and
stomping ghost strawberries, until it beats the ghost cake at the end.

## Pillars

The 2–3 things the game must always be. Every decision is checked against them.

1. **Bouncy** — running and jumping feels good on its own, before anything else is added.
2. **Funny** — blobs eating humans for a living, haunted desserts as villains. Lean in.
3. **Tweakable** — every number that matters (speed, jump height, money per human) lives
   in one resource file so the designer can change the game without touching code.

## Core loop

What the player does over and over.

```
run right -> jump a gap -> eat a human (+$) -> dodge or stomp a ghost strawberry -> ...
                                            \-> reach the ghost cake -> stomp it -> level won
                                            \-> get hit -> pay a fine -> the level restarts, money kept
```

## Player verbs

What the blob can *do*.

- Run left / right
- Jump
- Eat (touch a human — automatic, blobs can't help it)
- Stomp (land on top of an enemy)
- Pause

## Cast

| Who | Role | Behaviour |
| --- | --- | --- |
| **Blob** (blue, two eyes) | the player | runs, jumps, eats, stomps |
| **Humans** | the collectable ("coins") | stand around; touching one eats it for `human_value` money |
| **Ghost strawberry** | the goomba | walks left/right, turns at walls and ledges; stomp from above defeats it, touching its side costs you money and restarts the level |
| **Ghost cake** | the boss | bigger, waits at the end of the level, takes `boss_health` stomps to defeat |

## Rules, win and lose

- Eating a human pays `human_value` (1) money. Stomping a ghost strawberry pays
  `stomp_value` (2).
- Touching a ghost strawberry from the side **restarts the level and costs money**: the humans
  come back, the blob goes back to the start, the money goes back to what it was when the
  level started, and then `strawberry_fine` is taken. (Decided by the designer, 2026-09-05:
  "lose money and restart the level". *Interpretation to confirm with him:* "restart" means
  the attempt's earnings are forfeited too — otherwise getting caught after eating everyone
  and eating them all again would be a way to earn, not a punishment.)
- There are **no lives** and no game over. You cannot lose your job, only money.
- **Win**: stomp the ghost cake `boss_health` (3) times.
- There is **no clock**. Take your time, eat everyone. (Decided 2026-09-05; a speed
  bonus is a "later" idea, not a rule.)
- Money carries between levels (it's a job, after all).

## Controls

| Action | Keys |
| --- | --- |
| Run | A / D or ← / → |
| Jump | Space, W or ↑ |
| Pause / resume | Esc |
| Menus | mouse, or Enter on the focused button |

## Scope

**Milestone 1 — the blob can jump** (done 2026-09-05)

- Gravity and a `jump` action; a floor, two platforms and invisible walls at the screen edges
- One hand-built screen (`game/level/level.tscn`; its numbers in `game/core/levels/level_01.tres`)
- Title screen → level → results, pause — reused from the template
- Shipped with the template's coins and clock still in place (Milestone 2 replaced them)

**Milestone 1b — a wider world**

- A camera that follows the blob, and a level wider than one screen. Deferred from
  Milestone 1 because the first level fits in 640×360, so a camera had nothing to do.

**Milestone 2 — a job** (done 2026-09-05)

- Five hand-placed humans to eat; money and "humans left" in the HUD; eating everyone
  ends the level (the ghost cake takes over as the goal in Milestone 4)
- The template's coins, spawner and clock are gone

**Milestone 3 — ghost strawberries** (done 2026-09-05)

- Money moved up to the game (`Wallet`, owned by `Main`) so it survives a level restart
- Two ghost strawberries patrol level 1, turning at walls and ledges; stomp one from above
  for `stomp_value` ($2); touch one from the side and the world freezes for a beat, the
  attempt's earnings are forfeited, you pay `strawberry_fine` ($2), and the level restarts
- A little "+$2" / "−$7" pops where it happened, showing the money that really moved

**Milestone 4 — the ghost cake**

- Boss with health; stomping it wins the level

**Later / ideas**

- More levels, each with its own ghost cake
- Different blobs to play as (colours, abilities)
- Different kinds of humans worth different money (a chef? a baker? — cake's revenge)
- Sound effects and music
- Best-money memory
- Checkpoints inside long levels

## Art and audio direction

- Pixel-art look at 640×360, integer scaling, nearest-neighbour filtering (already set).
- Match the drawings in the book: a blob is a blue outline with two dot eyes; enemies
  are food with stick legs and faces. Sad strawberry, angry cake.
- Placeholder sprites are hand-written SVGs (text, tiny, Claude-editable) so the whole
  cast exists before any real art. Swap for a CC0 pack later — see `ASSETS.md`.
- No audio yet.

## Levels and progression

Levels are built by hand as scenes (a platformer wants deliberate jumps and enemy
placement, not random spawns). Tunable numbers for each level live in a `LevelConfig`
`.tres` next to it. Adding a level is adding a scene plus a `.tres` and choosing it on
the `Main` node.

## Open questions

- ~~How high should the blob jump — one platform, or two?~~ **Answered by playtest,
  2026-09-05: "Jump is good."** Two steps of 48 px with `jump_velocity 330` / `gravity 980`.
  Those numbers are now the reference; `test_level_flow` fails if a tweak makes a platform
  unreachable.
- `strawberry_fine` is $2 for now (as much as a stomp earns) and the blob **cannot** go below
  $0 — both are defaults awaiting the designer's verdict. Debt would be funny ("You owe $3").
- Does getting caught forfeit what you earned in that attempt (current rule), or keep it?
  Keeping it makes getting caught on purpose a way to earn. Designer's call.
- What happens if the blob falls off the bottom of a level? Level 1 has no pit, but a wider
  level will. (Suggestion: the same as a strawberry — restart and a fine.)
- Do humans run away when they see a blob? (Funny, but harder. Milestone 2 says: they don't.)
- What does the blob look like when it's eaten a lot? Bigger? Slower?
