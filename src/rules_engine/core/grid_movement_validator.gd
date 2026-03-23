## GridMovementValidator
## Pure logic class — no Node, no UI, no scene references.
## Validates a single 4-directional grid step for a player or entity.
##
## Rules enforced:
##   - Movement must be strictly 4-directional (N/S/E/W; no diagonals, no zero vector).
##   - The destination tile must not appear in the blocked_tiles list.
##   - Grid positions use Vector2i (integer tile coordinates).
##
## Usage:
##   var validator := GridMovementValidator.new()
##   var result := validator.validate_step(
##       Vector2i(3, 4),       # current position
##       Vector2i(0, -1),      # direction (north)
##       [Vector2i(3, 3)]      # blocked tiles
##   )
##   # result["success"]      → false
##   # result["new_position"] → Vector2i(3, 3)
##   # result["reason"]       → "blocked_by_collision"
class_name GridMovementValidator

## The four valid cardinal directions.
const DIR_NORTH: Vector2i = Vector2i(0, -1)
const DIR_SOUTH: Vector2i = Vector2i(0, 1)
const DIR_WEST: Vector2i = Vector2i(-1, 0)
const DIR_EAST: Vector2i = Vector2i(1, 0)


## Validate a single grid step.
##
## position      : Vector2i — current tile position.
## direction     : Vector2i — intended step direction (must be one of the four
##                            cardinal directions; diagonals and zero are rejected).
## blocked_tiles : Array    — Array of Vector2i tiles that cannot be entered.
##
## Returns a Dictionary:
##   "success"      : bool     — true if the step is valid.
##   "new_position" : Vector2i — destination tile (set even when success=false).
##   "reason"       : String   — "" | "invalid_direction" | "blocked_by_collision"
func validate_step(position: Vector2i, direction: Vector2i, blocked_tiles: Array) -> Dictionary:
	if not _is_cardinal(direction):
		return {
			"success": false,
			"new_position": position,
			"reason": "invalid_direction",
		}

	var dest: Vector2i = position + direction

	if dest in blocked_tiles:
		return {
			"success": false,
			"new_position": dest,
			"reason": "blocked_by_collision",
		}

	return {
		"success": true,
		"new_position": dest,
		"reason": "",
	}


# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

## Returns true if dir is exactly one of the four cardinal unit directions.
## Diagonals (both axes non-zero) and the zero vector are rejected.
func _is_cardinal(dir: Vector2i) -> bool:
	return (dir.x == 0 and (dir.y == 1 or dir.y == -1)) \
		or (dir.y == 0 and (dir.x == 1 or dir.x == -1))
