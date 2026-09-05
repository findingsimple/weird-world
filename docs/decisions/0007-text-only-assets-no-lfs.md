# 0007. Text-only assets in the template, no Git LFS

**Status:** Accepted — 2026-08-22

## Context

The example game needs sprites and an icon. Binary assets bloat git history and are
opaque to Claude; Git LFS is the usual answer, but GitHub template repositories cannot
include LFS-tracked files.

## Decision

- All shipped art is hand-written **SVG** (`icon.svg`, `player.svg`, `coin.svg`), which
  Godot imports natively. The UI theme uses flat `StyleBoxFlat`s and the engine's
  default font — no font files.
- No `.gitattributes` LFS filters. `check-added-large-files` (512 KB) in pre-commit
  flags accidental binaries.
- Real games add binary assets per `ASSETS.md`: CC0 packs (Kenney) beside the scene
  that uses them, with a credits table. Code is MIT; bundled art is CC0.

## Consequences

- Everything in the template is diffable and editable in a text editor — a kid can
  change a colour by editing a hex value (`first-change.md`, exercise 2).
- The art is deliberately placeholder-grade; replacing it is a one-line exercise in the
  docs.
- Nearest-neighbour filtering makes SVGs look like pixel art at integer scale; set
  `svg/scale` in the `.import` if a sprite needs to be rasterised larger.
- A game with many large assets should add LFS *after* leaving the template (LFS must
  be configured before the first commit of those files).

## Alternatives considered

- **Bundle a Kenney CC0 pack** — tempting, but PNGs in the template add binary churn
  and downstream projects inherit assets they will replace.
- **Git LFS from the start** — forbidden for template repos; also adds setup friction
  on every clone.
- **Procedurally drawn placeholders (`_draw`)** — no asset pipeline to learn from.
