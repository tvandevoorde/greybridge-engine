## test_reaction_trigger.gd
## Unit tests for ReactionTrigger (src/rules_engine/core/reaction_trigger.gd).
##
## Run headlessly from the Godot project root (src/) with:
##   godot --headless --script ./tests/unit/rules_engine/test_reaction_trigger.gd
##
## Exit code 0 = all assertions passed; 1 = one or more assertions failed.
extends SceneTree

const ReactionTriggerClass = preload("res://rules_engine/core/reaction_trigger.gd")

var _pass_count: int = 0
var _fail_count: int = 0


func _initialize() -> void:
	_run_all_tests()
	print("\nResults: %d passed, %d failed" % [_pass_count, _fail_count])
	quit(1 if _fail_count > 0 else 0)


func _check(condition: bool, description: String) -> void:
	if condition:
		print("  PASS: %s" % description)
		_pass_count += 1
	else:
		print("  FAIL: %s" % description)
		_fail_count += 1


func _run_all_tests() -> void:
	_test_check_reaction_spent_blocks_being_hit()
	_test_check_reaction_spent_blocks_creature_leaves_reach()
	_test_check_being_hit_with_reaction_available()
	_test_check_creature_leaves_reach_with_reaction_available()
	_test_check_unknown_trigger_type()
	_test_get_reactions_for_trigger_being_hit()
	_test_get_reactions_for_trigger_creature_leaves_reach()
	_test_get_reactions_for_trigger_unknown_returns_empty()
	_test_is_valid_reaction_shield()
	_test_is_valid_reaction_opportunity_attack()
	_test_is_valid_reaction_unknown_returns_false()
	_test_is_valid_reaction_empty_string_returns_false()


# ---------------------------------------------------------------------------
# check — reaction_spent blocks all trigger types
# ---------------------------------------------------------------------------
func _test_check_reaction_spent_blocks_being_hit() -> void:
	print("_test_check_reaction_spent_blocks_being_hit")
	var result := ReactionTriggerClass.check(ReactionTriggerClass.TriggerType.BEING_HIT, false)
	_check(result["can_trigger"] == false, "can_trigger is false when reaction is spent (BEING_HIT)")
	_check(result["reason"] == "reaction_spent", "reason is 'reaction_spent' when reaction is spent")


func _test_check_reaction_spent_blocks_creature_leaves_reach() -> void:
	print("_test_check_reaction_spent_blocks_creature_leaves_reach")
	var result := ReactionTriggerClass.check(
		ReactionTriggerClass.TriggerType.CREATURE_LEAVES_REACH, false
	)
	_check(result["can_trigger"] == false,
		"can_trigger is false when reaction is spent (CREATURE_LEAVES_REACH)")
	_check(result["reason"] == "reaction_spent",
		"reason is 'reaction_spent' for CREATURE_LEAVES_REACH when reaction spent")


# ---------------------------------------------------------------------------
# check — valid trigger types with reaction available
# ---------------------------------------------------------------------------
func _test_check_being_hit_with_reaction_available() -> void:
	print("_test_check_being_hit_with_reaction_available")
	var result := ReactionTriggerClass.check(ReactionTriggerClass.TriggerType.BEING_HIT, true)
	_check(result["can_trigger"] == true,
		"can_trigger is true for BEING_HIT when reaction is available")
	_check(result["reason"] == "", "reason is empty string for valid BEING_HIT trigger")


func _test_check_creature_leaves_reach_with_reaction_available() -> void:
	print("_test_check_creature_leaves_reach_with_reaction_available")
	var result := ReactionTriggerClass.check(
		ReactionTriggerClass.TriggerType.CREATURE_LEAVES_REACH, true
	)
	_check(result["can_trigger"] == true,
		"can_trigger is true for CREATURE_LEAVES_REACH when reaction is available")
	_check(result["reason"] == "",
		"reason is empty string for valid CREATURE_LEAVES_REACH trigger")


# ---------------------------------------------------------------------------
# check — unknown trigger type
# ---------------------------------------------------------------------------
func _test_check_unknown_trigger_type() -> void:
	print("_test_check_unknown_trigger_type")
	var result := ReactionTriggerClass.check(999, true)
	_check(result["can_trigger"] == false, "can_trigger is false for unknown trigger type")
	_check(result["reason"] == "unknown_trigger", "reason is 'unknown_trigger' for unknown type")


# ---------------------------------------------------------------------------
# get_reactions_for_trigger
# ---------------------------------------------------------------------------
func _test_get_reactions_for_trigger_being_hit() -> void:
	print("_test_get_reactions_for_trigger_being_hit")
	var reactions := ReactionTriggerClass.get_reactions_for_trigger(
		ReactionTriggerClass.TriggerType.BEING_HIT
	)
	_check(reactions.size() == 1, "BEING_HIT returns exactly one reaction")
	_check(reactions.has("shield"), "BEING_HIT returns 'shield'")


func _test_get_reactions_for_trigger_creature_leaves_reach() -> void:
	print("_test_get_reactions_for_trigger_creature_leaves_reach")
	var reactions := ReactionTriggerClass.get_reactions_for_trigger(
		ReactionTriggerClass.TriggerType.CREATURE_LEAVES_REACH
	)
	_check(reactions.size() == 1, "CREATURE_LEAVES_REACH returns exactly one reaction")
	_check(reactions.has("opportunity_attack"), "CREATURE_LEAVES_REACH returns 'opportunity_attack'")


func _test_get_reactions_for_trigger_unknown_returns_empty() -> void:
	print("_test_get_reactions_for_trigger_unknown_returns_empty")
	var reactions := ReactionTriggerClass.get_reactions_for_trigger(999)
	_check(reactions.size() == 0, "unknown trigger type returns empty array")


# ---------------------------------------------------------------------------
# is_valid_reaction
# ---------------------------------------------------------------------------
func _test_is_valid_reaction_shield() -> void:
	print("_test_is_valid_reaction_shield")
	_check(ReactionTriggerClass.is_valid_reaction("shield") == true,
		"'shield' is a valid reaction ID")


func _test_is_valid_reaction_opportunity_attack() -> void:
	print("_test_is_valid_reaction_opportunity_attack")
	_check(ReactionTriggerClass.is_valid_reaction("opportunity_attack") == true,
		"'opportunity_attack' is a valid reaction ID")


func _test_is_valid_reaction_unknown_returns_false() -> void:
	print("_test_is_valid_reaction_unknown_returns_false")
	_check(ReactionTriggerClass.is_valid_reaction("fireball") == false,
		"'fireball' is not a valid reaction ID")
	_check(ReactionTriggerClass.is_valid_reaction("SHIELD") == false,
		"uppercase 'SHIELD' is not a valid reaction ID")


func _test_is_valid_reaction_empty_string_returns_false() -> void:
	print("_test_is_valid_reaction_empty_string_returns_false")
	_check(ReactionTriggerClass.is_valid_reaction("") == false,
		"empty string is not a valid reaction ID")
