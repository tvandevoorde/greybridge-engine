## test_combat_results.gd
## Unit tests for AttackResult, SaveResult, and SpellResult
## (src/rules_engine/core/attack_result.gd, save_result.gd, spell_result.gd).
##
## Run headlessly from the Godot project root (src/) with:
##   godot --headless --script ../tests/unit/rules_engine/test_combat_results.gd
extends SceneTree

const AttackResult = preload("res://rules_engine/core/attack_result.gd")
const SaveResult = preload("res://rules_engine/core/save_result.gd")
const SpellResult = preload("res://rules_engine/core/spell_result.gd")
const AttackResolver = preload("res://rules_engine/core/attack_resolver.gd")
const SavingThrow = preload("res://rules_engine/core/saving_throw.gd")

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
	_test_attack_result_fields()
	_test_attack_result_defaults()
	_test_attack_result_from_resolver_hit()
	_test_attack_result_from_resolver_miss()
	_test_attack_result_from_resolver_critical()
	_test_attack_result_damage_field_settable()
	_test_save_result_fields()
	_test_save_result_defaults()
	_test_save_result_from_saving_throw_success()
	_test_save_result_from_saving_throw_failure()
	_test_spell_result_fields()
	_test_spell_result_defaults()
	_test_spell_result_applied_effects_mutable()


# ---------------------------------------------------------------------------
# AttackResult — field presence
# ---------------------------------------------------------------------------
func _test_attack_result_fields() -> void:
	print("_test_attack_result_fields")
	var r := AttackResult.new()
	_check("hit" in r,      "AttackResult has 'hit' field")
	_check("critical" in r, "AttackResult has 'critical' field")
	_check("roll" in r,     "AttackResult has 'roll' field")
	_check("total" in r,    "AttackResult has 'total' field")
	_check("damage" in r,   "AttackResult has 'damage' field")


# ---------------------------------------------------------------------------
# AttackResult — default values
# ---------------------------------------------------------------------------
func _test_attack_result_defaults() -> void:
	print("_test_attack_result_defaults")
	var r := AttackResult.new()
	_check(r.hit == false,      "AttackResult.hit defaults to false")
	_check(r.critical == false, "AttackResult.critical defaults to false")
	_check(r.roll == 0,         "AttackResult.roll defaults to 0")
	_check(r.total == 0,        "AttackResult.total defaults to 0")
	_check(r.damage == 0,       "AttackResult.damage defaults to 0")


# ---------------------------------------------------------------------------
# AttackResult — returned by AttackResolver on a normal hit
# ---------------------------------------------------------------------------
func _test_attack_result_from_resolver_hit() -> void:
	print("_test_attack_result_from_resolver_hit")
	var resolver := AttackResolver.new()
	var result: AttackResult = resolver.resolve(10, 3, 2, 15)
	_check(result is AttackResult, "resolver.resolve returns AttackResult instance")
	_check(result.hit == true,      "hit is true when total >= target_ac")
	_check(result.critical == false, "critical is false for non-20 roll")
	_check(result.roll == 10,        "roll stores raw d20")
	_check(result.total == 15,       "total is roll + modifier + proficiency")


# ---------------------------------------------------------------------------
# AttackResult — returned by AttackResolver on a miss
# ---------------------------------------------------------------------------
func _test_attack_result_from_resolver_miss() -> void:
	print("_test_attack_result_from_resolver_miss")
	var resolver := AttackResolver.new()
	var result: AttackResult = resolver.resolve(5, 0, 0, 15)
	_check(result is AttackResult, "resolver.resolve returns AttackResult on miss")
	_check(result.hit == false,     "hit is false when total < target_ac")
	_check(result.damage == 0,      "damage defaults to 0 when not set")


# ---------------------------------------------------------------------------
# AttackResult — natural 20 is a critical hit
# ---------------------------------------------------------------------------
func _test_attack_result_from_resolver_critical() -> void:
	print("_test_attack_result_from_resolver_critical")
	var resolver := AttackResolver.new()
	var result: AttackResult = resolver.resolve(20, 0, 0, 30)
	_check(result is AttackResult, "resolver.resolve returns AttackResult on critical")
	_check(result.hit == true,      "natural 20 always hits")
	_check(result.critical == true, "natural 20 sets critical flag")


