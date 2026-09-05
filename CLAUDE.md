# CLAUDE.md

Guidance for Claude Code when working in this repository. Humans: this is also the
shortest accurate description of how the project works — keep it true.

## What this is

**Weird World**, a Godot **4.7.2** + **GDScript** platformer: a hungry blob eats humans
for money, stomps ghost strawberries and takes on the ghost cake boss. The design is in
`docs/gdd.md` (milestones included); the concept book is `docs/design/`. Created from the
`game-scaffolding` template, whose Coin Dash example (coins, clock, spawner) is still in
place until Milestone 2 replaces coins with humans. Full docs live in `docs/`; start with
`docs/README.md`, `docs/architecture.md`, `docs/style-guide.md`, `docs/testing.md`.

## Commands (all via the Makefile — CI's test job runs `make ci` verbatim)

```sh
make ci                                   # version + lint + check + test. Run before finishing any task.
pre-commit run --all-files                # hygiene hooks CI's lint job also runs (git hook runs them per commit)
make lint                                 # gdformat --check + gdlint on game/ tests/ scripts/
make format                               # rewrite files with gdformat (tabs, 100 cols)
make check                                # load + compile every script/scene; typing rules are compile errors
make test                                 # GUT suite, headless; fails on parse errors or zero tests; JUnit -> reports/results.xml
make test GUT_ARGS="-gselect=test_game_rules -gunit_test_name=test_add_score"   # one test
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
   classes are `PascalCase`, signals are past tense (`coin_collected`), private members
   start with `_`, signal handlers are `_on_<source>_<signal>`.
3. **Member order** is enforced by gdlint: `@tool` → `class_name` → `extends` → `##` docs →
   signals → enums → consts → static vars → `@export` → public vars → private vars →
   `@onready` public → `@onready` private → methods. `gdformat` handles whitespace.
4. **Logic lives in `RefCounted` classes** (`GameRules`, `CoinSpawner`, `PlatformerMotion`)
   with no scene dependencies so it can be unit-tested. Scenes are thin and integration-tested.
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
  It swaps the single child of `$Screen` and always un-pauses on a swap.
- `Level` builds a `GameRules` from a `LevelConfig` resource (`game/core/levels/*.tres`),
  ticks it every frame, spawns `Coin`s on a `Timer` using `CoinSpawner` (RNG injected;
  `rng_seed` export for determinism), and forwards rules signals to `GameEvents`.
- `Player` (`CharacterBody2D`, layer 1, mask 4) reads `move_left/right` + `jump`, gets its
  velocity from `PlatformerMotion` (`RefCounted`: run, gravity, jump, fall cap — unit-tested)
  and `move_and_slide()`s against `StaticBody2D` ground on layer 3 `world`, hand-placed
  under `Level`'s `World` node. Anything the blob should stand on must be on `world`.
- `Coin` (`Area2D`, layer 2, mask 1) emits `collected` when a `Player` overlaps, then frees
  itself. `Level` turns that into `GameRules.add_score`.
- `Hud` listens to `GameEvents.score_changed` / `time_changed`. `PauseMenu` runs with
  `process_mode = Always`, handles the `pause` action, and toggles `get_tree().paused`.
- Input actions (`move_left/right`, `jump`, `pause`) are in `project.godot` → `[input]`.
  Physics layers: 1 `player`, 2 `pickups`, 3 `world` (see `docs/architecture.md`).
- Rendering: `gl_compatibility`, 640×360 viewport, integer scaling, nearest filtering,
  pixel snap — required for the Web export and right for pixel art.

## How to add things

- **A new scene/feature:** folder under `game/<feature>/` with `feature.tscn`,
  `feature.gd` (`class_name Feature`), assets beside them. Expose tunables with `@export`.
  Add `tests/integration/<feature>/test_feature.gd`. Wire it into `Level` or `Main`.
- **A new rule:** put it in a `RefCounted` class in `game/core/`, unit-test it in
  `tests/unit/core/`, then have a scene call it.
- **A new level:** duplicate `game/core/levels/level_01.tres`, tweak values, assign it to
  `Main`'s `Level Config` export.
- **A new platform:** in `game/level/level.tscn`, duplicate `LowPlatform` under `World`, set
  its `position`, keep `collision_layer = 4` (`world`) and `collision_mask = 0`, and resize the
  `RectangleShape2D` and the `ColorRect` together. `test_level_flow` checks every child of
  `World` is solid and that each platform step is within a jump, so `make test` tells you if
  you put one out of reach.
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
- Two tests await real time (`test_level_flow.gd` timeout/spawn cases); keep durations short.

## When working with Jason and his son

Explain *why*, not just *what*. Prefer the smallest change that teaches the concept. Offer
to add a test first. Ask before adding dependencies or addons. Keep `docs/` and this file in
sync with any change to commands, structure, or rules.
