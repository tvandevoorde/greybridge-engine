## DamageCalculator
## Pure logic class — no Node, no UI, no scene references.
## Calculates damage for a single D&D 5e SRD hit by rolling a dice expression,
## optionally adding an ability modifier, and recording the damage type.
##
## Usage:
##   var roller := DiceRoller.new()
##   var result := DamageCalculator.calculate(1, 8, "slashing", roller, 3)
##
## Result dictionary keys:
##   "amount"      : int    — total damage dealt (roll + modifier, minimum 0)
##   "damage_type" : String — e.g. "slashing", "piercing", "fire"
##   "roll"        : int    — raw dice total before the modifier is applied
##   "modifier"    : int    — ability modifier that was applied
class_name DamageCalculator

## Valid D&D 5e SRD damage types.
const DAMAGE_TYPES: Array[String] = [
	"acid",
	"bludgeoning",
	"cold",
	"fire",
	"force",
	"lightning",
	"necrotic",
	"piercing",
	"poison",
	"psychic",
	"radiant",
	"slashing",
	"thunder",
]


## Calculate damage for one hit.
##
## dice_count      : number of dice to roll (must be >= 1)
## dice_faces      : die type — must be a value in DiceRoller.VALID_DICE
## damage_type     : SRD damage type label (e.g. "slashing")
## roller          : DiceRoller instance (inject a seeded one for determinism)
## ability_modifier: STR or DEX modifier added to the damage roll (default 0)
##
## Returns a Dictionary (see class header).
## "amount" is always >= 0 (a large negative modifier cannot produce
## negative damage).
static func calculate(
	dice_count: int,
	dice_faces: int,
	damage_type: String,
	roller: DiceRoller,
	ability_modifier: int = 0,
) -> Dictionary:
	var roll: int = roller.roll_expression(dice_count, dice_faces)
	var amount: int = maxi(0, roll + ability_modifier)
	return {
		"amount": amount,
		"damage_type": damage_type,
		"roll": roll,
		"modifier": ability_modifier,
	}
