## TriggerTileResolver
## Pure logic class — NOT a Node.
## Determines whether a trigger tile should fire based on trigger data and
## encounters that already fired in the current session.
class_name TriggerTileResolver
extends RefCounted


## Resolve whether a trigger should fire.
##
## trigger     : Dictionary or null — trigger data from the map layer.
##               Expected keys for "combat_start" type:
##                 "type"          : String     — trigger type ("combat_start")
##                 "encounter_id"  : String     — encounter identifier
##                 "required_flags": Dictionary — flag_name → required_value;
##                                               all must match for the trigger
##                                               to fire (optional, default {})
## fired_ids   : Array      — encounter IDs that have already fired this session
## quest_flags : Dictionary — current world quest flag state
##
## Returns a Dictionary:
##   "should_fire" : bool   — true when the trigger should activate
##   "reason"      : String — why should_fire is false (empty string when true):
##                             "no_trigger"   : tile has no trigger data
##                             "already_fired": this encounter has already fired
##                             "unknown_type" : trigger type is not recognised
##                             "flag_blocked" : a required quest flag is not met
func resolve(trigger, fired_ids: Array, quest_flags: Dictionary) -> Dictionary:
	if trigger == null or not trigger is Dictionary:
		return {"should_fire": false, "reason": "no_trigger"}

	var trigger_type: String = trigger.get("type", "")
	var encounter_id: String = trigger.get("encounter_id", "")

	if trigger_type == "combat_start":
		if encounter_id != "" and fired_ids.has(encounter_id):
			return {"should_fire": false, "reason": "already_fired"}
		var required_flags: Dictionary = trigger.get("required_flags", {})
		for flag_name in required_flags:
			if quest_flags.get(flag_name, null) != required_flags[flag_name]:
				return {"should_fire": false, "reason": "flag_blocked"}
		return {"should_fire": true, "reason": ""}

	return {"should_fire": false, "reason": "unknown_type"}
