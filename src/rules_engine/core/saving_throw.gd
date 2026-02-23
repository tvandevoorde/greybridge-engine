## SavingThrow
## Pure logic class — no Node, no UI, no scene references.
## Resolves a D&D 5e SRD saving throw: d20 + ability modifier (+ proficiency
## when applicable) against a Difficulty Class.
##
## The d20 roll is provided via an injected Callable for deterministic testing:
##   func() -> int   # must return a value in [1, 20]
class_name SavingThrow

const SaveResultClass = preload("res://rules_engine/core/save_result.gd")


## Resolves a saving throw against the given DC.
##
## Parameters:
##   dc                - Difficulty Class to meet or beat
##   ability_modifier  - Modifier from the relevant ability score
##   proficiency_bonus - Actor's proficiency bonus (applied only when is_proficient)
##   is_proficient     - Whether the actor has proficiency in this saving throw
##   roll_d20          - Callable returning an int in [1, 20] (injected for determinism)
##
## Returns a SaveResult with fields:
##   roll    - Raw d20 result
##   total   - Roll + applicable bonuses
##   success - true when total >= dc
static func resolve(
	dc: int,
	ability_modifier: int,
	proficiency_bonus: int,
	is_proficient: bool,
	roll_d20: Callable
) -> SaveResult:
	var roll: int = roll_d20.call()
	var bonus: int = ability_modifier + (proficiency_bonus if is_proficient else 0)
	var result := SaveResultClass.new()
	result.roll = roll
	result.total = roll + bonus
	result.success = result.total >= dc
	return result


## Returns the damage dealt after a saving throw.
## When half_on_success is true, a successful save halves the damage (rounded down).
## A failed save always delivers the full damage amount.
static func apply_damage(damage: int, success: bool, half_on_success: bool) -> int:
	if success and half_on_success:
		return damage / 2  # int / int in GDScript 4 → truncating integer division (rounds toward zero)
	return damage
