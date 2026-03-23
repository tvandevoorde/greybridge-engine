## test_target_selector.gd
## Unit tests for TargetSelector (src/ui/target_selector.gd).
##
## Run headlessly from the Godot project root (src/) with:
##   godot --headless --script ./tests/unit/ui/test_target_selector.gd
extends SceneTree

const TargetSelectorClass = preload("res://ui/target_selector.gd")
const CombatInputLockClass = preload("res://combat_runtime/combat_input_lock.gd")

var _pass_count: int = 0
var _fail_count: int = 0
var _confirmed_position: Vector2i = Vector2i(-1, -1)
var _confirmed_count: int = 0
var _cancelled_count: int = 0


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


func _on_target_confirmed(position: Vector2i) -> void:
	_confirmed_position = position
	_confirmed_count += 1


func _on_target_cancelled() -> void:
	_cancelled_count += 1


func _make_selector() -> TargetSelectorClass:
	var selector := TargetSelectorClass.new()
	selector.target_confirmed.connect(_on_target_confirmed)
	selector.target_cancelled.connect(_on_target_cancelled)
	_confirmed_position = Vector2i(-1, -1)
	_confirmed_count = 0
	_cancelled_count = 0
	return selector


func _run_all_tests() -> void:
	_test_initial_state_not_active()
	_test_initial_get_valid_targets_empty()
	_test_initial_is_valid_target_false()
	_test_initial_get_mode_empty()
	_test_begin_selection_activates()
	_test_begin_selection_stores_mode_single()
	_test_begin_selection_stores_mode_aoe()
	_test_begin_selection_stores_valid_targets()
	_test_get_valid_targets_returns_copy()
	_test_is_valid_target_true_for_valid_position()
	_test_is_valid_target_false_for_unknown_position()
	_test_select_target_when_inactive_returns_false()
	_test_select_target_invalid_position_returns_false()
	_test_select_target_invalid_emits_no_signal()
	_test_select_target_valid_returns_true()
	_test_select_target_valid_emits_confirmed()
	_test_select_target_confirmed_position_correct()
	_test_select_target_deactivates_selector()
	_test_cancel_when_inactive_does_nothing()
	_test_cancel_when_active_emits_cancelled()
	_test_cancel_deactivates_selector()
	_test_cancel_clears_valid_targets()
	_test_second_begin_replaces_previous_state()
	_test_select_target_after_cancel_returns_false()
	_test_confirmed_signal_fired_exactly_once()
	_test_select_target_blocked_when_input_locked()
	_test_select_target_succeeds_after_unlock()
	_test_cancel_blocked_when_input_locked()
	_test_cancel_succeeds_after_unlock()
	_test_no_lock_attached_behaves_normally()
	_test_set_input_lock_null_detaches_lock()


# ---------------------------------------------------------------------------
# Initial state
# ---------------------------------------------------------------------------
func _test_initial_state_not_active() -> void:
	print("_test_initial_state_not_active")
	var selector := _make_selector()
	_check(selector.is_active() == false, "selector is inactive before begin_selection")


func _test_initial_get_valid_targets_empty() -> void:
	print("_test_initial_get_valid_targets_empty")
	var selector := _make_selector()
	_check(selector.get_valid_targets().size() == 0,
		"get_valid_targets returns empty array before begin_selection")


func _test_initial_is_valid_target_false() -> void:
	print("_test_initial_is_valid_target_false")
	var selector := _make_selector()
	_check(selector.is_valid_target(Vector2i(0, 0)) == false,
		"is_valid_target returns false before begin_selection")


func _test_initial_get_mode_empty() -> void:
	print("_test_initial_get_mode_empty")
	var selector := _make_selector()
	_check(selector.get_mode() == "",
		"get_mode returns empty string before begin_selection")


# ---------------------------------------------------------------------------
# begin_selection
# ---------------------------------------------------------------------------
func _test_begin_selection_activates() -> void:
	print("_test_begin_selection_activates")
	var selector := _make_selector()
	selector.begin_selection([Vector2i(1, 0)], "single")
	_check(selector.is_active() == true, "selector is active after begin_selection")


func _test_begin_selection_stores_mode_single() -> void:
	print("_test_begin_selection_stores_mode_single")
	var selector := _make_selector()
	selector.begin_selection([], "single")
	_check(selector.get_mode() == "single", "mode stored as 'single'")


