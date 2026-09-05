# Glossary

Plain-language definitions of the words used in this repo. Godot terms first, then
tooling terms.

## Godot

**Node** — the basic building block. Everything visible or active in the game is a
node: a sprite, a timer, a button, a physics body. Each node has a type that decides
what it can do.

**Scene** — a tree of nodes saved in a `.tscn` file. `player.tscn` is a scene; so is
the whole level. Scenes can be instanced inside other scenes (the level contains many
coins, each an instance of `coin.tscn`).

**Tree (scene tree)** — all the nodes currently running, arranged parent → child. The
root is the window. "Adding a node to the tree" makes it live; removing it stops it.

**Signal** — a message a node sends when something happens (`pressed`, `body_entered`,
`collected`). Other code *connects* to the signal to react. The sender does not know
who is listening.

**Autoload** — a node Godot creates automatically at startup and keeps alive for the
whole game, reachable from anywhere by name. This project has one: `GameEvents`.

**Resource** — data Godot can save and load: textures, themes, and your own classes
such as `LevelConfig`. Saved as `.tres` (text) files.

**`.gd`** — a GDScript file: code attached to a node or defining a class.

**`.tscn`** — a scene file (text). Lists the nodes, their properties, and which script
each uses.

**`.tres`** — a resource file (text), e.g. `level_01.tres`, `main_theme.tres`.

**`.uid`** — a tiny generated file next to each `.gd` holding its permanent id, so
references survive renames. Commit them.

**`.import`** — generated next to each asset (`coin.svg.import`) with the import
settings. Commit them too.

**`.godot/`** — Godot's cache folder. Generated, git-ignored, safe to delete
(`make import` rebuilds it).

**Viewport** — the rectangle the game is drawn into. This project draws at 640×360
and scales up by whole numbers so pixels stay crisp.

**Process frame vs physics frame** — `_process(delta)` runs once per drawn frame
(speed varies with the computer); `_physics_process(delta)` runs at a fixed rate
(60 per second) and is where movement and collisions happen. `delta` is the time since
the last one, in seconds.

**CharacterBody2D** — a physics body you move yourself from code (the player).
**Area2D** — detects overlaps but does not push anything (the coin).
**StaticBody2D** — a body that never moves (the floor, the platforms, the invisible walls).

**Collision layer vs mask** — *layer* is what a body *is* (the player is on layer 1,
coins on layer 2, the floor and platforms on layer 3, `world`). *Mask* is what it *looks
for* (the coin's mask is 1: it notices the player; the player's mask is 4: it bumps into
the world). A layer's *bit value* doubles each time: layer 1 = 1, layer 2 = 2, layer 3 = 4.
Named in `project.godot` → `[layer_names]`.

**`@export`** — marks a script variable as editable in the editor's Inspector (and
saved in the scene). `speed` on the player is one.

**Export (build)** — turning the project into something you can run without the
editor: a Web build, a `.exe`, a `.app`. `make export-web` does this.

**Export templates** — the pre-built engine binaries that exports are made from, one
per platform. Installed once by `make setup`.

**Headless** — running Godot without a window (`--headless`). How tests, checks and
exports run in the terminal and in CI.

**Template (this repo)** — a GitHub *template repository*: "Use this template" gives
you a fresh copy to start a new game from.

## Tooling

**CI (continuous integration)** — a robot (GitHub Actions here) that runs
`make ci` on every change you push, so nothing broken lands unnoticed.

**Lint** — automatic checking of code style and common mistakes without running it.
`gdlint` checks; `gdformat` fixes formatting.

**pre-commit** — a git hook that runs the linters on the files you are about to
commit, and stops the commit if they fail.

**Unit test** — checks one piece of logic on its own, with no scene tree
(`tests/unit/`). Fast.

**Integration test** — checks real scenes working together: input, physics, signals
(`tests/integration/`). Slower; closer to what the player experiences.

**GUT** — Godot Unit Test, the test framework in `addons/gut/`.

**Conventional commit** — a commit message with a prefix that says what kind of change
it is: `feat:` new feature, `fix:` bug fix, `docs:` documentation. The release tooling
reads them to decide the next version number.

**SemVer (semantic versioning)** — version numbers as `MAJOR.MINOR.PATCH`
(`1.4.2`). Patch = fixes, minor = new features, major = something incompatible.

**Release** — a tagged version (`v0.2.0`) with downloadable builds attached, made by
the release workflow when you merge the release PR.

**ADR (architecture decision record)** — a short note in `docs/decisions/` recording a
decision, why it was made, and what it costs. So future-you knows.
