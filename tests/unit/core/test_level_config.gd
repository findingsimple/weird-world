extends GutTest
## Unit tests for LevelConfig and the shipped level_01.tres.


func test_defaults_are_valid() -> void:
	assert_true(LevelConfig.new().is_valid())


func test_level_01_resource_loads_and_is_valid() -> void:
	var config := load("res://game/core/levels/level_01.tres") as LevelConfig
	assert_not_null(config)
	assert_true(config.is_valid())
	# The designer's numbers. When they change in level_01.tres, change them here too.
	assert_eq(config.human_value, 1)
	assert_eq(config.stomp_value, 2)
	assert_eq(config.strawberry_fine, 2)


func test_zero_human_value_is_invalid() -> void:
	var config := LevelConfig.new()
	config.human_value = 0
	assert_false(config.is_valid())


func test_a_free_stomp_and_no_fine_are_allowed() -> void:
	var config := LevelConfig.new()
	config.stomp_value = 0
	config.strawberry_fine = 0
	assert_true(config.is_valid())


func test_negative_stomp_value_or_fine_is_invalid() -> void:
	var config := LevelConfig.new()
	config.stomp_value = -1
	assert_false(config.is_valid())
	config.stomp_value = 2
	config.strawberry_fine = -1
	assert_false(config.is_valid())
