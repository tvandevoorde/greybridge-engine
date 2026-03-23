## ReactionWindowHandler
## Combat runtime class — extends Node.
## Manages reaction opportunity windows in a D&D 5e combat encounter.
##
## When a trigger event occurs (e.g., an attack is about to hit a creature),
## the handler opens a reaction window for the eligible reactor.  The window
## stays open until the reactor selects a reaction, explicitly declines, or the
## timeout elapses — whichever comes first.
##
## Enforces the SRD rule that each creature may use at most one reaction per
## round by delegating to ActionEconomy.use_reaction().
##
## Architecture: extends Node. Delegates rules validation to ReactionTrigger.
## No 5e math here beyond the reaction-slot check.
##
## Signals:
##   reaction_window_opened — the window just opened; UI should display options
##   reaction_selected      — reactor chose a reaction; runtime should resolve it
##   reaction_declined      — reactor passed (or timed out); resolution continues
##   reaction_window_closed — window closed regardless of outcome
##
## Timeout:
##   The window auto-closes after `timeout_seconds` seconds (default 10).
##   Set timeout_seconds before calling open_window() to override.
##   Call force_timeout() in tests to simulate expiry without a live game loop.
class_name ReactionWindowHandler
extends Node

const ActionEconomyClass = preload("res://rules_engine/core/action_economy.gd")
const ReactionTriggerClass = preload("res://rules_engine/core/reaction_trigger.gd")

## Default time, in seconds, before an open window auto-closes with no reaction.
const DEFAULT_TIMEOUT_SECONDS: float = 10.0

## Emitted when a new reaction window opens.
## trigger_type : int    (ReactionTrigger.TriggerType) — event that opened the window.
## reactor_id   : String — ID of the creature whose reaction is being offered.
signal reaction_window_opened(trigger_type: int, reactor_id: String)

## Emitted when the reactor selects a reaction before the window closes.
## reactor_id  : String — ID of the reacting creature.
## reaction_id : String — ID of the chosen reaction (e.g., "shield").
signal reaction_selected(reactor_id: String, reaction_id: String)

## Emitted when the reactor passes or the window times out.
## reactor_id : String — ID of the creature who did not react.
signal reaction_declined(reactor_id: String)

## Emitted whenever the window closes, regardless of outcome.
## reactor_id : String — ID of the creature the window was open for.
signal reaction_window_closed(reactor_id: String)

## Seconds before an open window auto-closes.  Override before calling open_window().
var timeout_seconds: float = DEFAULT_TIMEOUT_SECONDS

var _window_open: bool = false
var _reactor_id: String = ""
var _trigger_type: int = -1
var _action_economy: ActionEconomyClass = null
var _elapsed: float = 0.0


## Attempt to open a reaction window for the given reactor.
##
## trigger_type   : int (ReactionTrigger.TriggerType) — the triggering event
## reactor_id     : String — ID of the creature being offered the reaction
## action_economy : ActionEconomy — the reactor's current action economy
##
## Returns true if the window opened successfully.
## Returns false when:
##   - A window is already open
##   - action_economy is null
##   - The reactor's reaction slot is already spent (enforces one-per-round)
##   - The trigger_type is not a known TriggerType
func open_window(trigger_type: int, reactor_id: String, action_economy: ActionEconomyClass) -> bool:
	if _window_open:
		return false
	if action_economy == null:
		return false
	var trigger_result: Dictionary = ReactionTriggerClass.check(
		trigger_type, action_economy.is_reaction_available()
	)
	if not trigger_result["can_trigger"]:
		return false
	_reactor_id = reactor_id
	_trigger_type = trigger_type
	_action_economy = action_economy
	_window_open = true
	_elapsed = 0.0
	reaction_window_opened.emit(trigger_type, reactor_id)
	return true


## The reactor chooses a reaction.
##
## reaction_id : String — ID of the selected reaction (e.g., "shield")
##
## Returns true if the reaction was accepted (slot spent, signals emitted).
## Returns false when:
##   - No window is currently open
##   - reaction_id is not a valid reaction ID
##   - The reaction slot is already spent (should not normally occur here)
func select_reaction(reaction_id: String) -> bool:
	if not _window_open:
		return false
	if not ReactionTriggerClass.is_valid_reaction(reaction_id):
		return false
	if not _action_economy.use_reaction():
		return false
	var reactor: String = _reactor_id
	_close_window()
	reaction_selected.emit(reactor, reaction_id)
	return true


## The reactor explicitly passes on their reaction.
## Closes the window and emits reaction_declined.
## Has no effect when no window is open.
func decline() -> void:
	if not _window_open:
		return
	var reactor: String = _reactor_id
	_close_window()
	reaction_declined.emit(reactor)


## Simulate the timeout expiring (closes window as if it timed out).
## Primarily used in tests to avoid requiring a live game loop.
## Has no effect when no window is open.
func force_timeout() -> void:
	if not _window_open:
		return
	var reactor: String = _reactor_id
	_close_window()
	reaction_declined.emit(reactor)


## Returns true when a reaction window is currently open.
func is_window_open() -> bool:
	return _window_open


## Advances the timeout timer each frame.
## When the elapsed time reaches timeout_seconds, the window auto-closes.
func _process(delta: float) -> void:
	if not _window_open:
		return
	_elapsed += delta
	if _elapsed >= timeout_seconds:
		force_timeout()


# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

func _close_window() -> void:
	var reactor: String = _reactor_id
	_window_open = false
	_reactor_id = ""
	_trigger_type = -1
	_action_economy = null
	_elapsed = 0.0
	reaction_window_closed.emit(reactor)
