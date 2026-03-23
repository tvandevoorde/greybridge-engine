## InteractionValidator
## Pure logic class for validating overworld interaction adjacency.
## Checks that two grid positions are exactly one step apart along a
## cardinal axis (4-directional adjacency only — no diagonals).
##
## Architecture: pure GDScript class — NOT a Node. No scene/resource access.
class_name InteractionValidator
extends RefCounted


## Returns true if [param player_pos] and [param interactable_pos] are
## exactly one tile apart along a cardinal axis (Manhattan distance == 1).
func is_adjacent(player_pos: Vector2i, interactable_pos: Vector2i) -> bool:
	var delta := interactable_pos - player_pos
	var manhattan := abs(delta.x) + abs(delta.y)
	return manhattan == 1
