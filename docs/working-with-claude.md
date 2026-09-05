# Working with Claude on this project

This repo is built to be developed *with* an AI assistant — by an adult, by a kid, or
by both at the same keyboard. The tooling (types, lint, tests, `make ci`) is there so
that Claude's changes can be checked, not just trusted. This page is the playbook.

## The session recipe

1. **Say the goal in one sentence.** "Make humans on platforms worth more than ones on the floor."
2. **Ask for a plan first.** "Before changing anything, tell me which files you would
   touch and why." Read it together. Push back if it touches more than it needs to.
3. **One small change at a time.** A change that fits on one screen is a change you
   can understand. Big ideas become a list of small changes.
4. **Run `make ci`.** Lint, compile check, tests. Green or it is not done.
5. **Read the diff together.** `git diff`. Ask the kid: what changed? why? Ask
   Claude: "explain this diff line by line."
6. **Commit with a conventional message.** `feat: humans on platforms pay double`. That
   message ends up in the changelog.

Repeat. Ten small loops beat one big one.

## Prompts that work

| Say | Why it works |
| --- | --- |
| "Explain `game/level/level.gd` like I'm ten." | Forces a simple mental model before anything changes |
| "What are three ways to add an enemy, and which is simplest?" | You choose; Claude does not decide the design for you |
| "Add a failing test for X first, then make it pass." | The test is the spec; you can read it even if you can't read the code yet |
| "Why did you do it that way instead of ...?" | *Why* is the part you learn from; *what* you can see in the diff |
| "Only change `human.gd`. Tell me if that is not enough." | Scope guards keep the change reviewable |
| "Run `make ci` and show me the result." | Verification is part of the task, not a follow-up |
| "Is there anything in this change a careful reviewer would question?" | Invites the assistant to surface trade-offs it glossed over |
| "Update `CLAUDE.md` if this changed a rule or a command." | Keeps the assistant's instructions true for next time |

## Verify, don't trust

- **Run it.** `make run` after every change that touches the game. Play the thing.
- **Read the test.** If Claude says "tests pass," open the test and check that it
  asserts what you care about. A test that asserts nothing also passes.
- **Break it on purpose.** Change a number the wrong way and confirm the test fails.
  (The repo's `GameRules` tests were proven this way.)
- **Ask for the source.** "Which Godot doc says that?" Godot's API is big; guessing a
  method name is the most common mistake. `make check` catches the compile errors.

## Keep `CLAUDE.md` honest

`CLAUDE.md` at the repo root is what Claude reads before every session: the commands,
the rules, the architecture summary, the gotchas. When you change a rule — a new
`make` target, a new folder convention, a decision in `docs/decisions/` — update it in
the same commit. An out-of-date `CLAUDE.md` produces confident, wrong changes.

## Things not to do

- **Huge vague asks.** "Make a platformer" produces a pile of code nobody understands.
  "Make the player jump when I press space" is a session.
- **Accepting code you can't explain.** If neither of you can say what a function
  does, ask for a simpler version or a comment — or delete it.
- **Skipping tests because it's "just a tweak."** Tweaks are where bugs live. The
  test takes a minute; the bug hunt takes an evening.
- **Editing `addons/`.** Third-party code; it gets replaced on upgrade.
- **Letting Claude commit without reading the message.** The message is history.

## Let the kid drive

The person learning should be the one typing — the prompts *and* the `make` commands.
Narrate what you would do, then let them do it. When Claude explains something, ask
the kid to explain it back. When something breaks, resist fixing it: ask "what does
the error say?" and read it together. Errors are the best teacher in this whole
setup; the tooling exists to make them quick and safe.

## Starter projects

Sized for this codebase. Each one is a few sessions at most.

**Tiny (one sitting)**
- Make the blob faster, or jump higher (`speed`, `jump_velocity` in `game/player/player.gd`).
- Redraw the blob or the humans (`*.svg` files — they are text).
- Pay more per human (`game/core/levels/level_01.tres`), or place more humans (`level.tscn`).
- Change the win text on the results screen.

**Small (a weekend)**
- A second kind of human worth more — a chef? — with its own SVG and `value`. Tests:
  `test_human`, the money total in `test_level_flow`.
- A sound when a human is eaten (`AudioStreamPlayer`, a CC0 `.ogg`, update `ASSETS.md`).
- A best-money line on the title screen (save with `FileAccess` in `user://`).
- A second level: a new scene with its own platforms and humans, chosen on `Main`.

**Medium (several sessions)**
- The ghost strawberry (Milestone 3 in `docs/gdd.md`): walks, turns at edges, stomp it
  from above, lose a life if it touches your side. New `GameRules` lives, a `LOST`
  outcome that actually happens, new bus signal? Design it first — fill in the GDD
  before the code.
- Levels: a second level scene, a level-select screen, `Main` picking the next
  scene after a win.
- A 3D version of the level, reusing `game/core/` untouched (see
  `architecture.md` → Going 3D).

Write the idea in the GDD template first, even two lines. Then ask for the plan.
