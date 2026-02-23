## Condition
## Pure data class — no Node, no UI, no scene references.
## Defines the V1 D&D 5e SRD conditions with their mechanical effects.
class_name Condition

const ID_PRONE: String = "prone"
const ID_GRAPPLED: String = "grappled"
const ID_POISONED: String = "poisoned"

## All V1 condition definitions keyed by condition id.
## Keys per entry:
##   "id"                        : String  — condition identifier
##   "name"                      : String  — display name
##   "attack_disadvantage"       : bool    — actor has disadvantage on attack rolls
##   "ability_check_disadvantage": bool    — actor has disadvantage on ability checks
##   "speed_zero"                : bool    — actor's speed becomes 0
const DEFINITIONS: Dictionary = {
	"prone": {
		"id": "prone",
		"name": "Prone",
		"attack_disadvantage": true,
		"ability_check_disadvantage": false,
		"speed_zero": false,
	},
	"grappled": {
		"id": "grappled",
		"name": "Grappled",
		"attack_disadvantage": false,
		"ability_check_disadvantage": false,
		"speed_zero": true,
	},
	"poisoned": {
		"id": "poisoned",
		"name": "Poisoned",
		"attack_disadvantage": true,
		"ability_check_disadvantage": true,
		"speed_zero": false,
	},
}


## Returns the definition dictionary for the given condition id.
## Returns an empty dictionary if the id is not recognised.
static func get_definition(condition_id: String) -> Dictionary:
	return DEFINITIONS.get(condition_id, {})
