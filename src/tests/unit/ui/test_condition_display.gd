## test_condition_display.gd
## Unit tests for ConditionDisplay (src/ui/condition_display.gd).
##
## Acceptance criteria from the "Implement condition visualization layer" issue:
##   - Displays active conditions above actor
##   - Updates when condition applied/removed
##   - Reflects duration changes
##   - No rules logic inside visualization
##
## Run headlessly from the Godot project root (src/) with:
##   godot --headless --script ./tests/unit/ui/test_condition_display.gd
extends SceneTree

const ConditionDisplayClass = preload("res://ui/condition_display.gd")

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


func _make_display() -> ConditionDisplayClass:
	return ConditionDisplayClass.new()


func _run_all_tests() -> void:
	_test_initial_state_empty()
	_test_refresh_sets_actor_id()
	_test_refresh_populates_conditions()
	_test_get_condition_count()
	_test_get_displayed_conditions_keys()
	_test_has_condition_true()
	_test_has_condition_false()
	_test_get_condition_label()
	_test_get_condition_label_missing()
	_test_get_condition_duration_timed()
	_test_get_condition_duration_indefinite()
	_test_get_condition_duration_missing()
	_test_refresh_removes_conditions_not_in_new_snapshot()
	_test_refresh_with_empty_array_clears_all()
	_test_refresh_replaces_actor_id()
	_test_duration_update_reflected()
	_test_conditions_updated_signal_emitted()
	_test_conditions_updated_signal_carries_actor_id()
	_test_multiple_conditions_shown()
	_test_no_rules_logic_present()


# ---------------------------------------------------------------------------
# Initial state
# ---------------------------------------------------------------------------
func _test_initial_state_empty() -> void:
	print("_test_initial_state_empty")
	var d := _make_display()
	_check(d.get_actor_id() == "", "actor_id is empty before first refresh")
	_check(d.get_condition_count() == 0, "no conditions before first refresh")
	_check(d.get_displayed_conditions().size() == 0, "displayed conditions array is empty")
	d.free()


# ---------------------------------------------------------------------------
# refresh sets actor_id
# ---------------------------------------------------------------------------
func _test_refresh_sets_actor_id() -> void:
	print("_test_refresh_sets_actor_id")
	var d := _make_display()
	d.refresh("hero", [])
	_check(d.get_actor_id() == "hero", "actor_id is 'hero' after refresh")
	d.free()


# ---------------------------------------------------------------------------
# refresh populates conditions from the array
# ---------------------------------------------------------------------------
func _test_refresh_populates_conditions() -> void:
	print("_test_refresh_populates_conditions")
	var d := _make_display()
	var conditions: Array = [
		{"id": "prone", "name": "Prone", "duration": -1},
	]
	d.refresh("fighter", conditions)
	_check(d.get_condition_count() == 1, "one condition after refresh with one entry")
	d.free()


# ---------------------------------------------------------------------------
# get_condition_count
# ---------------------------------------------------------------------------
func _test_get_condition_count() -> void:
	print("_test_get_condition_count")
	var d := _make_display()
	d.refresh("hero", [
		{"id": "prone",    "name": "Prone",    "duration": -1},
		{"id": "poisoned", "name": "Poisoned", "duration": 3},
	])
	_check(d.get_condition_count() == 2, "two conditions after refresh with two entries")
	d.free()


# ---------------------------------------------------------------------------
# get_displayed_conditions contains expected keys
# ---------------------------------------------------------------------------
func _test_get_displayed_conditions_keys() -> void:
	print("_test_get_displayed_conditions_keys")
	var d := _make_display()
	d.refresh("hero", [{"id": "prone", "name": "Prone", "duration": -1}])
	var list: Array = d.get_displayed_conditions()
	_check(list.size() == 1, "displayed conditions has one entry")
	var entry: Dictionary = list[0]
	_check(entry.has("id"),       "entry has 'id' key")
	_check(entry.has("name"),     "entry has 'name' key")
	_check(entry.has("duration"), "entry has 'duration' key")
	_check(entry["id"] == "prone",  "entry id is 'prone'")
	_check(entry["name"] == "Prone", "entry name is 'Prone'")
	d.free()


