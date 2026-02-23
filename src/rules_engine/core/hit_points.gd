## HitPoints
## Pure logic class — no Node, no UI, no scene references.
## Tracks current and maximum HP for a single actor.
##
## HP cannot be reduced below 0.
## Healing cannot raise HP above the stored maximum.
##
## Usage:
##   var hp := HitPoints.new(12)
##   hp.apply_damage(5)   # current_hp is now 7
##   hp.apply_damage(10)  # current_hp is clamped to 0, not -3
class_name HitPoints

var _max_hp: int
var _current_hp: int


## Construct a HitPoints tracker.
## max_hp must be >= 1; pushes an error and defaults to 1 if not.
func _init(max_hp: int) -> void:
	if max_hp < 1:
		push_error("HitPoints: max_hp must be >= 1 (got %d)" % max_hp)
		max_hp = 1
	_max_hp = max_hp
	_current_hp = max_hp


## Returns the maximum HP value.
func get_max() -> int:
	return _max_hp


## Returns the current HP value.
func get_current() -> int:
	return _current_hp


## Reduces current HP by amount.
## amount is treated as non-negative; negative values are ignored (no healing).
## HP is clamped to 0 and never goes negative.
func apply_damage(amount: int) -> void:
	if amount < 0:
		return
	_current_hp = maxi(0, _current_hp - amount)


## Returns true when current HP has reached 0.
func is_at_zero() -> bool:
	return _current_hp == 0
