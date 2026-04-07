## OverworldSnapshot
## Pure data class (no Node). Captures a point-in-time snapshot of the overworld
## state for save / load integration.
##
## Fields are populated by OverworldController.capture_state().
## Call to_dict() to obtain a fully serializable (JSON-compatible) Dictionary.
## Call from_dict() to reconstruct a snapshot from a saved Dictionary.
class_name OverworldSnapshot
extends RefCounted

const OverworldSnapshotClass = preload("res://rules_engine/core/overworld_snapshot.gd")

## The map_id of the currently loaded map.
var map_id: String = ""

## Player's current grid tile position.
var player_position: Vector2i = Vector2i.ZERO

## Direction the player is facing (cardinal unit vector; default south = (0,1)).
var player_facing: Vector2i = Vector2i(0, 1)

## IDs of chests that have already been opened on this map.
var opened_chest_ids: Array = []

## Per-door state keyed by "x,y" tile string. Value is true when the door is open.
var door_states: Dictionary = {}

## World quest flags accumulated during this session.
var quest_flags: Dictionary = {}

## Encounter IDs for combat triggers that have already fired (suppressed).
var fired_trigger_ids: Array = []


## Return a fully serializable Dictionary representation of this snapshot.
## All values are primitive types (int, String, bool, Array, Dictionary) with no
## Godot-specific objects, making the result safe for JSON encoding.
func to_dict() -> Dictionary:
	return {
		"map_id": map_id,
		"player_position": {"x": player_position.x, "y": player_position.y},
		"player_facing": {"x": player_facing.x, "y": player_facing.y},
		"opened_chest_ids": opened_chest_ids.duplicate(),
		"door_states": door_states.duplicate(),
		"quest_flags": quest_flags.duplicate(),
		"fired_trigger_ids": fired_trigger_ids.duplicate(),
	}


## Reconstruct an OverworldSnapshot from a Dictionary previously produced by
## to_dict(). Missing keys are filled with safe defaults so old save files
## remain loadable after adding new fields.
static func from_dict(data: Dictionary) -> OverworldSnapshotClass:
	var snap := OverworldSnapshotClass.new()
	snap.map_id = data.get("map_id", "")
	var pos: Dictionary = data.get("player_position", {"x": 0, "y": 0})
	snap.player_position = Vector2i(pos.get("x", 0), pos.get("y", 0))
	var facing: Dictionary = data.get("player_facing", {"x": 0, "y": 1})
	snap.player_facing = Vector2i(facing.get("x", 0), facing.get("y", 1))
	snap.opened_chest_ids = data.get("opened_chest_ids", []).duplicate()
	snap.door_states = data.get("door_states", {}).duplicate()
	snap.quest_flags = data.get("quest_flags", {}).duplicate()
	snap.fired_trigger_ids = data.get("fired_trigger_ids", []).duplicate()
	return snap
