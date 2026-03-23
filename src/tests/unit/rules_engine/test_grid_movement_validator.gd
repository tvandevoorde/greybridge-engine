## test_grid_movement_validator.gd
## Unit tests for GridMovementValidator
## (src/rules_engine/core/grid_movement_validator.gd).
##
## Run headlessly from the Godot project root (src/) with:
##   godot --headless --script ./tests/unit/rules_engine/test_grid_movement_validator.gd
##
## Exit code 0 = all assertions passed; 1 = one or more assertions failed.
extends SceneTree

const GridMovementValidatorClass = preload("res://rules_engine/core/grid_movement_validator.gd")

var _pass_count: int = 0
var _fail_count: int = 0


func _initialize() -> void:
	_run_all_tests()
	print("\nResults: %d passed, %d failed" % [_pass_count, _fail_count])
	quit(1 if _fail_count > 0 else 0)


func _check(condition: bool, description: String) -> void:
	if condition:
		print("  PASS: %s" % description)
		_pass_count += 1
	else:
		print("  FAIL: %s" % description)
		_fail_count += 1


func _run_all_tests() -> void:
	_test_valid_north_step()
	_test_valid_south_step()
	_test_valid_west_step()
	_test_valid_east_step()
	_test_blocked_tile_returns_failure()
	_test_blocked_tile_new_position_is_destination()
	_test_invalid_direction_diagonal()
	_test_invalid_direction_zero_vector()
	_test_invalid_direction_position_unchanged()
	_test_empty_blocked_tiles_succeeds()
	_test_new_position_on_success()
	_test_reason_empty_on_success()


# ---------------------------------------------------------------------------
# Valid cardinal steps succeed
# ---------------------------------------------------------------------------
func _test_valid_north_step() -> void:
	print("_test_valid_north_step")
	var v := GridMovementValidatorClass.new()
	var result := v.validate_step(Vector2i(2, 2), Vector2i(0, -1), [])
	_check(result["success"] == true, "success is true for valid north step")
	_check(result["new_position"] == Vector2i(2, 1), "new_position is one tile north")
	_check(result["reason"] == "", "reason is empty on success")


func _test_valid_south_step() -> void:
	print("_test_valid_south_step")
	var v := GridMovementValidatorClass.new()
	var result := v.validate_step(Vector2i(2, 2), Vector2i(0, 1), [])
	_check(result["success"] == true, "success is true for valid south step")
	_check(result["new_position"] == Vector2i(2, 3), "new_position is one tile south")


func _test_valid_west_step() -> void:
	print("_test_valid_west_step")
	var v := GridMovementValidatorClass.new()
	var result := v.validate_step(Vector2i(2, 2), Vector2i(-1, 0), [])
	_check(result["success"] == true, "success is true for valid west step")
	_check(result["new_position"] == Vector2i(1, 2), "new_position is one tile west")


func _test_valid_east_step() -> void:
	print("_test_valid_east_step")
	var v := GridMovementValidatorClass.new()
	var result := v.validate_step(Vector2i(2, 2), Vector2i(1, 0), [])
	_check(result["success"] == true, "success is true for valid east step")
	_check(result["new_position"] == Vector2i(3, 2), "new_position is one tile east")


# ---------------------------------------------------------------------------
# Collision blocking
# ---------------------------------------------------------------------------
func _test_blocked_tile_returns_failure() -> void:
	print("_test_blocked_tile_returns_failure")
	var v := GridMovementValidatorClass.new()
	var blocked: Array = [Vector2i(2, 1)]
	var result := v.validate_step(Vector2i(2, 2), Vector2i(0, -1), blocked)
	_check(result["success"] == false, "success is false when destination is blocked")
	_check(result["reason"] == "blocked_by_collision", "reason is blocked_by_collision")


func _test_blocked_tile_new_position_is_destination() -> void:
	print("_test_blocked_tile_new_position_is_destination")
	var v := GridMovementValidatorClass.new()
	var blocked: Array = [Vector2i(5, 3)]
	var result := v.validate_step(Vector2i(5, 4), Vector2i(0, -1), blocked)
	_check(result["new_position"] == Vector2i(5, 3),
		"new_position is the blocked destination tile")


# ---------------------------------------------------------------------------
# Invalid direction rejection
# ---------------------------------------------------------------------------
func _test_invalid_direction_diagonal() -> void:
	print("_test_invalid_direction_diagonal")
	var v := GridMovementValidatorClass.new()
	var result := v.validate_step(Vector2i(0, 0), Vector2i(1, 1), [])
	_check(result["success"] == false, "success is false for diagonal direction")
	_check(result["reason"] == "invalid_direction", "reason is invalid_direction for diagonal")


func _test_invalid_direction_zero_vector() -> void:
	print("_test_invalid_direction_zero_vector")
	var v := GridMovementValidatorClass.new()
	var result := v.validate_step(Vector2i(0, 0), Vector2i(0, 0), [])
	_check(result["success"] == false, "success is false for zero direction")
	_check(result["reason"] == "invalid_direction", "reason is invalid_direction for zero vector")


func _test_invalid_direction_position_unchanged() -> void:
	print("_test_invalid_direction_position_unchanged")
	var v := GridMovementValidatorClass.new()
	var result := v.validate_step(Vector2i(3, 5), Vector2i(2, 0), [])
	_check(result["success"] == false, "success is false for out-of-range direction")
	_check(result["new_position"] == Vector2i(3, 5),
		"new_position equals current position when direction is invalid")


# ---------------------------------------------------------------------------
# Edge cases
# ---------------------------------------------------------------------------
func _test_empty_blocked_tiles_succeeds() -> void:
	print("_test_empty_blocked_tiles_succeeds")
	var v := GridMovementValidatorClass.new()
	var result := v.validate_step(Vector2i(0, 0), Vector2i(1, 0), [])
	_check(result["success"] == true, "step succeeds with empty blocked_tiles list")


func _test_new_position_on_success() -> void:
	print("_test_new_position_on_success")
	var v := GridMovementValidatorClass.new()
	var result := v.validate_step(Vector2i(10, 7), Vector2i(0, 1), [])
	_check(result["new_position"] == Vector2i(10, 8),
		"new_position is current + direction on success")


func _test_reason_empty_on_success() -> void:
	print("_test_reason_empty_on_success")
	var v := GridMovementValidatorClass.new()
	var result := v.validate_step(Vector2i(0, 0), Vector2i(0, -1), [])
	_check(result["reason"] == "", "reason is empty string on success")
