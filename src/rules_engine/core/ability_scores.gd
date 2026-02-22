## AbilityScores
## Pure logic class — no Node, no UI, no scene references.
## Stores the six D&D 5e SRD ability scores for one actor and derives
## modifiers on demand using the formula: floor((score - 10) / 2).
class_name AbilityScores

const ABILITIES: Array[String] = ["STR", "DEX", "CON", "INT", "WIS", "CHA"]
const MIN_SCORE: int = 1
const MAX_SCORE: int = 30

var _scores: Dictionary = {
	"STR": 10,
	"DEX": 10,
	"CON": 10,
	"INT": 10,
	"WIS": 10,
	"CHA": 10,
}


## Returns the raw score for the given ability key (e.g. "STR").
## Pushes an error and returns 0 if the key is invalid.
func get_score(ability: String) -> int:
	if not _scores.has(ability):
		push_error("AbilityScores: unknown ability '%s'" % ability)
		return 0
	return _scores[ability]


## Sets the score for the given ability key.
## Pushes an error and returns without modifying state if the key is
## invalid or the score is outside the SRD-compatible range [1, 30].
func set_score(ability: String, score: int) -> void:
	if not _scores.has(ability):
		push_error("AbilityScores: unknown ability '%s'" % ability)
		return
	if score < MIN_SCORE or score > MAX_SCORE:
		push_error(
			"AbilityScores: score %d out of valid range [%d, %d]" % [score, MIN_SCORE, MAX_SCORE]
		)
		return
	_scores[ability] = score


## Returns the ability modifier derived from the current score.
## Formula: floor((score - 10) / 2).
## Modifier is always up to date because it is computed from the stored score.
func get_modifier(ability: String) -> int:
	var score: int = get_score(ability)
	return floori((score - 10) / 2.0)


## Returns a shallow copy of the scores dictionary for serialization.
func to_dict() -> Dictionary:
	return _scores.duplicate()


## Populates scores from a dictionary. Unknown or out-of-range entries are
## rejected via set_score's validation. Returns self for chaining.
func from_dict(d: Dictionary) -> AbilityScores:
	for key: String in d:
		set_score(key, d[key])
	return self
