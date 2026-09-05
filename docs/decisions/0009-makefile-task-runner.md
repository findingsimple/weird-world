# 0009. Makefile as the task runner

**Status:** Accepted — 2026-08-22

## Context

Every task (import, check, lint, test, run, export, serve) needs one memorable entry
point that works identically for a developer, a child, Claude, and CI. Candidates:
`make`, `just`, a `Taskfile`, or shell scripts.

## Decision

A single **`Makefile`** with `.PHONY` targets and a self-documenting `make help`.
The Godot version is read from `.godot-version`; target dependencies encode that
`test`/`check`/`export-*` need `import` first. CI calls the same targets.

## Consequences

- Zero install: `make` ships with macOS (Xcode CLT) and every Linux CI image.
- `make help` is the discoverable command list; `CLAUDE.md` mirrors it.
- macOS ships **GNU make 3.81**, which silently ignores `.SHELLFLAGS` (added in 3.82).
  Piped recipe lines therefore set `set -o pipefail` explicitly, otherwise
  `godot ... | tee` would hide Godot's exit code — this bit us once during setup.
- Tabs in recipes are a classic footgun; `.editorconfig` pins tabs for `Makefile`.
- Anything non-trivial lives in `scripts/` (`setup.sh`, `check_scripts.gd`,
  `new_game.py`) rather than in recipe lines.

## Alternatives considered

- **`just`** — cleaner syntax, no tab issue, used by the best-known Godot template; but
  it is one more tool to install (`brew install just`) and one more thing to explain.
- **Taskfile (Go)** — YAML, nice cross-platform story; same install cost, less common
  in Godot projects.
- **Bare shell scripts** — no dependency graph (`test` would not auto-import), no
  `help`, and the zsh/bash word-splitting differences are a recurring trap.
