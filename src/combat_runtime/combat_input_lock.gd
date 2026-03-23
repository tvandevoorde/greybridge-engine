## CombatInputLock
## Combat runtime class — extends Node.
## Tracks the shared input-lock state for a combat encounter.
##
## Responsibilities:
##   - Provide a single authoritative locked / unlocked flag.
##   - Allow any runtime system (dice resolution, animation playback) to lock
##     player input by calling lock() with an optional descriptive reason.
##   - Notify subscribers via signals so UI components can react.
##   - Provide is_locked() for poll-based checks in UI selection methods.
##
## Usage:
##   lock.lock("dice_resolution")    # blocks input; emits input_locked
##   lock.unlock()                   # restores input; emits input_unlocked
##   lock.is_locked()                # true while any lock is active
##   lock.get_reason()               # empty string when unlocked
##
## UI components receive a reference via set_input_lock() and call is_locked()
## inside their selection handlers to return early without emitting signals.
class_name CombatInputLock
extends Node

## Emitted when input transitions from unlocked → locked.
## reason : String — caller-supplied description (e.g. "dice_resolution",
##                    "animation").  May be an empty string.
signal input_locked(reason: String)

## Emitted when input transitions from locked → unlocked.
signal input_unlocked()

var _locked: bool = false
var _reason: String = ""


## Locks player input.
## Has no effect when input is already locked (idempotent).
## reason is stored for diagnostic inspection via get_reason().
func lock(reason: String = "") -> void:
	if _locked:
		return
	_locked = true
	_reason = reason
	input_locked.emit(reason)


## Unlocks player input.
## Has no effect when input is already unlocked (idempotent).
func unlock() -> void:
	if not _locked:
		return
	_locked = false
	_reason = ""
	input_unlocked.emit()


## Returns true while input is locked.
func is_locked() -> bool:
	return _locked


## Returns the reason string supplied to the most recent lock() call.
## Returns an empty string when input is not locked.
func get_reason() -> String:
	return _reason