# ---------------------------------------------------------------------------
# has_condition
# ---------------------------------------------------------------------------
func _test_has_condition_true() -> void:
	print("_test_has_condition_true")
	var d := _make_display()
	d.refresh("hero", [{"id": "grappled", "name": "Grappled", "duration": -1}])
	_check(d.has_condition("grappled") == true, "has_condition returns true for active condition")
	d.free()


func _test_has_condition_false() -> void:
	print("_test_has_condition_false")
	var d := _make_display()
	d.refresh("hero", [])
	_check(d.has_condition("prone") == false, "has_condition returns false when condition absent")
	d.free()


# ---------------------------------------------------------------------------
# get_condition_label
# ---------------------------------------------------------------------------
func _test_get_condition_label() -> void:
	print("_test_get_condition_label")
	var d := _make_display()
	d.refresh("hero", [{"id": "poisoned", "name": "Poisoned", "duration": 2}])
	_check(d.get_condition_label("poisoned") == "Poisoned", "label returns 'Poisoned'")
	d.free()


func _test_get_condition_label_missing() -> void:
	print("_test_get_condition_label_missing")
	var d := _make_display()
	d.refresh("hero", [])
	_check(d.get_condition_label("prone") == "", "label returns '' for absent condition")
	d.free()


# ---------------------------------------------------------------------------
# get_condition_duration
# ---------------------------------------------------------------------------
func _test_get_condition_duration_timed() -> void:
	print("_test_get_condition_duration_timed")
	var d := _make_display()
	d.refresh("hero", [{"id": "poisoned", "name": "Poisoned", "duration": 4}])
	_check(d.get_condition_duration("poisoned") == 4, "duration is 4 for timed condition")
	d.free()


func _test_get_condition_duration_indefinite() -> void:
	print("_test_get_condition_duration_indefinite")
	var d := _make_display()
	d.refresh("hero", [{"id": "grappled", "name": "Grappled", "duration": -1}])
	_check(d.get_condition_duration("grappled") == -1, "duration is -1 for indefinite condition")
	d.free()


func _test_get_condition_duration_missing() -> void:
	print("_test_get_condition_duration_missing")
	var d := _make_display()
	d.refresh("hero", [])
	_check(d.get_condition_duration("prone") == 0, "duration returns 0 for absent condition")
	d.free()


# ---------------------------------------------------------------------------
# Conditions removed when absent from new snapshot (AC: updates when removed)
# ---------------------------------------------------------------------------
func _test_refresh_removes_conditions_not_in_new_snapshot() -> void:
	print("_test_refresh_removes_conditions_not_in_new_snapshot")
	var d := _make_display()
	d.refresh("hero", [
		{"id": "prone",    "name": "Prone",    "duration": -1},
		{"id": "poisoned", "name": "Poisoned", "duration": 2},
	])
	_check(d.get_condition_count() == 2, "two conditions before second refresh")
	# Second refresh: only poisoned remains
	d.refresh("hero", [
		{"id": "poisoned", "name": "Poisoned", "duration": 1},
	])
	_check(d.get_condition_count() == 1, "one condition after second refresh")
	_check(d.has_condition("prone") == false, "prone removed from display")
	_check(d.has_condition("poisoned") == true, "poisoned still shown")
	d.free()


# ---------------------------------------------------------------------------
# Empty snapshot clears all conditions (AC: updates when removed)
# ---------------------------------------------------------------------------
func _test_refresh_with_empty_array_clears_all() -> void:
	print("_test_refresh_with_empty_array_clears_all")
	var d := _make_display()
	d.refresh("hero", [{"id": "prone", "name": "Prone", "duration": -1}])
	_check(d.get_condition_count() == 1, "one condition before clear")
	d.refresh("hero", [])
	_check(d.get_condition_count() == 0, "all conditions cleared after refresh with empty array")
	d.free()


