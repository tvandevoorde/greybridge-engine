## test_saving_throw.gd
## Unit tests for SavingThrow (src/rules_engine/core/saving_throw.gd).
##
## Run headlessly from the Godot project root (src/) with:
##   godot --headless --script ../tests/unit/rules_engine/test_saving_throw.gd
extends SceneTree

const SavingThrow = preload("res://rules_engine/core/saving_throw.gd")
const SaveResult = preload("res://rules_engine/core/save_result.gd")

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
	_test_result_fields()
	_test_basic_failure()
	_test_basic_success()
	_test_exact_dc_is_success()
	_test_proficiency_applied()
	_test_proficiency_not_applied()
	_test_negative_ability_modifier()
	_test_half_damage_on_success()
	_test_full_damage_on_failure()
	_test_full_damage_when_no_half_on_success()
	_test_apply_damage_odd_rounds_down()


# ---------------------------------------------------------------------------
# Result object has the expected fields
# ---------------------------------------------------------------------------
func _test_result_fields() -> void:
	print("_test_result_fields")
	var result: SaveResult = SavingThrow.resolve(14, 2, 2, true, func() -> int: return 10)
	_check("roll" in result,    "result contains 'roll' field")
	_check("total" in result,   "result contains 'total' field")
	_check("success" in result, "result contains 'success' field")


# ---------------------------------------------------------------------------
# roll + modifier < dc → failure
# ---------------------------------------------------------------------------
func _test_basic_failure() -> void:
	print("_test_basic_failure")
	# Roll 8, modifier +2, not proficient, dc 14 → total 10 < 14 → fail
	var result: SaveResult = SavingThrow.resolve(14, 2, 2, false, func() -> int: return 8)
	_check(result.roll == 8,       "roll recorded as 8")
	_check(result.total == 10,     "total == roll(8) + modifier(2) = 10")
	_check(result.success == false, "total 10 < dc 14 → failure")


# ---------------------------------------------------------------------------
# roll + modifier > dc → success
# ---------------------------------------------------------------------------
func _test_basic_success() -> void:
	print("_test_basic_success")
	# Roll 15, modifier +3, not proficient, dc 14 → total 18 >= 14 → success
	var result: SaveResult = SavingThrow.resolve(14, 3, 2, false, func() -> int: return 15)
	_check(result.roll == 15,      "roll recorded as 15")
	_check(result.total == 18,     "total == roll(15) + modifier(3) = 18")
	_check(result.success == true, "total 18 >= dc 14 → success")


# ---------------------------------------------------------------------------
# Meeting the DC exactly counts as success
# ---------------------------------------------------------------------------
func _test_exact_dc_is_success() -> void:
	print("_test_exact_dc_is_success")
	# Roll 12, modifier +2, not proficient, dc 14 → total 14 == dc → success
	var result: SaveResult = SavingThrow.resolve(14, 2, 2, false, func() -> int: return 12)
	_check(result.total == 14,     "total == dc (14)")
	_check(result.success == true, "total == dc → success (meet or beat)")


# ---------------------------------------------------------------------------
# Proficiency bonus added when is_proficient = true
# ---------------------------------------------------------------------------
func _test_proficiency_applied() -> void:
	print("_test_proficiency_applied")
	# Roll 10, modifier +1, proficiency +2, is_proficient = true, dc 14
	# total = 10 + 1 + 2 = 13 — without proficiency this would be 11 (fail), with it 13 (fail)
	# Use a case where proficiency makes the difference:
	# Roll 10, modifier +1, proficiency +3, dc 14 → total 14 → success
	var result: SaveResult = SavingThrow.resolve(14, 1, 3, true, func() -> int: return 10)
	_check(result.total == 14,     "total == roll(10) + modifier(1) + proficiency(3) = 14")
	_check(result.success == true, "proficiency pushes total to dc → success")


# ---------------------------------------------------------------------------
# Proficiency bonus NOT added when is_proficient = false
# ---------------------------------------------------------------------------
func _test_proficiency_not_applied() -> void:
	print("_test_proficiency_not_applied")
	# Roll 10, modifier +1, proficiency +3, is_proficient = false, dc 14
	# total = 10 + 1 = 11 (proficiency ignored) → failure
	var result: SaveResult = SavingThrow.resolve(14, 1, 3, false, func() -> int: return 10)
	_check(result.total == 11,     "total == roll(10) + modifier(1) = 11 (no proficiency)")
	_check(result.success == false, "without proficiency total 11 < dc 14 → failure")


# ---------------------------------------------------------------------------
# Negative ability modifiers reduce the total
# ---------------------------------------------------------------------------
func _test_negative_ability_modifier() -> void:
	print("_test_negative_ability_modifier")
	# Roll 14, modifier -2, not proficient, dc 14 → total 12 < 14 → failure
	var result: SaveResult = SavingThrow.resolve(14, -2, 2, false, func() -> int: return 14)
	_check(result.total == 12,     "total == roll(14) + modifier(-2) = 12")
	_check(result.success == false, "negative modifier causes failure against dc 14")


# ---------------------------------------------------------------------------
# apply_damage: half damage (rounded down) on successful save with half_on_success
# ---------------------------------------------------------------------------
func _test_half_damage_on_success() -> void:
	print("_test_half_damage_on_success")
	_check(SavingThrow.apply_damage(20, true, true) == 10, "20 damage, success, half → 10")
	_check(SavingThrow.apply_damage(8, true, true) == 4,   "8 damage, success, half → 4")


# ---------------------------------------------------------------------------
# apply_damage: full damage on failed save regardless of half_on_success flag
# ---------------------------------------------------------------------------
func _test_full_damage_on_failure() -> void:
	print("_test_full_damage_on_failure")
	_check(SavingThrow.apply_damage(20, false, true) == 20,  "20 damage, failure, half_on_success → full 20")
	_check(SavingThrow.apply_damage(20, false, false) == 20, "20 damage, failure, no half → full 20")


# ---------------------------------------------------------------------------
# apply_damage: full damage on success when half_on_success = false
# ---------------------------------------------------------------------------
func _test_full_damage_when_no_half_on_success() -> void:
	print("_test_full_damage_when_no_half_on_success")
	_check(SavingThrow.apply_damage(20, true, false) == 20, "20 damage, success, no half → full 20")


# ---------------------------------------------------------------------------
# apply_damage: odd damage halved rounds down (SRD: always round down)
# ---------------------------------------------------------------------------
func _test_apply_damage_odd_rounds_down() -> void:
	print("_test_apply_damage_odd_rounds_down")
	_check(SavingThrow.apply_damage(7, true, true) == 3,  "7 damage halved rounds down to 3")
	_check(SavingThrow.apply_damage(1, true, true) == 0,  "1 damage halved rounds down to 0")
	_check(SavingThrow.apply_damage(15, true, true) == 7, "15 damage halved rounds down to 7")
