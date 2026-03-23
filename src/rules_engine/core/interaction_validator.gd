## InteractionValidator
## Pure logic class — no Node, no UI, no scene references.
## Determines whether a player position is adjacent (4-directional) to an
## interactable position on the overworld grid.
##
## "Adjacent" means the interactable occupies a tile directly north, south,
## east, or west of the player (distance of exactly 1 in one cardinal axis,
## 0 in the other).  Diagonal tiles are not considered adjacent.
##
## Usage:
##   var validator := InteractionValidator.new()
##   validator.is_adjacent(Vector2i(3, 4), Vector2i(3, 3))  # → true (north)
##   validator.is_adjacent(Vector2i(3, 4), Vector2i(4, 3))  # → false (diagonal)
class_name InteractionValidator


## Returns true if player_pos is exactly one cardinal step from interactable_pos.
## Diagonal tiles are not considered adjacent.
##
## player_pos        : Vector2i — current player tile.
## interactable_pos  : Vector2i — tile occupied by the interactable.
func is_adjacent(player_pos: Vector2i, interactable_pos: Vector2i) -> bool:
	var diff: Vector2i = interactable_pos - player_pos
	return (diff.x == 0 and (diff.y == 1 or diff.y == -1)) \
		or (diff.y == 0 and (diff.x == 1 or diff.x == -1))
