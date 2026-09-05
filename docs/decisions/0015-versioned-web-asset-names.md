# 0015 — Web assets are renamed per build so a stale cache cannot hide a release

- Status: Accepted, 2026-09-05

## Context and problem statement

Godot's Web export writes `index.html` plus `index.js`, `index.wasm` (39 MB), `index.pck` and a
few images, all with fixed names. GitHub Pages caches everything for 10 minutes at its CDN and
sends `cache-control: max-age=600`, but browsers treat large same-named assets generously: on
2026-09-05 the strawberries deployed at 19:43 and the designer's browser showed the morning's
build for hours, with no way for him to clear it. We cannot set headers on Pages.

## Decision

1. `make export-web` runs `scripts/version_web_assets.sh build/web <WEB_VERSION>` after the
   export: every `index.<ext>` except `index.html` becomes `index-<version>.<ext>`, and
   `index.html` is patched — the `<script>`, the icons, the splash, and
   `GODOT_CONFIG.executable`, from which the engine derives the `.wasm`, `.pck` and audio
   worklet names.
2. The script **proves** the result: no unversioned reference may survive (it would 404 and
   break the page rather than refresh it) and every versioned reference must exist on disk.
   It refuses to run twice on the same export.
3. `WEB_VERSION` is the short commit SHA — passed explicitly by `web.yml` (the build runs in a
   container that may have no `git`), `git rev-parse` locally, a timestamp as a last resort.
4. The deploy job ends with an informational probe: does the live `index.html` name this
   commit yet? It warns, never fails — the CDN's own 10-minute window makes "not yet" normal.

## Consequences

- Good: a browser that has cached last build's assets fetches new ones on the next page load,
  because the page asks for different names. The only remaining staleness is `index.html`
  itself, bounded by the CDN's 10 minutes.
- Good: "is the server current?" is now a one-line `curl … | grep -o 'index-[0-9a-f]*\.js'`.
- Bad: `build/web` holds differently-named files per export; the Makefile deletes old
  `index-*.*` before exporting so the Pages artifact never carries leftovers.
- Remember: never link to `index.pck` / `index.wasm` by fixed name anywhere (docs, tests,
  a custom HTML shell); the release zip also carries versioned names, which is fine.

## Alternatives considered

- **Cache headers** (`no-cache` / short `max-age` on assets) — the right tool on a host we
  control; GitHub Pages offers none.
- **Godot's PWA/service worker** — makes the problem worse by design (serve cached, update
  later) unless an update prompt is built.
- **Tell players to hard-reload** — the docs said exactly that; the first real player
  couldn't clear the cache, and a fix that depends on the player is not a fix.
- **A custom HTML shell with query strings (`index.pck?v=…`)** — the engine builds asset URLs
  from `executable`, so the pck/wasm names cannot take a query string without forking the shell.
