# CLAUDE.md

Guidance for Claude Code when working in this repository. Humans: this is also the
shortest accurate description of how the project works — keep it true.

## What this is

**Weird World**, a Godot **4.7.2** + **GDScript** platformer: a hungry blob eats humans
for money, stomps ghost strawberries and takes on the ghost cake boss. The design is in
`docs/gdd.md` (milestones included); the concept book is `docs/design/`. Created from the
`game-scaffolding` template; nothing of its Coin Dash example remains except the
architecture. Full docs live in `docs/`; start with
`docs/README.md`, `docs/architecture.md`, `docs/style-guide.md`, `docs/testing.md`.

## Commands (all via the Makefile — CI's test job runs `make ci` verbatim)

```sh
make ci                                   # version + lint + check + test. Run before finishing any task.
pre-commit run --all-files                # hygiene hooks CI's lint job also runs (git hook runs them per commit)
make lint                                 # gdformat --check + gdlint on game/ tests/ scripts/
make format                               # rewrite files with gdformat (tabs, 100 cols)
make check                                # load + compile every script/scene; typing rules are compile errors
make test                                 # GUT suite, headless; fails on parse errors or zero tests; JUnit -> reports/results.xml
make test GUT_ARGS="-gselect=test_game_rules -gunit_test_name=test_money_adds_up"   # one test
make import                               # rebuild .godot/ (needed after clone or new assets)
make run                                  # play the game
make export-web && make serve-web         # browser build on http://localhost:8060
make export-all                           # Web + Windows + Linux + macOS into build/
```

Tools must already be installed (`make setup` does it): `godot` 4.7.2 on PATH, `gdformat`
/ `gdlint` (gdtoolkit 4.5.0 — pinned identically in `setup.sh`, `.pre-commit-config.yaml` and CI), `pre-commit`. Export templates live in
`~/Library/Application Support/Godot/export_templates/4.7.2.stable/`.

## Hard rules

1. **Static typing everywhere.** `untyped_declaration` and the four `unsafe_*` checks are
   level 2 in `project.godot`, i.e. compile *errors* caught by `make check` and `make test`.
   Never call or access members on a `Variant` — assign to a typed variable first. Use `:=`
   only when the right-hand side makes the type obvious; otherwise write the type.
2. **Every script under `game/` has `class_name`** (test and tool scripts deliberately
   have none), files/folders are `snake_case`, node names and
   classes are `PascalCase`, signals are past tense (`eaten`, `money_changed`), private members
   start with `_`, signal handlers are `_on_<source>_<signal>`.
3. **Member order** is enforced by gdlint: `@tool` → `class_name` → `extends` → `##` docs →
   signals → enums → consts → static vars → `@export` → public vars → private vars →
   `@onready` public → `@onready` private → methods. `gdformat` handles whitespace.
4. **Logic lives in `RefCounted` classes** (`GameRules`, `Wallet`, `PlatformerMotion`, `Patrol`,
   `EnemyContact`) with no scene dependencies so it can be unit-tested. Scenes are thin and
   integration-tested.
5. **Signal up, call down.** A scene emits signals to whoever owns it and calls methods on
   its children. `GameEvents` (autoload) is only for events that cross screens; it holds no
   state. Don't add state or methods to it.
6. **Never edit `addons/`.** GUT is vendored as-is. Upgrade by replacing the folder.
7. **Commit sidecars, not caches:** commit `*.import`, `*.uid`, `export_presets.cfg`;
   never commit `.godot/`, `build/`, `reports/`, `__pycache__/`, `export_credentials.cfg`.
8. **Every behaviour change gets a test** — unit for rules, integration for scenes — and
   `make ci` must be green before you report a task as done.
9. **Assets per `ASSETS.md`.** Placeholder sprites are hand-written SVG (text, Claude-editable);
   real art and design files (e.g. `docs/design/*.pdf`) are fine but stay under pre-commit's
   size limit (`--maxkb` in `.pre-commit-config.yaml`), live beside the feature that uses
   them, and get a row in the credits table with their licence. No Git LFS.
