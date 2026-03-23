## ReactionMenu
## UI layer class — extends Node.
## Presents available reaction options to the player when a reaction window
## is open, and delegates all selection intent to the combat runtime via signals.
##
## Responsibilities:
##   - Query ReactionTrigger for the reactions valid for the current trigger type.
##   - Gate availability behind ActionEconomy.is_reaction_available().
##   - Emit reaction_chosen when the player makes a valid selection.
##   - Never call use_reaction() directly — that is the runtime's job.
##
## Usage:
##   menu.refresh(economy, trigger_type)   # call when a reaction window opens
##   menu.get_all_reactions()              # IDs of every renderable reaction button
##   menu.get_available_reactions()        # IDs of currently selectable reactions
##   menu.select_reaction("shield")        # returns true and emits signal if valid
##
## The combat runtime must connect to reaction_chosen to advance game state.
class_name ReactionMenu
extends Node

const ReactionTriggerClass = preload("res://rules_engine/core/reaction_trigger.gd")

## Emitted when the player selects a valid, available reaction.
## The combat runtime receives this signal and resolves the reaction via
## ReactionWindowHandler.  This class never calls use_reaction() itself.
signal reaction_chosen(reaction_id: String)

var _economy = null  # ActionEconomy (duck-typed — avoids GDScript 4.6 parse issues)
var _trigger_type: int = -1


## Bind an ActionEconomy snapshot and trigger context to this menu.
## Call whenever a reaction window opens (pass null economy to reset the menu).
func refresh(economy, trigger_type: int) -> void:
	_economy = economy
	_trigger_type = trigger_type


## Returns the IDs of every reaction button that should be rendered for the
## current trigger type — includes both enabled and disabled entries.
## Returns an empty array when no valid trigger type has been set.
func get_all_reactions() -> Array[String]:
	return ReactionTriggerClass.get_reactions_for_trigger(_trigger_type)


## Returns the IDs of reactions that are currently selectable.
## An empty array means all reaction buttons should be rendered as disabled.
func get_available_reactions() -> Array[String]:
	if _economy == null:
		return []
	if not _economy.is_reaction_available():
		return []
	return ReactionTriggerClass.get_reactions_for_trigger(_trigger_type)


## Returns true if the given reaction ID is selectable right now.
## Convenience helper for per-button enabled/disabled state.
func is_reaction_enabled(reaction_id: String) -> bool:
	return get_available_reactions().has(reaction_id)


## Attempts to select a reaction on behalf of the player.
## Validates:
##   1. An economy snapshot has been provided via refresh().
##   2. The reaction_id is valid for the current trigger type.
##   3. The Reaction slot has not yet been spent this round.
## On success emits reaction_chosen and returns true.
## On failure returns false without emitting anything.
func select_reaction(reaction_id: String) -> bool:
	if _economy == null:
		return false
	if not ReactionTriggerClass.get_reactions_for_trigger(_trigger_type).has(reaction_id):
		return false
	if not _economy.is_reaction_available():
		return false
	reaction_chosen.emit(reaction_id)
	return true
