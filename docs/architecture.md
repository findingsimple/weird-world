# Architecture

How Weird World is put together, and the rules that keep it easy to change.

## One rule: signal up, call down

- A parent **calls** methods on its children (it owns them, it knows their API).
- A child **emits signals** when something happens (it does not know who is listening).
- Things that cross screen boundaries go through one global bus, `GameEvents`.

This keeps every scene self-contained: you can open `human.tscn` or `player.tscn` on its
own, run it, and test it in isolation.

## Scene tree

```
Main (game/main.tscn)                     flow: title -> level -> results -> (level | title)
└── Screen                                exactly one child at a time
    ├── TitleScreen                       emits start_pressed
    ├── Level (game/level/level.tscn)     one level
    │   ├── Background                    visual only
    │   ├── World                         Floor, platforms, edge walls: StaticBody2D on layer `world`
    │   ├── Humans                        the hand-placed Human scenes the blob is paid to eat
    │   ├── Player                        CharacterBody2D, reads input, owns a PlatformerMotion
    │   ├── Hud                           CanvasLayer, listens to GameEvents
    │   └── PauseMenu                     CanvasLayer, process_mode = Always
    └── ResultsScreen                     emits retry_pressed / title_pressed
```

`Main` swaps the single child under `Screen`, always resetting `get_tree().paused`
so no screen starts frozen. Scene changes triggered by `game_over` are deferred,
because that signal can arrive in the middle of a physics callback.

## The pieces

| Class | File | Role |
| --- | --- | --- |
| `Main` | `game/main.gd` | Screen flow, the level scene and config to play, and the blob's `Wallet` — money outlives a level; the title screen starts a new job. |
| `Level` | `game/level/level.gd` | One level. Counts its humans, owns `GameRules`, hands it the wallet `Main` gave it, forwards signals to the bus. |
| `GameRules` | `game/core/game_rules.gd` | **Pure logic** (`RefCounted`): humans left, win when all are eaten; pays each human into the `Wallet`. Unit-tested. |
| `Wallet` | `game/core/wallet.gd` | **Pure logic**: the blob's money — `earn`, `pay_fine` (never below $0). Unit-tested. |
| `PlatformerMotion` | `game/core/platformer_motion.gd` | **Pure logic**: run speed, gravity, jump, fall cap — one `next_velocity()` call per physics frame. Unit-tested. |
| `LevelConfig` | `game/core/level_config.gd` | `Resource` of tunables (`human_value`). Saved as `game/core/levels/level_01.tres`. |
| `GameEventsBus` | `game/core/game_events.gd` | Autoload `GameEvents`. Signals only, no state. |
| `Player` | `game/player/player.gd` | `CharacterBody2D`; reads `move_left`/`move_right`/`jump`, asks `PlatformerMotion` for a velocity, `move_and_slide()`. |
| `Human` | `game/human/human.gd` | `Area2D`; fidgets, emits `eaten` when a `Player` overlaps, frees itself. |
| `Hud` | `game/ui/hud/hud.gd` | Money and humans-left labels bound to the bus. |
| `TitleScreen`, `ResultsScreen` | `game/ui/...` | Emit navigation signals; contain no game logic. |
| `PauseMenu` | `game/ui/pause_menu/pause_menu.gd` | Handles the `pause` action, pauses the tree, shows Resume and Title screen; emits `quit_pressed` up to `Level`. |

The logic classes (`GameRules`, `Wallet`, `PlatformerMotion`, `LevelConfig`) are `RefCounted`/`Resource`,
not nodes. That is deliberate: they run in a unit test in a millisecond with no scene
tree, and they can be reused unchanged in a 3D version of the game.

## The `GameEvents` bus contract

Autoloaded as `GameEvents` (`project.godot` → `[autoload]`). Holds no state.

| Signal | Emitted by | Listened to by |
| --- | --- | --- |
| `game_started(config: LevelConfig)` | `Level._ready` | (free for your own use: music, analytics, ...) |
| `money_changed(money: int)` | `Level` (initial value, then on every `Wallet.money_changed`) | `Hud.set_money` |
| `humans_changed(humans_left: int, humans_total: int)` | `Level` (initial value, then on every `GameRules.humans_changed`) | `Hud.set_humans` |
| `game_over(outcome: GameRules.Outcome, money: int)` | `Level._on_rules_finished` | `Main._on_game_over` |
| `pause_toggled(is_paused: bool)` | `PauseMenu.set_paused` | (free: dim music, etc.) |

Rule of thumb: add a signal here only when the emitter and the listener live on
different screens. Inside one scene, use a direct signal.

## Data flow: eating one human

