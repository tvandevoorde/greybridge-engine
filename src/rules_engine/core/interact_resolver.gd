## InteractResolver
## Pure logic class for resolving overworld interaction targets.
## Computes the tile the player is attempting to interact with based on
## their position and facing direction, then finds a matching NPC candidate.
##
## Architecture: pure GDScript class — NOT a Node. No scene/resource access.
class_name InteractResolver
extends RefCounted


## Returns the grid tile that the player is targeting for interaction.
## The target tile is one step ahead in the facing direction.
##
## position : Vector2i — current player grid position.
## facing   : Vector2i — direction the player is facing. Must be a unit
##            cardinal direction; a zero vector returns the player's own tile.
func get_interact_target(position: Vector2i, facing: Vector2i) -> Vector2i:
	return position + facing


## Finds the NPC candidate occupying [param target_tile], or null if none.
##
## target_tile : Vector2i — the tile to search.
## candidates  : Array    — Array of NpcDefinition objects to search through.
func resolve(target_tile: Vector2i, candidates: Array):
	for candidate in candidates:
		if candidate.position == target_tile:
			return candidate
	return null
