# 0010 — Stateless `GameEvents` bus, signal up / call down, logic in `RefCounted` classes

- Status: Accepted, 2026-08-22

## Context and problem statement

A game has events that cross scene boundaries (a round ending must reach the HUD, the
results screen and whatever owns the flow) and logic that should be testable without a
scene tree. Godot offers autoload singletons, signals, and plain classes; used carelessly,
autoloads become a global grab-bag of state that every scene depends on, and logic welded
to nodes can only be tested by instantiating scenes.

## Decision

1. **Signal up, call down.** A scene emits signals to whoever owns it and calls methods on
   its own children. A child never reaches up the tree (`get_parent()`, `get_node("../..")`).
2. **One stateless autoload, `GameEvents`**, declares the handful of signals that legitimately
   cross screens (`game_started`, `score_changed`, `time_changed`, `game_over`,
   `pause_toggled`). It holds no state and no methods; emitters and listeners are documented
   in `architecture.md`.
3. **Game logic lives in `RefCounted` classes** (`GameRules`, `CoinSpawner`) with their
   dependencies passed in (an RNG, numbers), so unit tests run with no scene tree. Scenes
   are thin: they own a logic object, call it, and forward its signals.

## Consequences

- Good: unit tests are instant and deterministic; scenes stay small; replacing a screen or
  the HUD never touches the rules; new games inherit a pattern that scales to 3D unchanged.
- Good: there is exactly one global thing to learn, and it is a list of signals.
- Bad: a global bus is still a global. Anyone can emit `game_over`; nothing stops a listener
  in a test from reacting to another test's emission (tests use `watch_signals(GameEvents)`
  and short-lived scenes to keep this manageable).
- Trade-off, deliberate: **`Hud` listens on the bus** even though it lives inside the
  `Level` scene, where a direct call would do. It is the template's worked example of a
  bus consumer, and its setters (`set_score`, `set_time`) are public and tested, so a game
  that prefers direct wiring (`_hud.set_score(...)` from `Level`) can switch in two lines.

## Alternatives considered

- **Wire everything through `Main`** (no bus): explicit, but every cross-screen event
  becomes a signal relayed through the flow controller, which grows with each feature.
- **Dependency-injected event objects** (pass an `EventHub` into each screen): testable and
  explicit, but unidiomatic in Godot and harder to explain to a beginner than "the bus".
- **Stateful autoload (`GameState` with score, time, settings)**: the common shortcut; it
  makes every scene depend on global mutable state and the rules untestable in isolation.
