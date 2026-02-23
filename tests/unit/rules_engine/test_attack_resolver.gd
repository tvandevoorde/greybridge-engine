## test_attack_resolver.gd
## Unit tests for AttackResolver (src/rules_engine/core/attack_resolver.gd).
##
## Run headlessly from the Godot project root (src/) with:
##   godot --headless --script ../tests/unit/rules_engine/test_attack_resolver.gd
extends SceneTree

const AttackResolver = preload("res://rules_engine/core/attack_resolver.gd")
const AttackResult = preload("res://rules_engine/core/attack_result.gd")

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
	_test_natural_20_is_critical_hit()
	_test_natural_1_is_automatic_miss()
	_test_normal_hit_meets_ac()
	_test_normal_miss_below_ac()
	_test_ability_modifier_affects_total()
	_test_proficiency_bonus_affects_total()
	_test_melee_uses_str_modifier()
	_test_ranged_uses_dex_modifier()
	_test_result_keys_present()
	_test_critical_does_not_require_meeting_ac()
	_test_auto_miss_ignores_high_total()


# ---------------------------------------------------------------------------
# Natural 20 is a critical hit and always hits
# ---------------------------------------------------------------------------
func _test_natural_20_is_critical_hit() -> void:
	print("_test_natural_20_is_critical_hit")
	var r := AttackResolver.new()
	var result: AttackResult = r.resolve(20, 0, 0, 30)
	_check(result.critical == true, "natural 20 sets critical flag")
	_check(result.hit == true, "natural 20 always hits (even AC 30)")


# ---------------------------------------------------------------------------
# Natural 1 is an automatic miss regardless of modifiers
# ---------------------------------------------------------------------------
func _test_natural_1_is_automatic_miss() -> void:
	print("_test_natural_1_is_automatic_miss")
	var r := AttackResolver.new()
	# Even with huge bonuses the natural 1 must miss
	var result: AttackResult = r.resolve(1, 10, 10, 1)
	_check(result.hit == false, "natural 1 always misses")
	_check(result.critical == false, "natural 1 is not a critical")


# ---------------------------------------------------------------------------
# Normal hit: total >= AC
# ---------------------------------------------------------------------------
func _test_normal_hit_meets_ac() -> void:
	print("_test_normal_hit_meets_ac")
	var r := AttackResolver.new()
	# roll 10 + modifier 3 + proficiency 2 = 15 vs AC 15 -> hit
	var result: AttackResult = r.resolve(10, 3, 2, 15)
	_check(result.hit == true, "total 15 hits AC 15")
	_check(result.critical == false, "non-20 roll is not critical")
	_check(result.total == 15, "total is 10 + 3 + 2 = 15")
	_check(result.roll == 10, "raw roll stored correctly")


# ---------------------------------------------------------------------------
# Normal miss: total < AC
# ---------------------------------------------------------------------------
func _test_normal_miss_below_ac() -> void:
	print("_test_normal_miss_below_ac")
	var r := AttackResolver.new()
	# roll 10 + modifier 0 + proficiency 0 = 10 vs AC 11 -> miss
	var result: AttackResult = r.resolve(10, 0, 0, 11)
	_check(result.hit == false, "total 10 misses AC 11")


# ---------------------------------------------------------------------------
# Ability modifier is added to the total
# ---------------------------------------------------------------------------
func _test_ability_modifier_affects_total() -> void:
	print("_test_ability_modifier_affects_total")
	var r := AttackResolver.new()
	# Positive modifier
	var pos: AttackResult = r.resolve(8, 4, 0, 12)
	_check(pos.total == 12, "roll 8 + modifier 4 = 12")
	_check(pos.hit == true, "total 12 hits AC 12")
	# Negative modifier
	var neg: AttackResult = r.resolve(8, -2, 0, 7)
	_check(neg.total == 6, "roll 8 + modifier -2 = 6")
	_check(neg.hit == false, "total 6 misses AC 7")


