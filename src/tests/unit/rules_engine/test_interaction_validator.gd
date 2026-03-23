## test_interaction_validator.gd
## Unit tests for InteractionValidator
## (src/rules_engine/core/interaction_validator.gd).
##
## Run headlessly from the Godot project root (src/) with:
##   godot --headless --script ./tests/unit/rules_engine/test_interaction_validator.gd
##
## Exit code 0 = all assertions passed; 1 = one or more assertions failed.
extends SceneTree

const InteractionValidatorClass = preload(
	"res://rules_engine/core/interaction_validator.gd")

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
	_test_adjacent_south()
	_test_adjacent_north()
	_test_adjacent_east()
	_test_adjacent_west()
	_test_same_tile_not_adjacent()
	_test_diagonal_not_adjacent()
	_test_distance_two_not_adjacent()
	_test_symmetry()


# ---------------------------------------------------------------------------
# is_adjacent — one step in each cardinal direction is adjacent
# ---------------------------------------------------------------------------
func _test_adjacent_south() -> void:
	print("_test_adjacent_south")
	var validator := InteractionValidatorClass.new()
	_check(validator.is_adjacent(Vector2i(3, 3), Vector2i(3, 4)),
		"one step south is adjacent")


func _test_adjacent_north() -> void:
	print("_test_adjacent_north")
	var validator := InteractionValidatorClass.new()
	_check(validator.is_adjacent(Vector2i(3, 3), Vector2i(3, 2)),
		"one step north is adjacent")


func _test_adjacent_east() -> void:
	print("_test_adjacent_east")
	var validator := InteractionValidatorClass.new()
	_check(validator.is_adjacent(Vector2i(3, 3), Vector2i(4, 3)),
		"one step east is adjacent")


func _test_adjacent_west() -> void:
	print("_test_adjacent_west")
	var validator := InteractionValidatorClass.new()
	_check(validator.is_adjacent(Vector2i(3, 3), Vector2i(2, 3)),
		"one step west is adjacent")


# ---------------------------------------------------------------------------
# is_adjacent — non-adjacent cases
# ---------------------------------------------------------------------------
func _test_same_tile_not_adjacent() -> void:
	print("_test_same_tile_not_adjacent")
	var validator := InteractionValidatorClass.new()
	_check(validator.is_adjacent(Vector2i(3, 3), Vector2i(3, 3)) == false,
		"same tile is not adjacent")


func _test_diagonal_not_adjacent() -> void:
	print("_test_diagonal_not_adjacent")
	var validator := InteractionValidatorClass.new()
	_check(validator.is_adjacent(Vector2i(3, 3), Vector2i(4, 4)) == false,
		"diagonal tile is not adjacent")


func _test_distance_two_not_adjacent() -> void:
	print("_test_distance_two_not_adjacent")
	var validator := InteractionValidatorClass.new()
	_check(validator.is_adjacent(Vector2i(3, 3), Vector2i(5, 3)) == false,
		"two steps away is not adjacent")


# ---------------------------------------------------------------------------
# is_adjacent — symmetry
# ---------------------------------------------------------------------------
func _test_symmetry() -> void:
	print("_test_symmetry")
	var validator := InteractionValidatorClass.new()
	var a := Vector2i(1, 2)
	var b := Vector2i(1, 3)
	_check(validator.is_adjacent(a, b) == validator.is_adjacent(b, a),
		"is_adjacent is symmetric")
