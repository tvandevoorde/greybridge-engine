## OpportunityAttack
## Pure logic class — no Node, no UI, no scene references.
## Validates whether a D&D 5e SRD opportunity attack may trigger.
##
## An opportunity attack triggers when a hostile creature leaves the attacker's
## melee reach without first taking the Disengage action.
##
## The caller (combat_runtime) is responsible for determining whether the target
## has actually left melee reach.  This class only validates the rule conditions.
##
## Usage:
##   var oa := OpportunityAttack.new()
##   var result := oa.check(attacker_has_reaction, target_is_disengaging)
##
## Result dictionary keys:
##   "can_trigger" : bool   — true if the opportunity attack is legal to make
##   "reason"      : String — "reaction_spent" | "target_disengaging" | ""
class_name OpportunityAttack


## Check whether an opportunity attack may legally trigger.
##
## attacker_has_reaction : bool — true if the attacker still has their reaction
##                                for this round
## target_is_disengaging : bool — true if the target used the Disengage action
##                                on their current turn
##
## Conditions checked (in order):
##   1. Attacker must have their reaction available.
##   2. Target must NOT have taken the Disengage action this turn.
func check(attacker_has_reaction: bool, target_is_disengaging: bool) -> Dictionary:
	if not attacker_has_reaction:
		return {"can_trigger": false, "reason": "reaction_spent"}
	if target_is_disengaging:
		return {"can_trigger": false, "reason": "target_disengaging"}
	return {"can_trigger": true, "reason": ""}
