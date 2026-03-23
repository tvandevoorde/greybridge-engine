## test_combat_input_lock.gd
## Unit tests for CombatInputLock (src/combat_runtime/combat_input_lock.gd).
##
## Run headlessly from the Godot project root (src/) with:
##   godot --headless --script ./tests/unit/combat_runtime/test_combat_input_lock.gd
##
## Exit code 0 = all assertions passed; 1 = one or more assertions failed.
extends SceneTree

const CombatInputLockClass = preload("res://combat_runtime/combat_input_lock.gd")

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
	_test_initial_state_is_unlocked()
	_test_lock_sets_locked_flag()
	_test_lock_stores_reason()
	_test_lock_empty_reason()
	_test_unlock_clears_locked_flag()
	_test_unlock_clears_reason()
	_test_lock_emits_signal()
	_test_lock_signal_carries_reason()
	_test_unlock_emits_signal()
	_test_lock_idempotent()
	_test_unlock_idempotent()
	_test_lock_idempotent_no_duplicate_signal()
	_test_unlock_idempotent_no_duplicate_signal()
	_test_lock_then_unlock_then_lock_again()
	_test_get_reason_empty_when_unlocked()


# ---------------------------------------------------------------------------
# Initial state
# ---------------------------------------------------------------------------
func _test_initial_state_is_unlocked() -> void:
	print("_test_initial_state_is_unlocked")
	var lock := CombatInputLockClass.new()
	_check(lock.is_locked() == false, "starts unlocked")
	_check(lock.get_reason() == "",    "starts with empty reason")
	lock.free()


# ---------------------------------------------------------------------------
# lock()
# ---------------------------------------------------------------------------
func _test_lock_sets_locked_flag() -> void:
	print("_test_lock_sets_locked_flag")
	var lock := CombatInputLockClass.new()
	lock.lock("dice_resolution")
	_check(lock.is_locked() == true, "is_locked() true after lock()")
	lock.free()


func _test_lock_stores_reason() -> void:
	print("_test_lock_stores_reason")
	var lock := CombatInputLockClass.new()
	lock.lock("animation")
	_check(lock.get_reason() == "animation", "get_reason() returns supplied reason")
	lock.free()


func _test_lock_empty_reason() -> void:
	print("_test_lock_empty_reason")
	var lock := CombatInputLockClass.new()
	lock.lock()
	_check(lock.is_locked() == true, "lock() with no reason still locks")
	_check(lock.get_reason() == "",   "get_reason() is empty when no reason supplied")
	lock.free()


# ---------------------------------------------------------------------------
# unlock()
# ---------------------------------------------------------------------------
func _test_unlock_clears_locked_flag() -> void:
	print("_test_unlock_clears_locked_flag")
	var lock := CombatInputLockClass.new()
	lock.lock("dice_resolution")
	lock.unlock()
	_check(lock.is_locked() == false, "is_locked() false after unlock()")
	lock.free()


func _test_unlock_clears_reason() -> void:
	print("_test_unlock_clears_reason")
	var lock := CombatInputLockClass.new()
	lock.lock("animation")
	lock.unlock()
	_check(lock.get_reason() == "", "get_reason() empty after unlock()")
	lock.free()


# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------
func _test_lock_emits_signal() -> void:
	print("_test_lock_emits_signal")
	var lock := CombatInputLockClass.new()
	var emitted: bool = false
	lock.input_locked.connect(func(_r: String) -> void: emitted = true)
	lock.lock("dice_resolution")
	_check(emitted == true, "input_locked signal emitted on lock()")
	lock.free()


func _test_lock_signal_carries_reason() -> void:
	print("_test_lock_signal_carries_reason")
	var lock := CombatInputLockClass.new()
	var received_reason: String = ""
	lock.input_locked.connect(func(r: String) -> void: received_reason = r)
	lock.lock("animation")
	_check(received_reason == "animation", "input_locked signal carries reason")
	lock.free()


func _test_unlock_emits_signal() -> void:
	print("_test_unlock_emits_signal")
	var lock := CombatInputLockClass.new()
	var emitted: bool = false
	lock.input_unlocked.connect(func() -> void: emitted = true)
	lock.lock("dice_resolution")
	lock.unlock()
	_check(emitted == true, "input_unlocked signal emitted on unlock()")
	lock.free()


# ---------------------------------------------------------------------------
# Idempotency
# ---------------------------------------------------------------------------
func _test_lock_idempotent() -> void:
	print("_test_lock_idempotent")
	var lock := CombatInputLockClass.new()
	lock.lock("first")
	lock.lock("second")
	_check(lock.is_locked() == true,  "still locked after second lock() call")
	_check(lock.get_reason() == "first", "reason unchanged after duplicate lock()")
	lock.free()


func _test_unlock_idempotent() -> void:
	print("_test_unlock_idempotent")
	var lock := CombatInputLockClass.new()
	lock.unlock()
	_check(lock.is_locked() == false, "unlock() on unlocked lock is safe")
	lock.free()


func _test_lock_idempotent_no_duplicate_signal() -> void:
	print("_test_lock_idempotent_no_duplicate_signal")
	var lock := CombatInputLockClass.new()
	var count: int = 0
	lock.input_locked.connect(func(_r: String) -> void: count += 1)
	lock.lock("first")
	lock.lock("second")
	_check(count == 1, "input_locked emitted only once for duplicate lock() calls")
	lock.free()


func _test_unlock_idempotent_no_duplicate_signal() -> void:
	print("_test_unlock_idempotent_no_duplicate_signal")
	var lock := CombatInputLockClass.new()
	var count: int = 0
	lock.input_unlocked.connect(func() -> void: count += 1)
	lock.lock("first")
	lock.unlock()
	lock.unlock()
	_check(count == 1, "input_unlocked emitted only once for duplicate unlock() calls")
	lock.free()


# ---------------------------------------------------------------------------
# Lock/unlock cycle
# ---------------------------------------------------------------------------
func _test_lock_then_unlock_then_lock_again() -> void:
	print("_test_lock_then_unlock_then_lock_again")
	var lock := CombatInputLockClass.new()
	var locked_count: int = 0
	var unlocked_count: int = 0
	lock.input_locked.connect(func(_r: String) -> void: locked_count += 1)
	lock.input_unlocked.connect(func() -> void: unlocked_count += 1)

	lock.lock("dice_resolution")
	lock.unlock()
	lock.lock("animation")
	lock.unlock()

	_check(locked_count == 2,   "input_locked emitted twice for two lock cycles")
	_check(unlocked_count == 2, "input_unlocked emitted twice for two lock cycles")
	_check(lock.is_locked() == false, "ends unlocked after two full cycles")
	lock.free()


# ---------------------------------------------------------------------------
# get_reason when unlocked
# ---------------------------------------------------------------------------
func _test_get_reason_empty_when_unlocked() -> void:
	print("_test_get_reason_empty_when_unlocked")
	var lock := CombatInputLockClass.new()
	_check(lock.get_reason() == "", "get_reason() empty on a fresh lock")
	lock.free()
