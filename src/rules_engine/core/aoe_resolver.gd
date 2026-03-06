## AoEResolver
## Pure logic class — no Node, no UI, no scene references.
## Resolves Area of Effect spell effects against a set of actors on the grid.
##
## Given an AoETemplate and a SpellEffect (saving throw type), it:
##   1. Determines which actors occupy tiles inside the template.
##   2. Runs a saving throw for each affected actor via SpellExecutor.
##   3. Applies full or half damage per the half_on_success flag.
##
## Dependencies are injected (DiceRoller, d20 callable) for determinism.
##
## Usage:
##   var resolver := AoEResolver.new()
##   var template := AoETemplate.make_radius(Vector2i(5, 5), 20)
##   var effect   := SpellEffect.make_saving_throw(14, "DEX", 8, 6, 0, "fire", true)
##   var roller   := DiceRoller.new(42)
##   var results  := resolver.resolve_area(template, actors, effect, roller,
##                       func() -> int: return roller.roll(20))
class_name AoEResolver

const AoETemplateClass = preload("res://rules_engine/core/aoe_template.gd")
const SpellExecutorClass = preload("res://rules_engine/core/spell_executor.gd")
const DiceRollerClass = preload("res://rules_engine/core/dice_roller.gd")

var _executor: SpellExecutorClass


func _init() -> void:
	_executor = SpellExecutorClass.new()


## Resolve an AoE saving throw effect against a list of actors.
##
## template    : AoETemplate dictionary from make_cone() or make_radius()
## actors      : Array of Dictionaries, each containing:
##                 "position"         : Vector2i — grid tile coordinates
##                 "ability_modifier" : int — modifier for the saving throw ability
##                 "proficiency_bonus": int — actor's proficiency bonus
##                 "is_proficient"    : bool — proficiency in this save type
## effect      : SpellEffect.make_saving_throw(...) dictionary
## roller      : DiceRoller used to roll damage dice
## roll_d20_fn : Callable() -> int — injected d20 provider; called once per actor
##
## Returns Array of Dictionaries (one entry per actor inside the area):
##   "actor"      : the original actor Dictionary
##   "roll"       : int   — raw d20 result from the saving throw
##   "total"      : int   — roll + applicable bonuses
##   "success"    : bool  — true when the save succeeded
##   "damage"     : int   — damage dealt (halved on success when half_on_success)
##   "damage_type": String — forwarded from the effect definition
func resolve_area(
	template: Dictionary,
	actors: Array,
	effect: Dictionary,
	roller: DiceRollerClass,
	roll_d20_fn: Callable
) -> Array:
	var affected_tiles: Array[Vector2i] = AoETemplateClass.get_affected_tiles(template)
	var results: Array = []
	for actor in actors:
		if not (actor["position"] in affected_tiles):
			continue
		var save_result: Dictionary = _executor.execute_saving_throw(
			effect,
			roll_d20_fn,
			actor["ability_modifier"],
			actor["proficiency_bonus"],
			actor["is_proficient"],
			roller
		)
		var entry: Dictionary = save_result.duplicate()
		entry["actor"] = actor
		results.append(entry)
	return results
