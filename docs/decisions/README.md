# Architecture Decision Records

Short notes that record a significant decision, the reasons behind it, and what it
costs. They exist so that six months from now (or a new collaborator, or Claude) can
tell a deliberate choice from an accident — and change it knowingly.

## Format

[MADR](https://adr.github.io/madr/) minimal, one file per decision,
`NNNN-short-title.md`:

```markdown
# NNNN — Title

- Status: Accepted, YYYY-MM-DD   (or: Superseded by NNNN, YYYY-MM-DD)

## Context and problem statement
What situation or problem made a decision necessary.

## Decision
What we chose — numbered points if there are several.

## Consequences
Good / Bad / Remember: what gets easier, what gets harder, what we must not forget.

## Alternatives considered
One line each: **option** — why not.
```

## Adding one

1. Copy the skeleton above into `docs/decisions/NNNN-title.md` (next number).
2. Keep it under ~30 lines. Link to research, issues, or docs rather than repeating them.
3. If it replaces an earlier decision, set that one's status to *Superseded by NNNN*.
4. Mention it in `CLAUDE.md` if it changes a rule the assistant must follow.

## Index

| # | Decision |
| --- | --- |
| [0001](0001-godot-gdscript.md) | Godot 4 with GDScript |
| [0002](0002-compatibility-renderer-640x360.md) | Compatibility renderer, 640×360 integer-scaled viewport |
| [0003](0003-gut-for-tests.md) | GUT as the test framework |
| [0004](0004-gdtoolkit-pre-commit.md) | gdtoolkit + pre-commit for formatting and lint |
| [0005](0005-single-threaded-web-github-pages.md) | Single-threaded Web export deployed to GitHub Pages |
| [0006](0006-template-repo-rename-script.md) | GitHub template repository with a rename script |
| [0007](0007-text-only-assets-no-lfs.md) | Text-only assets, no Git LFS |
| [0008](0008-release-please-versioning.md) | release-please for versions, changelog and releases |
| [0009](0009-makefile-task-runner.md) | Makefile as the task runner |
| [0010](0010-game-events-bus-and-signal-up.md) | Stateless `GameEvents` bus, signal up / call down, logic in `RefCounted` classes |
| [0011](0011-platformer-motion-and-world-layer.md) | Platformer physics in a `RefCounted`, solid ground on a `world` layer, hand-built levels |
| [0012](0012-humans-money-no-clock.md) | Hand-placed humans, money, no clock; eating everyone ends the level |
| [0013](0013-wallet-owned-by-main.md) | The blob's money lives in a `Wallet` owned by `Main`; it survives level restarts |
