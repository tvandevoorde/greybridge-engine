## test_concentration.gd
## Unit tests for Concentration (src/rules_engine/core/concentration.gd).
##
## Run headlessly from the Godot project root (src/) with:
##   godot --headless --script ../tests/unit/rules_engine/test_concentration.gd
extends SceneTree

const ConcentrationClass = preload("res://rules_engine/core/concentration.gd")

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
	_test_initial_state()
	_test_start_concentration()
	_test_only_one_effect_at_a_time()
	_test_end_concentration()
	_test_compute_dc_minimum()
	_test_compute_dc_scales_with_damage()
	_test_compute_dc_boundary()
	_test_save_result_fields()
	_test_save_success_maintains_concentration()
	_test_save_failure_ends_concentration()
	_test_save_failure_when_not_concentrating_is_safe()
	_test_save_dc_matches_computed()


# ---------------------------------------------------------------------------
# Initial state: no concentration active
# ---------------------------------------------------------------------------
func _test_initial_state() -> void:
	print("_test_initial_state")
	var c := ConcentrationClass.new()
	_check(c.is_concentrating == false, "new instance is not concentrating")
	_check(c.get_effect_id() == "",     "new instance has no effect id")


# ---------------------------------------------------------------------------
# start() activates concentration and records the effect id
# ---------------------------------------------------------------------------
func _test_start_concentration() -> void:
	print("_test_start_concentration")
	var c := ConcentrationClass.new()
	c.start("bless")
	_check(c.is_concentrating == true, "start() sets is_concentrating true")
	_check(c.get_effect_id() == "bless", "start() records effect id 'bless'")


# ---------------------------------------------------------------------------
# Only one concentration effect at a time — new start() replaces existing
# ---------------------------------------------------------------------------
func _test_only_one_effect_at_a_time() -> void:
	print("_test_only_one_effect_at_a_time")
	var c := ConcentrationClass.new()
	c.start("bless")
	c.start("hold_person")
	_check(c.is_concentrating == true,          "still concentrating after second start()")
	_check(c.get_effect_id() == "hold_person",  "second start() replaces first effect")


# ---------------------------------------------------------------------------
# end() clears concentration state
# ---------------------------------------------------------------------------
func _test_end_concentration() -> void:
	print("_test_end_concentration")
	var c := ConcentrationClass.new()
	c.start("bless")
	c.end()
	_check(c.is_concentrating == false, "end() clears is_concentrating")
	_check(c.get_effect_id() == "",     "end() clears effect id")


# ---------------------------------------------------------------------------
# compute_dc: minimum DC is 10 regardless of damage
# ---------------------------------------------------------------------------
func _test_compute_dc_minimum() -> void:
	print("_test_compute_dc_minimum")
	_check(ConcentrationClass.compute_dc(0)  == 10, "0 damage  → DC 10 (minimum)")
	_check(ConcentrationClass.compute_dc(1)  == 10, "1 damage  → DC 10 (floor(1/2)=0, min 10)")
	_check(ConcentrationClass.compute_dc(18) == 10, "18 damage → DC 10 (floor(18/2)=9, min 10)")
	_check(ConcentrationClass.compute_dc(20) == 10, "20 damage → DC 10 (floor(20/2)=10, min 10)")


# ---------------------------------------------------------------------------
# compute_dc: DC scales above the minimum
# ---------------------------------------------------------------------------
func _test_compute_dc_scales_with_damage() -> void:
	print("_test_compute_dc_scales_with_damage")
	_check(ConcentrationClass.compute_dc(22) == 11, "22 damage → DC 11")
	_check(ConcentrationClass.compute_dc(30) == 15, "30 damage → DC 15")
	_check(ConcentrationClass.compute_dc(50) == 25, "50 damage → DC 25")


# ---------------------------------------------------------------------------
# compute_dc: floor division at the exact boundary (odd damage)
# ---------------------------------------------------------------------------
func _test_compute_dc_boundary() -> void:
	print("_test_compute_dc_boundary")
	_check(ConcentrationClass.compute_dc(21) == 10, "21 damage → DC 10 (floor(21/2)=10)")
	_check(ConcentrationClass.compute_dc(23) == 11, "23 damage → DC 11 (floor(23/2)=11)")


# ---------------------------------------------------------------------------
# resolve_damage_save result contains expected keys
# ---------------------------------------------------------------------------
func _test_save_result_fields() -> void:
	print("_test_save_result_fields")
	var c := ConcentrationClass.new()
	c.start("bless")
	var result: Dictionary = c.resolve_damage_save(10, 2, 2, true, func() -> int: return 10)
	_check(result.has("dc"),      "result contains 'dc' key")
	_check(result.has("roll"),    "result contains 'roll' key")
	_check(result.has("total"),   "result contains 'total' key")
	_check(result.has("success"), "result contains 'success' key")


# ---------------------------------------------------------------------------
# Passing the concentration save keeps concentration active
# ---------------------------------------------------------------------------
func _test_save_success_maintains_concentration() -> void:
	print("_test_save_success_maintains_concentration")
	var c := ConcentrationClass.new()
	c.start("bless")
	# damage=10 → DC 10; roll=10, CON mod=0 → total 10 >= DC 10 → success
	var result: Dictionary = c.resolve_damage_save(10, 0, 0, false, func() -> int: return 10)
	_check(result["success"] == true,  "total 10 >= DC 10 → save success")
	_check(c.is_concentrating == true, "concentration maintained after successful save")
	_check(c.get_effect_id() == "bless", "effect id preserved after successful save")


# ---------------------------------------------------------------------------
# Failing the concentration save ends concentration
# ---------------------------------------------------------------------------
func _test_save_failure_ends_concentration() -> void:
	print("_test_save_failure_ends_concentration")
	var c := ConcentrationClass.new()
	c.start("hold_person")
	# damage=30 → DC 15; roll=5, CON mod=0 → total 5 < DC 15 → failure
	var result: Dictionary = c.resolve_damage_save(30, 0, 0, false, func() -> int: return 5)
	_check(result["dc"] == 15,          "30 damage → DC 15")
	_check(result["success"] == false,  "total 5 < DC 15 → save failure")
	_check(c.is_concentrating == false, "concentration broken on failed save")
	_check(c.get_effect_id() == "",     "effect id cleared on failed save")


# ---------------------------------------------------------------------------
# Calling resolve_damage_save while not concentrating does not cause errors
# ---------------------------------------------------------------------------
func _test_save_failure_when_not_concentrating_is_safe() -> void:
	print("_test_save_failure_when_not_concentrating_is_safe")
	var c := ConcentrationClass.new()
	# Not concentrating; a failed save should not crash
	var result: Dictionary = c.resolve_damage_save(30, 0, 0, false, func() -> int: return 1)
	_check(result["success"] == false,  "save fails as expected")
	_check(c.is_concentrating == false, "still not concentrating (no crash)")


# ---------------------------------------------------------------------------
# resolve_damage_save: DC in result matches compute_dc for the damage value
# ---------------------------------------------------------------------------
func _test_save_dc_matches_computed() -> void:
	print("_test_save_dc_matches_computed")
	var c := ConcentrationClass.new()
	c.start("bless")
	var result: Dictionary = c.resolve_damage_save(40, 0, 0, false, func() -> int: return 20)
	_check(result["dc"] == ConcentrationClass.compute_dc(40), "result dc matches compute_dc(40)")
	_check(result["dc"] == 20, "40 damage → DC 20")
