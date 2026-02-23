## test_death_saving_throw.gd
## Unit tests for DeathSavingThrow (src/rules_engine/core/death_saving_throw.gd).
##
## Run headlessly from the Godot project root (src/) with:
##   godot --headless --script ../tests/unit/rules_engine/test_death_saving_throw.gd
extends SceneTree

const DeathSavingThrow = preload("res://rules_engine/core/death_saving_throw.gd")

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
	_test_should_trigger_at_zero_hp()
	_test_should_not_trigger_above_zero_hp()
	_test_result_fields_present()
	_test_natural_20_restores_hp()
	_test_natural_20_resets_counters()
	_test_natural_1_counts_as_two_failures()
	_test_natural_1_causes_immediate_death_at_two_failures()
	_test_natural_1_causes_immediate_death_at_zero_failures()
	_test_roll_10_or_above_is_success()
	_test_roll_below_10_is_failure()
	_test_three_successes_stabilize()
	_test_three_failures_kill()
	_test_exact_10_is_success()
	_test_roll_9_is_failure()
	_test_success_count_increments()
	_test_failure_count_increments()


# ---------------------------------------------------------------------------
# should_trigger: true when HP = 0
# ---------------------------------------------------------------------------
func _test_should_trigger_at_zero_hp() -> void:
	print("_test_should_trigger_at_zero_hp")
	_check(DeathSavingThrow.should_trigger(0) == true, "HP 0 triggers death saving throw")
	_check(DeathSavingThrow.should_trigger(-1) == true, "HP -1 also triggers death saving throw")


# ---------------------------------------------------------------------------
# should_trigger: false when HP > 0
# ---------------------------------------------------------------------------
func _test_should_not_trigger_above_zero_hp() -> void:
	print("_test_should_not_trigger_above_zero_hp")
	_check(DeathSavingThrow.should_trigger(1) == false, "HP 1 does not trigger death saving throw")
	_check(DeathSavingThrow.should_trigger(10) == false, "HP 10 does not trigger death saving throw")


# ---------------------------------------------------------------------------
# Result dictionary contains all expected keys
# ---------------------------------------------------------------------------
func _test_result_fields_present() -> void:
	print("_test_result_fields_present")
	var result: Dictionary = DeathSavingThrow.roll(0, 0, func() -> int: return 10)
	_check(result.has("roll"),        "result contains 'roll' key")
	_check(result.has("outcome"),     "result contains 'outcome' key")
	_check(result.has("successes"),   "result contains 'successes' key")
	_check(result.has("failures"),    "result contains 'failures' key")
	_check(result.has("hp_restored"), "result contains 'hp_restored' key")


# ---------------------------------------------------------------------------
# Natural 20: restores 1 HP, outcome = "restored"
# ---------------------------------------------------------------------------
func _test_natural_20_restores_hp() -> void:
	print("_test_natural_20_restores_hp")
	var result: Dictionary = DeathSavingThrow.roll(0, 0, func() -> int: return 20)
	_check(result["roll"] == 20,           "roll recorded as 20")
	_check(result["outcome"] == "restored", "natural 20 outcome is 'restored'")
	_check(result["hp_restored"] == 1,     "natural 20 sets hp_restored to 1")


# ---------------------------------------------------------------------------
# Natural 20: resets both counters to 0
# ---------------------------------------------------------------------------
func _test_natural_20_resets_counters() -> void:
	print("_test_natural_20_resets_counters")
	# Even with existing successes/failures, natural 20 clears them
	var result: Dictionary = DeathSavingThrow.roll(2, 2, func() -> int: return 20)
	_check(result["successes"] == 0, "natural 20 resets successes to 0")
	_check(result["failures"] == 0,  "natural 20 resets failures to 0")


# ---------------------------------------------------------------------------
# Natural 1: counts as 2 failures
# ---------------------------------------------------------------------------
func _test_natural_1_counts_as_two_failures() -> void:
	print("_test_natural_1_counts_as_two_failures")
	# Starting at 0 failures: natural 1 → 2 failures, not yet dead
	var result: Dictionary = DeathSavingThrow.roll(0, 0, func() -> int: return 1)
	_check(result["roll"] == 1,          "roll recorded as 1")
	_check(result["failures"] == 2,      "natural 1 adds 2 failures (0 → 2)")
	_check(result["outcome"] == "failure", "2 failures is not yet dead")
	_check(result["hp_restored"] == 0,   "natural 1 does not restore HP")


# ---------------------------------------------------------------------------
# Natural 1 at 2 existing failures: immediate death (2 + 2 = 4 capped at 3)
# ---------------------------------------------------------------------------
func _test_natural_1_causes_immediate_death_at_two_failures() -> void:
	print("_test_natural_1_causes_immediate_death_at_two_failures")
	var result: Dictionary = DeathSavingThrow.roll(0, 2, func() -> int: return 1)
	_check(result["outcome"] == "dead", "natural 1 with 2 existing failures → dead")
	_check(result["failures"] >= 3,    "failure count reaches 3")


