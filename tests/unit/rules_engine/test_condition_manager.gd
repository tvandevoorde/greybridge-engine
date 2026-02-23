## test_condition_manager.gd
## Unit tests for ConditionManager (src/rules_engine/core/condition_manager.gd)
## and Condition definitions (src/rules_engine/core/condition.gd).
##
## Run headlessly from the Godot project root (src/) with:
##   godot --headless --script ../tests/unit/rules_engine/test_condition_manager.gd
extends SceneTree

const ConditionManager = preload("res://rules_engine/core/condition_manager.gd")
const Condition = preload("res://rules_engine/core/condition.gd")

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
	_test_add_and_has_condition()
	_test_remove_condition()
	_test_no_stacking()
	_test_get_active_conditions()
	_test_get_duration_indefinite()
	_test_get_duration_timed()
	_test_get_duration_not_active()
	_test_tick_decrements_duration()
	_test_tick_removes_expired_condition()
	_test_tick_does_not_remove_indefinite()
	_test_tick_multiple_conditions()
	_test_prone_attack_disadvantage()
	_test_poisoned_attack_disadvantage()
	_test_grappled_no_attack_disadvantage()
	_test_poisoned_ability_check_disadvantage()
	_test_prone_no_ability_check_disadvantage()
	_test_grappled_speed_zero()
	_test_prone_no_speed_zero()
	_test_no_conditions_no_effects()
	_test_condition_definitions_present()


# ---------------------------------------------------------------------------
# add_condition / has_condition
# ---------------------------------------------------------------------------
func _test_add_and_has_condition() -> void:
	print("_test_add_and_has_condition")
	var m := ConditionManager.new()
	_check(m.has_condition(Condition.ID_PRONE) == false, "prone not active before adding")
	m.add_condition(Condition.ID_PRONE)
	_check(m.has_condition(Condition.ID_PRONE) == true, "prone active after adding")


# ---------------------------------------------------------------------------
# remove_condition
# ---------------------------------------------------------------------------
func _test_remove_condition() -> void:
	print("_test_remove_condition")
	var m := ConditionManager.new()
	m.add_condition(Condition.ID_GRAPPLED)
	m.remove_condition(Condition.ID_GRAPPLED)
	_check(m.has_condition(Condition.ID_GRAPPLED) == false, "grappled removed successfully")
	# Removing non-active condition is a no-op (no error)
	m.remove_condition(Condition.ID_POISONED)
	_check(m.has_condition(Condition.ID_POISONED) == false, "removing inactive condition is safe")


# ---------------------------------------------------------------------------
# Stack prevention: adding the same condition twice has no effect
# ---------------------------------------------------------------------------
func _test_no_stacking() -> void:
	print("_test_no_stacking")
	var m := ConditionManager.new()
	m.add_condition(Condition.ID_POISONED, 3)
	m.add_condition(Condition.ID_POISONED, 10)  # second call should be ignored
	_check(m.get_duration(Condition.ID_POISONED) == 3, "second add_condition does not overwrite duration")
	_check(m.get_active_conditions().size() == 1, "only one condition active after duplicate add")


# ---------------------------------------------------------------------------
# get_active_conditions
# ---------------------------------------------------------------------------
func _test_get_active_conditions() -> void:
	print("_test_get_active_conditions")
	var m := ConditionManager.new()
	_check(m.get_active_conditions().size() == 0, "no conditions active on new manager")
	m.add_condition(Condition.ID_PRONE)
	m.add_condition(Condition.ID_POISONED)
	_check(m.get_active_conditions().size() == 2, "two conditions active")
	_check(m.get_active_conditions().has(Condition.ID_PRONE), "prone in active list")
	_check(m.get_active_conditions().has(Condition.ID_POISONED), "poisoned in active list")


# ---------------------------------------------------------------------------
# get_duration: indefinite condition returns -1
# ---------------------------------------------------------------------------
func _test_get_duration_indefinite() -> void:
	print("_test_get_duration_indefinite")
	var m := ConditionManager.new()
	m.add_condition(Condition.ID_GRAPPLED)  # default duration = -1
	_check(m.get_duration(Condition.ID_GRAPPLED) == -1, "indefinite condition returns duration -1")


