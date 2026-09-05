# Contributing

This is a family project, but it runs like a real one — the habits are the point.

## The loop

1. **Branch** from `main`: `git switch -c feat/moving-enemy`.
2. **Change one thing.** Small PRs are easier to review, test and revert.
3. **Test it**: add or update a test (unit for rules, integration for scenes), then run
   `make ci` — version check, lint, compile check, tests. CI's test job runs exactly that;
   its lint job also runs `pre-commit run --all-files` (the git hook runs it per commit).
4. **Commit** with a [Conventional Commit](https://www.conventionalcommits.org/) message
   (see below). `pre-commit` formats and lints automatically on every commit.
5. **Open a PR.** The template asks for what/why and a checklist. Wait for green CI.
6. **Squash-merge** into `main`. A release PR appears automatically (see
   [docs/release-and-deploy.md](docs/release-and-deploy.md)).

## Commit messages

release-please reads commit messages to decide the next version and write the changelog:

| Prefix | Meaning | Version bump |
|---|---|---|
| `feat:` | new player-visible behaviour | minor (0.1.0 → 0.2.0) |
| `fix:` | bug fix | patch (0.1.0 → 0.1.1) |
| `feat!:` / `fix!:` or a `BREAKING CHANGE:` footer | incompatible change (e.g. save format) | major |
| `docs:`, `test:`, `refactor:`, `chore:`, `ci:`, `style:` | everything else | none |

Examples: `feat: add a moving enemy to the arena`, `fix: coins no longer spawn on the player`,
`docs: explain how to add a level`.

Keep the subject under ~70 characters, imperative mood ("add", not "added").

## Code rules (the short version)

The full guide is [docs/style-guide.md](docs/style-guide.md). The ones that bite:

- Every declaration is typed, and nothing is called on a `Variant`. `untyped_declaration`
  and the `unsafe_*` checks are compile **errors** in this project.
- Every script under `game/` has a `class_name` (tests don't). Files and folders are `snake_case`.
- Game logic goes in `RefCounted` classes (like `GameRules`) so it can be unit-tested.
- Scenes talk up with signals and down with method calls. Use `GameEvents` only for
  things that cross screens.
- Never edit anything under `addons/`.
- Commit `.import` and `.uid` sidecar files; never commit `.godot/`, `build/`, `reports/`.

## Working with Claude

See [docs/working-with-claude.md](docs/working-with-claude.md). Short version: small asks,
read the diff, run `make ci`, and never merge code you can't explain.
