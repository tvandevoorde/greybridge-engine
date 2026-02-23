## test_damage_calculator.gd
## Unit tests for DamageCalculator (src/rules_engine/core/damage_calculator.gd).
##
## Run headlessly from the Godot project root (src/) with:
##   godot --headless --script ../tests/unit/rules_engine/test_damage_calculator.gd
extends SceneTree

const DiceRoller = preload("res://rules_engine/core/dice_roller.gd")
const DamageCalculator = preload("res://rules_engine/core/damage_calculator.gd")

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
	_test_result_keys_present()
	_test_roll_in_valid_range()
	_test_ability_modifier_added()
	_test_negative_modifier_does_not_go_below_zero()
	_test_damage_type_stored()
	_test_deterministic_with_seed()
	_test_zero_modifier_default()


# ---------------------------------------------------------------------------
# Result dictionary always contains the required keys
# ---------------------------------------------------------------------------
func _test_result_keys_present() -> void:
	print("_test_result_keys_present")
	var roller := DiceRoller.new(1)
	var result: Dictionary = DamageCalculator.calculate(1, 6, "slashing", roller)
	_check(result.has("amount"), "result has 'amount' key")
	_check(result.has("damage_type"), "result has 'damage_type' key")
	_check(result.has("roll"), "result has 'roll' key")
	_check(result.has("modifier"), "result has 'modifier' key")


# ---------------------------------------------------------------------------
# Roll result is within the expected dice range
# ---------------------------------------------------------------------------
func _test_roll_in_valid_range() -> void:
	print("_test_roll_in_valid_range")
	# 1d8: roll in [1, 8], amount in [1, 8] with no modifier
	var in_range := true
	for seed: int in range(0, 50):
		var roller := DiceRoller.new(seed)
		var result: Dictionary = DamageCalculator.calculate(1, 8, "piercing", roller)
		if result["roll"] < 1 or result["roll"] > 8:
			in_range = false
			break
	_check(in_range, "1d8 roll always in [1, 8]")

	# 2d6+0: amount in [2, 12]
	var in_range2 := true
	for seed: int in range(0, 50):
		var roller2 := DiceRoller.new(seed)
		var result2: Dictionary = DamageCalculator.calculate(2, 6, "fire", roller2)
		if result2["amount"] < 2 or result2["amount"] > 12:
			in_range2 = false
			break
	_check(in_range2, "2d6 amount always in [2, 12] with no modifier")


# ---------------------------------------------------------------------------
# Ability modifier is added to the dice roll total
# ---------------------------------------------------------------------------
func _test_ability_modifier_added() -> void:
	print("_test_ability_modifier_added")
	var roller := DiceRoller.new(42)
	var result: Dictionary = DamageCalculator.calculate(1, 8, "slashing", roller, 3)
	_check(result["amount"] == result["roll"] + 3, "amount == roll + 3 with modifier +3")
	_check(result["modifier"] == 3, "modifier stored as 3")

	# Negative modifier: roll + (-2)
	var roller2 := DiceRoller.new(42)
	var result2: Dictionary = DamageCalculator.calculate(1, 8, "slashing", roller2, -2)
	var expected: int = maxi(0, result2["roll"] - 2)
	_check(result2["amount"] == expected, "amount == max(0, roll - 2) with modifier -2")
	_check(result2["modifier"] == -2, "modifier stored as -2")


# ---------------------------------------------------------------------------
# Damage amount is clamped to 0 — negative modifier cannot produce negative damage
# ---------------------------------------------------------------------------
func _test_negative_modifier_does_not_go_below_zero() -> void:
	print("_test_negative_modifier_does_not_go_below_zero")
	# Use a very large negative modifier to force amount below zero
	var roller := DiceRoller.new(0)
	var result: Dictionary = DamageCalculator.calculate(1, 4, "cold", roller, -100)
	_check(result["amount"] >= 0, "amount never negative (got %d)" % result["amount"])
	_check(result["amount"] == 0, "amount clamped to 0 when roll + modifier < 0")


# ---------------------------------------------------------------------------
# Damage type is stored exactly as provided
# ---------------------------------------------------------------------------
func _test_damage_type_stored() -> void:
	print("_test_damage_type_stored")
	var roller := DiceRoller.new(7)
	var types: Array[String] = ["slashing", "fire", "cold", "necrotic", "radiant"]
	for dtype: String in types:
		var result: Dictionary = DamageCalculator.calculate(1, 6, dtype, roller)
		_check(result["damage_type"] == dtype, "damage_type stored as '%s'" % dtype)


# ---------------------------------------------------------------------------
# Same seed produces identical results (determinism)
# ---------------------------------------------------------------------------
func _test_deterministic_with_seed() -> void:
	print("_test_deterministic_with_seed")
	var roller1 := DiceRoller.new(999)
	var result1: Dictionary = DamageCalculator.calculate(2, 6, "bludgeoning", roller1, 4)
	var roller2 := DiceRoller.new(999)
	var result2: Dictionary = DamageCalculator.calculate(2, 6, "bludgeoning", roller2, 4)
	_check(result1["amount"] == result2["amount"], "same seed produces same amount (%d)" % result1["amount"])
	_check(result1["roll"] == result2["roll"], "same seed produces same roll (%d)" % result1["roll"])


# ---------------------------------------------------------------------------
# Default ability_modifier is 0 when not supplied
# ---------------------------------------------------------------------------
func _test_zero_modifier_default() -> void:
	print("_test_zero_modifier_default")
	var roller := DiceRoller.new(5)
	var result: Dictionary = DamageCalculator.calculate(1, 6, "fire", roller)
	_check(result["modifier"] == 0, "default modifier is 0")
	_check(result["amount"] == result["roll"], "amount equals roll when modifier is 0")