```
Physics server detects overlap
  -> Human.body_entered(body)             (Area2D signal)
  -> Human._on_body_entered: body is Player
  -> Human.eaten.emit(self); queue_free()
  -> Level._on_human_eaten(human)         (connected in Level._ready)
  -> GameRules.eat_human(human.value) -> Wallet.earn(value)
  -> Wallet.money_changed.emit(money); GameRules.humans_changed.emit(left, total)
  -> Level._on_wallet_money_changed / _on_rules_humans_changed
  -> GameEvents.money_changed.emit(money); GameEvents.humans_changed.emit(left, total)
  -> Hud.set_money / Hud.set_humans -> label text
  (if left == 0) GameRules.finished.emit(WON)
  -> Level._on_rules_finished -> GameEvents.game_over.emit(WON, money)
  -> Main._on_game_over -> results screen (deferred)
```

Every hop is either a signal (up) or a plain method call (down).

## Money, time and pausing

- The `Wallet` belongs to `Main`, not to the level: a level is rebuilt on every restart,
  and money must survive that (a ghost strawberry's fine, Milestone 3). "Play again" keeps
  the money; the title screen starts a new job with an empty wallet.
- There is no clock: a level ends when the last human is eaten (docs/gdd.md). There are no
  lives and no game over — you cannot lose your job, only money.
- `PauseMenu` has `process_mode = Always`, so it still receives input when
  `get_tree().paused` is true — that is what lets Esc resume. Everything else in the
  level inherits the paused state and stops (`_process`, physics).
- When the level ends, `Level` disables the pause menu (`_pause_menu.enabled = false`).
- The pause menu's **Title screen** button emits `quit_pressed` — a direct signal up to
  `Level`, not a bus signal, because only `Level` decides what leaving means: it ends the
  level as `LOST` with the money earned so far, and `Main` shows the results screen.
- A level with no humans is finished the moment it starts (`GameRules` is born `WON`;
  `Level` notices after wiring up and emits `game_over`). A non-`Human` node under `Humans`
  is reported with `push_error` and ignored, never counted.

## Physics layers

Named in `project.godot` → `[layer_names]`. A body is *on* its `collision_layer` and
*looks for* the layers in its `collision_mask`.

| Layer (bit value) | Name | Who is on it | Who looks for it |
| --- | --- | --- | --- |
| 1 (1) | `player` | `Player` | `Human` (mask 1) |
| 2 (2) | `pickups` | `Human` | nobody — an `Area2D` detects, it is not detected |
| 3 (4) | `world` | floor, platforms and edge walls (`StaticBody2D`) | `Player` (mask 4) |

Anything solid the blob should stand on goes on `world`. Otherwise it falls straight
through — the most common "why doesn't my platform work?" answer.

## Files Godot creates — what to commit

| File | What it is | Commit? |
| --- | --- | --- |
| `*.gd` | Script (plain text) | yes |
| `*.tscn` | Scene (plain text) — nodes, properties, which script each uses | yes |
| `*.tres` | Resource (plain text) — e.g. `level_01.tres`, `main_theme.tres` | yes |
| `*.gd.uid` | Stable unique id for a script, generated on import (Godot 4.4+) | **yes** |
| `*.svg.import` | Import settings for an asset, generated on import | **yes** |
| `.godot/` | Import cache and editor state | no (git-ignored) |
| `build/`, `reports/` | Exports and test/check output | no (git-ignored, `.gdignore`d) |

If a `.uid` or `.import` file is missing from git, the next machine generates a
*different* one and scene references can break. `make import` creates them; commit
what it creates.

## Folder conventions

- **Feature folders**: a scene, its script and its assets live together
  (`game/human/human.tscn`, `human.gd`, `human.svg`). Not `scenes/`, `scripts/`, `sprites/`.
- `game/core/` — logic and data that are not scenes.
- `game/ui/` — screens and HUD, one folder each; `game/ui/theme/` for the shared theme.
- `tests/unit/` and `tests/integration/` mirror `game/`.
- `addons/` — third-party code only (GUT). Never edit it; never lint it.
- `snake_case` for files and folders (Godot's packed file system is case-sensitive;
  macOS is not — lowercase avoids the surprise). `PascalCase` for node names and
  `class_name`s.

## Going 3D

The structure does not change:

- Keep `game/core/` exactly as it is. `GameRules`, `PlatformerMotion`, `LevelConfig` and
  the `GameEvents` contract are dimension-agnostic.
- Scenes become `Node3D` trees: `Player` extends `CharacterBody3D`, `Human` extends
  `Area3D`, ground is `StaticBody3D`. Unit tests do not change; integration tests swap
  `wait_physics_frames` targets for 3D nodes.
- Renderer: 3D wants `forward_plus` (or `mobile`). Change
  `rendering/renderer/rendering_method` in `project.godot` and drop the
  `"GL Compatibility"` feature tag. Note that only the Compatibility renderer runs on
  the Web, so a Forward+ game gives up the GitHub Pages deploy — remove or disable
  `.github/workflows/web.yml` and the `Web` preset, or keep a Compatibility-renderer
  build for the browser if the visuals allow it.
- `display/window/stretch/mode = "viewport"` with integer scaling is a pixel-art
  choice; a 3D game usually wants `canvas_items` and `fractional`.
