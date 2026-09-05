# 0006. GitHub template repository with a rename script

**Status:** Deprecated — 2026-09-05. This is the template's decision, kept for history.
Weird World *was* created this way; the script and its CI checks were then removed from
this repo (they live on in [game-scaffolding](https://github.com/findingsimple/game-scaffolding)).

## Context

Each new game should start from the scaffolding with its own history and name, and
stay easy to navigate for a child — one game per repository.

## Decision

- Mark the template repo as a **GitHub template**. "Use this template" gives a fresh
  single-commit history per game.
- `scripts/new_game.py` (Python, stdlib only) rewrites the example game's names
  (Coin Dash and its `snake_case` / `kebab-case` / `PascalCase` forms), the macOS bundle
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
  In the template, CI unit-tests it and runs a real rename on a temporary copy. Those
  checks are meaningless once the rename has happened — in Weird World they failed on the
  first push because the script had rewritten the very identifiers the check greps for —
  so a new game should delete the script and the two CI steps right after renaming.
- The blind string replace also rewrites prose *about* the template (this ADR's own
  list of example names came out as "Weird World", and the README kept calling the repo a
  template). Read the docs after renaming; the script cannot know what is a name and what
  is a sentence about a name.

## Alternatives considered

- **Plain clone + `rm -rf .git`** — works, but no "Use this template" button and no
  guard against pushing back to the template by accident.
- **Monorepo of games sharing a core package** — better reuse, but more structure than
  a kid should have to navigate, and Godot has no first-class package concept.
- **Self-deleting bootstrap workflow that renames on first push** — clever, but magic;
  an explicit script the author runs and reads is more teachable.
