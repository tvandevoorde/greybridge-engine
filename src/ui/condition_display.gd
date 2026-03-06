## ConditionDisplay
## UI layer class — extends Node.
## Displays active condition indicators above an actor, reflecting their
## names and remaining duration.  Updated entirely from the outside via
## refresh(); this class contains NO rules logic and performs NO 5e math.
##
## Responsibilities:
##   - Store a snapshot of active conditions for one actor.
##   - Expose helpers so a parent scene can render condition badges.
##   - Emit conditions_updated whenever the snapshot changes.
##
## Usage:
##   display.refresh("hero", [
##       {"id": "prone",    "name": "Prone",    "duration": -1},
##       {"id": "poisoned", "name": "Poisoned", "duration": 2},
##   ])
##   display.get_condition_count()         # → 2
##   display.get_condition_label("prone")  # → "Prone"
##   display.get_condition_duration("poisoned")  # → 2
##
## Each condition dictionary must contain:
##   "id"       : String — unique condition identifier
##   "name"     : String — human-readable display name
##   "duration" : int    — remaining turns (-1 = indefinite)
##
## The combat runtime (or a controller) is responsible for calling refresh()
## whenever conditions change on the tracked actor.
class_name ConditionDisplay
extends Node

## Emitted after every successful refresh() call, whether or not the
## conditions actually changed.  Consumers (e.g. a HUD scene) can connect
## to this signal to re-render condition badges.
signal conditions_updated(actor_id: String)

var _actor_id: String = ""

## Internal snapshot: condition_id (String) → Dictionary { id, name, duration }
var _conditions: Dictionary = {}


## Replace the current condition snapshot for [param actor_id].
##
## actor_id   : String — the actor whose conditions are being tracked.
## conditions : Array  — each entry must be a Dictionary with "id", "name",
##                        and "duration" keys.
##
## Any condition absent from [param conditions] is removed from the display.
## Calling refresh() with an empty array clears all displayed conditions.
func refresh(actor_id: String, conditions: Array) -> void:
	_actor_id = actor_id
	_conditions.clear()
	for cond in conditions:
		_conditions[cond["id"]] = {
			"id":       cond["id"],
			"name":     cond["name"],
			"duration": cond["duration"],
		}
	conditions_updated.emit(_actor_id)


## Returns the actor_id currently tracked by this display.
## Returns "" before the first refresh().
func get_actor_id() -> String:
	return _actor_id


## Returns the number of conditions currently shown.
func get_condition_count() -> int:
	return _conditions.size()


## Returns an Array of condition Dictionaries in the current snapshot.
## Each dictionary has "id", "name", and "duration" keys.
## Returns an empty Array when no conditions are active.
func get_displayed_conditions() -> Array:
	return _conditions.values()


## Returns true if the condition identified by [param condition_id] is
## currently shown.
func has_condition(condition_id: String) -> bool:
	return _conditions.has(condition_id)


## Returns the human-readable display name for [param condition_id].
## Returns "" if the condition is not currently displayed.
func get_condition_label(condition_id: String) -> String:
	if not _conditions.has(condition_id):
		return ""
	return _conditions[condition_id]["name"]


## Returns the remaining duration for [param condition_id].
## Returns -1 for indefinite conditions.
## Returns 0 when the condition is not currently displayed.
func get_condition_duration(condition_id: String) -> int:
	if not _conditions.has(condition_id):
		return 0
	return _conditions[condition_id]["duration"]
