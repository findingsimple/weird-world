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
                                            \-> get hit / fall off -> lose a life -> retry
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
| **Ghost strawberry** | the goomba | walks left/right, turns at walls and ledges; stomp from above defeats it, touching its side hurts you |
| **Ghost cake** | the boss | bigger, waits at the end of the level, takes `boss_health` stomps to defeat |

## Rules, win and lose

- The blob has `lives` (3).
- Eating a human pays `human_value` (1) money. Stomping a ghost strawberry pays
  `stomp_value` (2).
- Touching a ghost strawberry from the side, or falling off the bottom of the level,
  costs one life and restarts the blob at the level start (or last checkpoint).
- **Win**: stomp the ghost cake `boss_health` (3) times.
- **Lose**: run out of lives.
- Money carries between levels (it's a job, after all).

## Controls

| Action | Keys |
| --- | --- |
| Run | A / D or ← / → |
| Jump | Space, W or ↑ |
| Pause / resume | Esc |
| Menus | mouse, or Enter on the focused button |

## Scope

**Milestone 1 — the blob can jump** (start here)

- Gravity and a `jump` action; platforms you can stand on; a camera that follows the blob
- One hand-built test level (`game/core/levels/level_01.tres` + a level scene)
- Title screen → level → results, pause — reused from the template

**Milestone 2 — a job**

- Humans to eat; money shown in the HUD

**Milestone 3 — ghost strawberries**

- Patrol, stomp, hurt, lives

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

- Should the round still have a clock, like the template? (Suggestion: no clock; the
  cake is the goal. Try a "speed bonus" later if levels feel slow.)
- How high should the blob jump — one platform, or two? (Playtest with a kid at the controls.)
- Do humans run away when they see a blob? (Funny, but harder. Milestone 2 says: they don't.)
- What does the blob look like when it's eaten a lot? Bigger? Slower?
