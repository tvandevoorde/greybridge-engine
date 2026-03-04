## test_hit_points.gd
## Unit tests for HitPoints (src/rules_engine/core/hit_points.gd).
##
## Run headlessly from the Godot project root (src/) with:
##   godot --headless --script ../tests/unit/rules_engine/test_hit_points.gd
extends SceneTree

const HitPointsClass = preload("res://rules_engine/core/hit_points.gd")

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
	_test_apply_damage_reduces_hp()
	_test_damage_cannot_go_below_zero()
	_test_exact_damage_equals_current_hp()
	_test_is_at_zero()
	_test_multiple_damage_applications()
	_test_negative_damage_ignored()
	_test_zero_damage()


# ---------------------------------------------------------------------------
# Initial state: current HP equals max HP
# ---------------------------------------------------------------------------
func _test_initial_state() -> void:
	print("_test_initial_state")
	var hp := HitPointsClass.new(12)
	_check(hp.get_max() == 12, "max HP is 12 after construction")
	_check(hp.get_current() == 12, "current HP starts equal to max HP")
	_check(hp.is_at_zero() == false, "is_at_zero is false at full HP")


# ---------------------------------------------------------------------------
# apply_damage correctly reduces current HP
# ---------------------------------------------------------------------------
func _test_apply_damage_reduces_hp() -> void:
	print("_test_apply_damage_reduces_hp")
	var hp := HitPointsClass.new(20)
	hp.apply_damage(7)
	_check(hp.get_current() == 13, "20 HP - 7 damage = 13 HP")
	_check(hp.get_max() == 20, "max HP unchanged after damage")


# ---------------------------------------------------------------------------
# HP cannot be reduced below 0
# ---------------------------------------------------------------------------
func _test_damage_cannot_go_below_zero() -> void:
	print("_test_damage_cannot_go_below_zero")
	var hp := HitPointsClass.new(10)
	hp.apply_damage(25)
	_check(hp.get_current() == 0, "overkill damage clamps HP to 0 (not negative)")
	_check(hp.is_at_zero() == true, "is_at_zero is true after overkill")


# ---------------------------------------------------------------------------
# Damage exactly equal to current HP brings HP to 0
# ---------------------------------------------------------------------------
func _test_exact_damage_equals_current_hp() -> void:
	print("_test_exact_damage_equals_current_hp")
	var hp := HitPointsClass.new(8)
	hp.apply_damage(8)
	_check(hp.get_current() == 0, "exact lethal damage brings HP to exactly 0")
	_check(hp.is_at_zero() == true, "is_at_zero is true when HP is exactly 0")


# ---------------------------------------------------------------------------
# is_at_zero reflects the current HP correctly
# ---------------------------------------------------------------------------
func _test_is_at_zero() -> void:
	print("_test_is_at_zero")
	var hp := HitPointsClass.new(5)
	_check(hp.is_at_zero() == false, "is_at_zero false at full HP")
	hp.apply_damage(3)
	_check(hp.is_at_zero() == false, "is_at_zero false at 2 HP")
	hp.apply_damage(2)
	_check(hp.is_at_zero() == true, "is_at_zero true at 0 HP")


# ---------------------------------------------------------------------------
# Multiple damage applications accumulate correctly
# ---------------------------------------------------------------------------
func _test_multiple_damage_applications() -> void:
	print("_test_multiple_damage_applications")
	var hp := HitPointsClass.new(30)
	hp.apply_damage(10)
	_check(hp.get_current() == 20, "after 10 damage: 20 HP")
	hp.apply_damage(5)
	_check(hp.get_current() == 15, "after 5 more damage: 15 HP")
	hp.apply_damage(15)
	_check(hp.get_current() == 0, "after 15 more damage: 0 HP (clamped)")


# ---------------------------------------------------------------------------
# Negative damage values are ignored (no healing through apply_damage)
# ---------------------------------------------------------------------------
func _test_negative_damage_ignored() -> void:
	print("_test_negative_damage_ignored")
	var hp := HitPointsClass.new(10)
	hp.apply_damage(4)
	_check(hp.get_current() == 6, "baseline: 6 HP after 4 damage")
	hp.apply_damage(-5)
	_check(hp.get_current() == 6, "negative damage ignored — HP unchanged at 6")


# ---------------------------------------------------------------------------
# Zero damage is a no-op
# ---------------------------------------------------------------------------
func _test_zero_damage() -> void:
	print("_test_zero_damage")
	var hp := HitPointsClass.new(15)
	hp.apply_damage(0)
	_check(hp.get_current() == 15, "zero damage is a no-op — HP stays at 15")
