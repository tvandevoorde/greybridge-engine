## ActionEconomy
## Pure logic class — no Node, no UI, no scene references.
## Tracks the four action slots available to a combatant each turn in D&D 5e SRD:
##   Action, Bonus Action, Movement, and Reaction.
##
## Usage:
##   var economy := ActionEconomy.new(speed_ft)
##   economy.start_turn()
##   economy.use_action()       # returns false if already spent
##   economy.use_bonus_action() # returns false if already spent
##   economy.use_movement(ft)   # returns false if insufficient movement remains
##   economy.use_reaction()     # returns false if already spent this round
##   economy.start_turn()       # resets Action, Bonus Action, Movement; also resets Reaction
##
## Per SRD:
##   - Each combatant has one Action, one Bonus Action, and one Reaction per round.
##   - Movement up to speed can be split across the turn.
##   - Reaction resets at the start of the actor's OWN turn (handled by start_turn()).
class_name ActionEconomy

## Speed in feet; set at construction time. Must be >= 0 (0 means the actor cannot move).
var speed_ft: int

## Remaining movement in feet for the current turn.
var movement_remaining_ft: int

var _action_used: bool
var _bonus_action_used: bool
var _reaction_used: bool


func _init(p_speed_ft: int) -> void:
	speed_ft = p_speed_ft
	movement_remaining_ft = 0
	_action_used = true        # not yet started; nothing available until start_turn()
	_bonus_action_used = true
	_reaction_used = true


## Call at the start of the actor's turn.
## Resets Action, Bonus Action, and Movement.
## Per SRD, Reaction also resets at the start of the actor's turn.
func start_turn() -> void:
	_action_used = false
	_bonus_action_used = false
	_reaction_used = false
	movement_remaining_ft = speed_ft


## Attempt to spend the Action for this turn.
## Returns true on success, false if the Action has already been used.
func use_action() -> bool:
	if _action_used:
		return false
	_action_used = true
	return true


## Attempt to spend the Bonus Action for this turn.
## Returns true on success, false if already spent.
func use_bonus_action() -> bool:
	if _bonus_action_used:
		return false
	_bonus_action_used = true
	return true


## Attempt to move a given number of feet.
## Returns true on success, false if insufficient movement remains or feet is negative.
func use_movement(feet: int) -> bool:
	if feet < 0 or feet > movement_remaining_ft:
		return false
	movement_remaining_ft -= feet
	return true


## Attempt to spend the Reaction for this round.
## Returns true on success, false if already spent.
## Reaction is reset only at the start of the actor's own turn (start_turn()).
func use_reaction() -> bool:
	if _reaction_used:
		return false
	_reaction_used = true
	return true


## Read-only helpers — useful for UI / combat_runtime queries.
func is_action_available() -> bool:
	return not _action_used


func is_bonus_action_available() -> bool:
	return not _bonus_action_used


func is_reaction_available() -> bool:
	return not _reaction_used