# ---------------------------------------------------------------------------
# get_duration: timed condition returns remaining turns
# ---------------------------------------------------------------------------
func _test_get_duration_timed() -> void:
	print("_test_get_duration_timed")
	var m := ConditionManager.new()
	m.add_condition(Condition.ID_PRONE, 4)
	_check(m.get_duration(Condition.ID_PRONE) == 4, "timed condition returns correct duration")


# ---------------------------------------------------------------------------
# get_duration: inactive condition returns 0
# ---------------------------------------------------------------------------
func _test_get_duration_not_active() -> void:
	print("_test_get_duration_not_active")
	var m := ConditionManager.new()
	_check(m.get_duration(Condition.ID_POISONED) == 0, "inactive condition returns duration 0")


# ---------------------------------------------------------------------------
# tick: duration is decremented each turn
# ---------------------------------------------------------------------------
func _test_tick_decrements_duration() -> void:
	print("_test_tick_decrements_duration")
	var m := ConditionManager.new()
	m.add_condition(Condition.ID_PRONE, 3)
	m.tick()
	_check(m.get_duration(Condition.ID_PRONE) == 2, "duration decremented to 2 after one tick")
	m.tick()
	_check(m.get_duration(Condition.ID_PRONE) == 1, "duration decremented to 1 after two ticks")


# ---------------------------------------------------------------------------
# tick: condition is removed when duration reaches 0
# ---------------------------------------------------------------------------
func _test_tick_removes_expired_condition() -> void:
	print("_test_tick_removes_expired_condition")
	var m := ConditionManager.new()
	m.add_condition(Condition.ID_POISONED, 1)
	m.tick()
	_check(m.has_condition(Condition.ID_POISONED) == false, "condition removed after duration expires")
	_check(m.get_duration(Condition.ID_POISONED) == 0, "duration returns 0 after expiry")


# ---------------------------------------------------------------------------
# tick: indefinite conditions are never removed by tick
# ---------------------------------------------------------------------------
func _test_tick_does_not_remove_indefinite() -> void:
	print("_test_tick_does_not_remove_indefinite")
	var m := ConditionManager.new()
	m.add_condition(Condition.ID_GRAPPLED)  # indefinite
	m.tick()
	m.tick()
	m.tick()
	_check(m.has_condition(Condition.ID_GRAPPLED) == true, "indefinite condition persists after ticks")
	_check(m.get_duration(Condition.ID_GRAPPLED) == -1, "indefinite duration unchanged by ticks")


# ---------------------------------------------------------------------------
# tick: timed and indefinite conditions handled correctly in the same manager
# ---------------------------------------------------------------------------
func _test_tick_multiple_conditions() -> void:
	print("_test_tick_multiple_conditions")
	var m := ConditionManager.new()
	m.add_condition(Condition.ID_PRONE, 2)
	m.add_condition(Condition.ID_GRAPPLED)  # indefinite
	m.tick()
	_check(m.has_condition(Condition.ID_PRONE) == true, "prone still active after 1 tick (had 2)")
	_check(m.has_condition(Condition.ID_GRAPPLED) == true, "grappled still active after 1 tick")
	m.tick()
	_check(m.has_condition(Condition.ID_PRONE) == false, "prone removed after 2 ticks")
	_check(m.has_condition(Condition.ID_GRAPPLED) == true, "grappled unaffected by ticks")


# ---------------------------------------------------------------------------
# Prone imposes attack roll disadvantage
# ---------------------------------------------------------------------------
func _test_prone_attack_disadvantage() -> void:
	print("_test_prone_attack_disadvantage")
	var m := ConditionManager.new()
	m.add_condition(Condition.ID_PRONE)
	_check(m.has_attack_roll_disadvantage() == true, "prone imposes attack roll disadvantage")


