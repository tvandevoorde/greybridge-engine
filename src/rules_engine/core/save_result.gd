## SaveResult
## Pure data class — no Node, no UI, no scene references.
## Holds the outcome of a single D&D 5e SRD saving throw resolution.
class_name SaveResult extends RefCounted

## The DC (Difficulty Class) for the saving throw.
var dc: int = 0

## The raw d20 result that was rolled.
var roll: int = 0

## Roll + applicable ability and proficiency bonuses.
var total: int = 0

## true when total >= DC (saving throw succeeded).
var success: bool = false
