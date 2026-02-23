## InitiativeRoller
## Pure logic class — no Node, no UI, no scene references.
## Rolls and sorts initiative for a list of combatants per D&D 5e SRD rules.
##
## Initiative = d20 + DEX modifier.
## Ties are broken first by DEX score (higher wins), then by combatant id
## (lexicographic ascending) for full determinism.
class_name InitiativeRoller


## Roll initiative for all combatants and return them sorted in descending order.
##
## combatants : Array of Dictionaries, each with keys:
##   "id"        : String  — unique identifier for the combatant
##   "dex_score" : int     — DEX ability score (modifier derived internally)
##
## roller : DiceRoller instance (inject a seeded roller in tests)
##
## Returns an Array of Dictionaries, one per combatant, sorted descending by
## initiative total. Each entry contains:
##   "id"       : String — combatant identifier
##   "roll"     : int    — raw d20 result
##   "modifier" : int    — DEX modifier applied
##   "total"    : int    — roll + modifier (the initiative value)
##   "dex_score": int    — DEX score used for tie-breaking
func roll_for_combatants(combatants: Array, roller: DiceRoller) -> Array:
	var results: Array = []
	for c in combatants:
		var dex_score: int = c["dex_score"]
		var modifier: int = floori((dex_score - 10) / 2.0)
		var d20_roll: int = roller.roll(20)
		results.append({
			"id": c["id"],
			"roll": d20_roll,
			"modifier": modifier,
			"total": d20_roll + modifier,
			"dex_score": dex_score,
		})
	return sort_results(results)


## Sort an array of initiative result Dictionaries (as returned by
## roll_for_combatants) in place and return the sorted array.
## Sorting rules (highest priority first):
##   1. Descending initiative total.
##   2. Descending DEX score (tie-breaker).
##   3. Ascending id (lexicographic) for full determinism.
func sort_results(results: Array) -> Array:
	results.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a["total"] != b["total"]:
			return a["total"] > b["total"]
		if a["dex_score"] != b["dex_score"]:
			return a["dex_score"] > b["dex_score"]
		return a["id"] < b["id"]
	)
	return results
