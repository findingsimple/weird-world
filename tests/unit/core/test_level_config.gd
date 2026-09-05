extends GutTest
## Unit tests for LevelConfig and the shipped level_01.tres.


func test_defaults_are_valid() -> void:
	assert_true(LevelConfig.new().is_valid())


func test_level_01_resource_loads_and_is_valid() -> void:
	var config := load("res://game/core/levels/level_01.tres") as LevelConfig
	assert_not_null(config)
	assert_true(config.is_valid())
	# The designer's number. When it changes in level_01.tres, change it here too.
	assert_eq(config.human_value, 1)


func test_zero_human_value_is_invalid() -> void:
	var config := LevelConfig.new()
	config.human_value = 0
	assert_false(config.is_valid())
