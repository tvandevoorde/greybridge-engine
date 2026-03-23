## TriggerTileResolver
## Pure logic class — NOT a Node.
## Determines whether a trigger tile should fire based on the trigger data,
## which triggers have already fired, and the current quest flag state.
##
## Architecture: pure logic, no Node, no UI, no scene references.
class_name TriggerTileResolver


## Resolve whether a trigger should fire.
##
## trigger     : Dictionary or null — trigger data from the map layer.
##               Expected keys for "combat_start" type:
##                 "type"        : String — trigger type ("combat_start")
##                 "encounter_id": String — encounter identifier
## fired_ids   : Array     — encounter IDs that have already fired this session
## quest_flags : Dictionary — current quest flag state (reserved for conditional triggers)
##
## Returns a Dictionary:
##   "should_fire" : bool   — true when the trigger should activate
##   "reason"      : String — why should_fire is false (empty string when true):
##                             "no_trigger"   : tile has no trigger data
##                             "already_fired": this encounter has already fired
##                             "unknown_type" : trigger type is not recognised
func resolve(trigger, fired_ids: Array, quest_flags: Dictionary) -> Dictionary:
	if trigger == null or not trigger is Dictionary:
		return {"should_fire": false, "reason": "no_trigger"}

	var trigger_type: String = trigger.get("type", "")
	var encounter_id: String = trigger.get("encounter_id", "")

	if trigger_type == "combat_start":
		if encounter_id != "" and fired_ids.has(encounter_id):
			return {"should_fire": false, "reason": "already_fired"}
		return {"should_fire": true, "reason": ""}

	return {"should_fire": false, "reason": "unknown_type"}
