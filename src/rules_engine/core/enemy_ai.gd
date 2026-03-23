## EnemyAI
## Pure logic class — no Node, no UI, no scene references.
## Computes the AI decision for a single enemy turn in D&D 5e SRD combat.
##
## Decision priority (5e SRD compliant):
##   1. If already in melee range and action available, perform a melee attack.
##   2. Otherwise, move toward the nearest target within the available movement budget.
##      After movement, if now in melee range, perform a melee attack.
##   3. If melee is still impossible after movement, use a ranged attack if the weapon
##      has range and the target is reachable from the post- or pre-movement position.
##   4. If no attack is possible, just move toward the target to close the gap.
##
## The ActionEconomy is READ but NOT modified by this class.
## The caller (combat_runtime) is responsible for spending action/movement slots.
class_name EnemyAI

const CombatGridClass = preload("res://rules_engine/core/combat_grid.gd")
const ActionEconomyClass = preload("res://rules_engine/core/action_economy.gd")


## Find the nearest living player-side target to the enemy's current position.
##
## enemy_pos  : Vector2i — the enemy's current grid tile.
## candidates : Array of Dictionaries, each with keys:
##   "id"         : String   — combatant identifier
##   "position"   : Vector2i — grid tile of this combatant
##   "side"       : String   — only "player" side entries are considered
##   "current_hp" : int      — entries with hp <= 0 are skipped
##
## Returns the String ID of the nearest living player-side target, or "" if none.
func find_nearest_target(enemy_pos: Vector2i, candidates: Array) -> String:
	var nearest_id: String = ""
	var nearest_dist: int = 2147483647
	for c in candidates:
		if c.get("side", "") != "player":
			continue
		if c.get("current_hp", 0) <= 0:
			continue
		var pos: Vector2i = c.get("position", CombatGridClass.INVALID_POSITION)
		if pos == CombatGridClass.INVALID_POSITION:
			continue
		var dx: int = abs(enemy_pos.x - pos.x)
		var dy: int = abs(enemy_pos.y - pos.y)
		var dist: int = maxi(dx, dy)  # Chebyshev distance in tiles
		if dist < nearest_dist:
			nearest_dist = dist
			nearest_id = c["id"]
	return nearest_id


## Compute a greedy movement path from start toward target.
## Each step moves one tile closer using 8-directional (Chebyshev) movement.
## Stops when the mover is within melee_range_ft of the target, when a tile is
## blocked by another combatant, or when max_tiles steps are exhausted.
##
## start          : Vector2i  — starting tile (not included in the returned path).
## target         : Vector2i  — destination to approach.
## max_tiles      : int       — maximum number of tiles to travel.
## melee_range_ft : int       — stop moving when within this reach of the target.
## grid           : CombatGrid — used for occupancy checks (not mutated).
## mover_id       : String    — the mover's own ID (excluded from occupancy checks).
##
## Returns Array[Vector2i] of tiles to visit in order (not including start).
func path_toward(
	start: Vector2i,
	target: Vector2i,
	max_tiles: int,
	melee_range_ft: int,
	grid: CombatGridClass,
	mover_id: String
) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	var current: Vector2i = start
	for _i in max_tiles:
		# Stop when already within melee reach of the target.
		var dx_c: int = abs(current.x - target.x)
		var dy_c: int = abs(current.y - target.y)
		if maxi(dx_c, dy_c) * CombatGridClass.FEET_PER_TILE <= melee_range_ft:
			break
		# Take one greedy step toward the target (8-directional).
		var dx: int = sign(target.x - current.x)
		var dy: int = sign(target.y - current.y)
		var next: Vector2i = current + Vector2i(dx, dy)
		# Stop if the tile is occupied by someone other than the mover.
		var occupant: String = grid.get_combatant_at(next)
		if occupant != "" and occupant != mover_id:
			break
		path.append(next)
		current = next
	return path


