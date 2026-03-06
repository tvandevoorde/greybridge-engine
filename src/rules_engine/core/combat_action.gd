## CombatAction
## Pure data class — no Node, no UI, no scene references.
## Defines the five V1 combat actions that consume the Action slot per SRD:
##   Attack, Cast Spell, Dash, Disengage, Dodge.
##
## Usage:
##   CombatAction.get_available_actions(economy) → Array[String]
##     Returns the IDs of all actions whose resource requirements are met.
##
## Per SRD:
##   All five actions use the Action slot.  An actor may use each action at
##   most once per turn; the ActionEconomy class tracks slot availability.
class_name CombatAction

## Action identifiers used as canonical string keys throughout the engine.
const ATTACK: String = "attack"
const CAST_SPELL: String = "cast_spell"
const DASH: String = "dash"
const DISENGAGE: String = "disengage"
const DODGE: String = "dodge"

## All V1 actions that consume the Action slot (SRD p. 71–74).
## Order matches the SRD action listing for consistency.
const ACTION_SLOT_ACTIONS: Array[String] = [
	ATTACK,
	CAST_SPELL,
	DASH,
	DISENGAGE,
	DODGE,
]


## Returns the IDs of every action that can currently be selected.
## Accepts an ActionEconomy instance that reflects the actor's current turn state.
## All five V1 actions are available when the Action slot has not yet been spent;
## none are available once the slot is used.
static func get_available_actions(economy) -> Array[String]:
	if economy.is_action_available():
		return ACTION_SLOT_ACTIONS.duplicate()
	return []


## Returns true if the given action ID is a recognised V1 action.
static func is_valid_action(action_id: String) -> bool:
	return ACTION_SLOT_ACTIONS.has(action_id)
