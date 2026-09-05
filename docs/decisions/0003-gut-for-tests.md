# 0003. GUT as the test framework

**Status:** Accepted — 2026-08-22

## Context

Tests must run headless from `make` and CI, produce JUnit XML, cover both pure logic and
real scenes (input, physics, signals), and be simple enough that a beginner can read a
test and write one. Two frameworks are current for Godot 4: GUT and gdUnit4.

## Decision

**GUT 9.7.1**, vendored unchanged in `addons/gut/`, run via
`godot --headless -s addons/gut/gut_cmdln.gd` with `.gutconfig.json`.

## Consequences

- One-line CLI, config in one JSON file, JUnit via `-gjunit_xml_file`.
- `assert_eq(a, b)`-style API — readable for a kid; `GutInputSender`, `wait_physics_frames`
  and `add_child_autofree` cover scene tests.
- GUT publishes one release line per Godot minor (9.7.x ↔ 4.7), so a Godot bump means
  replacing `addons/gut/`.
- GUT exits 0 when a test *script* fails to parse, and when zero tests run; `make test`
  greps the log and checks `reports/results.xml` to fail on both (see `testing.md`).
- GUT silences GDScript warnings while loading tests; the rules we care about are
  level-2 errors, which survive that.
- The editor plugin is enabled for the in-editor panel; the CLI is the source of truth.

## Alternatives considered

- **gdUnit4 6.2.1** — richer (fluent asserts, scene runner, mocks, flaky retry, official
  GitHub Action) but runs through `runtest.sh` + a `GODOT_BIN` env var, requires Godot
  ≥ 4.5 with each major dropping older engines, and its fluent API is more to learn.
  A fine choice for a larger team; revisit if GUT's assert style becomes limiting.
- **No framework / ad-hoc scripts** — no reports, no assertions, no CI signal.
