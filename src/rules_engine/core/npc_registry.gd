## NpcRegistry
## Pure logic class for managing a collection of NpcDefinitions on a map.
## Provides tile-based NPC lookups and computes the set of tiles blocked
## by solid (non-pass-through) NPCs.
##
## Architecture: pure GDScript class — NOT a Node. No scene/resource access.
class_name NpcRegistry
extends RefCounted

const NpcDefinitionClass = preload("res://rules_engine/core/npc_definition.gd")

## Loaded NPC definitions.
var _npcs: Array = []


## Populates the registry from an Array of NPC data Dictionaries.
## Each entry is parsed via NpcDefinition.from_dict().
func load_npcs(npc_data: Array) -> void:
	_npcs = []
	for entry in npc_data:
		var def = NpcDefinitionClass.from_dict(entry)
		_npcs.append(def)


## Returns the positions of all non-pass-through NPCs as an Array of Vector2i.
## These tiles should be added to the GridMovementController's blocked set.
func get_blocked_tiles() -> Array:
	var tiles: Array = []
	for npc in _npcs:
		if not npc.pass_through:
			tiles.append(npc.position)
	return tiles


## Returns the NpcDefinition occupying [param pos], or null if no NPC is there.
func get_npc_at(pos: Vector2i):
	for npc in _npcs:
		if npc.position == pos:
			return npc
	return null


## Returns a duplicate of all loaded NpcDefinitions.
func get_all() -> Array:
	return _npcs.duplicate()
