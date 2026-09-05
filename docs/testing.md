# Testing

Tests run with [GUT 9.7.1](https://github.com/bitwes/Gut) (vendored in `addons/gut/`),
headless, with one command:

```sh
make test
```

That imports resources, runs every script under `tests/`, writes a JUnit report to
`reports/results.xml`, and exits non-zero if anything failed. CI runs exactly this.

## Running a subset

```sh
make test GUT_ARGS="-gselect=test_game_rules"                                   # one script (substring match)
make test GUT_ARGS="-gselect=test_game_rules -gunit_test_name=test_add_score"   # one test (substring match)
make test GUT_ARGS="-gdir=res://tests/unit -ginclude_subdirs"                   # one folder
```

Anything after `GUT_ARGS=` is passed straight to GUT's command line. Defaults come
from `.gutconfig.json`.

## Two kinds of test

| Kind | Lives in | Needs a scene tree? | Speed | Tests |
| --- | --- | --- | --- | --- |
| **Unit** | `tests/unit/` | no | ~instant | pure logic: `RefCounted` and `Resource` classes |
| **Integration** | `tests/integration/` | yes | frames/seconds | real scenes: input, physics, signals between nodes |

Folders mirror `game/`: `game/core/game_rules.gd` → `tests/unit/core/test_game_rules.gd`.

### Shipped tests

| File | Covers |
| --- | --- |
| `tests/unit/core/test_game_rules.gd` | Score, win, timeout, lose, whole-second ticks, clamping of bad inputs (11 tests) |
| `tests/unit/core/test_coin_spawner.gd` | Positions stay inside the arena, seeded determinism, avoidance radius, exhausted retries |
| `tests/unit/core/test_level_config.gd` | Defaults valid, `level_01.tres` loads, invalid values rejected |
| `tests/integration/player/test_player.gd` | Moves on `move_right`, idle stays still, diagonal not faster, clamped to bounds |
| `tests/integration/coin/test_coin.gd` | Emits `collected` on player overlap, frees itself, ignores a non-player `CharacterBody2D` that *is* overlapping (positive control) |
| `tests/integration/ui/test_hud.gd` | Labels follow `GameEvents`; setters format text |
| `tests/integration/ui/test_results_screen.gd` | Win/loss headings, buttons emit navigation signals |
| `tests/integration/ui/test_title_screen.gd` | Play button emits `start_pressed` |
| `tests/integration/ui/test_pause_menu.gd` | Visibility and tree pause follow `set_paused`, Resume un-pauses, `enabled = false` ignores the action |
| `tests/integration/main/test_main.gd` | Screen flow title → level → results → retry/title, un-pause on every swap, deferred `game_over` |
| `tests/integration/level/test_level_flow.gd` | A whole fast round: spawns up to exactly `max_coins`, `coin_value` scoring, win, timeout, cleanup after the round, player bounds from config, pause |

## Anatomy of a test script

```gdscript
extends GutTest
## One line about what this file covers.

var _rules: GameRules


func before_each() -> void:          # runs before every test_ function
	_rules = GameRules.new(3, 5.0)
	watch_signals(_rules)            # needed before any assert_signal_* on this object


func test_add_score_increments_and_emits_score_changed() -> void:
	_rules.add_score()
	assert_eq(_rules.score, 1)
	assert_signal_emitted_with_parameters(_rules, "score_changed", [1])
```

- Test scripts `extends GutTest` and have **no** `class_name`.
- Test functions start with `test_`; the name should read as the expected behaviour.
- `before_each` / `after_each` reset state so tests are independent and can run in
  any order.
- Static typing is enforced in tests too (`untyped_declaration` is an error), so type
  your locals.

## Asserts used in this repo

| Assert | Use |
| --- | --- |
| `assert_eq(a, b)`, `assert_ne` | exact equality (ints, strings, Vector2, enums) |
| `assert_true(x)`, `assert_false(x)` | booleans |
| `assert_almost_eq(a, b, tolerance)` | floats |
| `assert_gt`, `assert_lt`, `assert_gte`, `assert_lte` | comparisons |
| `assert_not_null(x)` | a `load()` worked |
| `watch_signals(obj)` then `assert_signal_emitted(obj, "name")` | a signal fired |
| `assert_signal_emitted_with_parameters(obj, "name", [args])` | ...with these args (checks the most recent emission) |
| `assert_signal_emit_count(obj, "name", n)` | exactly n times |
| `assert_signal_not_emitted(obj, "name")` | never fired |

Every assert takes an optional trailing message — use it when the failure would
otherwise be cryptic (`"point %s inside %s" % [p, inner]`).

## Testing scenes

```gdscript
const PLAYER_SCENE := preload("res://game/player/player.tscn")

func before_each() -> void:
	_player = PLAYER_SCENE.instantiate()
	_player.position = Vector2(100, 100)
	add_child_autofree(_player)        # added to the tree, freed after the test
```

- `add_child_autofree(node)` puts the node in the tree and frees it in teardown. Use
  it for everything you instantiate; orphaned nodes show up as "Orphans" in the run
  summary.
- Physics (overlaps, `move_and_slide`) only happens on physics frames:
  `await wait_physics_frames(3)`. Timers and `_process` need real time:
  `await wait_seconds(0.3)`. Keep waits short — the level test uses a 0.5 s round.
- Signals from the autoload bus: `watch_signals(GameEvents)` **before** adding the
  scene, because `Level._ready` emits immediately. GUT clears watched signals between
  tests.
- Make randomness deterministic: `Level.rng_seed = 42` in the test.

## Testing input

GUT's input helper is `GutInputSender` (in GUT 9 it is *not* called `InputSender`):

```gdscript
var _sender: GutInputSender


func before_each() -> void:
	_sender = GutInputSender.new(Input)


func after_each() -> void:
	_sender.release_all()
	_sender.clear()


func test_moves_right_while_move_right_held() -> void:
	_sender.action_down("move_right")
	await wait_physics_frames(10)
	assert_gt(_player.position.x, START.x)
```

Events sent through `Input` are delivered on the next frame. The pause test cannot
wait for a frame — once the tree is paused, the awaiter may never resume — so it forces
delivery synchronously:

```gdscript
_sender.action_down("pause")
Input.flush_buffered_events()
assert_true(get_tree().paused)
```

and `after_each` sets `get_tree().paused = false`.

## What "passing" means

`make test` fails when:

1. any assert fails (GUT exits 1), **or**
2. any test *script* fails to parse or load.

The second rule exists because GUT itself exits 0 when a test file cannot be loaded:
it reports "All tests passed" for the files it *could* run and prints an error for the
rest. During setup of this repo, two integration files failed to parse and the suite
was still green. The `test` target greps its log for `Failed to load script`,
`SCRIPT ERROR`, `Parse Error` and `[GUT ERROR]` to close that hole, and it also fails when
`reports/results.xml` is missing or reports zero tests — GUT exits 0 in that case too. `make check` catches the same
thing earlier by compiling every script under `game/` and `tests/`.

## Caveats

- Godot prints no level-1 warnings headlessly, so the typing rules this repo cares about
  are level 2 (errors) in `project.godot`; `make check` and `make test` both catch them.
  GUT additionally silences warnings while it loads test scripts — another reason only
  errors count.
- `double()`, `stub()`, `spy()` and `partial_double()` are available for mocking. The
  shipped tests do not need them — logic classes take their dependencies as arguments
  instead, which is usually simpler.
- The in-editor GUT panel (bottom dock; plugin enabled in `project.godot`) runs the
  same tests with a click, which is a nicer loop while writing a test. The command
  line is the source of truth.
- Reports land in `reports/` (git-ignored). The JUnit XML is what CI uploads.

## Writing your first new test

1. Find or create the matching file under `tests/unit/` or `tests/integration/`.
2. Write the test name as a sentence: `test_<thing>_<does_what>_<when>`.
3. Run just that file until it passes: `make test GUT_ARGS="-gselect=<file>"`.
4. Run `make ci` before you commit.
