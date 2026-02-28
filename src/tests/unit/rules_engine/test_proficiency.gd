## test_proficiency.gd
## Unit tests for Proficiency (src/rules_engine/core/proficiency.gd).
##
## Run headlessly from the Godot project root (src/) with:
##   godot --headless --script ../tests/unit/rules_engine/test_proficiency.gd
extends SceneTree

const ProficiencyClass = preload("res://rules_engine/core/proficiency.gd")

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
	_test_bonus_table_levels_1_to_20()
	_test_not_proficient_returns_zero()
	_test_proficient_returns_full_bonus()
	_test_expertise_returns_double_bonus()
	_test_invalid_level()


# ---------------------------------------------------------------------------
# SRD bonus table: every level 1–20 matches the expected value
# ---------------------------------------------------------------------------
func _test_bonus_table_levels_1_to_20() -> void:
	print("_test_bonus_table_levels_1_to_20")
	var expected: Dictionary = {
		1: 2, 2: 2, 3: 2, 4: 2,
		5: 3, 6: 3, 7: 3, 8: 3,
		9: 4, 10: 4, 11: 4, 12: 4,
		13: 5, 14: 5, 15: 5, 16: 5,
		17: 6, 18: 6, 19: 6, 20: 6,
	}
	for level: int in expected:
		var got: int = ProficiencyClass.get_bonus(level)
		var want: int = expected[level]
		_check(got == want, "level %d -> proficiency bonus %d (got %d)" % [level, want, got])


# ---------------------------------------------------------------------------
# apply() returns 0 when not proficient, regardless of level
# ---------------------------------------------------------------------------
func _test_not_proficient_returns_zero() -> void:
	print("_test_not_proficient_returns_zero")
	for level: int in [1, 5, 10, 17, 20]:
		var got: int = ProficiencyClass.apply(level, false, false)
		_check(got == 0, "level %d, not proficient -> 0 (got %d)" % [level, got])
	# expertise flag is ignored when not proficient
	var got_exp: int = ProficiencyClass.apply(10, false, true)
	_check(got_exp == 0, "level 10, not proficient + expertise flag -> 0 (got %d)" % got_exp)


# ---------------------------------------------------------------------------
# apply() returns full bonus when proficient (no expertise)
# ---------------------------------------------------------------------------
func _test_proficient_returns_full_bonus() -> void:
	print("_test_proficient_returns_full_bonus")
	var cases: Dictionary = {1: 2, 4: 2, 5: 3, 8: 3, 9: 4, 12: 4, 13: 5, 16: 5, 17: 6, 20: 6}
	for level: int in cases:
		var want: int = cases[level]
		var got: int = ProficiencyClass.apply(level, true, false)
		_check(got == want, "level %d, proficient -> %d (got %d)" % [level, want, got])


# ---------------------------------------------------------------------------
# apply() returns double bonus when expertise is true
# ---------------------------------------------------------------------------
func _test_expertise_returns_double_bonus() -> void:
	print("_test_expertise_returns_double_bonus")
	var cases: Dictionary = {1: 4, 4: 4, 5: 6, 8: 6, 9: 8, 12: 8, 13: 10, 16: 10, 17: 12, 20: 12}
	for level: int in cases:
		var want: int = cases[level]
		var got: int = ProficiencyClass.apply(level, true, true)
		_check(got == want, "level %d, expertise -> %d (got %d)" % [level, want, got])


# ---------------------------------------------------------------------------
# Levels outside [1, 20] are rejected (push_error + returns 0)
# ---------------------------------------------------------------------------
func _test_invalid_level() -> void:
	print("_test_invalid_level")
	_check(ProficiencyClass.get_bonus(0) == 0, "level 0 (below min) -> 0")
	_check(ProficiencyClass.get_bonus(21) == 0, "level 21 (above max) -> 0")
	_check(ProficiencyClass.apply(0, true, false) == 0, "apply level 0, proficient -> 0")
	_check(ProficiencyClass.apply(21, true, true) == 0, "apply level 21, expertise -> 0")