func _test_begin_selection_stores_mode_aoe() -> void:
	print("_test_begin_selection_stores_mode_aoe")
	var selector := _make_selector()
	selector.begin_selection([], "aoe")
	_check(selector.get_mode() == "aoe", "mode stored as 'aoe'")


func _test_begin_selection_stores_valid_targets() -> void:
	print("_test_begin_selection_stores_valid_targets")
	var selector := _make_selector()
	var targets: Array[Vector2i] = [Vector2i(2, 3), Vector2i(5, 1)]
	selector.begin_selection(targets, "single")
	var stored := selector.get_valid_targets()
	_check(stored.size() == 2,                "two valid targets stored")
	_check(stored.has(Vector2i(2, 3)),         "first target position stored")
	_check(stored.has(Vector2i(5, 1)),         "second target position stored")


# ---------------------------------------------------------------------------
# get_valid_targets returns an independent copy (not the live array)
# ---------------------------------------------------------------------------
func _test_get_valid_targets_returns_copy() -> void:
	print("_test_get_valid_targets_returns_copy")
	var selector := _make_selector()
	var targets: Array[Vector2i] = [Vector2i(1, 0)]
	selector.begin_selection(targets, "single")
	var copy := selector.get_valid_targets()
	copy.clear()
	# Mutating the returned copy must not affect the selector's internal list
	_check(selector.get_valid_targets().size() == 1,
		"internal valid_targets unaffected by mutating the returned copy")


# ---------------------------------------------------------------------------
# is_valid_target
# ---------------------------------------------------------------------------
func _test_is_valid_target_true_for_valid_position() -> void:
	print("_test_is_valid_target_true_for_valid_position")
	var selector := _make_selector()
	selector.begin_selection([Vector2i(4, 2)], "single")
	_check(selector.is_valid_target(Vector2i(4, 2)) == true,
		"is_valid_target returns true for a position in the valid set")


func _test_is_valid_target_false_for_unknown_position() -> void:
	print("_test_is_valid_target_false_for_unknown_position")
	var selector := _make_selector()
	selector.begin_selection([Vector2i(4, 2)], "single")
	_check(selector.is_valid_target(Vector2i(9, 9)) == false,
		"is_valid_target returns false for a position not in the valid set")


# ---------------------------------------------------------------------------
# select_target — inactive / invalid
# ---------------------------------------------------------------------------
func _test_select_target_when_inactive_returns_false() -> void:
	print("_test_select_target_when_inactive_returns_false")
	var selector := _make_selector()
	_check(selector.select_target(Vector2i(0, 0)) == false,
		"select_target returns false when selector is inactive")


func _test_select_target_invalid_position_returns_false() -> void:
	print("_test_select_target_invalid_position_returns_false")
	var selector := _make_selector()
	selector.begin_selection([Vector2i(1, 0)], "single")
	_check(selector.select_target(Vector2i(9, 9)) == false,
		"select_target returns false for a position not in valid targets")


func _test_select_target_invalid_emits_no_signal() -> void:
	print("_test_select_target_invalid_emits_no_signal")
	var selector := _make_selector()
	selector.begin_selection([Vector2i(1, 0)], "single")
	selector.select_target(Vector2i(9, 9))
	_check(_confirmed_count == 0, "target_confirmed not emitted for invalid position")


# ---------------------------------------------------------------------------
# select_target — valid selection
# ---------------------------------------------------------------------------
func _test_select_target_valid_returns_true() -> void:
	print("_test_select_target_valid_returns_true")
	var selector := _make_selector()
	selector.begin_selection([Vector2i(3, 0)], "single")
	_check(selector.select_target(Vector2i(3, 0)) == true,
		"select_target returns true for valid position")


func _test_select_target_valid_emits_confirmed() -> void:
	print("_test_select_target_valid_emits_confirmed")
	var selector := _make_selector()
	selector.begin_selection([Vector2i(3, 0)], "single")
	selector.select_target(Vector2i(3, 0))
	_check(_confirmed_count == 1, "target_confirmed signal emitted once")


