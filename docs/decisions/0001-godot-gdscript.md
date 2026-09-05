# 0001. Godot 4 with GDScript

**Status:** Accepted — 2026-08-22

## Context

A father–son game project, developed with Claude Code throughout, that should teach
real industry fundamentals and share builds easily (ideally a browser link). The
industry picture: C++ for AAA (Unreal, in-house engines), C# for most shipped indies
(Unity, MonoGame/FNA), Lua for scripting, Godot for the newest indie wave
(Slay the Spire 2, Brotato, Dome Keeper). Python and TypeScript are not what studios
ship with.

## Decision

Godot **4.7.2** (latest stable at the time) with **GDScript**, static typing enforced.
2D first; the structure is kept dimension-agnostic for a later 3D game.

## Consequences

- Scene/node/signal concepts transfer directly to Unity and other engines.
- Everything is plain text (`.tscn`, `.tres`, `.gd`), so Claude can read and write the
  whole project and the tooling can run headless in CI.
- GDScript reads like Python — good first language; typed mode keeps it honest.
- Free, open source, no account; Web, desktop and mobile exports.
- Cost: GDScript is Godot-only as a language skill; Godot has no 4.x LTS, so the pin
  in `.godot-version` must be bumped deliberately (see `release-and-deploy.md`).

## Alternatives considered

- **Godot + C#** — the most employable indie language, but C# projects cannot export
  to the Web in 4.7, need the .NET SDK, and carry more ceremony for a beginner.
- **Unity + C#** — what Team Cherry and most indies use, but proprietary, account-gated,
  and editor-centric (YAML scenes full of GUIDs) — a poor fit for Claude-assisted work.
- **Unreal + C++/Blueprints** — AAA standard; enormous, slow compile loop, Blueprints
  are binary.
- **Phaser (TypeScript), Pygame (Python)** — matched the installed tooling but are not
  industry game stacks; Vampire Survivors left Phaser for Unity.
- **Rust + Bevy** — interesting, niche, nothing installed, steep for pairing with a child.
