## MapTransition
## Pure data class representing a single map transition point.
##
## A transition tile that, when stepped on by the player, can transport them
## to a target map at a specified spawn position, optionally gated behind
## quest flags.
##
## Architecture: pure GDScript class — NOT a Node. No scene/resource access.
class_name MapTransition
extends RefCounted

const MapTransitionClass = preload("res://rules_engine/core/map_transition.gd")

## The grid tile that triggers this transition when stepped on.
var tile: Vector2i = Vector2i.ZERO

## The map_id of the destination map.
var target_map: String = ""

## The grid position where the player spawns on the destination map.
var target_spawn: Vector2i = Vector2i.ZERO

## Quest flags required for the transition to fire (flag_name → expected value).
## An empty Dictionary means the transition is unconditional.
var required_flags: Dictionary = {}


## Constructs a MapTransition from a Dictionary (e.g. parsed JSON).
## Expected keys:
##   "tile"           : Dictionary with "x" (int) and "y" (int)
##   "target_map"     : String — destination map_id
##   "target_spawn"   : Dictionary with "x" (int) and "y" (int)
##   "required_flags" : Dictionary (optional, defaults to {})
static func from_dict(data: Dictionary) -> MapTransitionClass:
	var t := MapTransitionClass.new()
	var tile_data: Dictionary = data.get("tile", {})
	t.tile = Vector2i(int(tile_data.get("x", 0)), int(tile_data.get("y", 0)))
	t.target_map = data.get("target_map", "")
	var spawn_data: Dictionary = data.get("target_spawn", {})
	t.target_spawn = Vector2i(int(spawn_data.get("x", 0)), int(spawn_data.get("y", 0)))
	t.required_flags = data.get("required_flags", {})
	return t


## Returns true when target_map is non-empty.
func is_valid() -> bool:
	return target_map != ""
