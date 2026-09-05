# Your first change

Four small exercises. Each one changes the game in a way you can see, and ends with a
command that proves it worked. Do them in order — each is a little bigger than the last.

Before you start: `make run` should open the game. If it doesn't, see
[getting-started.md](getting-started.md).

## 1. Make the player faster

The player's speed is a number in one file.

1. Open `game/player/player.gd`.
2. Find this line:

   ```gdscript
   @export var speed: float = 120.0
   ```

3. Change `120.0` to `240.0`.
4. Run:

   ```sh
   make run
   ```

Press Play and run with A/D or the arrow keys; Space jumps. Twice as fast! Try `60.0`
too — too slow to be fun? That is game design: you just tuned the feel.

Now try `jump_velocity` (a few lines down). `500.0` is a super-jump; `150.0` cannot reach
the low platform. And `gravity` at `200.0` turns the blob into a blob on the moon.

*Another way:* open the project in Godot, open `player.tscn`, click the `Player` node,
and change **Speed** in the Inspector on the right. Same number, no code.

When you are done experimenting, run:

```sh
make test
```

Every test should still pass. The tests don't care how fast the player is — only that
moving works.

## 2. Change the coin's colour

The coin picture is a text file. Really.

1. Open `game/coin/coin.svg`. It looks like this:

   ```xml
   <circle cx="6" cy="6" r="5.5" fill="#b8860b"/>
   <circle cx="6" cy="6" r="4.5" fill="#ffd700"/>
   ```

2. The `fill="#ffd700"` part is the colour (that is gold). Change it to `#00ccff`
   for a blue coin, or `#ff4488` for pink. Any colour works — search "hex colour
   picker" online to find one you like.
3. Run:

   ```sh
   make run
   ```

Blue coins! Godot re-imports the picture automatically.

Now try the player in `game/player/player.svg` — the `#3a86ff` shirt is a good one to
change.

Finish with `make test`. Still green: colours don't change the rules.

## 3. Make the round harder

How many coins do you need, and how long do you get? That is in a *resource* file.

1. Open `game/core/levels/level_01.tres`:

   ```
   target_score = 10
   duration_seconds = 30.0
   ```

2. Change `target_score` to `20` and `duration_seconds` to `20.0`.
3. `make run` — can you still win? Tune the numbers until it is hard but possible.

*In the editor:* double-click `level_01.tres` in the FileSystem dock and change the
numbers in the Inspector. The file is the same either way.

Run `make test`. One test reads this file — `test_level_01_resource_loads_and_is_valid`
in `tests/unit/core/test_level_config.gd`. It checks that `target_score` is `10`. **It
will fail now.** That is good: the test noticed the game changed. Open the test,
change the `10` to your new number, and run `make test` again. Green.

That is what tests are for: they tell you when something you relied on has changed.

## 4. Add a test

The rules of the game live in `game/core/game_rules.gd`. Its tests live in
`tests/unit/core/test_game_rules.gd`. Let's add one.

1. Open `tests/unit/core/test_game_rules.gd`. Look at any test — for example:

   ```gdscript
   func test_add_score_accepts_custom_amount() -> void:
   	_rules.add_score(2)
   	assert_eq(_rules.score, 2)
   ```

   `_rules` is a fresh `GameRules` with a target of 3 coins, made for every test by
   `before_each`. `assert_eq` means "check these two are equal."

2. Add this new test at the bottom of the file (indent with a **tab**, like the
   others):

   ```gdscript
   func test_two_big_pickups_win_a_ten_coin_round() -> void:
   	var rules := GameRules.new(10, 30.0)
   	rules.add_score(5)
   	assert_false(rules.is_finished())
   	rules.add_score(5)
   	assert_eq(rules.outcome, GameRules.Outcome.WON)
   ```

3. Run just this file:

   ```sh
   make test GUT_ARGS="-gselect=test_game_rules"
   ```

   Every test in that file should pass — one more than before.

4. Now break the rules on purpose. In `game/core/game_rules.gd`, find
   `if score >= target_score:` and change `>=` to `>`. Run the test again. It fails —
   with 10 coins you no longer win. Change it back. Green again.

5. Run everything:

   ```sh
   make ci
   ```

`make ci` also runs the formatter and linter. If it complains about your new test,
run `make format` and look at what it changed.

## What next?

- Commit your changes: `git add -A && git commit -m "feat: faster player and blue coins"`.
- Pick something from the starter projects in
  [working-with-claude.md](working-with-claude.md).
- Or read [architecture.md](architecture.md) to see how the pieces you just touched fit
  together.
