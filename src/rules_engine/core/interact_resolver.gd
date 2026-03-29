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
## Pure logic class — no Node, no UI, no scene references.
## Computes the interaction target tile given a player position and facing direction,
## and resolves which interactable (if any) occupies that tile.
##
## Interactable candidates are plain Dictionaries with keys:
##   "id"       : String   — unique identifier for the interactable (NPC id, door id, etc.).
##   "position" : Vector2i — tile position of the interactable.
##
## Usage:
##   var resolver := InteractResolver.new()
##   var target := resolver.get_interact_target(Vector2i(3, 4), Vector2i(0, -1))
##   var found := resolver.resolve(target, candidates)
##   if not found.is_empty():
##       # interact with found["id"]
class_name InteractResolver


## Returns the tile immediately in front of the player.
##
## position : Vector2i — player's current grid position.
## facing   : Vector2i — unit direction the player is facing.
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
## Searches candidates for an interactable at target_tile.
##
## target_tile : Vector2i — tile to check.
## candidates  : Array    — Array of Dictionaries, each with "id" (String)
##                          and "position" (Vector2i).
##
## Returns the first matching Dictionary, or an empty Dictionary if none found.
func resolve(target_tile: Vector2i, candidates: Array) -> Dictionary:
	for candidate in candidates:
		if candidate["position"] == target_tile:
			return candidate
	return {}
