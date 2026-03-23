## test_map_transition_resolver.gd
## Unit tests for MapTransitionResolver
## (src/rules_engine/core/map_transition_resolver.gd).
##
## Run headlessly from the Godot project root (src/) with:
##   godot --headless --script ./tests/unit/rules_engine/test_map_transition_resolver.gd
##
## Exit code 0 = all assertions passed; 1 = one or more assertions failed.
extends SceneTree

const MapTransitionClass = preload("res://rules_engine/core/map_transition.gd")
const MapTransitionResolverClass = preload("res://rules_engine/core/map_transition_resolver.gd")

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


func _make_transition(required_flags: Dictionary) -> MapTransitionClass:
	var t := MapTransitionClass.new()
	t.tile = Vector2i(5, 0)
	t.target_map = "greybridge_town"
	t.target_spawn = Vector2i(1, 1)
	t.required_flags = required_flags
	return t


func _run_all_tests() -> void:
	_test_no_flags_always_passable()
	_test_flag_present_with_correct_value_passes()
	_test_flag_present_with_wrong_value_blocked()
	_test_flag_missing_from_quest_flags_blocked()
	_test_multiple_flags_all_matching_passes()
	_test_multiple_flags_one_failing_blocked()
	_test_reason_empty_on_success()
	_test_reason_missing_flag_on_blocked()


# ---------------------------------------------------------------------------
# No required flags — always passable
# ---------------------------------------------------------------------------
func _test_no_flags_always_passable() -> void:
	print("_test_no_flags_always_passable")
	var resolver := MapTransitionResolverClass.new()
	var transition := _make_transition({})
	var result := resolver.resolve(transition, {})
	_check(result["can_transition"] == true, "transition with no required flags can always fire")


# ---------------------------------------------------------------------------
# Flag present with correct value
# ---------------------------------------------------------------------------
func _test_flag_present_with_correct_value_passes() -> void:
	print("_test_flag_present_with_correct_value_passes")
	var resolver := MapTransitionResolverClass.new()
	var transition := _make_transition({"gate_open": true})
	var result := resolver.resolve(transition, {"gate_open": true})
	_check(result["can_transition"] == true, "transition fires when required flag matches")


# ---------------------------------------------------------------------------
# Flag present with wrong value
# ---------------------------------------------------------------------------
func _test_flag_present_with_wrong_value_blocked() -> void:
	print("_test_flag_present_with_wrong_value_blocked")
	var resolver := MapTransitionResolverClass.new()
	var transition := _make_transition({"gate_open": true})
	var result := resolver.resolve(transition, {"gate_open": false})
	_check(result["can_transition"] == false, "transition blocked when flag has wrong value")


# ---------------------------------------------------------------------------
# Required flag absent from quest_flags
# ---------------------------------------------------------------------------
func _test_flag_missing_from_quest_flags_blocked() -> void:
	print("_test_flag_missing_from_quest_flags_blocked")
	var resolver := MapTransitionResolverClass.new()
	var transition := _make_transition({"met_merchant": true})
	var result := resolver.resolve(transition, {})
	_check(result["can_transition"] == false, "transition blocked when required flag is absent")


# ---------------------------------------------------------------------------
# Multiple flags — all matching
# ---------------------------------------------------------------------------
func _test_multiple_flags_all_matching_passes() -> void:
	print("_test_multiple_flags_all_matching_passes")
	var resolver := MapTransitionResolverClass.new()
	var transition := _make_transition({"gate_open": true, "met_merchant": true})
	var result := resolver.resolve(transition, {"gate_open": true, "met_merchant": true})
	_check(result["can_transition"] == true, "transition fires when all required flags match")


# ---------------------------------------------------------------------------
# Multiple flags — one failing
# ---------------------------------------------------------------------------
func _test_multiple_flags_one_failing_blocked() -> void:
	print("_test_multiple_flags_one_failing_blocked")
	var resolver := MapTransitionResolverClass.new()
	var transition := _make_transition({"gate_open": true, "met_merchant": true})
	var result := resolver.resolve(transition, {"gate_open": true, "met_merchant": false})
	_check(result["can_transition"] == false, "transition blocked when any required flag fails")


# ---------------------------------------------------------------------------
# reason field
# ---------------------------------------------------------------------------
func _test_reason_empty_on_success() -> void:
	print("_test_reason_empty_on_success")
	var resolver := MapTransitionResolverClass.new()
	var transition := _make_transition({})
	var result := resolver.resolve(transition, {})
	_check(result["reason"] == "", "reason is empty string on success")


func _test_reason_missing_flag_on_blocked() -> void:
	print("_test_reason_missing_flag_on_blocked")
	var resolver := MapTransitionResolverClass.new()
	var transition := _make_transition({"gate_open": true})
	var result := resolver.resolve(transition, {})
	_check(result["reason"] == "missing_flag", "reason is 'missing_flag' when blocked by flag")
