## MapTransitionResolver
## Pure logic class. Validates whether a MapTransition may fire given the
## current quest flag state.
##
## Architecture: pure GDScript class — NOT a Node. No scene/resource access.
class_name MapTransitionResolver
extends RefCounted

const MapTransitionClass = preload("res://rules_engine/core/map_transition.gd")


## Resolves whether [param transition] can fire given [param quest_flags].
##
## Returns a Dictionary:
##   "can_transition" : bool   — true when all required flags are satisfied.
##   "reason"         : String — empty on success; "missing_flag" when blocked.
func resolve(transition: MapTransitionClass, quest_flags: Dictionary) -> Dictionary:
	for flag_name in transition.required_flags:
		var required_value = transition.required_flags[flag_name]
		var actual_value = quest_flags.get(flag_name, null)
		if actual_value != required_value:
			return {"can_transition": false, "reason": "missing_flag"}
	return {"can_transition": true, "reason": ""}