10. **Conventional Commits** (`feat:`, `fix:`, `docs:`, `test:`, `chore:`, `ci:`); they
    drive release-please. No AI-attribution or Co-Authored-By lines in commits.

## Architecture in six lines

- `game/main.tscn` (`Main`) owns the screen flow: `TitleScreen` → `Level` → `ResultsScreen`.
  It swaps the single child of `$Screen` and always un-pauses on a swap. It also owns the
  blob's `Wallet` (money outlives a level; the title screen starts a new job) and hands it
  to each `Level`.
- `Level` counts the `Human`s hand-placed under its `Humans` node, builds a `GameRules` from
  that count and the wallet, gives each human its `value` from the `LevelConfig` resource
  (`game/core/levels/*.tres`), and forwards signals to `GameEvents`. No clock: the level is
  won when the last human is eaten. There are no lives; leaving early is `LOST`.
- `Player` (`CharacterBody2D`, layer 1, mask 4) reads `move_left/right` + `jump`, gets its
  velocity from `PlatformerMotion` (`RefCounted`: run, gravity, jump, fall cap — unit-tested)
  and `move_and_slide()`s against `StaticBody2D` ground on layer 3 `world`, hand-placed
  under `Level`'s `World` node. Anything the blob should stand on must be on `world`.
- `Human` (`Area2D`, layer 2, mask 1) emits `eaten` when a `Player` overlaps, then frees
  itself. `Level` turns that into `GameRules.eat_human`.
- `Strawberry` (`CharacterBody2D`, layer 8 = `enemies`, mask 4 = `world`) walks with
  `PlatformerMotion` (jump 0), turns via `Patrol` at walls and ledges (a `RayCast2D`), and its
  `Hitbox` (`Area2D`, mask 1) asks `EnemyContact.is_stomp` on contact: stomp → `stomped`, blob
  bounces, it frees itself; else `blob_touched`. `Level` pays `stomp_value`, or on a touch
  freezes the world, resets the `Wallet` to the level's starting money, takes
  `strawberry_fine`, and after `CAUGHT_PAUSE` emits `GameEvents.blob_caught`; `Main` rebuilds
  the level with the same wallet. Once caught, nothing in the level pays or finishes.
- `Hud` listens to `GameEvents.money_changed` / `humans_changed`. `PauseMenu` runs with
  `process_mode = Always`, handles the `pause` action, and toggles `get_tree().paused`.
- Input actions (`move_left/right`, `jump`, `pause`) are in `project.godot` → `[input]`.
  Physics layers: 1 `player`, 2 `pickups`, 3 `world`, 4 `enemies` (see `docs/architecture.md`).
- Rendering: `gl_compatibility`, 640×360 viewport, integer scaling, nearest filtering,
  pixel snap — required for the Web export and right for pixel art.

## How to add things

- **A new scene/feature:** folder under `game/<feature>/` with `feature.tscn`,
  `feature.gd` (`class_name Feature`), assets beside them. Expose tunables with `@export`.
  Add `tests/integration/<feature>/test_feature.gd`. Wire it into `Level` or `Main`.
- **A new rule:** put it in a `RefCounted` class in `game/core/`, unit-test it in
  `tests/unit/core/`, then have a scene call it.
- **A new level:** a level is a scene. Duplicate `game/level/level.tscn`, rearrange `World`
  and `Humans`, and assign it to `Main`'s `Level Scene` export. If it should pay differently,
  duplicate `game/core/levels/level_01.tres` too and assign that to `Level Config`.
- **A new platform:** in `game/level/level.tscn`, duplicate `LowPlatform` under `World`, set
  its `position`, keep `collision_layer = 4` (`world`) and `collision_mask = 0`, and resize the
  `RectangleShape2D` and the `ColorRect` together. `test_level_flow` checks every child of
  `World` is solid and every piece of ground is within one jump (vertically) of a lower one,
  so `make test` catches a platform placed too high — not one placed too far sideways. Play it.
