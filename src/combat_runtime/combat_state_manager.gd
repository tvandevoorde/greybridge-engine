## CombatStateManager
## Pure state container for a single combat encounter.
## Lives in combat_runtime but contains no rules logic — all 5e calculations
## (initiative rolling, attack resolution, etc.) are delegated to the rules
## engine before data is passed into this class.
##
## Responsibilities:
##   - Tracks participants (player + enemies)
##   - Tracks initiative order
##   - Tracks current turn index
##   - Tracks round number (increments when the turn order cycles back to index 0)
##   - Tracks combat active / inactive state
class_name CombatStateManager

const CombatSnapshotClass = preload("res://rules_engine/core/combat_snapshot.gd")

var _active: bool = false
var _participants: Array = []
var _initiative_order: Array = []
var _current_turn_index: int = 0
var _round: int = 0


## Start a new combat encounter.
##
## participants     : Array of Dictionaries, each must contain "id": String.
## initiative_order : Array of String IDs in descending initiative order.
##                    Typically produced by InitiativeRoller.roll_for_combatants().
##
## Calling start_combat() while a combat is already active resets all state
## to the new encounter (no need to call end_combat() first).
func start_combat(participants: Array, initiative_order: Array) -> void:
	_participants = participants.duplicate()
	_initiative_order = initiative_order.duplicate()
	_current_turn_index = 0
	_round = 1
	_active = true


## End the current encounter and reset all state.
func end_combat() -> void:
	_active = false
	_participants = []
	_initiative_order = []
	_current_turn_index = 0
	_round = 0


## Returns true when a combat encounter is in progress.
func is_active() -> bool:
	return _active


## Returns a copy of the participants array.
func get_participants() -> Array:
	return _participants.duplicate()


## Returns a copy of the initiative order (Array of String IDs).
func get_initiative_order() -> Array:
	return _initiative_order.duplicate()


## Returns the current turn index within the initiative order.
func get_current_turn_index() -> int:
	return _current_turn_index


## Returns the id of the combatant whose turn it currently is.
## Returns "" when no combat is active or the initiative order is empty.
func get_current_combatant_id() -> String:
	if not _active or _initiative_order.is_empty():
		return ""
	return _initiative_order[_current_turn_index]


## Returns the current round number (1-based while combat is active).
## Returns 0 when no combat is active.
func get_round() -> int:
	return _round


## Advance to the next turn in the initiative order.
## When the last combatant has acted the index wraps back to 0 and the round
## counter is incremented.
## Has no effect when combat is inactive or the initiative order is empty.
func advance_turn() -> void:
	if not _active or _initiative_order.is_empty():
		return
	_current_turn_index += 1
	if _current_turn_index >= _initiative_order.size():
		_current_turn_index = 0
		_round += 1


## Take a point-in-time snapshot of the current combat state.
##
## positions : Dictionary mapping actor id (String) → Vector2i grid position.
##             Pass an empty Dictionary when positions are not tracked.
##
## Returns a CombatSnapshot whose to_dict() method yields a fully serializable
## (JSON-compatible) representation of the snapshot.
func take_snapshot(positions: Dictionary) -> CombatSnapshotClass:
	var snap: CombatSnapshotClass = CombatSnapshotClass.new()
	snap.round = _round
	snap.turn_index = _current_turn_index
	snap.current_combatant_id = get_current_combatant_id()
	snap.initiative_order = _initiative_order.duplicate()
	for p: Dictionary in _participants:
		var actor_id: String = p.get("id", "")
		var entry: Dictionary = {
			"id": actor_id,
			"current_hp": p.get("current_hp", 0),
		}
		if positions.has(actor_id):
			var pos: Vector2i = positions[actor_id]
			entry["position_x"] = pos.x
			entry["position_y"] = pos.y
		snap.actors.append(entry)
	return snap
