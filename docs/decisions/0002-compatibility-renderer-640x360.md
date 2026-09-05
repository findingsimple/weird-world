# 0002. Compatibility renderer, 640×360 integer-scaled viewport

**Status:** Accepted — 2026-08-22

## Context

The game must run in a browser (GitHub Pages) and look crisp as pixel art on any
desktop resolution. Godot 4 offers three renderers; only one runs on the Web.

## Decision

- `rendering/renderer/rendering_method = "gl_compatibility"` (also for `.mobile`).
- Base viewport 640×360; window opens at 1280×720; stretch mode `viewport`, aspect
  `keep`, scale mode `integer`.
- Nearest-neighbour texture filtering and 2D pixel snap on by default.
- `textures/vram_compression/import_etc2_astc = true` (required by universal macOS
  exports; harmless otherwise).

## Consequences

- Web export works (WebGL 2). Compatibility is "usually good enough for 2D" per the
  Godot docs and runs on weak hardware.
- 640×360 scales cleanly to 720p, 1080p and 4K with no half-pixels.
- Cost: UI text is rendered at 360p and scaled, so it is chunky by design. A UI-heavy
  game may prefer `canvas_items` stretch mode (crisp UI, non-pixel-exact sprites).
- A 3D game will switch to `forward_plus` and lose the Web target (see
  `architecture.md` → Going 3D).

## Alternatives considered

- **Forward+** — best 3D quality; desktop only, no Web.
- **Mobile** — lighter 3D; still no Web.
- **`canvas_items` stretch** — sharper UI; not pixel-perfect for sprites.
- **Higher base resolution (e.g. 1280×720)** — more detail, but sprites would need to
  be drawn larger and integer scaling gives fewer clean steps.
