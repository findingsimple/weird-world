# Weird World

[![CI](https://github.com/findingsimple/weird-world/actions/workflows/ci.yml/badge.svg)](https://github.com/findingsimple/weird-world/actions/workflows/ci.yml)
[![Web](https://github.com/findingsimple/weird-world/actions/workflows/web.yml/badge.svg)](https://github.com/findingsimple/weird-world/actions/workflows/web.yml)
[![Release](https://github.com/findingsimple/weird-world/actions/workflows/release.yml/badge.svg)](https://github.com/findingsimple/weird-world/actions/workflows/release.yml)

A platformer where a hungry blob eats humans for money, stomps ghost strawberries and
takes on the ghost cake boss. Designed by a kid, built with his dad and Claude Code in
**Godot 4.7.2 + GDScript**. The design is in [docs/gdd.md](docs/gdd.md); the original
concept book is in [docs/design/](docs/design/).

**Where it's at:** Milestone 2 — the blob runs and jumps around one hand-built screen and
eats every human on it for money. No clock. Next: ghost strawberries (Milestone 3).

**Play in the browser:** <https://findingsimple.github.io/weird-world/> — rebuilt and
published by the Web workflow on every push to `main`. Or `make run` for a native window.

## Why this exists

Making a game with a kid is the fun part. Setting up a toolchain that catches mistakes,
runs the tests, builds for the browser and publishes releases is not — and it's the part
that quietly decides whether a project survives its third weekend. This repo was created
from [game-scaffolding](https://github.com/findingsimple/game-scaffolding), a template
that does that part once, properly, so the game started from a known-good baseline.

It is also built for **Claude-assisted development**: everything is text, every rule is
written down in [CLAUDE.md](CLAUDE.md), and every check runs from one command.

## Quick start (macOS)

```sh
git clone git@github.com:findingsimple/weird-world.git
cd weird-world
make setup     # installs Godot 4.7.2, gdtoolkit, pre-commit, export templates (asks first)
make run       # play Weird World
make ci        # version + lint + compile check + tests — exactly what CI runs
```

Want to start *another* game like this one? Use the
[game-scaffolding](https://github.com/findingsimple/game-scaffolding) template, not this repo.

## Commands

| Command | What it does |
|---|---|
| `make help` | List every target |
| `make setup` | One-shot developer setup (idempotent, prompts before installing) |
| `make run` | Run the game in a window |
| `make ci` | `version` + `lint` + `check` + `test` — exactly what CI's test job runs. CI's lint job also runs `pre-commit run --all-files`; do that too before a PR |
| `make version` | Fail unless the installed Godot matches `.godot-version` |
| `make import` | Rebuild Godot's `.godot/` cache (after clone, or when assets change) |
| `make lint` / `make format` | `gdformat --check` + `gdlint` / rewrite files with `gdformat` |
| `make check` | Load and compile every script and scene under `game/` and `tests/` (typing rules are compile errors here) |
| `make test` | GUT test suite, headless; JUnit XML in `reports/results.xml`; fails if a test file won't parse or no tests ran |
| `make test GUT_ARGS="-gselect=test_game_rules"` | Run one test script (add `-gunit_test_name=...` for one test) |
| `make export-web` / `make serve-web` | Build the browser version into `build/web/` and serve it on <http://localhost:8060> |
| `make export-all` | Web + Windows + Linux + macOS builds into `build/` |
| `make clean` | Delete `.godot/`, `build/`, `reports/` |

`make help` is generated from the Makefile and is the authoritative list.

## What's inside

```
game/                 The game
  main.tscn/.gd       Screen flow: title → level → results
  core/               Pure logic + data: PlatformerMotion, GameRules, Wallet, LevelConfig, GameEvents bus
  player/             The blob: a CharacterBody2D that asks PlatformerMotion where to go
  human/              A human: an Area2D that gets eaten for money
  level/              The hand-built level: floor, platforms, walls, humans, the rules and HUD
  ui/                 HUD, title, results, pause menu, shared theme
tests/
  unit/               Logic tests — no scene tree (PlatformerMotion, GameRules, Wallet, LevelConfig)
  integration/        Scene tests — real physics, real input (Player, Human, Level, UI, screen flow)
addons/gut/           GUT 9.7.1 test framework (vendored, never edited)
scripts/              setup.sh (developer setup), check_scripts.gd (the compile check)
docs/                 Design doc and concept book, guides, glossary, architecture decisions
.github/workflows/    ci.yml (lint+test), web.yml (GitHub Pages), release.yml (release-please + builds)
```

Tooling, in one line each:

- **Godot 4.7.2** — pinned in `.godot-version`; `make version` enforces it.
- **GUT** — unit + integration tests, headless, JUnit output. `make test` also fails if a test
  *file* fails to parse or if no tests ran (GUT alone does neither).
- **gdtoolkit** (`gdformat`, `gdlint`) via **pre-commit** — formatting and lint on every commit.
- **Static typing enforced** — untyped declarations and unsafe (untyped) property/method access are compile errors (`project.godot` → `[debug]`).
- **GitHub Actions** — CI on every PR; Web build to GitHub Pages on every push to `main`;
  **release-please** turns conventional commits into versioned releases with downloadable builds.
- **Exports** — Web (single-threaded, no special headers needed), Windows, Linux, macOS (ad-hoc signed).

## Documentation

Start at [docs/README.md](docs/README.md). Highlights:

- [Getting started](docs/getting-started.md) · [Architecture](docs/architecture.md) ·
  [Style guide](docs/style-guide.md) · [Testing](docs/testing.md) ·
  [Release & deploy](docs/release-and-deploy.md)
- [Working with Claude](docs/working-with-claude.md) — how we pair with Claude Code on this repo
- [Your first change](docs/first-change.md) — a tutorial for new (and young) developers
- [Glossary](docs/glossary.md) · [Game design doc](docs/gdd.md) · [GDD template](docs/gdd-template.md) ·
  [Decisions (ADRs)](docs/decisions/README.md) — why Godot, why GUT, why single-threaded web, …

## Licence

Code is [MIT](LICENSE). Example assets are CC0 — see [ASSETS.md](ASSETS.md).
