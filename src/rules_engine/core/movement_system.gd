## MovementSystem
## Pure logic class — no Node, no UI, no scene references.
## Integrates opportunity attacks into the movement system for D&D 5e SRD.
##
## Melee reach in 5e SRD is 5 feet (1 grid tile) for standard weapons.
## Grid positions use integer x/y keys.  Distance uses Chebyshev (square) measurement
## which is standard for D&D 5e on a grid (diagonal = 5 ft).
##
## Typical usage (caller detects tile transitions, passes context here):
##
##   var ms := MovementSystem.new()
##
##   # Reach check — call per-attacker each time the mover enters a new tile.
##   var was_in_reach := ms.is_within_reach(old_pos, attacker_pos)
##   var now_in_reach := ms.is_within_reach(new_pos, attacker_pos)
##   if was_in_reach and not now_in_reach:
##       var d20 := dice_roller.roll(20)
##       var result := ms.process_leave_reach(
##           attacker_economy, d20,
##           attacker_str_mod, attacker_prof_bonus,
##           mover_ac, mover_is_disengaging
##       )
##
## process_leave_reach() result keys:
##   "triggered" : bool   — true if an opportunity attack was made
##   "reason"    : String — "" | "reaction_spent" | "target_disengaging"
##   "hit"       : bool   — whether the OA hit (only meaningful when triggered=true)
##   "critical"  : bool   — whether the OA was a critical hit
##   "roll"      : int    — raw d20 value used
##   "total"     : int    — attack total (roll + modifiers)
class_name MovementSystem

const OpportunityAttack = preload("res://rules_engine/core/opportunity_attack.gd")
const AttackResolver = preload("res://rules_engine/core/attack_resolver.gd")

## Standard melee reach per 5e SRD: 5 feet (one grid tile).
const DEFAULT_MELEE_REACH_FT: int = 5


## Return true if pos_a and pos_b are within reach_ft of each other on a square grid
## where one tile equals 5 feet.  Uses Chebyshev (square) distance, which is the
## standard 5e SRD grid measurement (diagonal counts as 5 ft).
##
## pos_a, pos_b : Dictionary — must contain integer "x" and "y" keys (grid coords)
## reach_ft     : int        — reach in feet; defaults to DEFAULT_MELEE_REACH_FT (5)
func is_within_reach(
	pos_a: Dictionary,
	pos_b: Dictionary,
	reach_ft: int = DEFAULT_MELEE_REACH_FT
) -> bool:
	var tiles: int = reach_ft / 5
	var dx: int = abs(pos_a["x"] - pos_b["x"])
	var dy: int = abs(pos_a["y"] - pos_b["y"])
	return dx <= tiles and dy <= tiles


## Called by combat_runtime (or tests) when a mover has left an attacker's melee reach.
## Resolves the full opportunity-attack sequence:
##   1. Validate OA conditions via OpportunityAttack.check().
##   2. If valid, consume the attacker's reaction via attacker_economy.use_reaction().
##   3. Resolve the attack roll via AttackResolver.resolve().
##   4. Return a structured result.
##
## Parameters:
##   attacker_economy      : ActionEconomy — the OA attacker's action-economy tracker
##   d20_roll              : int           — pre-rolled d20 (injected for determinism)
##   str_modifier          : int           — attacker's STR modifier
##   proficiency_bonus     : int           — attacker's proficiency bonus
##   target_ac             : int           — mover's Armor Class
##   target_is_disengaging : bool          — true if the mover used Disengage this turn
##
## Returns a Dictionary (see class-level doc for keys).
func process_leave_reach(
	attacker_economy: ActionEconomy,
	d20_roll: int,
	str_modifier: int,
	proficiency_bonus: int,
	target_ac: int,
	target_is_disengaging: bool
) -> Dictionary:
	var oa := OpportunityAttack.new()
	var check: Dictionary = oa.check(attacker_economy.is_reaction_available(), target_is_disengaging)

	if not check["can_trigger"]:
		return {
			"triggered": false,
			"reason": check["reason"],
			"hit": false,
			"critical": false,
			"roll": 0,
			"total": 0,
		}

	# Consume the attacker's reaction — only one reaction per round (SRD).
	attacker_economy.use_reaction()

	# Resolve the attack roll.
	var resolver := AttackResolver.new()
	var attack: AttackResult = resolver.resolve(d20_roll, str_modifier, proficiency_bonus, target_ac)

	return {
		"triggered": true,
		"reason": "",
		"hit": attack.hit,
		"critical": attack.critical,
		"roll": attack.roll,
		"total": attack.total,
	}
