## Proficiency
## Pure logic class — no Node, no UI, no scene references.
## Derives the D&D 5e SRD proficiency bonus from character level and
## applies it to checks based on proficiency / expertise status.
class_name Proficiency

const MIN_LEVEL: int = 1
const MAX_LEVEL: int = 20

## SRD proficiency bonus table indexed by level (1-based, index 0 unused).
## Levels 1–4: +2, 5–8: +3, 9–12: +4, 13–16: +5, 17–20: +6.
const BONUS_TABLE: Array[int] = [
	0,             # index 0 (unused — levels are 1-based)
	2, 2, 2, 2,   # levels  1–4
	3, 3, 3, 3,   # levels  5–8
	4, 4, 4, 4,   # levels  9–12
	5, 5, 5, 5,   # levels 13–16
	6, 6, 6, 6,   # levels 17–20
]


## Returns the proficiency bonus for the given character level (1–20).
## Pushes an error and returns 0 for levels outside that range.
static func get_bonus(level: int) -> int:
	if level < MIN_LEVEL or level > MAX_LEVEL:
		push_error(
			"Proficiency: level %d is outside valid range [%d, %d]" % [level, MIN_LEVEL, MAX_LEVEL]
		)
		return 0
	return BONUS_TABLE[level]


## Returns the proficiency contribution to add to a roll.
## - Not proficient → 0.
## - Proficient     → full bonus.
## - Expertise      → double bonus (expertise implies proficiency).
## Pushes an error and returns 0 for levels outside [1, 20].
static func apply(level: int, is_proficient: bool, has_expertise: bool) -> int:
	if not is_proficient:
		return 0
	var bonus: int = get_bonus(level)
	return bonus * 2 if has_expertise else bonus
