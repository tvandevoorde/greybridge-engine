## test_damage_roll.gd
## Unit tests for DamageRoll (src/rules_engine/core/damage_roll.gd).
##
## Run headlessly from the Godot project root (src/) with:
##   godot --headless --script ../tests/unit/rules_engine/test_damage_roll.gd
extends SceneTree

const DamageRoll = preload("res://rules_engine/core/damage_roll.gd")

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
	_test_normal_returns_full_damage()
	_test_resistance_halves_damage()
	_test_resistance_rounds_down()
	_test_vulnerability_doubles_damage()
	_test_immunity_negates_damage()
	_test_zero_damage_all_modifiers()


# ---------------------------------------------------------------------------
# NORMAL modifier leaves damage unchanged
# ---------------------------------------------------------------------------
func _test_normal_returns_full_damage() -> void:
	print("_test_normal_returns_full_damage")
	_check(DamageRoll.apply(10, DamageRoll.NORMAL) == 10, "10 damage, normal → 10")
	_check(DamageRoll.apply(7,  DamageRoll.NORMAL) == 7,  "7 damage, normal → 7")


# ---------------------------------------------------------------------------
# RESISTANCE halves damage (even numbers)
# ---------------------------------------------------------------------------
func _test_resistance_halves_damage() -> void:
	print("_test_resistance_halves_damage")
	_check(DamageRoll.apply(20, DamageRoll.RESISTANCE) == 10, "20 damage, resistance → 10")
	_check(DamageRoll.apply(8,  DamageRoll.RESISTANCE) == 4,  "8 damage, resistance → 4")


# ---------------------------------------------------------------------------
# RESISTANCE rounds down for odd damage (SRD: always round down)
# ---------------------------------------------------------------------------
func _test_resistance_rounds_down() -> void:
	print("_test_resistance_rounds_down")
	_check(DamageRoll.apply(7,  DamageRoll.RESISTANCE) == 3, "7 damage, resistance → 3 (rounds down)")
	_check(DamageRoll.apply(1,  DamageRoll.RESISTANCE) == 0, "1 damage, resistance → 0 (rounds down)")
	_check(DamageRoll.apply(15, DamageRoll.RESISTANCE) == 7, "15 damage, resistance → 7 (rounds down)")


# ---------------------------------------------------------------------------
# VULNERABILITY doubles damage
# ---------------------------------------------------------------------------
func _test_vulnerability_doubles_damage() -> void:
	print("_test_vulnerability_doubles_damage")
	_check(DamageRoll.apply(10, DamageRoll.VULNERABILITY) == 20, "10 damage, vulnerability → 20")
	_check(DamageRoll.apply(7,  DamageRoll.VULNERABILITY) == 14, "7 damage, vulnerability → 14")
	_check(DamageRoll.apply(1,  DamageRoll.VULNERABILITY) == 2,  "1 damage, vulnerability → 2")


# ---------------------------------------------------------------------------
# IMMUNITY negates all damage regardless of amount
# ---------------------------------------------------------------------------
func _test_immunity_negates_damage() -> void:
	print("_test_immunity_negates_damage")
	_check(DamageRoll.apply(10,  DamageRoll.IMMUNITY) == 0, "10 damage, immunity → 0")
	_check(DamageRoll.apply(1,   DamageRoll.IMMUNITY) == 0, "1 damage, immunity → 0")
	_check(DamageRoll.apply(100, DamageRoll.IMMUNITY) == 0, "100 damage, immunity → 0")


# ---------------------------------------------------------------------------
# Zero damage is unchanged under all modifiers
# ---------------------------------------------------------------------------
func _test_zero_damage_all_modifiers() -> void:
	print("_test_zero_damage_all_modifiers")
	_check(DamageRoll.apply(0, DamageRoll.NORMAL)        == 0, "0 damage, normal → 0")
	_check(DamageRoll.apply(0, DamageRoll.RESISTANCE)    == 0, "0 damage, resistance → 0")
	_check(DamageRoll.apply(0, DamageRoll.VULNERABILITY) == 0, "0 damage, vulnerability → 0")
	_check(DamageRoll.apply(0, DamageRoll.IMMUNITY)      == 0, "0 damage, immunity → 0")
