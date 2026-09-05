# Architecture

How the example game ("Weird World") is put together, and the rules that keep it easy to
change. Everything here carries over to your own game.

## One rule: signal up, call down

- A parent **calls** methods on its children (it owns them, it knows their API).
- A child **emits signals** when something happens (it does not know who is listening).
- Things that cross screen boundaries go through one global bus, `GameEvents`.

This keeps every scene self-contained: you can open `coin.tscn` or `player.tscn` on its
own, run it, and test it in isolation.

## Scene tree

```
Main (game/main.tscn)                     flow: title -> level -> results -> (level | title)
└── Screen                                exactly one child at a time
    ├── TitleScreen                       emits start_pressed
    ├── Level (game/level/level.tscn)     one round
    │   ├── Background, ArenaEdge         visual only
    │   ├── Coins                         container for spawned Coin scenes
    │   ├── Player                        CharacterBody2D, reads input
    │   ├── SpawnTimer                    Timer -> Level._on_spawn_timer_timeout
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
| `Main` | `game/main.gd` | Screen flow only. Owns the `LevelConfig` to play. |
| `Level` | `game/level/level.gd` | One round. Owns `GameRules` + `CoinSpawner`, spawns coins, forwards rule signals to the bus. |
| `GameRules` | `game/core/game_rules.gd` | **Pure logic** (`RefCounted`): score, countdown, win/lose. No nodes. Unit-tested. |
| `CoinSpawner` | `game/core/coin_spawner.gd` | **Pure logic**: picks spawn positions. RNG is injected so tests can seed it. |
| `LevelConfig` | `game/core/level_config.gd` | `Resource` of tunables (`target_score`, `duration_seconds`, ...). Saved as `game/core/levels/level_01.tres`. |
| `GameEventsBus` | `game/core/game_events.gd` | Autoload `GameEvents`. Signals only, no state. |
| `Player` | `game/player/player.gd` | `CharacterBody2D`; moves from `Input.get_vector`, clamped to `bounds`. |
| `Coin` | `game/coin/coin.gd` | `Area2D`; bobs, emits `collected` when a `Player` overlaps, frees itself. |
| `Hud` | `game/ui/hud/hud.gd` | Score and time labels bound to the bus. |
| `TitleScreen`, `ResultsScreen` | `game/ui/...` | Emit navigation signals; contain no game logic. |
| `PauseMenu` | `game/ui/pause_menu/pause_menu.gd` | Handles the `pause` action, pauses the tree, shows Resume. |

The logic classes (`GameRules`, `CoinSpawner`, `LevelConfig`) are `RefCounted`/`Resource`,
not nodes. That is deliberate: they run in a unit test in a millisecond with no scene
tree, and they can be reused unchanged in a 3D version of the game.

## The `GameEvents` bus contract

Autoloaded as `GameEvents` (`project.godot` → `[autoload]`). Holds no state.

| Signal | Emitted by | Listened to by |
| --- | --- | --- |
| `game_started(config: LevelConfig)` | `Level._ready` | (free for your own use: music, analytics, ...) |
| `score_changed(score: int, target: int)` | `Level` (initial value, then on every `GameRules.score_changed`) | `Hud.set_score` |
| `time_changed(seconds_left: int)` | `Level` (initial value, then on every `GameRules.time_changed`) | `Hud.set_time` |
| `game_over(outcome: GameRules.Outcome, score: int)` | `Level._on_rules_finished` | `Main._on_game_over` |
| `pause_toggled(is_paused: bool)` | `PauseMenu.set_paused` | (free: dim music, etc.) |

Rule of thumb: add a signal here only when the emitter and the listener live on
different screens. Inside one scene, use a direct signal.

## Data flow: picking up one coin

```
Physics server detects overlap
  -> Coin.body_entered(body)              (Area2D signal)
  -> Coin._on_body_entered: body is Player
  -> Coin.collected.emit(self); queue_free()
  -> Level._on_coin_collected(coin)       (connected in Level.spawn_coin_at)
  -> GameRules.add_score(coin.value)
  -> GameRules.score_changed.emit(score)
  -> Level._on_rules_score_changed
  -> GameEvents.score_changed.emit(score, target)
  -> Hud.set_score -> label text
  (if score >= target) GameRules.finished.emit(WON)
  -> Level._on_rules_finished -> GameEvents.game_over.emit(WON, score)
  -> Main._on_game_over -> results screen (deferred)
```

Every hop is either a signal (up) or a plain method call (down).

## Time and pausing

- `Level._process(delta)` calls `GameRules.tick(delta)`. The countdown is frame-rate
  independent.
- `SpawnTimer` fires every `config.spawn_interval` seconds; `Level._spawn_coin` skips
  when `max_coins` are already on screen.
- `PauseMenu` has `process_mode = Always`, so it still receives input when
  `get_tree().paused` is true — that is what lets Esc resume. Everything else in the
  level inherits the paused state and stops (timers, `_process`, physics).
- When the round ends, `Level` disables the pause menu (`_pause_menu.enabled = false`).

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
  (`game/coin/coin.tscn`, `coin.gd`, `coin.svg`). Not `scenes/`, `scripts/`, `sprites/`.
- `game/core/` — logic and data that are not scenes.
- `game/ui/` — screens and HUD, one folder each; `game/ui/theme/` for the shared theme.
- `tests/unit/` and `tests/integration/` mirror `game/`.
- `addons/` — third-party code only (GUT). Never edit it; never lint it.
- `snake_case` for files and folders (Godot's packed file system is case-sensitive;
  macOS is not — lowercase avoids the surprise). `PascalCase` for node names and
  `class_name`s.

## Going 3D

The structure does not change:

- Keep `game/core/` exactly as it is. `GameRules`, `LevelConfig`, `CoinSpawner`
  (return a `Vector3` instead) and the `GameEvents` contract are dimension-agnostic.
- Scenes become `Node3D` trees: `Player` extends `CharacterBody3D`, `Coin` extends
  `Area3D`, the arena is an `AABB` instead of a `Rect2`. Unit tests do not change;
  integration tests swap `wait_physics_frames` targets for 3D nodes.
- Renderer: 3D wants `forward_plus` (or `mobile`). Change
  `rendering/renderer/rendering_method` in `project.godot` and drop the
  `"GL Compatibility"` feature tag. Note that only the Compatibility renderer runs on
  the Web, so a Forward+ game gives up the GitHub Pages deploy — remove or disable
  `.github/workflows/web.yml` and the `Web` preset, or keep a Compatibility-renderer
  build for the browser if the visuals allow it.
- `display/window/stretch/mode = "viewport"` with integer scaling is a pixel-art
  choice; a 3D game usually wants `canvas_items` and `fractional`.
