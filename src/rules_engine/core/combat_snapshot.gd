## CombatSnapshot
## Pure data class (no Node). Captures a point-in-time snapshot of the combat
## state for debugging and save integration.
##
## Fields are populated by CombatStateManager.take_snapshot().
## Call to_dict() to obtain a fully serializable (JSON-compatible) Dictionary.
class_name CombatSnapshot

## Current round number (1-based while combat is active; 0 when inactive).
var round: int = 0

## Index within the initiative order of the combatant currently acting.
var turn_index: int = 0

## ID of the combatant whose turn it currently is. Empty string when inactive.
var current_combatant_id: String = ""

## Initiative order as an Array of String actor IDs (descending initiative).
var initiative_order: Array = []

## Per-actor state. Each entry is a Dictionary with:
##   "id"         : String — actor identifier
##   "current_hp" : int    — current hit points
##   "position_x" : int    — grid column (omitted when position is unknown)
##   "position_y" : int    — grid row    (omitted when position is unknown)
var actors: Array = []


## Return a fully serializable Dictionary representation of this snapshot.
## All values are primitive types (int, String, Array, Dictionary) with no
## Godot-specific objects, making the result safe for JSON encoding.
func to_dict() -> Dictionary:
	return {
		"round": round,
		"turn_index": turn_index,
		"current_combatant_id": current_combatant_id,
		"initiative_order": initiative_order.duplicate(),
		"actors": actors.duplicate(true),
	}
