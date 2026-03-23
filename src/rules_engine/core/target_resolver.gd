## TargetResolver
## Pure logic class — no Node, no UI, no scene references.
## Determines which positions are valid targets for a given action.
##
## Two selection modes are supported:
##   "single" — attack or single-target spell; each candidate must be within range
##              of the attacker and must not be the attacker itself.
##   "aoe"    — area-of-effect origin; same range enforcement.  The caller decides
##              which tiles to pass as candidates (e.g. enemy tiles, all grid tiles).
##
## All distance calculations use the Chebyshev metric (5-5-5 diagonal rule),
## consistent with CombatGrid.distance_ft().
##
## Usage:
##   var resolver := TargetResolver.new()
##   var candidates := [
##       {"id": "bandit_1", "position": Vector2i(3, 0)},
##       {"id": "bandit_2", "position": Vector2i(9, 0)},
##   ]
##   var valid := resolver.get_valid_targets(Vector2i(0, 0), 30, candidates, "player", "single")
##   # valid == [Vector2i(3, 0)]  — bandit_2 at 45 ft is out of range
class_name TargetResolver

## Feet represented by one tile (must match CombatGrid.FEET_PER_TILE).
const FEET_PER_TILE: int = 5


## Returns the Chebyshev distance in feet between two grid positions.
## Consistent with CombatGrid.distance_ft().
static func distance_ft(pos_a: Vector2i, pos_b: Vector2i) -> int:
	var dx: int = abs(pos_a.x - pos_b.x)
	var dy: int = abs(pos_a.y - pos_b.y)
	return maxi(dx, dy) * FEET_PER_TILE


## Returns the subset of candidate positions that are valid targets.
##
## attacker_pos  : Grid position of the acting combatant.
## range_ft      : Maximum range in feet (inclusive).
## candidates    : Array of Dictionaries, each containing:
##                   "id"       : String — combatant identifier
##                   "position" : Vector2i — grid tile
## attacker_id   : The acting combatant's ID; always excluded from results.
## mode          : "single" or "aoe".
##                 "single" — returns candidates reachable within range_ft, excluding
##                            the attacker.
##                 "aoe"    — same range check; caller decides which tiles to pass
##                            as candidates (e.g. enemy tiles, all grid tiles).
##
## Returns Array[Vector2i] of positions that satisfy range and validity constraints.
func get_valid_targets(
	attacker_pos: Vector2i,
	range_ft: int,
	candidates: Array,
	attacker_id: String,
	mode: String
) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for candidate in candidates:
		var cid: String = candidate["id"]
		var cpos: Vector2i = candidate["position"]
		if cid == attacker_id:
			continue
		if TargetResolver.distance_ft(attacker_pos, cpos) <= range_ft:
			result.append(cpos)
	return result
