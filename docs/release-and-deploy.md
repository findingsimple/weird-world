# Release and deploy

## The flow

```
conventional commits on main
  -> release-please opens/updates a "chore(main): release X.Y.Z" PR
     (bumps version.txt, writes CHANGELOG.md from the commit messages)
  -> you merge it
  -> release-please tags vX.Y.Z and creates a GitHub Release
  -> the build-artifacts job exports Web, Windows, Linux, macOS and attaches four zips
```

Commit messages drive the version:

| Prefix | Bump | Example |
| --- | --- | --- |
| `fix:` | patch | `fix: coins could spawn on top of the player` |
| `feat:` | minor | `feat: add a second coin type worth 5` |
| `feat!:` or a `BREAKING CHANGE:` footer | major | `feat!: new save format` |
| `docs:`, `chore:`, `test:`, `refactor:`, `ci:` | none | appear in the changelog only if configured |

Workflows: `.github/workflows/release.yml`. Config: `release-please-config.json`,
`.release-please-manifest.json`.

**One-time repo setting**: Settings → Actions → General → *Allow GitHub Actions to
create and approve pull requests* must be on, or release-please cannot open its PR.

## Where the version lives

- `version.txt` is the source of truth, maintained by release-please.
- `project.godot` carries `config/version="0.0.0"` in git. The release job stamps
  the real version into it (and into the macOS preset's `short_version`/`version`)
  with `sed` **at export time**, so the in-game `ProjectSettings.get_setting("application/config/version")`
  is correct in releases and obviously "dev" everywhere else.
- Why not a release-please marker comment in `project.godot`? The Godot editor rewrites
  that file on save and strips comments, so the marker would silently disappear.

## Local exports

```sh
make export-web      # build/web/index.html + index-<sha>.wasm/.pck/... (WEB_VERSION= to override)
make serve-web       # http://localhost:8060 — play it in a browser
make export-all      # + build/windows/*.exe, build/linux/*.x86_64, build/macos/*.zip
```

Requirements: export templates installed (`make setup`, step 4) and a `make import`
(the targets do this for you). Presets live in `export_presets.cfg`, which is safe to
commit: since Godot 4.1 secrets go to `.godot/export_credentials.cfg` (git-ignored).
All presets exclude `addons/*`, `tests/*` and `scripts/*` — the test framework and dev
tooling never ship. (Godot still packs the enabled plugin's `plugin.cfg`, a few lines of
text; harmless.)

### Web preset

- `variant/thread_support=false` — single-threaded build. This is the default since
  Godot 4.3 and the whole reason the deploy is simple: it needs **no**
  `Cross-Origin-Opener-Policy` / `Cross-Origin-Embedder-Policy` headers, so it runs on
  GitHub Pages, itch.io, or `python3 -m http.server` as-is. Costs: no `Thread` class,
  somewhat lower performance, audio effects limited.
- The project uses the **Compatibility** renderer (`gl_compatibility`) because it is
  the only one that runs on the Web (WebGL 2).
- PWA is off. Turn it on in the preset if you want an installable app.
- **Asset names are versioned per build.** Godot writes `index.js` / `.wasm` / `.pck` with fixed
  names, and browsers cache a 39 MB `.wasm` for as long as they like — so a new release can
  look like nothing changed (it did, on 2026-09-05, for hours). `make export-web` therefore
  runs `scripts/version_web_assets.sh`, which renames them to `index-<WEB_VERSION>.*` and
  patches `index.html`, then proves no unversioned reference survived. CI passes the commit
  SHA as `WEB_VERSION`; locally it is `git rev-parse --short HEAD`. GitHub Pages caches
  `index.html` itself for 10 minutes, so a push is live for everyone within about ten minutes,
  and nothing older can be served after that.

### GitHub Pages

`.github/workflows/web.yml` exports and deploys on every push to `main`.

One-time setup: Settings → Pages → **Source: GitHub Actions**. The repo must be
**public** (GitHub Pages on the free plan requires it); the deploy job is skipped on
private repos, the build job still runs so breakage is caught. The game appears at
`https://<owner>.github.io/<repo>/`.

### macOS

The macOS preset uses **ad-hoc code signing** (`codesign/codesign=1`) and notarization
off. That is enough to run locally, but a downloaded build triggers Gatekeeper's
"developer cannot be verified" dialog. Tell family members to right-click → Open (once),
or:

```sh
xattr -dr com.apple.quarantine "Weird World.app"
```

Proper notarization needs an Apple Developer ID (paid) — fill in the
`codesign/identity` and `notarization/*` options if you go that way. Universal
(Intel + Apple Silicon) exports require `textures/vram_compression/import_etc2_astc=true`
in `project.godot`; it is set.

### Windows and Linux

`binary_format/embed_pck=true`: one self-contained executable instead of an `.exe` +
`.pck` pair. Windows has `application/modify_resources=false` so the export does not
need `rcedit`/Wine to rewrite icons and version info on Linux CI.

## The CI machinery

| Piece | Used by | Why |
| --- | --- | --- |
| `chickensoft-games/setup-godot@v2` | `ci.yml` test job | Installs the pinned Godot on a plain runner; fast; `use-dotnet: false` since this is GDScript |
| `barichello/godot-ci:<version>` container | `web.yml`, `release.yml` | Ships the export templates pre-installed (no 1.3 GB download per job); the same image Godot's own demo repo uses |
| `pre-commit/action` | `ci.yml` lint job | Runs `.pre-commit-config.yaml` exactly as locally |
| `actions/upload-pages-artifact` + `actions/deploy-pages` | `web.yml` | Official Pages deploy, no `gh-pages` branch |
| `googleapis/release-please-action` | `release.yml` | Version bump, changelog, tag, release |

The export job is chained with `needs:` rather than triggered by the tag, because tags
created with `GITHUB_TOKEN` never trigger other workflows.

## Bumping Godot

When a new Godot 4.x is out:

1. `.godot-version` — the single pin; `make version`, `setup.sh` and `ci.yml` read it.
2. `project.godot` → `config/features` version tag (the editor updates this on open).
3. Container image tags `barichello/godot-ci:<version>` in `web.yml` **and**
   `release.yml` (the build step fails loudly if they disagree with `.godot-version`).
4. Export templates: re-run `make setup` (it installs the matching `.tpz`).
5. GUT: it ships one release line per Godot minor (9.7.x for 4.7). Download the
   matching release, replace `addons/gut/`, run `make test`.
6. gdtoolkit: new GDScript syntax may need a newer `gdtoolkit`; bump the `rev` in
   `.pre-commit-config.yaml`, `GDTOOLKIT_VERSION` in `scripts/setup.sh`, the `pip install`
   line in `ci.yml`, and re-run `uv tool install "gdtoolkit==<new>"`.
7. Open the project in the editor once, commit whatever it rewrites, run `make ci`.

Every place the engine version appears:

| Where | What | Checked by |
| --- | --- | --- |
| `.godot-version` | the pin | `make version` (local and in every CI job) |
| `.github/workflows/web.yml` | `container: image: barichello/godot-ci:<v>` | `make version` step fails on drift |
| `.github/workflows/release.yml` | same container tag | `make version` step fails on drift |
| `project.godot` → `config/features` | editor feature tag | editor rewrites on open |
| `~/Library/Application Support/Godot/export_templates/<v>.stable/` | export templates | `make setup` installs the matching ones |
| `addons/gut/` | GUT release line per Godot minor | `make test` |

## How the release workflow is structured

Three jobs, chained with `needs:`: **release-please** (opens/merges the release PR and
creates the tag; `contents: write`, `pull-requests: write`) → **build** (runs in the
`godot-ci` container with read-only permissions, checks out the *tag* — not whatever
`main` is by then — stamps the version, `make export-all`, uploads `build/` as a workflow
artifact) → **publish** (plain Ubuntu, `contents: write`, zips the four platforms and
`gh release upload`s them). The write-scoped token never enters the third-party container.

## When it goes wrong

**A release was created but the build or publish job failed.** Fix the cause, then re-run
the failed jobs from the Actions tab — the publish job re-attaches to the existing release.
Or do it by hand: `make export-all`, zip each `build/<platform>/` folder, then
`gh release upload vX.Y.Z dist/*.zip`.

**release-please stopped opening PRs.** Check Settings → Actions → General → "Allow GitHub
Actions to create and approve pull requests". Also: only `feat:`/`fix:`/`!` commits trigger
a release; `docs:`/`chore:` alone never will.

**GitHub Pages serves an old build.** First check it really does: `curl -s <page>/index.html |
grep -o 'index-[0-9a-f]*\.js'` names the commit the *server* is on; the `Web` run's last step
prints the same. If the server is current, the browser is holding `index.html` from within
the CDN's 10-minute window — wait it out or hard-reload once; the assets themselves are
versioned, so nothing older than that can ever be served. If the server is stale, re-run
`Web` via *workflow_dispatch* and confirm Settings → Pages → Source is *GitHub Actions* and
the repository is public (the deploy job is skipped for private repos).

**The release PR's CI shows "action required".** GitHub asks a human to approve workflow
runs for PRs opened by the Actions bot. Approve it from the PR's checks tab, or just merge —
the PR only touches `version.txt` and `CHANGELOG.md`.

**Before 1.0.0.** `release-please-config.json` sets `initial-version: 0.1.0`,
`bump-minor-pre-major` and `bump-patch-for-minor-pre-major`: `feat:` → 0.x+1.0, `fix:` →
0.x.y+1, and a breaking change bumps minor, not major, until you ship 1.0.0 by hand
(`Release-As: 1.0.0` in a commit footer).

**`Unable to resolve action`.** A Dependabot bump or a deleted tag; open the Dependabot PR
and check the action's releases page.

**`ERROR: need Godot X, found Y` in CI.** The container tag and `.godot-version` disagree —
see "Bumping Godot" above.
