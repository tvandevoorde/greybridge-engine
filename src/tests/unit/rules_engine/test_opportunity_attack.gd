## test_opportunity_attack.gd
## Unit tests for OpportunityAttack (src/rules_engine/core/opportunity_attack.gd).
##
## Run headlessly from the Godot project root (src/) with:
##   godot --headless --script ../tests/unit/rules_engine/test_opportunity_attack.gd
extends SceneTree

const OpportunityAttackClass = preload("res://rules_engine/core/opportunity_attack.gd")

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
	_test_triggers_when_reaction_available_and_not_disengaging()
	_test_cannot_trigger_when_reaction_spent()
	_test_cannot_trigger_when_target_is_disengaging()
	_test_reaction_spent_takes_priority_over_disengage()
	_test_result_keys_present()


# ---------------------------------------------------------------------------
# Happy path: reaction available, target not disengaging → can trigger
# ---------------------------------------------------------------------------
func _test_triggers_when_reaction_available_and_not_disengaging() -> void:
	print("_test_triggers_when_reaction_available_and_not_disengaging")
	var oa := OpportunityAttackClass.new()
	var result: Dictionary = oa.check(true, false)
	_check(result["can_trigger"] == true, "OA triggers when reaction available and target is not disengaging")
	_check(result["reason"] == "", "reason is empty when OA can trigger")


# ---------------------------------------------------------------------------
# Reaction already spent → cannot trigger
# ---------------------------------------------------------------------------
func _test_cannot_trigger_when_reaction_spent() -> void:
	print("_test_cannot_trigger_when_reaction_spent")
	var oa := OpportunityAttackClass.new()
	var result: Dictionary = oa.check(false, false)
	_check(result["can_trigger"] == false, "OA cannot trigger when reaction is spent")
	_check(result["reason"] == "reaction_spent", "reason is 'reaction_spent'")


# ---------------------------------------------------------------------------
# Target used Disengage → cannot trigger
# ---------------------------------------------------------------------------
func _test_cannot_trigger_when_target_is_disengaging() -> void:
	print("_test_cannot_trigger_when_target_is_disengaging")
	var oa := OpportunityAttackClass.new()
	var result: Dictionary = oa.check(true, true)
	_check(result["can_trigger"] == false, "OA cannot trigger when target used Disengage")
	_check(result["reason"] == "target_disengaging", "reason is 'target_disengaging'")


# ---------------------------------------------------------------------------
# Reaction spent AND target disengaging → reaction_spent takes priority
# ---------------------------------------------------------------------------
func _test_reaction_spent_takes_priority_over_disengage() -> void:
	print("_test_reaction_spent_takes_priority_over_disengage")
	var oa := OpportunityAttackClass.new()
	var result: Dictionary = oa.check(false, true)
	_check(result["can_trigger"] == false, "OA cannot trigger when both reaction spent and target disengaging")
	_check(result["reason"] == "reaction_spent", "reaction_spent is reported when reaction is spent (checked first)")


# ---------------------------------------------------------------------------
# Result dictionary always contains the required keys
# ---------------------------------------------------------------------------
func _test_result_keys_present() -> void:
	print("_test_result_keys_present")
	var oa := OpportunityAttackClass.new()
	var result: Dictionary = oa.check(true, false)
	_check(result.has("can_trigger"), "result has 'can_trigger' key")
	_check(result.has("reason"), "result has 'reason' key")
