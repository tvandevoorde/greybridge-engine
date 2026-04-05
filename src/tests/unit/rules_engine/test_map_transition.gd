## test_map_transition.gd
## Unit tests for MapTransition (src/rules_engine/core/map_transition.gd).
##
## Run headlessly from the Godot project root (src/) with:
##   godot --headless --script ./tests/unit/rules_engine/test_map_transition.gd
##
## Exit code 0 = all assertions passed; 1 = one or more assertions failed.
extends SceneTree

const MapTransitionClass = preload("res://rules_engine/core/map_transition.gd")

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
	_test_from_dict_parses_tile()
	_test_from_dict_parses_target_map()
	_test_from_dict_parses_target_spawn()
	_test_from_dict_parses_required_flags()
	_test_from_dict_defaults_tile_to_zero()
	_test_from_dict_defaults_target_map_to_empty()
	_test_from_dict_defaults_target_spawn_to_zero()
	_test_from_dict_defaults_required_flags_to_empty()
	_test_is_valid_true_when_target_map_set()
	_test_is_valid_false_when_target_map_empty()


# ---------------------------------------------------------------------------
# from_dict — tile parsing
# ---------------------------------------------------------------------------
func _test_from_dict_parses_tile() -> void:
	print("_test_from_dict_parses_tile")
	var t := MapTransitionClass.from_dict({
		"tile": {"x": 5, "y": 7},
		"target_map": "some_map",
		"target_spawn": {"x": 1, "y": 2},
	})
	_check(t.tile == Vector2i(5, 7), "tile parsed correctly from dict")


# ---------------------------------------------------------------------------
# from_dict — target_map parsing
# ---------------------------------------------------------------------------
func _test_from_dict_parses_target_map() -> void:
	print("_test_from_dict_parses_target_map")
	var t := MapTransitionClass.from_dict({
		"tile": {"x": 0, "y": 0},
		"target_map": "greybridge_town",
		"target_spawn": {"x": 0, "y": 0},
	})
	_check(t.target_map == "greybridge_town", "target_map parsed correctly from dict")


# ---------------------------------------------------------------------------
# from_dict — target_spawn parsing
# ---------------------------------------------------------------------------
func _test_from_dict_parses_target_spawn() -> void:
	print("_test_from_dict_parses_target_spawn")
	var t := MapTransitionClass.from_dict({
		"tile": {"x": 0, "y": 0},
		"target_map": "greybridge_town",
		"target_spawn": {"x": 3, "y": 9},
	})
	_check(t.target_spawn == Vector2i(3, 9), "target_spawn parsed correctly from dict")


# ---------------------------------------------------------------------------
# from_dict — required_flags parsing
# ---------------------------------------------------------------------------
func _test_from_dict_parses_required_flags() -> void:
	print("_test_from_dict_parses_required_flags")
	var t := MapTransitionClass.from_dict({
		"tile": {"x": 0, "y": 0},
		"target_map": "some_map",
		"target_spawn": {"x": 0, "y": 0},
		"required_flags": {"met_merchant": true, "gate_open": false},
	})
	_check(t.required_flags.get("met_merchant") == true, "required_flags: met_merchant parsed correctly")
	_check(t.required_flags.get("gate_open") == false, "required_flags: gate_open parsed correctly")


# ---------------------------------------------------------------------------
# from_dict — defaults
# ---------------------------------------------------------------------------
func _test_from_dict_defaults_tile_to_zero() -> void:
	print("_test_from_dict_defaults_tile_to_zero")
	var t := MapTransitionClass.from_dict({})
	_check(t.tile == Vector2i(0, 0), "tile defaults to Vector2i(0,0) when absent")


func _test_from_dict_defaults_target_map_to_empty() -> void:
	print("_test_from_dict_defaults_target_map_to_empty")
	var t := MapTransitionClass.from_dict({})
	_check(t.target_map == "", "target_map defaults to empty string when absent")


func _test_from_dict_defaults_target_spawn_to_zero() -> void:
	print("_test_from_dict_defaults_target_spawn_to_zero")
	var t := MapTransitionClass.from_dict({})
	_check(t.target_spawn == Vector2i(0, 0), "target_spawn defaults to Vector2i(0,0) when absent")


func _test_from_dict_defaults_required_flags_to_empty() -> void:
	print("_test_from_dict_defaults_required_flags_to_empty")
	var t := MapTransitionClass.from_dict({})
	_check(t.required_flags == {}, "required_flags defaults to empty dict when absent")


# ---------------------------------------------------------------------------
# is_valid
# ---------------------------------------------------------------------------
func _test_is_valid_true_when_target_map_set() -> void:
	print("_test_is_valid_true_when_target_map_set")
	var t := MapTransitionClass.from_dict({"target_map": "greybridge_town"})
	_check(t.is_valid() == true, "is_valid() returns true when target_map is non-empty")


func _test_is_valid_false_when_target_map_empty() -> void:
	print("_test_is_valid_false_when_target_map_empty")
	var t := MapTransitionClass.from_dict({})
	_check(t.is_valid() == false, "is_valid() returns false when target_map is empty")
