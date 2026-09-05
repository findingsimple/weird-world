# Documentation

Everything about how this project is built, tested, shipped, and — most importantly —
how to learn from it. Each doc is short and focused; read what you need.

| Doc | What it covers |
| --- | --- |
| [getting-started.md](getting-started.md) | Installing the tools, opening the project, first run, troubleshooting |
| [first-change.md](first-change.md) | Four small, safe exercises to make your first change to the game |
| [working-with-claude.md](working-with-claude.md) | How to pair with Claude Code on this repo (parent + kid edition) |
| [architecture.md](architecture.md) | How the game is put together: scenes, signals, rules, physics layers, data flow |
| [style-guide.md](style-guide.md) | How GDScript is written here, and what the linter enforces |
| [testing.md](testing.md) | GUT tests: where they live, how to run them, how to write new ones |
| [release-and-deploy.md](release-and-deploy.md) | Versioning, releases, exports, GitHub Pages, and bumping Godot |
| [glossary.md](glossary.md) | Plain-language definitions of the words used everywhere else |
| [gdd.md](gdd.md) | **The Weird World design document** — what we are making and its rules; keep it current |
| [gdd-template.md](gdd-template.md) | The GDD template, filled in for the Coin Dash example game the project started from |
| [decisions/](decisions/README.md) | Architecture Decision Records: *why* things are the way they are |

## Suggested reading order

### If you are Jason (or another engineer)

1. `getting-started.md` — get `make ci` green on your machine.
2. `architecture.md` — the mental model of the game.
3. `style-guide.md` and `testing.md` — the rules the tooling enforces.
4. `decisions/` — the reasoning behind the stack, so you can disagree with it knowingly.
5. `release-and-deploy.md` — when you are ready to ship something.
6. `working-with-claude.md` — before your first pairing session with your co-developer.

### If you are just starting out

1. `getting-started.md` — ask for help with the setup steps; it is a one-time thing.
2. `first-change.md` — make the blob faster. Seriously, start there.
3. `glossary.md` — keep it open; look words up as you meet them.
4. `working-with-claude.md` — how to ask for help so you learn *and* get things done.
5. `architecture.md` — once you are curious how the pieces connect.
