# weird-world

[![CI](https://github.com/findingsimple/weird-world/actions/workflows/ci.yml/badge.svg)](https://github.com/findingsimple/weird-world/actions/workflows/ci.yml)
[![Web](https://github.com/findingsimple/weird-world/actions/workflows/web.yml/badge.svg)](https://github.com/findingsimple/weird-world/actions/workflows/web.yml)
[![Release](https://github.com/findingsimple/weird-world/actions/workflows/release.yml/badge.svg)](https://github.com/findingsimple/weird-world/actions/workflows/release.yml)

A professional starting point for 2D games in **Godot 4.7 + GDScript**, built to be
cloned for every new game: tests, lint, compile checks, CI, browser builds, releases,
and documentation are all wired up on day one. It ships with a small example game, with tests for
its rules, physics, UI and screen flow, — **Weird World** — that shows every convention in action.

**Play the example:** <https://findingsimple.github.io/weird-world/>

## Why this exists

Making a game with a kid is the fun part. Setting up a toolchain that catches mistakes,
runs the tests, builds for the browser and publishes releases is not — and it's the part
that quietly decides whether a project survives its third weekend. This repo does that
part once, properly, so each new game starts from a known-good baseline.

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

Starting a *new game* from this template? Read [TEMPLATE.md](TEMPLATE.md).

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
game/                 The example game (delete or replace when you start yours)
  main.tscn/.gd       Screen flow: title → level → results
  core/               Pure logic + data: GameRules, CoinSpawner, LevelConfig, GameEvents bus
  player/ coin/       One folder per feature: scene + script + sprite together
  level/              The round: owns the rules, spawns coins, forwards signals
  ui/                 HUD, title, results, pause menu, shared theme
tests/
  unit/               Logic tests — no scene tree (GameRules, CoinSpawner, LevelConfig)
  integration/        Scene tests — real physics, real input (Player, Coin, HUD, Level flow)
addons/gut/           GUT 9.7.1 test framework (vendored, never edited)
scripts/              setup.sh, new_game.py (rename the template), check_scripts.gd
docs/                 Guides, tutorials, glossary, GDD template, architecture decisions
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
- [Glossary](docs/glossary.md) · [GDD template](docs/gdd-template.md) ·
  [Decisions (ADRs)](docs/decisions/README.md) — why Godot, why GUT, why single-threaded web, …

## Licence

Code is [MIT](LICENSE). Example assets are CC0 — see [ASSETS.md](ASSETS.md).
