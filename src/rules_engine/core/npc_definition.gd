## NpcDefinition
## Pure data class representing an NPC placed on a map.
## Holds the NPC's identity, position, dialogue link, movement rule,
## and the quest flags that are set when the player interacts with it.
##
## Architecture: pure GDScript class — NOT a Node. No scene/resource access.
class_name NpcDefinition
extends RefCounted

const NpcDefinitionClass = preload("res://rules_engine/core/npc_definition.gd")

## Unique identifier for this NPC instance.
var npc_id: String = ""

## Grid position (tile coordinates) where the NPC is placed.
var position: Vector2i = Vector2i.ZERO

## Identifier for the dialogue tree to start when this NPC is interacted with.
var dialogue_id: String = ""

## When true the NPC does not block player movement.
var pass_through: bool = false

## Quest flags to apply when the player interacts with this NPC.
## Keys are flag names (String); values are the flag values (Variant).
var quest_flags: Dictionary = {}


## Constructs an NpcDefinition from a Dictionary (e.g. parsed from JSON).
## Expected keys:
##   "npc_id"       : String
##   "position"     : Dictionary with "x" (int) and "y" (int)
##   "dialogue_id"  : String
##   "pass_through" : bool       (default false)
##   "quest_flags"  : Dictionary (default {})
static func from_dict(data: Dictionary) -> NpcDefinition:
	var def := NpcDefinitionClass.new()
	def.npc_id = data.get("npc_id", "")
	var pos: Dictionary = data.get("position", {})
	def.position = Vector2i(int(pos.get("x", 0)), int(pos.get("y", 0)))
	def.dialogue_id = data.get("dialogue_id", "")
	def.pass_through = bool(data.get("pass_through", false))
	def.quest_flags = data.get("quest_flags", {}).duplicate()
	return def


## Returns true if this definition has a non-empty npc_id.
func is_valid() -> bool:
	return npc_id != ""
