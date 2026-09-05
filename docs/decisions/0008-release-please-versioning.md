# 0008. release-please for versions, changelog and releases

**Status:** Accepted — 2026-08-22

## Context

Versions, a changelog and downloadable builds should come out of normal commits, with
no manual tagging ritual. The version must also be visible in-game
(`application/config/version`).

## Decision

- **Conventional Commits** on `main`.
- `googleapis/release-please-action`, `release-type: simple`: maintains `version.txt`
  and `CHANGELOG.md` in a release PR; merging it tags `vX.Y.Z` and creates the Release.
- A `needs:`-chained job in the same workflow exports Web/Windows/Linux/macOS and
  attaches four zips.
- The version is **stamped into `project.godot` and the macOS preset at export time**
  (`sed` in the workflow). Locally it reads `0.0.0`.

## Consequences

- Zero-effort changelog; version bumps follow the commit prefixes (`fix:` patch,
  `feat:` minor, `!` major).
- Requires the repo setting *Allow GitHub Actions to create and approve pull requests*.
- The export job must be chained with `needs:` — tags pushed by `GITHUB_TOKEN` never
  trigger `on: push: tags` workflows.
- The Godot editor rewrites `project.godot` on save and strips comments, so the
  `# x-release-please-version` marker approach was rejected; stamping at export time has
  no such failure mode.

## Alternatives considered

- **git-cliff** — great changelog generator, but no version bump or release PR; would
  still need manual tagging.
- **Manual tags + hand-written CHANGELOG** — the ritual that never gets done.
- **release-please `extra-files` on `project.godot`** — works until the editor strips
  the marker comment, then silently stops updating.
