extends GutTest
## Unit tests for LevelConfig and the shipped level_01.tres.


func test_defaults_are_valid() -> void:
	assert_true(LevelConfig.new().is_valid())


func test_level_01_resource_loads_and_is_valid() -> void:
	var config := load("res://game/core/levels/level_01.tres") as LevelConfig
	assert_not_null(config)
	assert_true(config.is_valid())
	assert_eq(config.target_score, 10)


func test_zero_target_is_invalid() -> void:
	var config := LevelConfig.new()
	config.target_score = 0
	assert_false(config.is_valid())


func test_negative_margin_is_invalid() -> void:
	var config := LevelConfig.new()
	config.arena_margin = -1.0
	assert_false(config.is_valid())
