## MapDefinition
## Pure data class representing a loaded map definition.
## Holds the map's configuration including spawn point and layer assignments.
##
## Architecture: pure GDScript class — NOT a Node. No scene/resource access.
extends RefCounted

## Unique identifier for this map.
var map_id: String = ""

## Player spawn position in grid coordinates (tile units).
var spawn_point: Vector2i = Vector2i.ZERO

## Physics collision layer bitmask for this map.
var collision_layer: int = 1

## Interaction/trigger layer bitmask for this map.
var interaction_layer: int = 2

## Raw transition point Dictionaries for this map (parsed from JSON).
## Pass to MapTransitionController.load_transitions() to activate them.
var transitions: Array = []
## NPC spawn data as a list of raw Dictionaries parsed from JSON.
## Each entry is passed to NpcController.load_npcs() at runtime.
var npcs: Array = []
## Tile positions the player cannot enter, in grid coordinates.
## Each element is a Vector2i.
var blocked_tiles: Array = []

const MapDefinitionClass = preload("res://overworld/map_definition.gd")


## Constructs a MapDefinition from a Dictionary (e.g. parsed JSON).
## Expected keys:
##   "map_id"            : String
##   "spawn_point"       : Dictionary with "x" (int) and "y" (int)
##   "collision_layer"   : int  (default 1)
##   "interaction_layer" : int  (default 2)
##   "blocked_tiles"     : Array of Dictionaries with "x" (int) and "y" (int)
##                         (optional, defaults to empty)
static func from_dict(data: Dictionary):
	var def := MapDefinitionClass.new()
	def.map_id = data.get("map_id", "")
	var sp: Dictionary = data.get("spawn_point", {})
	def.spawn_point = Vector2i(int(sp.get("x", 0)), int(sp.get("y", 0)))
	def.collision_layer = int(data.get("collision_layer", 1))
	def.interaction_layer = int(data.get("interaction_layer", 2))
	def.transitions = data.get("transitions", [])
	def.npcs = data.get("npcs", []).duplicate()
	var raw_blocked: Array = data.get("blocked_tiles", [])
	for entry in raw_blocked:
		if entry is Dictionary:
			def.blocked_tiles.append(Vector2i(int(entry.get("x", 0)), int(entry.get("y", 0))))
	return def


## Returns true if this definition has a non-empty map_id.
func is_valid() -> bool:
	return map_id != ""