## Compute the full AI decision for one enemy turn.
##
## enemy_id    : String — ID of the acting enemy (must be placed on the grid).
## enemy_stats : Dictionary with keys:
##   "melee_range_ft"  : int — melee reach in feet (default 5).
##   "ranged_range_ft" : int — ranged attack range in feet; 0 means no ranged (default 0).
##   "speed_ft"        : int — movement speed in feet (default 30).
## candidates  : Array of Dictionaries (all combatants; non-player or dead entries are
##               ignored when selecting targets):
##   "id"         : String
##   "position"   : Vector2i
##   "side"       : String  — "player" entries are potential targets
##   "current_hp" : int
## grid        : CombatGrid — current grid state (read-only; not mutated).
## economy     : ActionEconomy — current action economy (read-only; not mutated).
##
## Returns Dictionary:
##   "move_path"   : Array[Vector2i] — tiles to visit in order (not including start).
##   "attack_type" : String          — "melee", "ranged", or "none".
##   "target_id"   : String          — target ID, or "" if no attack is planned.
func decide(
	enemy_id: String,
	enemy_stats: Dictionary,
	candidates: Array,
	grid: CombatGridClass,
	economy: ActionEconomyClass
) -> Dictionary:
	var no_op: Dictionary = {"move_path": [], "attack_type": "none", "target_id": ""}

	var enemy_pos: Vector2i = grid.get_position(enemy_id)
	if enemy_pos == CombatGridClass.INVALID_POSITION:
		return no_op

	var target_id: String = find_nearest_target(enemy_pos, candidates)
	if target_id == "":
		return no_op

	# Retrieve the target's position from the candidates list.
	var target_pos: Vector2i = CombatGridClass.INVALID_POSITION
	for c in candidates:
		if c.get("id", "") == target_id:
			target_pos = c.get("position", CombatGridClass.INVALID_POSITION)
			break
	if target_pos == CombatGridClass.INVALID_POSITION:
		return no_op

	var melee_range_ft: int = enemy_stats.get("melee_range_ft", 5)
	var ranged_range_ft: int = enemy_stats.get("ranged_range_ft", 0)
	var speed_ft: int = enemy_stats.get("speed_ft", 30)

	# Chebyshev distance from enemy to target in feet.
	var dist_to_target_ft: int = maxi(
		abs(enemy_pos.x - target_pos.x), abs(enemy_pos.y - target_pos.y)
	) * CombatGridClass.FEET_PER_TILE

	# 1. Already in melee range — attack without moving.
	if economy.is_action_available() and dist_to_target_ft <= melee_range_ft:
		return {"move_path": [], "attack_type": "melee", "target_id": target_id}

	# 2. Move toward the target using the available movement budget.
	var move_path: Array[Vector2i] = []
	var final_pos: Vector2i = enemy_pos
	var movement_ft: int = mini(economy.movement_remaining_ft, speed_ft)
	if movement_ft > 0:
		var max_tiles: int = movement_ft / CombatGridClass.FEET_PER_TILE
		move_path = path_toward(enemy_pos, target_pos, max_tiles, melee_range_ft, grid, enemy_id)
		if move_path.size() > 0:
			final_pos = move_path[move_path.size() - 1]

	# 3. After movement: check melee range from the final position.
	var dist_after_move_ft: int = maxi(
		abs(final_pos.x - target_pos.x), abs(final_pos.y - target_pos.y)
	) * CombatGridClass.FEET_PER_TILE
	if economy.is_action_available() and dist_after_move_ft <= melee_range_ft:
		return {"move_path": move_path, "attack_type": "melee", "target_id": target_id}

	# 4. Ranged attack if the weapon has range and the target is reachable.
	if economy.is_action_available() and ranged_range_ft > 0:
		# Prefer shooting from the post-movement position if still in range.
		if dist_after_move_ft <= ranged_range_ft:
			return {"move_path": move_path, "attack_type": "ranged", "target_id": target_id}
		# Fall back to shooting from the current position if still in range.
		if dist_to_target_ft <= ranged_range_ft:
			return {"move_path": [], "attack_type": "ranged", "target_id": target_id}

	# 5. No attack possible — move toward the target to close the gap next turn.
	return {"move_path": move_path, "attack_type": "none", "target_id": ""}