# ---------------------------------------------------------------------------
# Proficiency bonus is added to the total
# ---------------------------------------------------------------------------
func _test_proficiency_bonus_affects_total() -> void:
	print("_test_proficiency_bonus_affects_total")
	var r := AttackResolver.new()
	# Without proficiency: roll 9 + 0 + 0 = 9 vs AC 10 -> miss
	var no_prof: AttackResult = r.resolve(9, 0, 0, 10)
	_check(no_prof.hit == false, "roll 9 misses AC 10 without proficiency")
	# With proficiency +2: 9 + 0 + 2 = 11 vs AC 10 -> hit
	var with_prof: AttackResult = r.resolve(9, 0, 2, 10)
	_check(with_prof.hit == true, "roll 9 + proficiency 2 hits AC 10")
	_check(with_prof.total == 11, "total includes proficiency bonus")


# ---------------------------------------------------------------------------
# Melee attack: caller passes STR modifier
# ---------------------------------------------------------------------------
func _test_melee_uses_str_modifier() -> void:
	print("_test_melee_uses_str_modifier")
	# STR 16 -> modifier +3; roll 10 + 3 + 2 = 15 vs AC 14 -> hit
	var r := AttackResolver.new()
	var str_modifier: int = 3   # represents STR 16
	var proficiency: int = 2
	var result: AttackResult = r.resolve(10, str_modifier, proficiency, 14)
	_check(result.hit == true, "melee (STR +3, prof +2): roll 10 hits AC 14")
	_check(result.total == 15, "melee total = 10 + 3 + 2 = 15")


# ---------------------------------------------------------------------------
# Ranged attack: caller passes DEX modifier
# ---------------------------------------------------------------------------
func _test_ranged_uses_dex_modifier() -> void:
	print("_test_ranged_uses_dex_modifier")
	# DEX 14 -> modifier +2; roll 10 + 2 + 2 = 14 vs AC 15 -> miss
	var r := AttackResolver.new()
	var dex_modifier: int = 2   # represents DEX 14
	var proficiency: int = 2
	var result: AttackResult = r.resolve(10, dex_modifier, proficiency, 15)
	_check(result.hit == false, "ranged (DEX +2, prof +2): roll 10 misses AC 15")
	_check(result.total == 14, "ranged total = 10 + 2 + 2 = 14")


# ---------------------------------------------------------------------------
# Result object always contains the required fields
# ---------------------------------------------------------------------------
func _test_result_keys_present() -> void:
	print("_test_result_keys_present")
	var r := AttackResolver.new()
	var result: AttackResult = r.resolve(15, 2, 2, 12)
	_check("hit" in result,      "result has 'hit' field")
	_check("critical" in result, "result has 'critical' field")
	_check("roll" in result,     "result has 'roll' field")
	_check("total" in result,    "result has 'total' field")
	_check("damage" in result,   "result has 'damage' field")


# ---------------------------------------------------------------------------
# Natural 20 hits even when the attacker could never meet the AC with modifiers
# ---------------------------------------------------------------------------
func _test_critical_does_not_require_meeting_ac() -> void:
	print("_test_critical_does_not_require_meeting_ac")
	var r := AttackResolver.new()
	# total = 20 + (-5) + 0 = 15 vs AC 25 — would normally miss, but nat 20 hits
	var result: AttackResult = r.resolve(20, -5, 0, 25)
	_check(result.hit == true, "natural 20 hits AC 25 despite low total")
	_check(result.critical == true, "critical flag set on natural 20")


# ---------------------------------------------------------------------------
# Natural 1 misses even when total would normally exceed AC
# ---------------------------------------------------------------------------
func _test_auto_miss_ignores_high_total() -> void:
	print("_test_auto_miss_ignores_high_total")
	var r := AttackResolver.new()
	# total = 1 + 10 + 10 = 21 vs AC 1 — would hit, but nat 1 always misses
	var result: AttackResult = r.resolve(1, 10, 10, 1)
	_check(result.hit == false, "natural 1 misses AC 1 despite high total")
	_check(result.critical == false, "no critical on natural 1")
