## Concentration
## Pure logic class — no Node, no UI, no scene references.
## Tracks concentration state for a single actor and resolves concentration
## saving throws per D&D 5e SRD rules.
##
## Only one concentration effect may be active at a time; starting a new effect
## automatically replaces the previous one.
##
## Concentration save DC = max(10, floor(damage / 2)).
class_name Concentration

const SavingThrow = preload("res://rules_engine/core/saving_throw.gd")

## Whether the actor is currently concentrating on a spell or effect.
var is_concentrating: bool = false

var _effect_id: String = ""


## Begin concentrating on the given effect. Replaces any existing concentration.
func start(effect_id: String) -> void:
	is_concentrating = true
	_effect_id = effect_id


## End concentration immediately, clearing the tracked effect.
func end() -> void:
	is_concentrating = false
	_effect_id = ""


## Returns the identifier of the currently concentrated effect, or "" if none.
func get_effect_id() -> String:
	return _effect_id


## Returns the concentration save DC for the given damage amount.
## Formula (SRD): max(10, floor(damage / 2)).
static func compute_dc(damage: int) -> int:
	return max(10, damage / 2)


## Resolves a concentration saving throw triggered by taking damage.
##
## Parameters:
##   damage            - Hit point damage taken (used to compute the save DC)
##   con_modifier      - Actor's CON ability modifier
##   proficiency_bonus - Actor's current proficiency bonus
##   is_proficient     - Whether the actor has CON save proficiency
##   roll_d20          - Callable returning an int in [1, 20] (injected for determinism)
##
## Returns a Dictionary:
##   "dc"      - Computed save DC
##   "roll"    - Raw d20 result
##   "total"   - Roll + applicable bonuses
##   "success" - true when concentration is maintained
##
## If the save fails and the actor was concentrating, concentration is ended.
func resolve_damage_save(
	damage: int,
	con_modifier: int,
	proficiency_bonus: int,
	is_proficient: bool,
	roll_d20: Callable
) -> Dictionary:
	var dc: int = compute_dc(damage)
	var result: Dictionary = SavingThrow.resolve(
		dc, con_modifier, proficiency_bonus, is_proficient, roll_d20
	)
	result["dc"] = dc
	if not result["success"]:
		end()
	return result
