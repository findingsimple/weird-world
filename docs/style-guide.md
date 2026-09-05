# GDScript style guide

Distilled from the [official Godot style guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html)
and [GDQuest's guidelines](https://gdquest.gitbook.io/gdquests-guidelines/godot-gdscript-guidelines),
narrowed to what this repo's tooling actually enforces. If `make lint` and
`make check` pass, you are following it.

## Enforced by the tools

| Rule | Enforced by |
| --- | --- |
| Tabs for indentation, max 100 columns | `gdformat` (rewrites), `gdlint` |
| Member order (below) | `gdlint` `class-definitions-order` |
| Naming patterns (below) | `gdlint` |
| No trailing whitespace, LF endings, final newline | `pre-commit`, `.editorconfig` |
| Every declaration typed | Godot: `untyped_declaration = 2` (**error**) |
| No property/method access or casts on untyped (`Variant`) values | Godot: `unsafe_property_access`, `unsafe_method_access`, `unsafe_cast`, `unsafe_call_argument` = 2 (**error**) |
| Max 10 function arguments, 6 returns, 40 public methods, 1000 lines per file | `gdlint` (`gdlintrc`) |

`addons/` is excluded from all of it — third-party code keeps its own style.

## Member order

Exactly what `gdlintrc` → `class-definitions-order` lists:

1. `@tool`
2. `class_name`
3. `extends`
4. `##` docstring
5. signals
6. enums
7. constants
8. static variables
9. `@export` variables
10. public variables
11. private variables (`_name`)
12. `@onready` public variables
13. `@onready` private variables
14. everything else: `_init`, `_ready`, other virtuals, public methods, private methods

Two blank lines between functions (gdformat does this for you).

## Naming

| Thing | Style | Example |
| --- | --- | --- |
| Files, folders | `snake_case` | `platformer_motion.gd`, `game/ui/pause_menu/` |
| `class_name`, node names | `PascalCase` | `PlatformerMotion`, `LowPlatform` |
| Functions, variables, signal parameters | `snake_case` | `next_velocity`, `humans_left` |
| Private members | leading underscore | `_rules`, `_on_human_eaten()` |
| Constants | `CONSTANT_CASE` | `MIN_FALL_RATE` |
| Enums / members | `PascalCase` / `CONSTANT_CASE` | `Outcome.IN_PROGRESS` |
| Signals | past tense, what happened | `eaten`, `money_changed`, `start_pressed` |
| Signal handlers | `_on_<source>_<signal>` | `_on_human_eaten`, `_on_play_button_pressed` |
| Booleans | `is_`, `has_`, `can_` | `is_finished()`, `is_valid()` |

## Typing

- **Type everything**: variables, parameters, return values, typed arrays
  (`Array[Human]`). Untyped declarations are a compile error in this project.
- Use `:=` only when the type is obvious from the right-hand side —
  `var motion := PlatformerMotion.new(...)`, `var box := collider.shape as RectangleShape2D`.
  Write the type when it is not: `var level: Level = LEVEL_SCENE.instantiate()`.
- Prefer `int` for counts and scores, `float` for time and positions. `ceili`, `maxi`,
  `maxf` and friends keep types explicit.
- Avoid `Variant`. If you must, narrow it immediately with a typed assignment.

## Structure

- `class_name` on every script, even small ones — it makes types usable everywhere and
  shows up in the editor's node list.
- `##` doc comments on the class and on every public member. They appear in the
  editor's help and they are the first thing Claude reads.
- `@export` for anything a designer (or a kid) might tune. Use `@export_range` with
  sensible bounds.
- `@onready var _label: Label = %UniqueName` for child references; mark the node
  *Access as Unique Name* in the scene. No `get_node("Path/To/Deep/Node")` chains.
- Signals up, calls down (see `architecture.md`). Pass dependencies in — `Player`
  hands `PlatformerMotion` its tunables; `Level` hands each `Human` its `value`.
- Put rules and math in `RefCounted` classes, not in nodes, so they can be unit-tested
  without a scene tree. `GameRules` and `PlatformerMotion` are the pattern.
- Small functions that do one thing. If you need a comment to explain *what* a block
  does, extract a function named after it; keep comments for *why*.

## Example

Bad — untyped, logic trapped in a node, reaches across the tree:

```gdscript
extends Area2D

var value = 1

func _on_body_entered(body):
	if body.name == "Player":
		get_node("../../Hud/Score").text = str(int(get_node("../../Hud/Score").text) + value)
		queue_free()
```

Good — typed, emits a signal, lets the owner decide what a human is worth:

```gdscript
class_name Human
extends Area2D
## A human: the blob's paycheck. Emits [signal eaten] when the player touches it.

signal eaten(human: Human)

@export var value: int = 1


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		eaten.emit(self)
		queue_free()
```

## Scenes and resources

- Edit `.tscn` and `.tres` in the Godot editor when you can; they are plain text, so
  hand edits (and Claude edits) are fine for small, reviewable changes.
- Never reformat them by hand — the engine owns their layout.
- Keep scene files small: one feature per scene; compose with instances.
