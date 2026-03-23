## ReactionTrigger
## Pure logic class — no Node, no UI, no scene references.
## Defines the valid reaction trigger types recognised by the V1 engine and
## validates whether a reaction window may open for a given trigger.
##
## Trigger types reflect the D&D 5e SRD events that allow a creature to spend
## its reaction:
##   BEING_HIT            — e.g., Shield spell when the target is about to be hit
##   CREATURE_LEAVES_REACH — e.g., Opportunity Attack when an enemy leaves melee reach
##
## Usage:
##   var result := ReactionTrigger.check(ReactionTrigger.TriggerType.BEING_HIT, true)
##   if result["can_trigger"]:
##       # open reaction window
##
## Result dictionary keys:
##   "can_trigger" : bool   — true if the reaction window may open
##   "reason"      : String — "reaction_spent" | "unknown_trigger" | ""
class_name ReactionTrigger


## Trigger types that can open a reaction window.
enum TriggerType {
	BEING_HIT,             ## The reactor is about to be hit (e.g., Shield)
	CREATURE_LEAVES_REACH, ## An enemy leaves the reactor's melee reach (e.g., Opportunity Attack)
}

## All valid reaction IDs recognised by the V1 engine.
const REACTION_IDS: Array[String] = ["shield", "opportunity_attack"]


## Validate whether a reaction window may open.
##
## trigger_type         : int  (TriggerType) — the event that occurred
## reactor_has_reaction : bool — true if the reactor still has their reaction for this round
##
## Returns a Dictionary:
##   "can_trigger" : bool   — true if the reaction window is legal to open
##   "reason"      : String — "reaction_spent" | "unknown_trigger" | ""
static func check(trigger_type: int, reactor_has_reaction: bool) -> Dictionary:
	if not reactor_has_reaction:
		return {"can_trigger": false, "reason": "reaction_spent"}
	match trigger_type:
		TriggerType.BEING_HIT, TriggerType.CREATURE_LEAVES_REACH:
			return {"can_trigger": true, "reason": ""}
	return {"can_trigger": false, "reason": "unknown_trigger"}


## Returns the list of reaction IDs that may be chosen for a given trigger type.
## Returns an empty array for unknown trigger types.
static func get_reactions_for_trigger(trigger_type: int) -> Array[String]:
	if trigger_type == TriggerType.BEING_HIT:
		return ["shield"]
	if trigger_type == TriggerType.CREATURE_LEAVES_REACH:
		return ["opportunity_attack"]
	return []


## Returns true if the given reaction_id is a valid, recognised reaction.
static func is_valid_reaction(reaction_id: String) -> bool:
	return REACTION_IDS.has(reaction_id)
