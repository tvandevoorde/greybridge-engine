## ConditionManager
## Pure logic class — no Node, no UI, no scene references.
## Manages the set of active conditions on a single actor.
##
## Duration semantics:
##   -1 = indefinite (never expires automatically)
##    0 = used only as sentinel for "not active" in get_duration()
##   >0 = turns remaining; decremented by tick(); removed when it reaches 0
##
## Stack prevention: calling add_condition() with an already-active condition
## is a no-op — the same condition cannot appear twice on the same actor.
class_name ConditionManager

## Internal storage: { condition_id: String -> duration_turns: int }
var _conditions: Dictionary = {}


## Adds a condition to this actor.
## If the condition is already active the call is silently ignored (no stacking).
##
## condition_id   : one of Condition.ID_* constants or any registered id
## duration_turns : turns until expiry, or -1 for indefinite
func add_condition(condition_id: String, duration_turns: int = -1) -> void:
	if _conditions.has(condition_id):
		return
	_conditions[condition_id] = duration_turns


## Removes the condition immediately, regardless of remaining duration.
## Does nothing if the condition is not currently active.
func remove_condition(condition_id: String) -> void:
	_conditions.erase(condition_id)


## Returns true if the actor currently has the given condition.
func has_condition(condition_id: String) -> bool:
	return _conditions.has(condition_id)


## Returns the remaining duration for an active condition.
## Returns -1 when the condition is active but indefinite.
## Returns  0 when the condition is not active.
func get_duration(condition_id: String) -> int:
	if not _conditions.has(condition_id):
		return 0
	return _conditions[condition_id]


## Returns an Array of all currently active condition ids.
func get_active_conditions() -> Array:
	return _conditions.keys()


## Advances all timed conditions by one turn.
## Conditions with duration > 0 are decremented; those that reach 0 are removed.
## Indefinite conditions (duration == -1) are unaffected.
func tick() -> void:
	var to_remove: Array = []
	for cid: String in _conditions:
		if _conditions[cid] > 0:
			_conditions[cid] -= 1
			if _conditions[cid] == 0:
				to_remove.append(cid)
	for cid: String in to_remove:
		_conditions.erase(cid)


## Returns true if any active condition imposes disadvantage on the actor's attack rolls.
## (5e SRD: Prone and Poisoned impose attack roll disadvantage on the afflicted actor.)
func has_attack_roll_disadvantage() -> bool:
	for cid: String in _conditions:
		var def: Dictionary = Condition.get_definition(cid)
		if def.get("attack_disadvantage", false):
			return true
	return false


## Returns true if any active condition imposes disadvantage on the actor's ability checks.
## (5e SRD: Poisoned imposes disadvantage on ability checks.)
func has_ability_check_disadvantage() -> bool:
	for cid: String in _conditions:
		var def: Dictionary = Condition.get_definition(cid)
		if def.get("ability_check_disadvantage", false):
			return true
	return false


## Returns true if any active condition forces the actor's speed to zero.
## (5e SRD: Grappled reduces speed to 0.)
func has_speed_zero() -> bool:
	for cid: String in _conditions:
		var def: Dictionary = Condition.get_definition(cid)
		if def.get("speed_zero", false):
			return true
	return false
