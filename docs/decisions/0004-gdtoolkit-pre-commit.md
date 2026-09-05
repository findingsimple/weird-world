# 0004. gdtoolkit + pre-commit for formatting and lint

**Status:** Accepted — 2026-08-22

## Context

A consistent style should be enforced by tools, not reviews, and the same checks must
run locally and in CI. Godot has no built-in formatter or linter for GDScript.

## Decision

- **gdtoolkit 4.5.0** (`gdformat`, `gdlint`), installed with `uv tool install "gdtoolkit==4.5.0"` — the same pin as the
  pre-commit `rev` and the CI job, so every environment formats identically.
  Config in `gdlintrc` (defaults plus `max-public-methods: 40` for test files and
  excluded `addons/`, `.godot/`, `build/`, `reports/`).
- **pre-commit** with the official `Scony/godot-gdscript-toolkit` hooks plus the standard
  hygiene hooks (whitespace, EOF, YAML/JSON, merge markers, large files, line endings).
  `exclude: ^addons/`.
- `make lint` / `make format` wrap the same tools; CI runs `pre-commit/action`.
- Engine-level checks: `untyped_declaration = 2` and the four `unsafe_*` checks = 2
  (errors), enforced by `make check` and `make test`. Level-1 warnings were tried first
  and found to be invisible in headless runs, so they are not used as a gate.
- `shellcheck` and `ruff` hooks cover `scripts/` — the two files that run with the
  developer's full privileges.

## Consequences

- Formatting is never discussed; `gdformat` is uncompromising (tabs, 100 cols).
- Style arguments are settled in `gdlintrc` once.
- gdtoolkit's last release was 2025-10; new GDScript syntax in a future Godot may need
  a newer release or an inline `# gdlint:ignore`.
- Godot has no global "warnings as errors" switch, so each warning level is set
  individually in `project.godot`.

## Alternatives considered

- **GDQuest's Rust formatter** — fast and has an editor addon, but no linter and less
  adopted in CI.
- **Editor-only checks** — not reproducible in CI, invisible to Claude.
- **Just engine warnings** — no formatting, no naming rules.
