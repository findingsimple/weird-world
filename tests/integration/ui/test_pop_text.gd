extends GutTest
## Integration tests for PopText: shows its text, floats up, fades, and frees itself.

const POP_SCENE := preload("res://game/ui/pop_text/pop_text.tscn")


func test_shows_the_text_and_goes_away_on_its_own() -> void:
	var pop: PopText = POP_SCENE.instantiate()
	pop.position = Vector2(100, 100)
	add_child_autofree(pop)
	pop.show_text("+$2")
	var label: Label = pop.get_node("Label")
	assert_eq(label.text, "+$2")
	await wait_seconds(pop.duration * 0.5)
	assert_lt(pop.position.y, 100.0, "floating up")
	assert_lt(pop.modulate.a, 1.0, "fading")
	await wait_seconds(pop.duration * 0.5 + 0.2)
	assert_false(is_instance_valid(pop), "freed itself")
