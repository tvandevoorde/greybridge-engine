## test_dice_roller.gd
## Unit tests for DiceRoller (src/rules_engine/core/dice_roller.gd).
##
## Run headlessly from the Godot project root (src/) with:
##   godot --headless --script ../tests/unit/rules_engine/test_dice_roller.gd
extends SceneTree

const DiceRollerClass = preload("res://rules_engine/core/dice_roller.gd")

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
	_test_valid_dice_ranges()
	_test_invalid_die_faces()
	_test_deterministic_seed()
	_test_roll_expression()
	_test_roll_expression_invalid_count()
	_test_roll_string_basic()
	_test_roll_string_implicit_count()
	_test_roll_string_negative_modifier()
	_test_roll_string_invalid()
	_test_advantage_is_max()
	_test_disadvantage_is_min()


# ---------------------------------------------------------------------------
# Every valid SRD die produces values in [1, faces].
# ---------------------------------------------------------------------------
func _test_valid_dice_ranges() -> void:
	print("_test_valid_dice_ranges")
	var roller := DiceRollerClass.new(42)
	for faces: int in DiceRollerClass.VALID_DICE:
		var in_range := true
		for _i in 50:
			var result: int = roller.roll(faces)
			if result < 1 or result > faces:
				in_range = false
				break
		_check(in_range, "d%d always in [1, %d]" % [faces, faces])


# ---------------------------------------------------------------------------
# An invalid die count returns 0.
# ---------------------------------------------------------------------------
func _test_invalid_die_faces() -> void:
	print("_test_invalid_die_faces")
	var roller := DiceRollerClass.new(0)
	_check(roller.roll(7) == 0, "d7 (invalid) returns 0")
	_check(roller.roll(2) == 0, "d2 (invalid) returns 0")
	_check(roller.roll(100) == 0, "d100 (invalid) returns 0")


# ---------------------------------------------------------------------------
# Same seed always produces the same roll sequence.
# ---------------------------------------------------------------------------
func _test_deterministic_seed() -> void:
	print("_test_deterministic_seed")
	var r1 := DiceRollerClass.new(1234)
	var r2 := DiceRollerClass.new(1234)
	var match_all := true
	for _i in 20:
		if r1.roll(20) != r2.roll(20):
			match_all = false
			break
	_check(match_all, "two rollers with the same seed produce identical sequences")

	var r3 := DiceRollerClass.new(1234)
	var r4 := DiceRollerClass.new(5678)
	var differs := false
	for _i in 20:
		if r3.roll(20) != r4.roll(20):
			differs = true
			break
	_check(differs, "different seeds produce different sequences")


# ---------------------------------------------------------------------------
# roll_expression sums correctly and applies modifier.
# ---------------------------------------------------------------------------
func _test_roll_expression() -> void:
	print("_test_roll_expression")
	var roller := DiceRollerClass.new(99)
	# 1d6+0 must be in [1, 6]
	var r1: int = roller.roll_expression(1, 6)
	_check(r1 >= 1 and r1 <= 6, "1d6 result in [1, 6] (got %d)" % r1)
	# 2d6+3 must be in [5, 15]
	var r2: int = roller.roll_expression(2, 6, 3)
	_check(r2 >= 5 and r2 <= 15, "2d6+3 result in [5, 15] (got %d)" % r2)
	# 4d4-2 must be in [2, 14]
	var r3: int = roller.roll_expression(4, 4, -2)
	_check(r3 >= 2 and r3 <= 14, "4d4-2 result in [2, 14] (got %d)" % r3)
	# Determinism: same seed + same expression = same result.
	var ra := DiceRollerClass.new(7).roll_expression(3, 8, 1)
	var rb := DiceRollerClass.new(7).roll_expression(3, 8, 1)
	_check(ra == rb, "roll_expression is deterministic for same seed (got %d)" % ra)


# ---------------------------------------------------------------------------
# roll_expression with count < 1 returns 0.
# ---------------------------------------------------------------------------
func _test_roll_expression_invalid_count() -> void:
	print("_test_roll_expression_invalid_count")
	var roller := DiceRollerClass.new(0)
	_check(roller.roll_expression(0, 6) == 0, "count 0 returns 0")
	_check(roller.roll_expression(-1, 6) == 0, "count -1 returns 0")


