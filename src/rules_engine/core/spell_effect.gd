## SpellEffect
## Pure data class — no Node, no UI, no scene references.
## Defines constants and factory methods for building spell effect data objects
## consumed by SpellExecutor.
##
## All factory methods return a Dictionary with a "type" key and the fields
## required for that effect type.  SpellExecutor validates required keys at
## execution time.
class_name SpellEffect

## Effect type identifiers — use these constants instead of raw strings.
const TYPE_ATTACK: String = "attack"
const TYPE_SAVING_THROW: String = "saving_throw"
const TYPE_HEALING: String = "healing"
const TYPE_CONCENTRATION: String = "concentration"


## Build an attack spell effect data object.
##
## dice_count    : number of damage dice (e.g. 2 for "2d6")
## dice_faces    : die size           (e.g. 6 for "2d6"); must be in DiceRoller.VALID_DICE
## damage_modifier: flat bonus added after rolling (may be negative)
## damage_type   : descriptor string such as "fire", "piercing", etc.
##
## The executor doubles dice_count (not damage_modifier) on a critical hit
## per SRD rules.
static func make_attack(
	dice_count: int,
	dice_faces: int,
	damage_modifier: int,
	damage_type: String
) -> Dictionary:
	return {
		"type": TYPE_ATTACK,
		"dice_count": dice_count,
		"dice_faces": dice_faces,
		"damage_modifier": damage_modifier,
		"damage_type": damage_type,
	}


## Build a saving throw spell effect data object.
##
## dc            : Difficulty Class the target must meet or beat
## save_ability  : ability key used for the save (e.g. "DEX", "CON")
## dice_count    : number of damage dice
## dice_faces    : die size; must be in DiceRoller.VALID_DICE
## damage_modifier: flat bonus added after rolling
## damage_type   : descriptor string such as "fire", "cold", etc.
## half_on_success: when true a successful save halves damage (SRD default for
##                  most area spells); false means a successful save still deals
##                  full damage (the save has no mitigating effect on damage)
static func make_saving_throw(
	dc: int,
	save_ability: String,
	dice_count: int,
	dice_faces: int,
	damage_modifier: int,
	damage_type: String,
	half_on_success: bool
) -> Dictionary:
	return {
		"type": TYPE_SAVING_THROW,
		"dc": dc,
		"save_ability": save_ability,
		"dice_count": dice_count,
		"dice_faces": dice_faces,
		"damage_modifier": damage_modifier,
		"damage_type": damage_type,
		"half_on_success": half_on_success,
	}


## Build a healing spell effect data object.
##
## dice_count : number of healing dice
## dice_faces : die size; must be in DiceRoller.VALID_DICE
## modifier   : flat bonus added after rolling (e.g. spellcasting modifier)
static func make_healing(dice_count: int, dice_faces: int, modifier: int) -> Dictionary:
	return {
		"type": TYPE_HEALING,
		"dice_count": dice_count,
		"dice_faces": dice_faces,
		"modifier": modifier,
	}


## Build a concentration effect data object.
##
## duration_rounds: maximum number of rounds the effect lasts while the
##                  caster maintains concentration
static func make_concentration(duration_rounds: int) -> Dictionary:
	return {
		"type": TYPE_CONCENTRATION,
		"duration_rounds": duration_rounds,
	}
