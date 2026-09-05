# 0006. GitHub template repository with a rename script

**Status:** Accepted — 2026-08-22

## Context

Each new game should start from this scaffolding with its own history and name, and
stay easy to navigate for a child — one game per repository.

## Decision

- Mark the repo as a **GitHub template**. "Use this template" gives a fresh single-commit
  history per game.
- `scripts/new_game.py` (Python, stdlib only) rewrites the example's names
  (`Weird World` / `WeirdWorld` / `weird_world` / `weird-world` / `weirdworld`), the macOS bundle
  id and the template's GitHub URL across tracked files, resets version and changelog,
  and deletes `TEMPLATE.md`. It skips `addons/` and binaries. `--dry-run` previews.
- `TEMPLATE.md` is the after-creation checklist (Pages source, Actions PR permission,
  removing the example).
- The example game's code stays in the new repo as a working reference until the
  author deletes it.

## Consequences

- Upstream improvements do not flow to existing games automatically (no fork link).
  Cherry-pick by hand when worth it.
- GitHub templates cannot contain Git LFS files (see 0007).
- The rename is a plain string replace with input validation and a dirty-worktree guard.
  CI unit-tests it (`scripts/test_new_game.py`) and runs a real rename on a temporary copy,
  asserting that no template identifier survives, so it cannot rot silently.

## Alternatives considered

- **Plain clone + `rm -rf .git`** — works, but no "Use this template" button and no
  guard against pushing back to the template by accident.
- **Monorepo of games sharing a core package** — better reuse, but more structure than
  a kid should have to navigate, and Godot has no first-class package concept.
- **Self-deleting bootstrap workflow that renames on first push** — clever, but magic;
  an explicit script the author runs and reads is more teachable.