# ---------------------------------------------------------------------------
# Natural 1 at 0 failures with count = 2 already causes death (edge: 0 + 2 = 2, still alive)
# Natural 1 at 1 failure: 1 + 2 = 3 → dead
# ---------------------------------------------------------------------------
func _test_natural_1_causes_immediate_death_at_zero_failures() -> void:
	print("_test_natural_1_causes_immediate_death_at_zero_failures")
	# 1 existing failure + natural 1 (2 more) = 3 → dead
	var result: Dictionary = DeathSavingThrow.roll(0, 1, func() -> int: return 1)
	_check(result["outcome"] == "dead", "natural 1 with 1 existing failure → dead (1+2=3)")


# ---------------------------------------------------------------------------
# Roll 10–19: 1 success, outcome = "success" (not yet stable)
# ---------------------------------------------------------------------------
func _test_roll_10_or_above_is_success() -> void:
	print("_test_roll_10_or_above_is_success")
	var result: Dictionary = DeathSavingThrow.roll(0, 0, func() -> int: return 15)
	_check(result["roll"] == 15,           "roll recorded as 15")
	_check(result["outcome"] == "success", "roll 15 → outcome is 'success'")
	_check(result["successes"] == 1,       "success count increments to 1")
	_check(result["hp_restored"] == 0,     "non-20 roll does not restore HP")


# ---------------------------------------------------------------------------
# Roll 2–9: 1 failure, outcome = "failure" (not yet dead)
# ---------------------------------------------------------------------------
func _test_roll_below_10_is_failure() -> void:
	print("_test_roll_below_10_is_failure")
	var result: Dictionary = DeathSavingThrow.roll(0, 0, func() -> int: return 5)
	_check(result["roll"] == 5,            "roll recorded as 5")
	_check(result["outcome"] == "failure", "roll 5 → outcome is 'failure'")
	_check(result["failures"] == 1,        "failure count increments to 1")


# ---------------------------------------------------------------------------
# 3 cumulative successes: outcome = "stable"
# ---------------------------------------------------------------------------
func _test_three_successes_stabilize() -> void:
	print("_test_three_successes_stabilize")
	# Already at 2 successes; rolling a 10+ reaches 3 → stable
	var result: Dictionary = DeathSavingThrow.roll(2, 0, func() -> int: return 12)
	_check(result["outcome"] == "stable", "3rd success stabilizes the creature")
	_check(result["successes"] == 3,      "success count reaches 3")


# ---------------------------------------------------------------------------
# 3 cumulative failures: outcome = "dead"
# ---------------------------------------------------------------------------
func _test_three_failures_kill() -> void:
	print("_test_three_failures_kill")
	# Already at 2 failures; rolling 2–9 reaches 3 → dead
	var result: Dictionary = DeathSavingThrow.roll(0, 2, func() -> int: return 7)
	_check(result["outcome"] == "dead", "3rd failure kills the creature")
	_check(result["failures"] == 3,     "failure count reaches 3")


# ---------------------------------------------------------------------------
# Boundary: roll exactly 10 is a success
# ---------------------------------------------------------------------------
func _test_exact_10_is_success() -> void:
	print("_test_exact_10_is_success")
	var result: Dictionary = DeathSavingThrow.roll(0, 0, func() -> int: return 10)
	_check(result["outcome"] == "success", "roll 10 is a success (threshold is 10+)")
	_check(result["successes"] == 1,       "success count increments for roll 10")


# ---------------------------------------------------------------------------
# Boundary: roll exactly 9 is a failure
# ---------------------------------------------------------------------------
func _test_roll_9_is_failure() -> void:
	print("_test_roll_9_is_failure")
	var result: Dictionary = DeathSavingThrow.roll(0, 0, func() -> int: return 9)
	_check(result["outcome"] == "failure", "roll 9 is a failure (below threshold 10)")
	_check(result["failures"] == 1,        "failure count increments for roll 9")


# ---------------------------------------------------------------------------
# Success count increments correctly across multiple rolls
# ---------------------------------------------------------------------------
func _test_success_count_increments() -> void:
	print("_test_success_count_increments")
	var r1: Dictionary = DeathSavingThrow.roll(0, 0, func() -> int: return 11)
	var r2: Dictionary = DeathSavingThrow.roll(r1["successes"], r1["failures"], func() -> int: return 14)
	_check(r1["successes"] == 1, "first success: count = 1")
	_check(r2["successes"] == 2, "second success: count = 2")
	_check(r2["outcome"] == "success", "still not stable at 2 successes")


# ---------------------------------------------------------------------------
# Failure count increments correctly across multiple rolls
# ---------------------------------------------------------------------------
func _test_failure_count_increments() -> void:
	print("_test_failure_count_increments")
	var r1: Dictionary = DeathSavingThrow.roll(0, 0, func() -> int: return 4)
	var r2: Dictionary = DeathSavingThrow.roll(r1["successes"], r1["failures"], func() -> int: return 6)
	_check(r1["failures"] == 1, "first failure: count = 1")
	_check(r2["failures"] == 2, "second failure: count = 2")
	_check(r2["outcome"] == "failure", "still not dead at 2 failures")
