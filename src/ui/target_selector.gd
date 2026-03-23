## TargetSelector
## UI layer class — extends Node.
## Manages the target selection phase during combat.
##
## Responsibilities:
##   - Store the set of valid target positions supplied by the combat runtime.
##   - Gate selection attempts; only positions in the valid set are accepted.
##   - Emit target_confirmed when a valid target is chosen.
##   - Emit target_cancelled when the player cancels; the combat runtime must
##     return focus to the action menu on receiving this signal.
##
## Usage:
##   selector.begin_selection(valid_targets, "single")
##   selector.select_target(Vector2i(3, 2))   # → true + emits target_confirmed
##   selector.cancel()                         # → emits target_cancelled
class_name TargetSelector
extends Node

## Emitted when the player confirms a valid target position.
## The combat runtime receives this and advances to resolution.
signal target_confirmed(position: Vector2i)

## Emitted when the player cancels target selection.
## The combat runtime must reconnect the player to the action menu.
signal target_cancelled()

var _valid_targets: Array[Vector2i] = []
var _mode: String = "single"
var _active: bool = false


## Activates target selection with the provided set of valid positions.
## mode must be "single" or "aoe".
## While active, only positions in valid_targets will be accepted by select_target.
func begin_selection(valid_targets: Array[Vector2i], mode: String) -> void:
	_valid_targets = valid_targets.duplicate()
	_mode = mode
	_active = true


## Attempts to confirm the given position as the chosen target.
## Returns true and emits target_confirmed if the position is valid and selection is active.
## Returns false without emitting anything if the position is invalid or selection is inactive.
## _active is set to false before emitting to prevent re-entrant selection from a handler.
func select_target(position: Vector2i) -> bool:
	if not _active:
		return false
	if not is_valid_target(position):
		return false
	_active = false
	target_confirmed.emit(position)
	return true


## Cancels the current target selection.
## Emits target_cancelled if selection is active; otherwise does nothing.
## _active is cleared before emitting to prevent re-entrant cancel.
## _valid_targets is cleared after emitting so signal handlers can inspect
## the positions that were in play at the time of cancellation.
func cancel() -> void:
	if not _active:
		return
	_active = false
	target_cancelled.emit()
	_valid_targets = []


## Returns true if target selection is currently active.
func is_active() -> bool:
	return _active


## Returns the current selection mode ("single" or "aoe").
## Returns an empty string if selection is not active.
func get_mode() -> String:
	if not _active:
		return ""
	return _mode


## Returns the list of valid target positions for the current selection.
## Returns an empty array if selection is not active.
func get_valid_targets() -> Array[Vector2i]:
	if not _active:
		return []
	return _valid_targets.duplicate()


## Returns true if the given position is among the current valid targets.
func is_valid_target(position: Vector2i) -> bool:
	return _valid_targets.has(position)
