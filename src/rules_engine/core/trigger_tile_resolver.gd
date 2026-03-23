## TriggerTileResolver
## Pure logic class — no Node, no UI, no scene references.
## Validates whether a trigger tile should fire given the player's current
## quest-flag state and the set of already-fired one-time trigger IDs.
##
## Trigger Dictionary format (as stored in map data):
##   "id"         : String  — unique identifier (required for one_time tracking).
##   "type"       : String  — action type: "combat_start" | "dialogue_start" |
##                            "set_flag" | "teleport".
##   "one_time"   : bool    — if true the trigger fires only once (default false).
##   "conditions" : Array   — list of {"flag": String, "value": bool} entries.
##                            All conditions must be satisfied for the trigger to fire.
##
##   Type-specific payload fields:
##     combat_start  : "encounter_id" (String)
##     dialogue_start: "dialogue_id"  (String)
##     set_flag      : "flag_key"     (String), "flag_value" (bool)
##     teleport      : "target_map"   (String), "target_pos" ({"x": int, "y": int})
##
## Usage:
##   var resolver := TriggerTileResolver.new()
##   var result := resolver.resolve(trigger_dict, fired_ids, quest_flags)
##   # result["should_fire"] → bool
##   # result["reason"]      → "" | "already_fired" | "condition_not_met"
class_name TriggerTileResolver
extends RefCounted

## Valid trigger action type identifiers.
const ACTION_COMBAT_START: String = "combat_start"
const ACTION_DIALOGUE_START: String = "dialogue_start"
const ACTION_SET_FLAG: String = "set_flag"
const ACTION_TELEPORT: String = "teleport"


## Determines whether [param trigger] should fire.
##
## trigger     : Dictionary — trigger definition from map data.
## fired_ids   : Array      — IDs of one-time triggers already fired this session.
## quest_flags : Dictionary — current quest-flag state (flag name → bool).
##
## Returns a Dictionary:
##   "should_fire" : bool   — true if the trigger should fire now.
##   "reason"      : String — "" | "already_fired" | "condition_not_met"
func resolve(trigger: Dictionary, fired_ids: Array, quest_flags: Dictionary) -> Dictionary:
	# One-time guard: if already fired, do not fire again.
	var id: String = trigger.get("id", "")
	var one_time: bool = trigger.get("one_time", false)
	if one_time and id != "" and id in fired_ids:
		return {"should_fire": false, "reason": "already_fired"}

	# Condition guard: every condition must match the current quest flags.
	var conditions: Array = trigger.get("conditions", [])
	for condition in conditions:
		var flag_key: String = condition.get("flag", "")
		var expected: bool = condition.get("value", true)
		var actual: bool = quest_flags.get(flag_key, false)
		if actual != expected:
			return {"should_fire": false, "reason": "condition_not_met"}

	return {"should_fire": true, "reason": ""}


## Returns true if [param action_type] is a recognised trigger action type.
func is_valid_type(action_type: String) -> bool:
	return action_type in [
		ACTION_COMBAT_START,
		ACTION_DIALOGUE_START,
		ACTION_SET_FLAG,
		ACTION_TELEPORT,
	]
