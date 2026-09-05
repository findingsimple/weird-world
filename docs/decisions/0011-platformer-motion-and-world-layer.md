# 0011 — Platformer physics in a `RefCounted`, solid ground on a `world` layer

- Status: Accepted, 2026-09-05. Two forecasts below did not come true: there are no lives
  (0014: a fine and a restart), and the floor branch now cancels *downward* speed only so a
  stomp bounce survives the frame.

## Context and problem statement

Weird World is a side-on platformer; the template it was created from was a top-down
collector (`CharacterBody2D` in *Floating* motion mode, colliding with nothing, clamped to
an arena rectangle). `move_and_slide()` works in any mode, but floor detection
(`is_on_floor()`) and floor snapping need *Grounded* mode and a body on a physics layer the
player's mask includes. Jump feel — gravity, jump speed, fall cap — is the most-tuned code
in any platformer and the first thing a young designer wants to change, so it has to be
testable and tweakable without a scene tree.

## Decision

1. **The maths lives in `PlatformerMotion`** (`RefCounted`, `game/core/`): one call,
   `next_velocity(velocity, input_x, jump_pressed, on_floor, delta)`. `Player` reads input,
   hands the motion its four `@export` tunables every physics frame (`configure()`), asks
   for a velocity and calls `move_and_slide()`. This is ADR 0010's pattern applied to movement.
2. **Solid ground is `StaticBody2D` on physics layer 3, `world`.** `Player` masks only that
   layer; pickups stay on layer 2, the player on layer 1 (`architecture.md` → Physics layers).
3. **Levels are hand-built scenes.** Floor, platforms, invisible edge walls and the player's
   start are placed in `level.tscn`, not computed. The physics tick rate is pinned to 60 in
   `project.godot` so jump height is the same on every machine.
4. **The template's coins and clock stay until Milestone 2**, but the coin area
   (`Level.arena`, set in `level.tscn`) is shrunk to the strip above the floor the blob can
   jump to, so the round stays winnable meanwhile.

## Consequences

- Good: jump numbers are unit-tested in `test_platformer_motion.gd` in milliseconds, and a
  kid can change `gravity` in the Inspector *while playing* and watch the blob float.
- Good: adding ground is copying a `StaticBody2D` in the scene; no code. Tests check every
  child of `World` is solid and that each platform step is within a jump.
- Bad: the blob is boxed in by walls at the screen edges. Falling out of the world, lives and
  respawning are Milestone 3 (ghost strawberries); a follow camera and levels wider than one
  screen are Milestone 1b.
- Bad: with the jump maths cancelling vertical speed on the floor, ground must be flat.
  Slopes would mean applying gravity every frame and letting the collision zero it.
- Remember: anything solid must be on `world` (bit value 4) or the blob falls through it.

## Alternatives considered

- **Maths inline in `Player._physics_process`** — the tutorial default; only testable with a
  scene and a real floor, and it grows into a 200-line node.
- **`TileMapLayer` with collision for ground** — the right tool once there are tiles
  (Milestone 1b/2); premature for a first hand-built screen.
- **Keep Floating mode and fake gravity by hand** — fights the engine; `is_on_floor()` never
  works, so stomping enemies later would need its own detection.
- **A death plane instead of walls** — the platformer idiom, but it needs lives and respawn
  to mean anything; walls are one scene node each and teach the layer again.