# ---------------------------------------------------------------------------
# refresh updates actor_id when called a second time
# ---------------------------------------------------------------------------
func _test_refresh_replaces_actor_id() -> void:
	print("_test_refresh_replaces_actor_id")
	var d := _make_display()
	d.refresh("hero", [])
	_check(d.get_actor_id() == "hero", "actor is 'hero' after first refresh")
	d.refresh("bandit", [])
	_check(d.get_actor_id() == "bandit", "actor is 'bandit' after second refresh")
	d.free()


# ---------------------------------------------------------------------------
# Duration updates reflected on next refresh (AC: reflects duration changes)
# ---------------------------------------------------------------------------
func _test_duration_update_reflected() -> void:
	print("_test_duration_update_reflected")
	var d := _make_display()
	d.refresh("hero", [{"id": "poisoned", "name": "Poisoned", "duration": 3}])
	_check(d.get_condition_duration("poisoned") == 3, "duration is 3 initially")
	d.refresh("hero", [{"id": "poisoned", "name": "Poisoned", "duration": 2}])
	_check(d.get_condition_duration("poisoned") == 2, "duration updated to 2 after refresh")
	d.refresh("hero", [{"id": "poisoned", "name": "Poisoned", "duration": 1}])
	_check(d.get_condition_duration("poisoned") == 1, "duration updated to 1 after refresh")
	d.free()


# ---------------------------------------------------------------------------
# conditions_updated signal emitted on refresh (AC: updates when condition applied/removed)
# ---------------------------------------------------------------------------
func _test_conditions_updated_signal_emitted() -> void:
	print("_test_conditions_updated_signal_emitted")
	var d := _make_display()
	var signal_count: int = 0
	d.conditions_updated.connect(func(_id: String) -> void: signal_count += 1)
	d.refresh("hero", [])
	_check(signal_count == 1, "conditions_updated emitted once on refresh")
	d.refresh("hero", [{"id": "prone", "name": "Prone", "duration": -1}])
	_check(signal_count == 2, "conditions_updated emitted on second refresh")
	d.free()


# ---------------------------------------------------------------------------
# Signal carries correct actor_id
# ---------------------------------------------------------------------------
func _test_conditions_updated_signal_carries_actor_id() -> void:
	print("_test_conditions_updated_signal_carries_actor_id")
	var d := _make_display()
	var received_id: String = ""
	d.conditions_updated.connect(func(id: String) -> void: received_id = id)
	d.refresh("bandit_1", [])
	_check(received_id == "bandit_1", "conditions_updated carries actor_id 'bandit_1'")
	d.free()


# ---------------------------------------------------------------------------
# Multiple conditions displayed simultaneously (AC: displays active conditions)
# ---------------------------------------------------------------------------
func _test_multiple_conditions_shown() -> void:
	print("_test_multiple_conditions_shown")
	var d := _make_display()
	d.refresh("hero", [
		{"id": "prone",    "name": "Prone",    "duration": -1},
		{"id": "grappled", "name": "Grappled", "duration": -1},
		{"id": "poisoned", "name": "Poisoned", "duration": 2},
	])
	_check(d.get_condition_count() == 3, "three conditions displayed simultaneously")
	_check(d.has_condition("prone"),    "prone shown")
	_check(d.has_condition("grappled"), "grappled shown")
	_check(d.has_condition("poisoned"), "poisoned shown")
	d.free()


# ---------------------------------------------------------------------------
# No rules logic: ConditionDisplay has no rules-engine methods
# ---------------------------------------------------------------------------
func _test_no_rules_logic_present() -> void:
	print("_test_no_rules_logic_present")
	var d := _make_display()
	# ConditionDisplay must NOT expose any rules-engine calculation methods.
	# These methods must NOT exist on the class:
	_check(not d.has_method("has_attack_roll_disadvantage"),
		"no has_attack_roll_disadvantage method (rules logic must stay in rules_engine)")
	_check(not d.has_method("tick"),
		"no tick method (duration decrement is rules_engine responsibility)")
	_check(not d.has_method("add_condition"),
		"no add_condition method (condition management is rules_engine responsibility)")
	d.free()
