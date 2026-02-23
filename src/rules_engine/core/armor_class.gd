## ArmorClass
## Pure logic class — no Node, no UI, no scene references.
## Calculates a character's Armor Class (AC) according to D&D 5e SRD rules.
##
## Usage:
##   var ac := ArmorClass.new()
##   ac.equip_armor(ArmorClass.ARMOR_LIGHT, 11)  # leather armor
##   ac.equip_shield(true)
##   ac.add_temp_bonus(5)                        # Shield spell
##   var total_ac: int = ac.calculate(dex_modifier)
##
## Armor type rules (SRD):
##   ARMOR_NONE   : 10 + DEX modifier (full DEX)
##   ARMOR_LIGHT  : base_ac + DEX modifier (full DEX)
##   ARMOR_MEDIUM : base_ac + DEX modifier (max +2)
##   ARMOR_HEAVY  : base_ac (DEX modifier not applied)
##   Shield       : +2 AC bonus, stackable with armor
##   Temp bonuses : stack with all other bonuses
class_name ArmorClass

const ARMOR_NONE: String = "none"
const ARMOR_LIGHT: String = "light"
const ARMOR_MEDIUM: String = "medium"
const ARMOR_HEAVY: String = "heavy"

const VALID_ARMOR_TYPES: Array[String] = [ARMOR_NONE, ARMOR_LIGHT, ARMOR_MEDIUM, ARMOR_HEAVY]

const SHIELD_BONUS: int = 2
const UNARMORED_BASE: int = 10
const MEDIUM_ARMOR_DEX_CAP: int = 2

var _armor_type: String = ARMOR_NONE
var _armor_base: int = 0
var _has_shield: bool = false
var _temp_bonus: int = 0


## Equips the given armor.  armor_type must be one of the ARMOR_* constants.
## base_ac is the armor's base AC value (ignored when armor_type is ARMOR_NONE).
## Pushes an error and leaves state unchanged if armor_type is invalid.
func equip_armor(armor_type: String, base_ac: int) -> void:
	if not VALID_ARMOR_TYPES.has(armor_type):
		push_error("ArmorClass: unknown armor type '%s'" % armor_type)
		return
	_armor_type = armor_type
	_armor_base = base_ac


## Equips or removes a shield (+2 AC bonus).
func equip_shield(equipped: bool) -> void:
	_has_shield = equipped


## Adds a temporary AC bonus (e.g., Shield spell +5).
## Multiple calls stack; bonuses persist until clear_temp_bonuses() is called.
func add_temp_bonus(bonus: int) -> void:
	_temp_bonus += bonus


## Removes all temporary AC bonuses.
func clear_temp_bonuses() -> void:
	_temp_bonus = 0


## Calculates and returns the total AC for the given DEX modifier.
##
## The DEX modifier is applied as follows:
##   ARMOR_NONE / ARMOR_LIGHT : added in full
##   ARMOR_MEDIUM             : added up to a maximum of +2
##   ARMOR_HEAVY              : not applied
## Shield bonus and temporary bonuses are then added on top.
func calculate(dex_modifier: int) -> int:
	var base: int
	match _armor_type:
		ARMOR_NONE:
			base = UNARMORED_BASE + dex_modifier
		ARMOR_LIGHT:
			base = _armor_base + dex_modifier
		ARMOR_MEDIUM:
			base = _armor_base + mini(dex_modifier, MEDIUM_ARMOR_DEX_CAP)
		ARMOR_HEAVY:
			base = _armor_base
		_:
			base = UNARMORED_BASE + dex_modifier
	if _has_shield:
		base += SHIELD_BONUS
	base += _temp_bonus
	return base
