## test_skill_check.gd
## Unit tests for SkillCheck (src/rules_engine/core/skill_check.gd).
##
## Run headlessly from the Godot project root (src/) with:
##   godot --headless --script ../tests/unit/rules_engine/test_skill_check.gd
##
## resolve_with_rolls() is used for all deterministic tests so no RNG seeding
## is required.  A seeded-RNG smoke test exercises resolve() itself.
extends SceneTree

const SkillCheck = preload("res://rules_engine/core/skill_check.gd")

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
	_test_normal_roll_success()
	_test_normal_roll_failure()
	_test_proficiency_bonus_applied()
	_test_proficiency_bonus_not_applied_when_not_proficient()
	_test_advantage_takes_higher()
	_test_disadvantage_takes_lower()
	_test_nat20_not_auto_success()
	_test_nat1_not_auto_failure()
	_test_is_nat20_flag()
	_test_is_nat1_flag()
	_test_resolve_with_seeded_rng()


# ---------------------------------------------------------------------------
# Normal roll: success when total >= DC
# ---------------------------------------------------------------------------
func _test_normal_roll_success() -> void:
	print("_test_normal_roll_success")
	# Roll 15, ability modifier +2 (no proficiency) => total 17 vs DC 15 => success
	var r: Dictionary = SkillCheck.resolve_with_rolls(
		15, 2, 0, false, SkillCheck.AdvantageMode.NORMAL, 15, 10
	)
	_check(r["roll"] == 15, "normal: chosen roll is roll1 (15)")
	_check(r["total"] == 17, "normal: total is 15 + 2 = 17")
	_check(r["success"] == true, "normal: 17 >= 15 => success")


# ---------------------------------------------------------------------------
# Normal roll: failure when total < DC
# ---------------------------------------------------------------------------
func _test_normal_roll_failure() -> void:
	print("_test_normal_roll_failure")
	# Roll 5, ability modifier -1 => total 4 vs DC 10 => failure
	var r: Dictionary = SkillCheck.resolve_with_rolls(
		10, -1, 0, false, SkillCheck.AdvantageMode.NORMAL, 5, 18
	)
	_check(r["roll"] == 5, "failure: chosen roll is roll1 (5)")
	_check(r["total"] == 4, "failure: total is 5 + (-1) = 4")
	_check(r["success"] == false, "failure: 4 < 10 => failure")


# ---------------------------------------------------------------------------
# Proficiency bonus is added when the character is proficient
# ---------------------------------------------------------------------------
func _test_proficiency_bonus_applied() -> void:
	print("_test_proficiency_bonus_applied")
	# Roll 10, modifier +1, proficiency +2 => total 13 vs DC 13 => success
	var r: Dictionary = SkillCheck.resolve_with_rolls(
		13, 1, 2, true, SkillCheck.AdvantageMode.NORMAL, 10, 10
	)
	_check(r["total"] == 13, "proficient: total is 10 + 1 + 2 = 13")
	_check(r["success"] == true, "proficient: 13 >= 13 => success")


# ---------------------------------------------------------------------------
# Proficiency bonus is NOT added when the character is not proficient
# ---------------------------------------------------------------------------
func _test_proficiency_bonus_not_applied_when_not_proficient() -> void:
	print("_test_proficiency_bonus_not_applied_when_not_proficient")
	# Roll 10, modifier +1, proficiency +2 but NOT proficient => total 11 vs DC 13 => failure
	var r: Dictionary = SkillCheck.resolve_with_rolls(
		13, 1, 2, false, SkillCheck.AdvantageMode.NORMAL, 10, 10
	)
	_check(r["total"] == 11, "not proficient: total is 10 + 1 = 11 (proficiency ignored)")
	_check(r["success"] == false, "not proficient: 11 < 13 => failure")


# ---------------------------------------------------------------------------
# Advantage: use the higher of two rolls
# ---------------------------------------------------------------------------
func _test_advantage_takes_higher() -> void:
	print("_test_advantage_takes_higher")
	# Rolls 8 and 17 with advantage — should use 17
	var r: Dictionary = SkillCheck.resolve_with_rolls(
		15, 0, 0, false, SkillCheck.AdvantageMode.ADVANTAGE, 8, 17
	)
	_check(r["roll"] == 17, "advantage: chosen roll is max(8, 17) = 17")
	_check(r["total"] == 17, "advantage: total is 17 + 0 = 17")
	_check(r["success"] == true, "advantage: 17 >= 15 => success")

	# Verify the reverse order gives the same chosen roll
	var r2: Dictionary = SkillCheck.resolve_with_rolls(
		15, 0, 0, false, SkillCheck.AdvantageMode.ADVANTAGE, 17, 8
	)
	_check(r2["roll"] == 17, "advantage: chosen roll is max(17, 8) = 17 (order reversed)")


