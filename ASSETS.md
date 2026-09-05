# Assets

How art, audio and other assets are handled in this template, and how to add your own.

## Licence split

| What | Licence | File |
|---|---|---|
| Code (`.gd`, `.tscn`, `.tres`, scripts, workflows) | MIT | [LICENSE](LICENSE) |
| Assets shipped with the example (`*.svg`, `icon.svg`) | CC0 1.0 (public domain) | this file |

Assets you add keep whatever licence their author gave them — record it in the credits
table below. Keep the split explicit: a game's code being MIT does not make its art MIT.

## The text-only rule (and why)

Every asset in this template is a hand-written **SVG**. There are no PNGs, no audio, no
fonts, no Git LFS. Reasons:

- **GitHub template repositories cannot contain Git LFS objects**, so binary-heavy
  templates either bloat the repo or break "Use this template".
- Text assets diff, merge and review like code — and Claude can read and edit them.
- Godot imports SVG natively (`*.svg.import` sidecars are committed next to each file).

The rule is for the *template*. Your game will have real art; see below.

## How Godot treats an asset

1. You drop `player.png` (or `.svg`, `.ogg`, `.ttf`) next to the scene that uses it —
   assets live with their feature, not in a global `assets/` bucket.
2. On the next editor open or `make import`, Godot writes `player.png.import` (the import
   settings) and a cached, engine-ready copy under `.godot/imported/`.
3. **Commit the `.import` file, never `.godot/`.** The cache is rebuilt from the sidecar.

Pixel art: the project already sets nearest-neighbour filtering and pixel snapping
globally (`project.godot` → `[rendering]`), so sprites stay crisp at any integer scale.

## Adding free assets

[Kenney](https://kenney.nl/assets) publishes thousands of CC0 game assets — no attribution
required (a credit is still a kind thing to do). Good starting packs for a 2D game:
[Pixel Platformer](https://kenney.nl/assets/pixel-platformer),
[Tiny Town](https://kenney.nl/assets/tiny-town), [Tiny Dungeon](https://kenney.nl/assets/tiny-dungeon),
[Pixel UI Pack](https://kenney.nl/assets/pixel-ui-pack).
[OpenGameArt](https://opengameart.org/) has more, under mixed licences — check each one.

To add a pack:

1. Unzip only the files you use into the feature folder (e.g. `game/player/`).
2. Keep the pack's `License.txt` alongside them.
3. Add a row to the credits table below (title, author, source URL, licence).
4. `make import`, then commit the assets **and** their `.import` files.

If you add anything larger than ~500 KB, pre-commit's `check-added-large-files` will stop
the commit — raise the limit in `.pre-commit-config.yaml` deliberately, or shrink the asset.

## Credits

| Asset | Author | Source | Licence |
|---|---|---|---|
| `icon.svg`, `game/player/player.svg`, `game/coin/coin.svg` | findingsimple | this repository | CC0 1.0 |
