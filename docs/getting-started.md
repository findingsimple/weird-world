# Getting started

Goal: run Weird World and get `make ci` green on your machine. Budget about
20 minutes, most of it downloading.

## Prerequisites (macOS)

- [Homebrew](https://brew.sh) — installs Godot.
- [uv](https://docs.astral.sh/uv/) — installs the Python-based lint tools (`brew install uv`).
- `make` and `python3` — already on every Mac.
- Git, and a clone of this repository.

Other platforms: `scripts/setup.sh` is macOS-only, but every tool it installs is
cross-platform. Install Godot 4.7.2, `gdtoolkit` 4.x, `pre-commit`, and the export
templates by hand, then use the same `make` targets.

## `make setup`

Runs `scripts/setup.sh`. It is idempotent — re-run it any time — and it **asks before
each install** (pass `--yes` to skip the prompts):

| Step | What it does | Size |
| --- | --- | --- |
| 1. Godot | `brew install --cask godot`, then checks the version against `.godot-version` (4.7.2) | ~200 MB |
| 2. gdtoolkit | `uv tool install "gdtoolkit==4.5.0"` (same pin as pre-commit and CI) → `gdformat` and `gdlint` | small |
| 3. pre-commit | `uv tool install pre-commit` and `pre-commit install` (git hook that lints every commit) | small |
| 4. Export templates | Downloads the official `.tpz` for 4.7.2, verifies it against godot-builds' `SHA512-SUMS.txt`, and unpacks it into `~/Library/Application Support/Godot/export_templates/4.7.2.stable/` | **~1.3 GB** |
| 5. Import | `make import` — builds Godot's `.godot/` cache for the project | — |

Step 4 is only needed for `make export-*`. Skip it if you just want to play and test.

## Check the installation

```sh
make version   # "Godot 4.7.2 OK"
make run       # the game opens in a window — play a round
make ci        # lint + compile check + tests; everything should be green
make help      # lists every target
```

A green `make ci` looks like: `gdformat` reports files unchanged, `gdlint` says
`Success: no problems found`, the compile check prints `check OK`, and GUT ends with
`---- All tests passed! ----`.

## Opening the project in Godot

Launch Godot, click **Import**, pick `project.godot` in the repo root, and open it.
The first open imports the assets (the same thing `make import` does). The GUT panel
appears at the bottom of the editor because the plugin is enabled in `project.godot`.

The editor sometimes rewrites `project.godot` and `.tscn` files when you save. That
is normal — review the diff before committing, as you would with any generated change.

## VS Code (optional but recommended)

Open the repo folder; VS Code will offer the extensions in `.vscode/extensions.json`:

- **godot-tools** (`geequlim.godot-tools`) — syntax, completion, go-to-definition. It
  talks to the running Godot editor's language server on port **6005**

`.vscode/settings.json` points `godotTools.editorPath.godot4` at the macOS path
`/Applications/Godot.app/Contents/MacOS/Godot`; change it on Windows/Linux.
  (`.vscode/settings.json` already sets this; the extension's default is wrong for
  Godot 4). Keep the Godot editor open for completion to work.
- **EditorConfig** — tabs in `.gd`, spaces elsewhere, LF line endings.

`.vscode/launch.json` has two configurations, *Launch main scene* and *Launch current
scene*, which start the game with the debugger attached on port 6007.

## Daily loop

```sh
make run                         # play
make test                        # run every test
make test GUT_ARGS="-gselect=test_game_rules"   # one test script
make lint                        # check formatting + lint
make format                      # fix formatting
make ci                          # what CI runs — do this before every PR
```

## Troubleshooting

**`make version` fails / "need Godot 4.7.2, found ..."**
Homebrew installed a different version. Download the exact build from
[godot-builds 4.7.2-stable](https://github.com/godotengine/godot-builds/releases/tag/4.7.2-stable)
and make sure the `godot` on your `PATH` is that one (`which godot`).

**"Identifier not found: GameEvents" (or another autoload) in the check or tests**
After adding or renaming an autoload, the cached class list is stale. Run `make import`
(or re-open the project in the editor) and try again.

**Errors about missing resources, or `.godot/` does not exist**
Run `make import`. The `.godot/` folder is generated and git-ignored, so a fresh clone
always needs one import. All `make` targets that need it depend on it automatically.

**I changed a sprite / `.tres` and the game looks the same**
`make run` imports before launching, so this should not happen from the command line.
If the editor is open, it re-imports on focus; otherwise run `make import`.

**"gdformat changed my file" / lint fails on formatting**
That is the formatter doing its job. Run `make format` and commit the result. The
only things it will not touch are files under `addons/`.

**pre-commit blocked my commit**
Read the message: a hook either fixed something (stage the fix and commit again) or
found a problem (fix it, then commit). `pre-commit run --all-files` runs the same
checks on demand.

**`make export-*` fails with "No export template found"**
Step 4 of `make setup` was skipped. Re-run `make setup` and accept the download.

**The game runs but looks blurry or stretched**
Check `project.godot` → `[display]`: the project is designed for a 640×360 viewport
scaled by whole numbers. Resize the window to a multiple of that.
