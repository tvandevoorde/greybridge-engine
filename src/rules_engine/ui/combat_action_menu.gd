## CombatActionMenu
## UI layer class — extends Node.
## Presents available combat actions to the player each turn and delegates
## all selection intent to the combat runtime via signals.
##
## Responsibilities:
##   - Query the rules engine (CombatAction + ActionEconomy) for available actions.
##   - Expose the full action list so the UI can render all buttons.
##   - Prevent invalid or already-spent action selections.
##   - Emit action_selected when a valid action is chosen; never execute rules directly.
##
## Usage:
##   menu.refresh(economy)               # call at the start of each turn
##   menu.get_all_actions()              # IDs of every renderable action
##   menu.get_available_actions()        # IDs of currently selectable actions
##   menu.select_action("attack")        # returns true and emits signal if valid
##
## The combat runtime must connect to action_selected to advance game state.
class_name CombatActionMenu
extends Node

const CombatActionClass = preload("res://rules_engine/core/combat_action.gd")

## Emitted when the player selects a valid, available action.
## The combat runtime receives this signal and calls the rules engine to
## resolve the chosen action.  This class never calls use_action() itself.
signal action_selected(action_id: String)

var _economy = null


## Binds a new ActionEconomy snapshot to the menu.
## Call at the start of each actor turn so availability reflects current state.
func refresh(economy) -> void:
	_economy = economy


## Returns the IDs of every action that can be rendered as a button.
## Includes both enabled and disabled entries so the UI can show the full set.
func get_all_actions() -> Array[String]:
	return CombatActionClass.ACTION_SLOT_ACTIONS.duplicate()


## Returns the IDs of actions that are currently selectable (Action slot available).
## An empty array means all action buttons should be rendered as disabled.
func get_available_actions() -> Array[String]:
	if _economy == null:
		return []
	return CombatActionClass.get_available_actions(_economy)


## Returns true if the given action ID is selectable right now.
## Convenience helper for per-button enabled/disabled state.
func is_action_enabled(action_id: String) -> bool:
	return get_available_actions().has(action_id)


## Attempts to select an action on behalf of the player.
## Validates:
##   1. An economy snapshot has been provided via refresh().
##   2. The action_id is a recognised V1 action.
##   3. The Action slot has not yet been spent this turn.
## On success emits action_selected and returns true.
## On failure returns false without emitting anything.
func select_action(action_id: String) -> bool:
	if _economy == null:
		return false
	if not CombatActionClass.is_valid_action(action_id):
		return false
	if not _economy.is_action_available():
		return false
	action_selected.emit(action_id)
	return true