# ---------------------------------------------------------------------------
# Disadvantage: use the lower of two rolls
# ---------------------------------------------------------------------------
func _test_disadvantage_takes_lower() -> void:
	print("_test_disadvantage_takes_lower")
	# Rolls 14 and 6 with disadvantage — should use 6
	var r: Dictionary = SkillCheck.resolve_with_rolls(
		10, 0, 0, false, SkillCheck.AdvantageMode.DISADVANTAGE, 14, 6
	)
	_check(r["roll"] == 6, "disadvantage: chosen roll is min(14, 6) = 6")
	_check(r["total"] == 6, "disadvantage: total is 6 + 0 = 6")
	_check(r["success"] == false, "disadvantage: 6 < 10 => failure")

	# Verify the reverse order gives the same chosen roll
	var r2: Dictionary = SkillCheck.resolve_with_rolls(
		10, 0, 0, false, SkillCheck.AdvantageMode.DISADVANTAGE, 6, 14
	)
	_check(r2["roll"] == 6, "disadvantage: chosen roll is min(6, 14) = 6 (order reversed)")


# ---------------------------------------------------------------------------
# Nat 20 is NOT an automatic success on skill checks (strict SRD)
# ---------------------------------------------------------------------------
func _test_nat20_not_auto_success() -> void:
	print("_test_nat20_not_auto_success")
	# Roll 20, but modifier -15 => total 5 vs DC 10 — must fail despite nat20
	var r: Dictionary = SkillCheck.resolve_with_rolls(
		10, -15, 0, false, SkillCheck.AdvantageMode.NORMAL, 20, 1
	)
	_check(r["roll"] == 20, "nat20 check: chosen roll is 20")
	_check(r["is_nat20"] == true, "nat20 check: is_nat20 flag is true")
	_check(r["total"] == 5, "nat20 check: total is 20 + (-15) = 5")
	_check(r["success"] == false, "nat20 check: 5 < 10 => failure (no auto-success on skill checks)")


# ---------------------------------------------------------------------------
# Nat 1 is NOT an automatic failure on skill checks (strict SRD)
# ---------------------------------------------------------------------------
func _test_nat1_not_auto_failure() -> void:
	print("_test_nat1_not_auto_failure")
	# Roll 1, modifier +15 => total 16 vs DC 10 — must succeed despite nat1
	var r: Dictionary = SkillCheck.resolve_with_rolls(
		10, 15, 0, false, SkillCheck.AdvantageMode.NORMAL, 1, 20
	)
	_check(r["roll"] == 1, "nat1 check: chosen roll is 1")
	_check(r["is_nat1"] == true, "nat1 check: is_nat1 flag is true")
	_check(r["total"] == 16, "nat1 check: total is 1 + 15 = 16")
	_check(r["success"] == true, "nat1 check: 16 >= 10 => success (no auto-failure on skill checks)")


# ---------------------------------------------------------------------------
# is_nat20 flag is set only when chosen roll is 20
# ---------------------------------------------------------------------------
func _test_is_nat20_flag() -> void:
	print("_test_is_nat20_flag")
	var r_nat20: Dictionary = SkillCheck.resolve_with_rolls(
		10, 0, 0, false, SkillCheck.AdvantageMode.NORMAL, 20, 5
	)
	_check(r_nat20["is_nat20"] == true, "is_nat20 true when chosen roll is 20")
	_check(r_nat20["is_nat1"] == false, "is_nat1 false when chosen roll is 20")

	var r_other: Dictionary = SkillCheck.resolve_with_rolls(
		10, 0, 0, false, SkillCheck.AdvantageMode.NORMAL, 15, 5
	)
	_check(r_other["is_nat20"] == false, "is_nat20 false when chosen roll is 15")


# ---------------------------------------------------------------------------
# is_nat1 flag is set only when chosen roll is 1
# ---------------------------------------------------------------------------
func _test_is_nat1_flag() -> void:
	print("_test_is_nat1_flag")
	var r_nat1: Dictionary = SkillCheck.resolve_with_rolls(
		10, 0, 0, false, SkillCheck.AdvantageMode.NORMAL, 1, 15
	)
	_check(r_nat1["is_nat1"] == true, "is_nat1 true when chosen roll is 1")
	_check(r_nat1["is_nat20"] == false, "is_nat20 false when chosen roll is 1")

	var r_other: Dictionary = SkillCheck.resolve_with_rolls(
		10, 0, 0, false, SkillCheck.AdvantageMode.NORMAL, 10, 5
	)
	_check(r_other["is_nat1"] == false, "is_nat1 false when chosen roll is 10")


# ---------------------------------------------------------------------------
# Smoke test: resolve() with a seeded RNG produces a valid result dictionary
# ---------------------------------------------------------------------------
func _test_resolve_with_seeded_rng() -> void:
	print("_test_resolve_with_seeded_rng")
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var r: Dictionary = SkillCheck.resolve(
		12, 2, 2, true, SkillCheck.AdvantageMode.NORMAL, rng
	)
	_check(r.has("roll"), "seeded rng: result has 'roll' key")
	_check(r.has("total"), "seeded rng: result has 'total' key")
	_check(r.has("success"), "seeded rng: result has 'success' key")
	_check(r.has("is_nat20"), "seeded rng: result has 'is_nat20' key")
	_check(r.has("is_nat1"), "seeded rng: result has 'is_nat1' key")
	_check(r["roll"] >= 1 and r["roll"] <= 20, "seeded rng: roll is in [1, 20]")
	_check(r["total"] == r["roll"] + 2 + 2, "seeded rng: total = roll + modifier(2) + proficiency(2)")
	_check(r["success"] == (r["total"] >= 12), "seeded rng: success flag matches total >= dc")
