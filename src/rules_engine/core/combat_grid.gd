## CombatGrid
## Pure logic class — no Node, no UI, no scene references.
## Manages the positions of combatants on a 2D tile grid.
##
## 1 tile = FEET_PER_TILE feet.  Each tile may be occupied by at most one combatant.
##
## Usage:
##   var grid := CombatGrid.new()
##   grid.place_combatant("fighter", Vector2i(0, 0))
##   grid.place_combatant("bandit",  Vector2i(2, 0))
##   grid.is_occupied(Vector2i(1, 0))                     # false
##   grid.get_position("fighter")                          # Vector2i(0, 0)
##   grid.move_combatant("fighter", Vector2i(1, 0))        # true
##   grid.is_adjacent(Vector2i(1, 0), Vector2i(2, 0))     # true
##   grid.distance_ft(Vector2i(0, 0), Vector2i(3, 4))     # 20 (Chebyshev)
class_name CombatGrid

## Feet represented by one tile.
const FEET_PER_TILE: int = 5

## Sentinel returned by get_position() when a combatant is not on the grid.
const INVALID_POSITION: Vector2i = Vector2i(-9999, -9999)

## combatant_id -> Vector2i position
var _positions: Dictionary = {}

## Vector2i position -> combatant_id  (reverse lookup)
var _occupants: Dictionary = {}


## Place a combatant on the grid at the given position.
## Returns true on success.
## Returns false if the position is already occupied or the combatant is already placed.
func place_combatant(combatant_id: String, position: Vector2i) -> bool:
	if _positions.has(combatant_id):
		return false
	if _occupants.has(position):
		return false
	_positions[combatant_id] = position
	_occupants[position] = combatant_id
	return true


## Remove a combatant from the grid.
## Returns true if the combatant was present, false otherwise.
func remove_combatant(combatant_id: String) -> bool:
	if not _positions.has(combatant_id):
		return false
	var pos: Vector2i = _positions[combatant_id]
	_positions.erase(combatant_id)
	_occupants.erase(pos)
	return true


## Move a combatant to a new position.
## Returns true on success.
## Returns false if the combatant is not on the grid or the target tile is occupied.
func move_combatant(combatant_id: String, new_position: Vector2i) -> bool:
	if not _positions.has(combatant_id):
		return false
	if _occupants.has(new_position):
		return false
	var old_pos: Vector2i = _positions[combatant_id]
	_occupants.erase(old_pos)
	_positions[combatant_id] = new_position
	_occupants[new_position] = combatant_id
	return true


## Returns true if the given tile is occupied by any combatant.
func is_occupied(position: Vector2i) -> bool:
	return _occupants.has(position)


## Returns the combatant ID at the given position, or an empty string if unoccupied.
func get_combatant_at(position: Vector2i) -> String:
	return _occupants.get(position, "")


## Returns the current position of a combatant.
## Returns INVALID_POSITION if the combatant is not on the grid.
func get_position(combatant_id: String) -> Vector2i:
	return _positions.get(combatant_id, INVALID_POSITION)


## Returns true if the combatant is currently placed on the grid.
func has_combatant(combatant_id: String) -> bool:
	return _positions.has(combatant_id)


## Returns true if two positions are adjacent (8-directional, including diagonals).
## A tile is not adjacent to itself.
func is_adjacent(pos_a: Vector2i, pos_b: Vector2i) -> bool:
	var dx: int = abs(pos_a.x - pos_b.x)
	var dy: int = abs(pos_a.y - pos_b.y)
	return dx <= 1 and dy <= 1 and (dx + dy) > 0


## Returns the distance in feet between two positions using the Chebyshev metric.
## The Chebyshev metric treats diagonal movement identically to cardinal movement
## (5-5-5 diagonal rule): distance = max(|dx|, |dy|) * FEET_PER_TILE.
func distance_ft(pos_a: Vector2i, pos_b: Vector2i) -> int:
	var dx: int = abs(pos_a.x - pos_b.x)
	var dy: int = abs(pos_a.y - pos_b.y)
	return maxi(dx, dy) * FEET_PER_TILE


## Returns true if pos_b is within reach_ft feet of pos_a (Chebyshev distance).
func is_within_reach(pos_a: Vector2i, pos_b: Vector2i, reach_ft: int) -> bool:
	return distance_ft(pos_a, pos_b) <= reach_ft
