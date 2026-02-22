## SkillCheck
## Pure logic class — no Node, no UI, no scene references.
## Resolves ability and skill checks per D&D 5e SRD rules.
##
## Key SRD rules applied here:
##   - Total = d20 + ability_modifier (+ proficiency_bonus if proficient).
##   - Advantage: roll two d20s and keep the higher result.
##   - Disadvantage: roll two d20s and keep the lower result.
##   - A natural 20 or natural 1 on a skill check is NOT an automatic
##     success or failure — that rule applies only to attack rolls.
##   - Success: total >= dc.
class_name SkillCheck

enum AdvantageMode { NORMAL, ADVANTAGE, DISADVANTAGE }


## Resolves a skill check by rolling d20(s) using the supplied RNG and then
## delegating to resolve_with_rolls for all mechanical computation.
##
## Parameters:
##   dc               — Difficulty Class to meet or beat.
##   ability_modifier — Ability modifier for the relevant ability score.
##   proficiency_bonus — Proficiency bonus value (only applied if is_proficient).
##   is_proficient    — Whether the character is proficient in this skill.
##   advantage_mode   — NORMAL, ADVANTAGE, or DISADVANTAGE.
##   rng              — Injected RandomNumberGenerator (seed it for determinism).
##
## Returns a Dictionary (see resolve_with_rolls).
static func resolve(
	dc: int,
	ability_modifier: int,
	proficiency_bonus: int,
	is_proficient: bool,
	advantage_mode: AdvantageMode,
	rng: RandomNumberGenerator,
) -> Dictionary:
	var roll1: int = rng.randi_range(1, 20)
	var roll2: int = rng.randi_range(1, 20)
	return resolve_with_rolls(
		dc,
		ability_modifier,
		proficiency_bonus,
		is_proficient,
		advantage_mode,
		roll1,
		roll2,
	)


## Deterministic core of skill-check resolution — accepts pre-generated die
## values so that tests need no RNG at all.
##
## Returns a Dictionary with:
##   "roll"     : int  — the d20 result used after advantage/disadvantage.
##   "total"    : int  — roll + modifiers.
##   "success"  : bool — true if total >= dc.
##   "is_nat20" : bool — true if the chosen roll is 20 (informational only).
##   "is_nat1"  : bool — true if the chosen roll is 1  (informational only).
static func resolve_with_rolls(
	dc: int,
	ability_modifier: int,
	proficiency_bonus: int,
	is_proficient: bool,
	advantage_mode: AdvantageMode,
	roll1: int,
	roll2: int,
) -> Dictionary:
	var chosen_roll: int
	match advantage_mode:
		AdvantageMode.ADVANTAGE:
			chosen_roll = max(roll1, roll2)
		AdvantageMode.DISADVANTAGE:
			chosen_roll = min(roll1, roll2)
		_:
			chosen_roll = roll1

	var bonus: int = ability_modifier
	if is_proficient:
		bonus += proficiency_bonus

	var total: int = chosen_roll + bonus

	return {
		"roll": chosen_roll,
		"total": total,
		"success": total >= dc,
		"is_nat20": chosen_roll == 20,
		"is_nat1": chosen_roll == 1,
	}