# ---------------------------------------------------------------------------
# roll_string parses common expressions correctly.
# ---------------------------------------------------------------------------
func _test_roll_string_basic() -> void:
	print("_test_roll_string_basic")
	var roller := DiceRollerClass.new(55)
	var r1: int = roller.roll_string("2d6+3")
	_check(r1 >= 5 and r1 <= 15, "2d6+3 in [5, 15] (got %d)" % r1)
	var r2: int = roller.roll_string("1d20")
	_check(r2 >= 1 and r2 <= 20, "1d20 in [1, 20] (got %d)" % r2)
	var r3: int = roller.roll_string("3d8-2")
	_check(r3 >= 1 and r3 <= 22, "3d8-2 in [1, 22] (got %d)" % r3)


# ---------------------------------------------------------------------------
# Omitting the count prefix is equivalent to 1.
# ---------------------------------------------------------------------------
func _test_roll_string_implicit_count() -> void:
	print("_test_roll_string_implicit_count")
	var roller := DiceRollerClass.new(12)
	var r: int = roller.roll_string("d12")
	_check(r >= 1 and r <= 12, "d12 (no count) in [1, 12] (got %d)" % r)


# ---------------------------------------------------------------------------
# Negative modifiers are applied correctly.
# ---------------------------------------------------------------------------
func _test_roll_string_negative_modifier() -> void:
	print("_test_roll_string_negative_modifier")
	var roller := DiceRollerClass.new(3)
	var r: int = roller.roll_string("1d4-1")
	_check(r >= 0 and r <= 3, "1d4-1 in [0, 3] (got %d)" % r)


# ---------------------------------------------------------------------------
# Unparseable expressions return 0.
# ---------------------------------------------------------------------------
func _test_roll_string_invalid() -> void:
	print("_test_roll_string_invalid")
	var roller := DiceRollerClass.new(0)
	_check(roller.roll_string("fireball") == 0, "'fireball' returns 0")
	_check(roller.roll_string("") == 0, "empty string returns 0")
	_check(roller.roll_string("2+3") == 0, "'2+3' (no 'd') returns 0")


# ---------------------------------------------------------------------------
# advantage returns the higher of two d20 rolls.
# ---------------------------------------------------------------------------
func _test_advantage_is_max() -> void:
	print("_test_advantage_is_max")
	# Verify over many iterations that the advantage result is always >= each
	# individual roll from the same seed (by checking statistical properties).
	var _always_ge_normal := true
	# Compare straight roll vs advantage across 200 samples.
	var sum_adv: int = 0
	var sum_straight: int = 0
	for _i in 200:
		var adv_roller := DiceRollerClass.new(_i)
		sum_adv += adv_roller.roll_advantage()
		var straight_roller := DiceRollerClass.new(_i)
		sum_straight += straight_roller.roll(20)
	_check(sum_adv >= sum_straight, "advantage sum (%d) >= straight sum (%d) over 200 samples" % [sum_adv, sum_straight])
	# Verify the result is always within [1, 20].
	var roller := DiceRollerClass.new(77)
	var in_range := true
	for _i in 50:
		var r: int = roller.roll_advantage()
		if r < 1 or r > 20:
			in_range = false
			break
	_check(in_range, "roll_advantage always in [1, 20]")


# ---------------------------------------------------------------------------
# disadvantage returns the lower of two d20 rolls.
# ---------------------------------------------------------------------------
func _test_disadvantage_is_min() -> void:
	print("_test_disadvantage_is_min")
	var sum_dis: int = 0
	var sum_straight: int = 0
	for _i in 200:
		var dis_roller := DiceRollerClass.new(_i)
		sum_dis += dis_roller.roll_disadvantage()
		var straight_roller := DiceRollerClass.new(_i)
		sum_straight += straight_roller.roll(20)
	_check(sum_dis <= sum_straight, "disadvantage sum (%d) <= straight sum (%d) over 200 samples" % [sum_dis, sum_straight])
	# Verify the result is always within [1, 20].
	var roller := DiceRollerClass.new(88)
	var in_range := true
	for _i in 50:
		var r: int = roller.roll_disadvantage()
		if r < 1 or r > 20:
			in_range = false
			break
	_check(in_range, "roll_disadvantage always in [1, 20]")
