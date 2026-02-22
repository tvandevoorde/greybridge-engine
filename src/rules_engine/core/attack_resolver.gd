## AttackResolver
## Pure logic class — no Node, no UI, no scene references.
## Resolves a single D&D 5e SRD attack roll against a target Armor Class.
##
## Usage:
##   var resolver := AttackResolver.new()
##   var result := resolver.resolve(d20_roll, ability_modifier, proficiency_bonus, target_ac)
##
## Result dictionary keys:
##   "hit"      : bool  — true if the attack hits (includes natural 20)
##   "critical" : bool  — true if the d20 showed a natural 20
##   "roll"     : int   — the raw d20 result that was passed in
##   "total"    : int   — d20_roll + ability_modifier + proficiency_bonus
class_name AttackResolver


## Resolve an attack roll against a target AC.
##
## d20_roll         : raw d20 result in [1, 20]
## ability_modifier : STR modifier for melee attacks, DEX modifier for ranged
## proficiency_bonus: attacker's current proficiency bonus
## target_ac        : defender's Armor Class
##
## Natural 20 is always a critical hit (auto-hit, critical flag set).
## Natural  1 is always an automatic miss regardless of modifiers.
## All other results hit when (d20_roll + ability_modifier + proficiency_bonus) >= target_ac.
func resolve(
	d20_roll: int,
	ability_modifier: int,
	proficiency_bonus: int,
	target_ac: int
) -> Dictionary:
	var critical: bool = d20_roll == 20
	var auto_miss: bool = d20_roll == 1
	var total: int = d20_roll + ability_modifier + proficiency_bonus
	var hit: bool = critical or (not auto_miss and total >= target_ac)
	return {"hit": hit, "critical": critical, "roll": d20_roll, "total": total}