# ---------------------------------------------------------------------------
# Poisoned imposes attack roll disadvantage
# ---------------------------------------------------------------------------
func _test_poisoned_attack_disadvantage() -> void:
	print("_test_poisoned_attack_disadvantage")
	var m := ConditionManager.new()
	m.add_condition(Condition.ID_POISONED)
	_check(m.has_attack_roll_disadvantage() == true, "poisoned imposes attack roll disadvantage")


# ---------------------------------------------------------------------------
# Grappled does NOT impose attack roll disadvantage
# ---------------------------------------------------------------------------
func _test_grappled_no_attack_disadvantage() -> void:
	print("_test_grappled_no_attack_disadvantage")
	var m := ConditionManager.new()
	m.add_condition(Condition.ID_GRAPPLED)
	_check(m.has_attack_roll_disadvantage() == false, "grappled does not impose attack roll disadvantage")


# ---------------------------------------------------------------------------
# Poisoned imposes ability check disadvantage
# ---------------------------------------------------------------------------
func _test_poisoned_ability_check_disadvantage() -> void:
	print("_test_poisoned_ability_check_disadvantage")
	var m := ConditionManager.new()
	m.add_condition(Condition.ID_POISONED)
	_check(m.has_ability_check_disadvantage() == true, "poisoned imposes ability check disadvantage")


# ---------------------------------------------------------------------------
# Prone does NOT impose ability check disadvantage
# ---------------------------------------------------------------------------
func _test_prone_no_ability_check_disadvantage() -> void:
	print("_test_prone_no_ability_check_disadvantage")
	var m := ConditionManager.new()
	m.add_condition(Condition.ID_PRONE)
	_check(m.has_ability_check_disadvantage() == false, "prone does not impose ability check disadvantage")


# ---------------------------------------------------------------------------
# Grappled sets speed to zero
# ---------------------------------------------------------------------------
func _test_grappled_speed_zero() -> void:
	print("_test_grappled_speed_zero")
	var m := ConditionManager.new()
	m.add_condition(Condition.ID_GRAPPLED)
	_check(m.has_speed_zero() == true, "grappled sets actor speed to zero")


# ---------------------------------------------------------------------------
# Prone does NOT set speed to zero
# ---------------------------------------------------------------------------
func _test_prone_no_speed_zero() -> void:
	print("_test_prone_no_speed_zero")
	var m := ConditionManager.new()
	m.add_condition(Condition.ID_PRONE)
	_check(m.has_speed_zero() == false, "prone does not set speed to zero")


# ---------------------------------------------------------------------------
# Actor with no conditions has no roll/stat effects
# ---------------------------------------------------------------------------
func _test_no_conditions_no_effects() -> void:
	print("_test_no_conditions_no_effects")
	var m := ConditionManager.new()
	_check(m.has_attack_roll_disadvantage() == false, "no conditions → no attack roll disadvantage")
	_check(m.has_ability_check_disadvantage() == false, "no conditions → no ability check disadvantage")
	_check(m.has_speed_zero() == false, "no conditions → speed not forced to zero")


# ---------------------------------------------------------------------------
# Condition.DEFINITIONS contains all V1 conditions
# ---------------------------------------------------------------------------
func _test_condition_definitions_present() -> void:
	print("_test_condition_definitions_present")
	_check(Condition.DEFINITIONS.has(Condition.ID_PRONE), "DEFINITIONS contains prone")
	_check(Condition.DEFINITIONS.has(Condition.ID_GRAPPLED), "DEFINITIONS contains grappled")
	_check(Condition.DEFINITIONS.has(Condition.ID_POISONED), "DEFINITIONS contains poisoned")
	var prone_def: Dictionary = Condition.get_definition(Condition.ID_PRONE)
	_check(prone_def.has("attack_disadvantage"), "prone definition has attack_disadvantage key")
	_check(prone_def.has("ability_check_disadvantage"), "prone definition has ability_check_disadvantage key")
	_check(prone_def.has("speed_zero"), "prone definition has speed_zero key")