func _test_select_target_confirmed_position_correct() -> void:
	print("_test_select_target_confirmed_position_correct")
	var selector := _make_selector()
	selector.begin_selection([Vector2i(3, 0)], "single")
	selector.select_target(Vector2i(3, 0))
	_check(_confirmed_position == Vector2i(3, 0),
		"target_confirmed carries the correct position")


func _test_select_target_deactivates_selector() -> void:
	print("_test_select_target_deactivates_selector")
	var selector := _make_selector()
	selector.begin_selection([Vector2i(3, 0)], "single")
	selector.select_target(Vector2i(3, 0))
	_check(selector.is_active() == false, "selector deactivates after successful selection")


# ---------------------------------------------------------------------------
# cancel
# ---------------------------------------------------------------------------
func _test_cancel_when_inactive_does_nothing() -> void:
	print("_test_cancel_when_inactive_does_nothing")
	var selector := _make_selector()
	selector.cancel()
	_check(_cancelled_count == 0, "cancel when inactive emits no signal")


func _test_cancel_when_active_emits_cancelled() -> void:
	print("_test_cancel_when_active_emits_cancelled")
	var selector := _make_selector()
	selector.begin_selection([Vector2i(1, 0)], "single")
	selector.cancel()
	_check(_cancelled_count == 1, "target_cancelled emitted on cancel")


func _test_cancel_deactivates_selector() -> void:
	print("_test_cancel_deactivates_selector")
	var selector := _make_selector()
	selector.begin_selection([Vector2i(1, 0)], "single")
	selector.cancel()
	_check(selector.is_active() == false, "selector deactivates after cancel")


func _test_cancel_clears_valid_targets() -> void:
	print("_test_cancel_clears_valid_targets")
	var selector := _make_selector()
	selector.begin_selection([Vector2i(1, 0), Vector2i(2, 0)], "single")
	selector.cancel()
	_check(selector.get_valid_targets().size() == 0,
		"valid targets cleared after cancel")


# ---------------------------------------------------------------------------
# begin_selection called a second time replaces previous state
# ---------------------------------------------------------------------------
func _test_second_begin_replaces_previous_state() -> void:
	print("_test_second_begin_replaces_previous_state")
	var selector := _make_selector()
	selector.begin_selection([Vector2i(1, 0)], "single")
	selector.begin_selection([Vector2i(5, 5), Vector2i(6, 6)], "aoe")
	_check(selector.get_mode() == "aoe",              "mode updated on second begin_selection")
	_check(selector.get_valid_targets().size() == 2,  "target list replaced on second begin_selection")
	_check(selector.is_valid_target(Vector2i(1, 0)) == false,
		"old target no longer valid after second begin_selection")
	_check(selector.is_valid_target(Vector2i(5, 5)) == true,
		"new target valid after second begin_selection")


# ---------------------------------------------------------------------------
# After cancel, select_target returns false (cannot select after cancel)
# ---------------------------------------------------------------------------
func _test_select_target_after_cancel_returns_false() -> void:
	print("_test_select_target_after_cancel_returns_false")
	var selector := _make_selector()
	selector.begin_selection([Vector2i(1, 0)], "single")
	selector.cancel()
	_check(selector.select_target(Vector2i(1, 0)) == false,
		"select_target returns false after cancel deactivates selector")


# ---------------------------------------------------------------------------
# target_confirmed is fired exactly once per successful selection
# ---------------------------------------------------------------------------
func _test_confirmed_signal_fired_exactly_once() -> void:
	print("_test_confirmed_signal_fired_exactly_once")
	var selector := _make_selector()
	selector.begin_selection([Vector2i(2, 2)], "single")
	selector.select_target(Vector2i(2, 2))
	# Attempting a second selection after deactivation must not fire again
	selector.select_target(Vector2i(2, 2))
	_check(_confirmed_count == 1, "target_confirmed fired exactly once per selection")


# ---------------------------------------------------------------------------
# Input lock — select_target is blocked when a lock is active
# ---------------------------------------------------------------------------
func _test_select_target_blocked_when_input_locked() -> void:
	print("_test_select_target_blocked_when_input_locked")
	var selector := TargetSelectorClass.new()
	selector.target_confirmed.connect(func(p: Vector2i) -> void: _confirmed_count += 1)
	_confirmed_count = 0
	var lock := CombatInputLockClass.new()
	selector.set_input_lock(lock)
	selector.begin_selection([Vector2i(1, 1)], "single")
	lock.lock("dice_resolution")
	_check(selector.select_target(Vector2i(1, 1)) == false, "select_target returns false when locked")
	_check(_confirmed_count == 0, "target_confirmed not emitted when locked")
	_check(selector.is_active() == true, "selector remains active when input locked")
	lock.free()
	selector.free()


