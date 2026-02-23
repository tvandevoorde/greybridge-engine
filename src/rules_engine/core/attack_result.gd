## AttackResult
## Pure data class — no Node, no UI, no scene references.
## Holds the outcome of a single D&D 5e SRD attack roll resolution.
class_name AttackResult

## The raw d20 result that was rolled.
var roll: int = 0

## d20_roll + ability_modifier + proficiency_bonus.
var total: int = 0

## true when the attack hits the target.
var hit: bool = false

## true when the d20 showed a natural 20 (critical hit).
var critical: bool = false

## Damage dealt. Set to 0 until damage is resolved by the caller.
var damage: int = 0