# ---------------------------------------------------------------------------
# AttackResult — damage field is directly settable by the caller
# ---------------------------------------------------------------------------
func _test_attack_result_damage_field_settable() -> void:
	print("_test_attack_result_damage_field_settable")
	var resolver := AttackResolver.new()
	var result: AttackResult = resolver.resolve(15, 2, 2, 12)
	result.damage = 8
	_check(result.damage == 8, "damage field is settable to 8")


# ---------------------------------------------------------------------------
# SaveResult — field presence
# ---------------------------------------------------------------------------
func _test_save_result_fields() -> void:
	print("_test_save_result_fields")
	var r := SaveResult.new()
	_check("roll" in r,     "SaveResult has 'roll' field")
	_check("total" in r,    "SaveResult has 'total' field")
	_check("success" in r,  "SaveResult has 'success' field")


# ---------------------------------------------------------------------------
# SaveResult — default values
# ---------------------------------------------------------------------------
func _test_save_result_defaults() -> void:
	print("_test_save_result_defaults")
	var r := SaveResult.new()
	_check(r.roll == 0,          "SaveResult.roll defaults to 0")
	_check(r.total == 0,         "SaveResult.total defaults to 0")
	_check(r.success == false,   "SaveResult.success defaults to false")


# ---------------------------------------------------------------------------
# SaveResult — returned by SavingThrow on a success
# ---------------------------------------------------------------------------
func _test_save_result_from_saving_throw_success() -> void:
	print("_test_save_result_from_saving_throw_success")
	var result: SaveResult = SavingThrow.resolve(14, 2, 0, false, func() -> int: return 15)
	_check(result is SaveResult,  "SavingThrow.resolve returns SaveResult instance")
	_check(result.roll == 15,     "roll stores raw d20 value")
	_check(result.total == 17,    "total is roll + modifier")
	_check(result.success == true, "success is true when total >= dc")


# ---------------------------------------------------------------------------
# SaveResult — returned by SavingThrow on a failure
# ---------------------------------------------------------------------------
func _test_save_result_from_saving_throw_failure() -> void:
	print("_test_save_result_from_saving_throw_failure")
	var result: SaveResult = SavingThrow.resolve(14, 0, 0, false, func() -> int: return 8)
	_check(result is SaveResult,   "SavingThrow.resolve returns SaveResult on failure")
	_check(result.roll == 8,       "roll stores raw d20 value")
	_check(result.total == 8,      "total equals roll when no bonuses")
	_check(result.success == false, "success is false when total < dc")


# ---------------------------------------------------------------------------
# SpellResult — field presence
# ---------------------------------------------------------------------------
func _test_spell_result_fields() -> void:
	print("_test_spell_result_fields")
	var r := SpellResult.new()
	_check("applied_effects" in r, "SpellResult has 'applied_effects' field")


# ---------------------------------------------------------------------------
# SpellResult — default values
# ---------------------------------------------------------------------------
func _test_spell_result_defaults() -> void:
	print("_test_spell_result_defaults")
	var r := SpellResult.new()
	_check(r.applied_effects.size() == 0, "applied_effects is empty by default")


# ---------------------------------------------------------------------------
# SpellResult — applied_effects is mutable and stores effect identifiers
# ---------------------------------------------------------------------------
func _test_spell_result_applied_effects_mutable() -> void:
	print("_test_spell_result_applied_effects_mutable")
	var r := SpellResult.new()
	r.applied_effects.append("poisoned")
	r.applied_effects.append("blinded")
	_check(r.applied_effects.size() == 2,       "two effects recorded")
	_check(r.applied_effects[0] == "poisoned",  "first effect is 'poisoned'")
	_check(r.applied_effects[1] == "blinded",   "second effect is 'blinded'")
