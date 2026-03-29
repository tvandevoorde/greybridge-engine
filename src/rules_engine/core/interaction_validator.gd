## InteractionValidator
## Pure logic class for validating overworld interaction adjacency.
## Determines whether a player position is adjacent (4-directional) to an
## interactable position on the overworld grid.
##
## "Adjacent" means the interactable occupies a tile directly north, south,
## east, or west of the player (distance of exactly 1 in one cardinal axis,
## 0 in the other).  Diagonal tiles are not considered adjacent.
##
## Architecture: pure GDScript class — NOT a Node. No scene/resource access.
class_name InteractionValidator
extends RefCounted


## Returns true if player_pos is exactly one cardinal step from interactable_pos.
## Diagonal tiles are not considered adjacent.
##
## player_pos        : Vector2i — current player tile.
## interactable_pos  : Vector2i — tile occupied by the interactable.
func is_adjacent(player_pos: Vector2i, interactable_pos: Vector2i) -> bool:
	var diff: Vector2i = interactable_pos - player_pos
	return (diff.x == 0 and (diff.y == 1 or diff.y == -1)) \
		or (diff.y == 0 and (diff.x == 1 or diff.x == -1))
