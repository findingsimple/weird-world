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
make test GUT_ARGS="-gselect=test_game_rules -gunit_test_name=test_money_adds_up"   # one test (substring match)
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
| `tests/unit/core/test_game_rules.gd` | Money adds up, humans count down, the last human wins exactly once, nothing after the win, negative values, clamping (9 tests) |
| `tests/unit/core/test_level_config.gd` | Defaults valid, `level_01.tres` loads with the designer's `human_value`, zero rejected |
| `tests/unit/core/test_platformer_motion.gd` | Run speed and input clamping, gravity per step, fall cap reached and held, jump only from the floor, landing zeroes vertical speed, `configure()`, nonsense tunables clamped (13 tests) |
| `tests/integration/player/test_player.gd` | Falls and lands on a `world`-layer floor, idle stays still, runs on `move_right` at `speed`, jumps on `jump`, no double jump, non-default tunables reach the motion even after `_ready` |
| `tests/integration/human/test_human.gd` | Emits `eaten` on player overlap, frees itself, fidgets the sprite but never the hitbox, ignores a non-player `CharacterBody2D` that *is* overlapping (positive control) |
| `tests/integration/ui/test_hud.gd` | Money and humans-left labels follow `GameEvents`; setters format text |
| `tests/integration/ui/test_results_screen.gd` | Win/loss headings, buttons emit navigation signals |
| `tests/integration/ui/test_title_screen.gd` | Play button emits `start_pressed` and has focus; the subtitle describes the current controls |
| `tests/integration/ui/test_pause_menu.gd` | Visibility and tree pause follow `set_paused`, Resume un-pauses, Title screen emits `quit_pressed` (and decides nothing itself), `enabled = false` ignores the action |
| `tests/integration/main/test_main.gd` | Screen flow title → level → results → retry/title, un-pause on every swap, deferred `game_over` |
| `tests/integration/level/test_level_flow.gd` | A whole level: the designer's human count (pinned once), HUD labels read through the level, every human paid the config's value, eating pays and emits exactly once, eating everyone wins exactly once and disables pausing, not won with one left, an empty level ends at once, a stray node under `Humans` is ignored, quitting from the pause menu ends the level as `LOST` with the money so far, pause; the world: player drops in and lands, every `World` child is solid, walls hold, every piece of ground is within one jump of a lower one, every human stands on something |

## Anatomy of a test script

```gdscript
extends GutTest
## One line about what this file covers.

var _rules: GameRules


func before_each() -> void:          # runs before every test_ function
	_rules = GameRules.new(3)
	watch_signals(_rules)            # needed before any assert_signal_* on this object


func test_eating_a_human_pays_and_emits_money_changed() -> void:
	_rules.eat_human(2)
	assert_eq(_rules.money, 2)
	assert_signal_emitted_with_parameters(_rules, "money_changed", [2])
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
- A `CharacterBody2D` with gravity needs something to stand on, or it falls out of the
  test: `test_player.gd`'s `_make_ground()` builds a `StaticBody2D` on the `world` layer
  (bit value 4) under the player, and `_land()` waits for the landing before asserting.
- Physics (overlaps, `move_and_slide`) only happens on physics frames:
  `await wait_physics_frames(3)`. Timers and `_process` need real time:
  `await wait_seconds(0.3)`. Keep waits short — the only real-time wait in the suite is the
  level test's wall check, 1.2 s in total.
- `wait_physics_frames(n)` is *about* n steps of your node, not exactly n — GUT's counter
  and your node run in different slots of a step. To measure something per frame, bracket
  the wait with `Engine.get_physics_frames()` and divide by the steps that really ran
  (see `test_tunables_drive_the_motion_even_after_ready`).
- Signals from the autoload bus: `watch_signals(GameEvents)` **before** adding the
  scene, because `Level._ready` emits immediately. GUT clears watched signals between
  tests.
- GUT fails a test on any `push_error` or engine error it did not expect. When the error
  *is* the behaviour under test (a misconfigured level), claim it:
  `assert_push_error("no humans")` — the message may be a substring.
- Nothing in the game is random any more. If something becomes random, inject the RNG the
  way `PlatformerMotion` takes its tunables, so a test can seed it.

## Testing input

GUT's input helper is `GutInputSender` (in GUT 9 it is *not* called `InputSender`):

```gdscript
var _sender: GutInputSender


func before_each() -> void:
	_sender = GutInputSender.new(Input)


func after_each() -> void:
	_sender.release_all()
	_sender.clear()


func test_runs_right_while_move_right_held() -> void:
	await _land()
	var resting := _player.position
	_sender.action_down("move_right")
	await wait_physics_frames(10)
	assert_gt(_player.position.x, resting.x)
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
