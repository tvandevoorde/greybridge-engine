## InteractResolver
## Pure logic class for resolving overworld interaction targets.
## Computes the interaction target tile given a player position and facing direction,
## and resolves which interactable (if any) occupies that tile.
##
## Interactable candidates are plain Dictionaries with keys:
##   "id"       : String   — unique identifier for the interactable (NPC id, door id, etc.).
##   "position" : Vector2i — tile position of the interactable.
##
## Architecture: pure GDScript class — NOT a Node. No scene/resource access.
class_name InteractResolver
extends RefCounted


## Returns the tile immediately in front of the player.
##
## position : Vector2i — player's current grid position.
## facing   : Vector2i — unit direction the player is facing.
func get_interact_target(position: Vector2i, facing: Vector2i) -> Vector2i:
	return position + facing


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
