## DiceRoller
## Pure logic class — no Node, no UI, no scene references.
## Centralised, deterministic dice rolling engine for D&D 5e SRD mechanics.
## Accepts an optional seed for reproducible results in tests.
class_name DiceRoller

## Valid die face counts per 5e SRD.
const VALID_DICE: Array[int] = [4, 6, 8, 10, 12, 20]

var _rng: RandomNumberGenerator


## Construct a DiceRoller.
## Pass a non-negative seed_value to produce deterministic rolls (testing).
## Omit or pass -1 to use a random seed.
func _init(seed_value: int = -1) -> void:
	_rng = RandomNumberGenerator.new()
	if seed_value >= 0:
		_rng.seed = seed_value
	else:
		_rng.randomize()


## Roll a single die with the given number of faces.
## Returns a value in [1, faces].
## Pushes an error and returns 0 for invalid face counts.
func roll(faces: int) -> int:
	if faces not in VALID_DICE:
		push_error("DiceRoller: invalid die faces '%d'; valid values are %s" % [faces, VALID_DICE])
		return 0
	return _rng.randi_range(1, faces)


## Roll count dice of the given faces, sum the results, and add modifier.
## Equivalent to the expression NdF+M (e.g. count=2, faces=6, modifier=3 → 2d6+3).
## Pushes an error and returns 0 if count < 1 or faces are invalid.
func roll_expression(count: int, faces: int, modifier: int = 0) -> int:
	if count < 1:
		push_error("DiceRoller: count must be >= 1 (got %d)" % count)
		return 0
	var total: int = modifier
	for i in count:
		var result: int = roll(faces)
		if result == 0:
			return 0
		total += result
	return total


## Parse and evaluate a dice expression string such as "2d6+3" or "1d20" or "d8".
## Returns 0 and pushes an error if the expression cannot be parsed.
func roll_string(expression: String) -> int:
	var expr: String = expression.to_lower().replace(" ", "")
	var regex := RegEx.new()
	regex.compile("^(\\d+)?d(\\d+)([+-]\\d+)?$")
	var match_result := regex.search(expr)
	if match_result == null:
		push_error("DiceRoller: cannot parse expression '%s'" % expression)
		return 0
	var count: int = 1 if match_result.get_string(1) == "" else int(match_result.get_string(1))
	var faces: int = int(match_result.get_string(2))
	var modifier: int = 0 if match_result.get_string(3) == "" else int(match_result.get_string(3))
	return roll_expression(count, faces, modifier)


## Roll a d20 with advantage: roll twice and return the higher result.
func roll_advantage() -> int:
	var a: int = roll(20)
	var b: int = roll(20)
	return maxi(a, b)


## Roll a d20 with disadvantage: roll twice and return the lower result.
func roll_disadvantage() -> int:
	var a: int = roll(20)
	var b: int = roll(20)
	return mini(a, b)
