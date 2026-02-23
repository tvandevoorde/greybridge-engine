## SpellResult
## Pure data class — no Node, no UI, no scene references.
## Holds the outcome of a spell's application to a target.
class_name SpellResult

## Identifiers of the effects applied to the target (e.g. condition names,
## damage type strings). Empty when no effects were applied.
var applied_effects: Array[String] = []