- **A new human:** in `game/level/level.tscn`, duplicate a `Human*` node under `Humans` and
  set its `position` — standing on the floor is `y = 337`, on a platform its top minus 7.
  Only `Human` instances belong under `Humans` (anything else is reported and ignored).
  `test_level_flow` pins the human count (`HUMANS_IN_LEVEL`) and checks every human stands on
  ground, so `make test` goes red until you update the count — that is deliberate.
- **A new ghost strawberry:** duplicate a `*Strawberry` node under `Strawberries` in
  `game/level/level.tscn`, set `position` (standing on the floor is `y = 338`; on a platform
  its top minus 6) and `start_direction`. It turns at walls and ledges by itself, needs ~16 px
  of ground either side of its start (or it jitters), and walks straight through other
  strawberries (give two on one floor room or opposite directions). `test_level_flow` checks
  every strawberry starts on ground and is still patrolling that ground 1.5 s later.
- **A new input action:** add it to `project.godot` `[input]` (copy an existing block; use
  `physical_keycode`), then read it with `Input.get_axis` / `Input.is_action_just_pressed`
  (`Player` shows both).
- **A test:** `extends GutTest`, methods named `test_*`, `before_each` for setup. Scene tests
  use `add_child_autofree`, `await wait_physics_frames(n)`, and `GutInputSender.new(Input)`
  for input (the class is `GutInputSender`, not `InputSender`, in GUT 9).
- **Hand-writing `.tscn`/`.tres` files is fine** (they are text); run `make import` so Godot
  generates `.uid`/`.import` sidecars, and commit those too.

## Gotchas (learned the hard way)

- `project.godot` comments must use `;` — a `#` line silently truncates the section.
  The editor rewrites this file on save and strips comments; don't rely on them.
- `godot --check-only` is per-file and fails on autoloads; use `make check`
  (`scripts/check_scripts.gd` loads and recompiles everything on the first frame so
  autoloads are available).
- GUT exits 0 when a test *script* fails to parse. `make test` greps the log for
  `Failed to load script|SCRIPT ERROR|Parse Error` to close that hole — keep that line.
- macOS ships GNU make 3.81, which ignores `.SHELLFLAGS`; piped recipe lines set
  `set -o pipefail` explicitly so Godot's exit code isn't swallowed by `tee`.
- BSD `sed` has no `\b`; use plain patterns or Python for bulk edits.
- Godot imports anything it can find in the project, including `build/` output — the
  Makefile drops a `.gdignore` into `build/` and `reports/` for that reason.
- Universal/arm64 macOS exports need `rendering/textures/vram_compression/import_etc2_astc=true`.
- `config/version` must be numeric (`0.0.0` locally); CI stamps the release version.
- Release builds strip `assert()`; validate inputs with `push_error` + a fallback (see `Level._ready`).
- Godot prints **no** level-1 GDScript warnings in headless runs, so a grep-for-warnings
  gate can never work (we tried). A rule you want enforced must be level 2 (error) in
  `project.godot`; there is no "strict mode".
- Never set `process_mode` (or disable a collider) on a `CollisionObject2D` from inside a
  physics callback such as `Area2D.body_entered` — Godot logs an error and GUT fails the
  test. `call_deferred()` it (see `Level._on_strawberry_blob_touched`).
- Don't name a method `_set`, `_get`, `_ready`-style unless you mean the engine virtual:
  `Wallet._set(int)` clashed with `Object._set(StringName, Variant)` and broke every
  dependent script's compile.
- GUT helpers such as `get_signal_emit_count()` return `Variant`; `:=` cannot infer it, so
  write the type (`var n: int = ...`) or the whole test file fails to parse.
- Some tests await real time — walls (1.2 s), strawberry turns (1.7 s), the caught pause
  (0.8 s each), pop text (0.8 s), strawberries patrolling (1.5 s). Add one only when the
  behaviour genuinely takes time, and keep it as short as the physics allows.

## When working with Jason and his son

Explain *why*, not just *what*. Prefer the smallest change that teaches the concept. Offer
to add a test first. Ask before adding dependencies or addons. Keep `docs/` and this file in
sync with any change to commands, structure, or rules.
