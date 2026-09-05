# 0005. Single-threaded Web export deployed to GitHub Pages

**Status:** Accepted — 2026-08-22

## Context

The main way to share a build with family is a link. Godot 4 Web builds that use
threads need `Cross-Origin-Opener-Policy`/`Cross-Origin-Embedder-Policy` headers
(SharedArrayBuffer), which GitHub Pages cannot set.

## Decision

- Web preset with `variant/thread_support = false` (Godot's default since 4.3),
  `extensions_support = false`, PWA off.
- `.github/workflows/web.yml` exports in the `barichello/godot-ci` container and
  publishes with `actions/upload-pages-artifact` + `actions/deploy-pages` on every push
  to `main`. Deploy is gated on the repo being public.

## Consequences

- Works on GitHub Pages, itch.io and `python3 -m http.server` with zero header tricks.
- No `Thread` class, somewhat lower performance, audio effects limited — irrelevant for
  small 2D games.
- Requires a **public** repository on GitHub's free plan; private repos still run the
  build job so export breakage is caught.
- The URL is `https://<owner>.github.io/<repo>/`.

## Alternatives considered

- **Threaded export + `coi-serviceworker`** — works, but adds a reload on first visit
  and a third-party script; the plugin that injects it now recommends single-thread.
- **Threaded export + PWA "ensure cross-origin isolation headers"** — built-in, but a
  service worker with its own caching behaviour; unnecessary here.
- **itch.io via butler** — nicer landing page, but needs an account, an API-key secret,
  and a manual "playable in browser" toggle. Easy to add later.
- **`gh-pages` branch via a deploy action** — older pattern; commits build output to git.
