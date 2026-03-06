## MovementResolver
## Pure logic class — no Node, no UI, no scene references.
## Validates and resolves a movement path for a combatant on a CombatGrid.
##
## Rules enforced (per D&D 5e SRD):
##   - 1 tile = CombatGrid.FEET_PER_TILE feet.
##   - Diagonal movement uses the 5-5-5 rule: every tile step costs FEET_PER_TILE feet.
##   - Total path cost cannot exceed the movement budget supplied by the caller.
##   - The path cannot pass through a tile occupied by another combatant.
##   - Leaving a tile that is within melee reach of a hostile flags a potential
##     opportunity-attack (OA) trigger.  The caller (combat_runtime) must resolve
##     each trigger via OpportunityAttack.check() using the attacker's actual
##     reaction state.
##
## Usage:
##   var resolver := MovementResolver.new()
##   var result := resolver.resolve(
##       path,                  # Array[Vector2i] — tiles to visit, NOT including start
##       start,                 # Vector2i — mover's current position
##       movement_remaining_ft, # int — movement budget remaining this turn
##       grid,                  # CombatGrid instance
##       mover_id,              # String — ID of the combatant being moved
##       hostiles               # Array[Dictionary] — [{id: String, reach_ft: int}]
##   )
##
## Result dictionary keys:
##   "success"      : bool    — true if the full path is valid and affordable
##   "tiles_moved"  : int     — number of tiles moved before stopping
##   "cost_ft"      : int     — total movement cost in feet
##   "blocked_at"   : Variant — Vector2i of the blocking tile, or null if unblocked
##   "reason"       : String  — "" | "insufficient_movement" | "tile_occupied"
##   "oa_triggers"  : Array   — potential OA events:
##                              [{from: Vector2i, to: Vector2i, threatening_id: String}]
##                              Each entry means the mover stepped out of that
##                              hostile's melee reach at that step.
class_name MovementResolver

const CombatGridClass = preload("res://rules_engine/core/combat_grid.gd")

const FEET_PER_TILE: int = 5


## Resolve a movement path.
##
## path                  : Array[Vector2i] — ordered steps to take (start excluded).
## start                 : Vector2i — mover's tile at the beginning of the move.
## movement_remaining_ft : int — feet of movement budget available this turn.
## grid                  : CombatGrid — current grid state (read-only; not mutated).
## mover_id              : String — combatant being moved (excluded from occupancy check).
## hostiles              : Array[Dictionary] — each entry must have:
##                           "id"       : String — combatant ID of the hostile
##                           "reach_ft" : int    — melee reach of that hostile in feet
##                         Positions are looked up from the grid at resolve time.
##
## Returns a result Dictionary (see class docstring for full key descriptions).
func resolve(
	path: Array,
	start: Vector2i,
	movement_remaining_ft: int,
	grid: CombatGridClass,
	mover_id: String,
	hostiles: Array
) -> Dictionary:
	var oa_triggers: Array = []
	var cost_so_far: int = 0
	var current: Vector2i = start

	for tile in path:
		var next: Vector2i = tile as Vector2i
		var step_cost: int = FEET_PER_TILE

		# Check movement budget before committing the step.
		if cost_so_far + step_cost > movement_remaining_ft:
			return {
				"success": false,
				"tiles_moved": cost_so_far / FEET_PER_TILE,
				"cost_ft": cost_so_far,
				"blocked_at": next,
				"reason": "insufficient_movement",
				"oa_triggers": oa_triggers
			}

		# Check that the destination tile is not occupied by another combatant.
		var occupant: String = grid.get_combatant_at(next)
		if occupant != "" and occupant != mover_id:
			return {
				"success": false,
				"tiles_moved": cost_so_far / FEET_PER_TILE,
				"cost_ft": cost_so_far,
				"blocked_at": next,
				"reason": "tile_occupied",
				"oa_triggers": oa_triggers
			}

		# Check for opportunity-attack triggers.
		# An OA may trigger when the mover leaves (`current`) a tile that is within
		# a hostile's melee reach, moving to (`next`) which is outside that reach.
		for hostile in hostiles:
			var hostile_pos: Vector2i = grid.get_position(hostile["id"])
			if hostile_pos == CombatGridClass.INVALID_POSITION:
				continue
			if grid.is_within_reach(hostile_pos, current, hostile["reach_ft"]) \
					and not grid.is_within_reach(hostile_pos, next, hostile["reach_ft"]):
				oa_triggers.append({
					"from": current,
					"to": next,
					"threatening_id": hostile["id"]
				})

		cost_so_far += step_cost
		current = next

	return {
		"success": true,
		"tiles_moved": cost_so_far / FEET_PER_TILE,
		"cost_ft": cost_so_far,
		"blocked_at": null,
		"reason": "",
		"oa_triggers": oa_triggers
	}
