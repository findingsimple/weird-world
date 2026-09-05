# Your first change

Four small exercises. Each one changes the game in a way you can see, and ends with a
command that proves it worked. Do them in order — each is a little bigger than the last.

Before you start: `make run` should open the game. If it doesn't, see
[getting-started.md](getting-started.md).

## 1. Make the blob faster

The blob's speed is a number in one file.

1. Open `game/player/player.gd`.
2. Find this line:

   ```gdscript
   @export_range(0.0, 600.0, 1.0) var speed: float = 120.0
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

*Another way:* open the project in Godot, press ▶, click the `Player` node in the Level
scene, and drag **Speed** in the Inspector *while the game is running*. Same numbers, no
code, instant.

When you are done experimenting, run:

```sh
make test
```

Every test should still pass. The tests don't care how fast the blob is — only that
running and jumping work and every platform can still be reached. (If you made the jump
too small for the high platform, one test *will* fail and tell you so. That is the point.)

## 2. Draw the blob

The blob picture is a text file. Really.

1. Open `game/player/player.svg`. It is a list of lines like this:

   ```xml
   <rect x="5" y="7" width="2" height="2" fill="#222"/>
   ```

   Each `<rect>` is one block of pixels: where it starts (`x`, `y`), how big it is, and
   its colour. The blob is 16 by 16 pixels; the two `#222` blocks near the middle are the
   eyes.
2. Change the outline colour `#2f6df6` to something else, or move an eye, or add a
   block. Any hex colour works — search "hex colour picker" online.
3. Run:

   ```sh
   make run
   ```

Your blob! Godot re-imports the picture automatically.

The humans are in `game/human/human.svg` — the `#3a86ff` shirt is a good one to change.

Finish with `make test`. Still green: pictures don't change the rules.

## 3. Pay the blob more (and place a human)

How much is a human worth? That is in a *resource* file.

1. Open `game/core/levels/level_01.tres`:

   ```
   human_value = 1
   ```

2. Change it to `5`.
3. `make run` — eat everyone and watch the money.

*In the editor:* double-click `level_01.tres` in the FileSystem dock and change the
number in the Inspector. The file is the same either way.

Run `make test`. One test reads this file — `test_level_01_resource_loads_and_is_valid`
in `tests/unit/core/test_level_config.gd`. It checks that `human_value` is `1`. **It
will fail now.** That is good: the test noticed the game changed. Open the test,
change the `1` to your new number, and run `make test` again. Green.

That is what tests are for: they tell you when something you relied on has changed.

Now add a human. Open `game/level/level.tscn` and find `Human5`. It is two lines with a blank
line after it:

```
[node name="Human5" parent="Humans" instance=ExtResource("2_human")]
position = Vector2(580, 337)
```

Copy both lines, paste them right below (keep a blank line between blocks), and change the
name to `Human6` and the position to `Vector2(400, 337)`. Why 337? The floor's top edge is at
`y = 344` and a human is 14 pixels tall, so its middle sits 7 above that. `make run`: six
humans.

`make test` now goes red, on purpose: `test_level_01_has_the_designers_humans` in
`tests/integration/level/test_level_flow.gd` says the level should place 5 humans and asks
you to change `HUMANS_IN_LEVEL`. Change it to `6`; green again. (Put a human in the air
instead and a different test, `test_every_human_stands_on_something`, is the one that
complains.)

## 4. Add a test

The rules of the game live in `game/core/game_rules.gd`. Its tests live in
`tests/unit/core/test_game_rules.gd`. Let's add one.

1. Open `tests/unit/core/test_game_rules.gd`. Look at any test — for example:

   ```gdscript
   func test_money_adds_up() -> void:
   	_rules.eat_human(VALUE)
   	_rules.eat_human(5)
   	assert_eq(_wallet.money, VALUE + 5)
   ```

   `_rules` is a fresh `GameRules` with 3 humans in it, paying into a fresh `_wallet`, made
   for every test by `before_each`. `assert_eq` means "check these two are equal."

2. Add this new test at the bottom of the file (indent with a **tab**, like the
   others):

   ```gdscript
   func test_two_humans_do_not_finish_a_two_human_level_until_both_are_eaten() -> void:
   	var rules := GameRules.new(2, Wallet.new())
   	rules.eat_human(1)
   	assert_false(rules.is_finished())
   	rules.eat_human(1)
   	assert_eq(rules.outcome, GameRules.Outcome.WON)
   ```

3. Run just this file:

   ```sh
   make test GUT_ARGS="-gselect=test_game_rules"
   ```

   Every test in that file should pass — one more than before.

4. Now break the rules on purpose. In `game/core/game_rules.gd`, find
   `if humans_left == 0:` and change it to `if humans_left <= 1:`. Run the test again. It
   fails — the level is "won" with a human still walking around. Change it back. Green.

5. Run everything:

   ```sh
   make ci
   ```

`make ci` also runs the formatter and linter. If it complains about your new test,
run `make format` and look at what it changed.

## What next?

- Commit your changes: `git add -A && git commit -m "feat: a faster blob and a sixth human"`.
- Pick something from the starter projects in
  [working-with-claude.md](working-with-claude.md).
- Or read [architecture.md](architecture.md) to see how the pieces you just touched fit
  together.
