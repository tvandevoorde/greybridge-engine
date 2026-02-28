## SpellExecutor
## Pure logic class — no Node, no UI, no scene references.
## Executes spell effects defined as SpellEffect data objects (Dictionaries).
##
## Dependencies are injected at construction time to keep all rolls
## deterministic and the class unit-testable without a running scene.
##
## Usage:
##   var roller    := DiceRoller.new(42)            # seeded for determinism
##   var executor  := SpellExecutor.new()
##
##   # Attack spell
##   var effect := SpellEffect.make_attack(2, 6, 3, "fire")
##   var result := executor.execute_attack(effect, d20_roll, ability_mod, prof, target_ac, roller)
##
##   # Saving throw spell
##   var st_effect := SpellEffect.make_saving_throw(14, "DEX", 8, 6, 0, "fire", true)
##   var st_result := executor.execute_saving_throw(st_effect, func(): return 10,
##                        ability_mod, prof, is_proficient, roller)
##
##   # Healing
##   var heal_effect := SpellEffect.make_healing(1, 8, 3)
##   var heal_result := executor.execute_healing(heal_effect, roller)
##
##   # Concentration DC for an ongoing effect
##   var dc := SpellExecutor.concentration_dc(18)   # → 10  (max(10, floor(18/2)) = max(10, 9) = 10)
class_name SpellExecutor

const AttackResolverClass = preload("res://rules_engine/core/attack_resolver.gd")
const SavingThrowClass = preload("res://rules_engine/core/saving_throw.gd")

var _attack_resolver: AttackResolver


func _init() -> void:
	_attack_resolver = AttackResolverClass.new()


## Execute an attack spell effect against a target.
##
## effect           : SpellEffect.make_attack(...) dictionary
## d20_roll         : raw d20 result in [1, 20]
## ability_modifier : caster's relevant ability modifier (usually spellcasting mod)
## proficiency_bonus: caster's proficiency bonus
## target_ac        : defender's Armor Class
## roller           : DiceRoller used to roll damage dice
##
## Returns a Dictionary:
##   "hit"      : bool  — whether the spell hits
##   "critical" : bool  — whether the roll was a natural 20
##   "roll"     : int   — raw d20 result
##   "total"    : int   — d20 + ability_modifier + proficiency_bonus
##   "damage"   : int   — damage dealt (0 on a miss; dice doubled on critical)
##   "damage_type": String — from the effect definition
func execute_attack(
	effect: Dictionary,
	d20_roll: int,
	ability_modifier: int,
	proficiency_bonus: int,
	target_ac: int,
	roller: DiceRoller
) -> Dictionary:
	var attack = _attack_resolver.resolve(
		d20_roll, ability_modifier, proficiency_bonus, target_ac
	)
	var damage: int = 0
	if attack["hit"]:
		damage = _roll_damage(effect, roller, attack["critical"])
	return {
		"hit": attack["hit"],
		"critical": attack["critical"],
		"roll": attack["roll"],
		"total": attack["total"],
		"damage": damage,
		"damage_type": effect.get("damage_type", ""),
	}


## Execute a saving throw spell effect against a target.
##
## effect           : SpellEffect.make_saving_throw(...) dictionary
## roll_d20         : Callable returning int in [1, 20] (injected for determinism)
## ability_modifier : target's modifier for the relevant ability
## proficiency_bonus: target's proficiency bonus
## is_proficient    : whether the target has proficiency in this save
## roller           : DiceRoller used to roll damage dice
##
## Returns a Dictionary:
##   "roll"       : int   — raw d20 result from the saving throw
##   "total"      : int   — roll + applicable bonuses
##   "success"    : bool  — true when total >= dc
##   "damage"     : int   — damage dealt after applying half-damage rule
##   "damage_type": String — from the effect definition
func execute_saving_throw(
	effect: Dictionary,
	roll_d20: Callable,
	ability_modifier: int,
	proficiency_bonus: int,
	is_proficient: bool,
	roller: DiceRoller
) -> Dictionary:
	var save = SavingThrowClass.resolve(
		effect["dc"], ability_modifier, proficiency_bonus, is_proficient, roll_d20
	)
	var raw_damage: int = _roll_damage(effect, roller, false)
	var damage: int = SavingThrowClass.apply_damage(raw_damage, save["success"], effect["half_on_success"])
	return {
		"roll": save["roll"],
		"total": save["total"],
		"success": save["success"],
		"damage": damage,
		"damage_type": effect.get("damage_type", ""),
	}


## Execute a healing spell effect.
##
## effect : SpellEffect.make_healing(...) dictionary
## roller : DiceRoller used to roll healing dice
##
## Returns a Dictionary:
##   "amount" : int — hit points restored
func execute_healing(effect: Dictionary, roller: DiceRoller) -> Dictionary:
	var amount: int = roller.roll_expression(
		effect["dice_count"], effect["dice_faces"], effect.get("modifier", 0)
	)
	return {"amount": amount}


## Return the concentration save DC for the given damage amount.
## SRD formula: DC = max(10, floor(damage / 2)).
static func concentration_dc(damage: int) -> int:
	return maxi(10, int(damage / 2.0))


## Internal helper — roll damage for an effect.
## On a critical hit the SRD doubles the number of dice (modifier is not doubled).
func _roll_damage(effect: Dictionary, roller: DiceRoller, is_critical: bool) -> int:
	var count: int = effect["dice_count"] * 2 if is_critical else effect["dice_count"]
	return roller.roll_expression(count, effect["dice_faces"], effect.get("damage_modifier", 0))
