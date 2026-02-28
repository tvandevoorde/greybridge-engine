## DamageRoll
## Pure logic class — no Node, no UI, no scene references.
## Applies D&D 5e SRD damage modifiers per damage instance:
##   resistance, vulnerability, and immunity.
##
## Per SRD:
##   - Resistance:    halves damage (rounded down)
##   - Vulnerability: doubles damage
##   - Immunity:      negates damage entirely (result is always 0)
##   - Normal:        damage is unchanged
class_name DamageRoll

## Damage modifier constants.
const NORMAL        := 0
const RESISTANCE    := 1
const VULNERABILITY := 2
const IMMUNITY      := 3


## Returns the final damage after applying the given modifier.
##
## Parameters:
##   damage   - The base damage amount (>= 0)
##   modifier - One of NORMAL, RESISTANCE, VULNERABILITY, or IMMUNITY
##
## Returns:
##   The modified damage as an int (>= 0).
static func apply(damage: int, modifier: int) -> int:
	match modifier:
		IMMUNITY:
			return 0
		RESISTANCE:
			return damage >> 1  # Bitwise right shift by 1 (equivalent to floor division by 2)
		VULNERABILITY:
			return damage * 2
		_:  # NORMAL or unrecognised modifier
			return damage