# ---------------------------------------------------------------------------
# Input lock — select_target succeeds after unlock
# ---------------------------------------------------------------------------
func _test_select_target_succeeds_after_unlock() -> void:
print("_test_select_target_succeeds_after_unlock")
var selector := TargetSelectorClass.new()
selector.target_confirmed.connect(func(p: Vector2i) -> void: _confirmed_count += 1)
_confirmed_count = 0
var lock := CombatInputLockClass.new()
selector.set_input_lock(lock)
selector.begin_selection([Vector2i(1, 1)], "single")
lock.lock("animation")
selector.select_target(Vector2i(1, 1))
lock.unlock()
_check(selector.select_target(Vector2i(1, 1)) == true, "select_target succeeds after unlock")
_check(_confirmed_count == 1, "target_confirmed emitted once after unlock")
lock.free()
selector.free()


# ---------------------------------------------------------------------------
# Input lock — cancel is blocked when a lock is active
# ---------------------------------------------------------------------------
func _test_cancel_blocked_when_input_locked() -> void:
print("_test_cancel_blocked_when_input_locked")
var selector := TargetSelectorClass.new()
selector.target_cancelled.connect(func() -> void: _cancelled_count += 1)
_cancelled_count = 0
var lock := CombatInputLockClass.new()
selector.set_input_lock(lock)
selector.begin_selection([Vector2i(1, 1)], "single")
lock.lock("dice_resolution")
selector.cancel()
_check(_cancelled_count == 0, "target_cancelled not emitted when input locked")
_check(selector.is_active() == true, "selector remains active when cancel blocked")
lock.free()
selector.free()


# ---------------------------------------------------------------------------
# Input lock — cancel succeeds after unlock
# ---------------------------------------------------------------------------
func _test_cancel_succeeds_after_unlock() -> void:
print("_test_cancel_succeeds_after_unlock")
var selector := TargetSelectorClass.new()
selector.target_cancelled.connect(func() -> void: _cancelled_count += 1)
_cancelled_count = 0
var lock := CombatInputLockClass.new()
selector.set_input_lock(lock)
selector.begin_selection([Vector2i(1, 1)], "single")
lock.lock("animation")
selector.cancel()
_check(_cancelled_count == 0, "cancel blocked while locked")
lock.unlock()
selector.cancel()
_check(_cancelled_count == 1, "cancel succeeds after unlock")
lock.free()
selector.free()


# ---------------------------------------------------------------------------
# Input lock — no lock attached → normal behaviour
# ---------------------------------------------------------------------------
func _test_no_lock_attached_behaves_normally() -> void:
print("_test_no_lock_attached_behaves_normally")
var selector := TargetSelectorClass.new()
selector.target_confirmed.connect(func(p: Vector2i) -> void: _confirmed_count += 1)
_confirmed_count = 0
selector.begin_selection([Vector2i(2, 2)], "single")
_check(selector.select_target(Vector2i(2, 2)) == true, "select_target works without a lock")
_check(_confirmed_count == 1, "target_confirmed emitted without lock")
selector.free()


# ---------------------------------------------------------------------------
# Input lock — null detaches any existing lock
# ---------------------------------------------------------------------------
func _test_set_input_lock_null_detaches_lock() -> void:
print("_test_set_input_lock_null_detaches_lock")
var selector := TargetSelectorClass.new()
selector.target_confirmed.connect(func(p: Vector2i) -> void: _confirmed_count += 1)
_confirmed_count = 0
var lock := CombatInputLockClass.new()
selector.set_input_lock(lock)
lock.lock("dice_resolution")
selector.begin_selection([Vector2i(3, 3)], "single")
_check(selector.select_target(Vector2i(3, 3)) == false, "select_target blocked before detach")
selector.set_input_lock(null)
_check(selector.select_target(Vector2i(3, 3)) == true, "select_target works after lock detached")
_check(_confirmed_count == 1, "target_confirmed emitted after lock detached")
lock.free()
selector.free()
