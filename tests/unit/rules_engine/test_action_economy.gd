## test_action_economy.gd
## Unit tests for ActionEconomy (src/rules_engine/core/action_economy.gd).
##
## Run headlessly from the Godot project root (src/) with:
##   godot --headless --script ../tests/unit/rules_engine/test_action_economy.gd
extends SceneTree

const ActionEconomy = preload("res://rules_engine/core/action_economy.gd")

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
	_test_nothing_available_before_start_turn()
	_test_start_turn_grants_all_slots()
	_test_action_can_be_used_once()
	_test_bonus_action_can_be_used_once()
	_test_reaction_can_be_used_once()
	_test_movement_splits_across_turn()
	_test_movement_cannot_exceed_speed()
	_test_start_turn_resets_action()
	_test_start_turn_resets_bonus_action()
	_test_start_turn_resets_movement()
	_test_start_turn_resets_reaction()
	_test_reaction_not_reset_between_others_turns()
	_test_availability_helpers()
	_test_movement_negative_feet_rejected()


# ---------------------------------------------------------------------------
# Before start_turn() nothing should be available (guard against pre-turn use)
# ---------------------------------------------------------------------------
func _test_nothing_available_before_start_turn() -> void:
	print("_test_nothing_available_before_start_turn")
	var e := ActionEconomy.new(30)
	_check(e.use_action() == false, "action unavailable before start_turn")
	_check(e.use_bonus_action() == false, "bonus action unavailable before start_turn")
	_check(e.use_reaction() == false, "reaction unavailable before start_turn")
	_check(e.use_movement(5) == false, "movement unavailable before start_turn")


# ---------------------------------------------------------------------------
# start_turn() grants all four slots
# ---------------------------------------------------------------------------
func _test_start_turn_grants_all_slots() -> void:
	print("_test_start_turn_grants_all_slots")
	var e := ActionEconomy.new(30)
	e.start_turn()
	_check(e.is_action_available(), "action available after start_turn")
	_check(e.is_bonus_action_available(), "bonus action available after start_turn")
	_check(e.is_reaction_available(), "reaction available after start_turn")
	_check(e.movement_remaining_ft == 30, "full speed available after start_turn")


# ---------------------------------------------------------------------------
# Action: usable once, then denied
# ---------------------------------------------------------------------------
func _test_action_can_be_used_once() -> void:
	print("_test_action_can_be_used_once")
	var e := ActionEconomy.new(30)
	e.start_turn()
	_check(e.use_action() == true, "first use_action succeeds")
	_check(e.use_action() == false, "second use_action denied")
	_check(e.is_action_available() == false, "action no longer available")


# ---------------------------------------------------------------------------
# Bonus Action: usable once, then denied
# ---------------------------------------------------------------------------
func _test_bonus_action_can_be_used_once() -> void:
	print("_test_bonus_action_can_be_used_once")
	var e := ActionEconomy.new(30)
	e.start_turn()
	_check(e.use_bonus_action() == true, "first use_bonus_action succeeds")
	_check(e.use_bonus_action() == false, "second use_bonus_action denied")
	_check(e.is_bonus_action_available() == false, "bonus action no longer available")


# ---------------------------------------------------------------------------
# Reaction: usable once, then denied
# ---------------------------------------------------------------------------
func _test_reaction_can_be_used_once() -> void:
	print("_test_reaction_can_be_used_once")
	var e := ActionEconomy.new(30)
	e.start_turn()
	_check(e.use_reaction() == true, "first use_reaction succeeds")
	_check(e.use_reaction() == false, "second use_reaction denied")
	_check(e.is_reaction_available() == false, "reaction no longer available")


# ---------------------------------------------------------------------------
# Movement can be split across multiple use_movement() calls
# ---------------------------------------------------------------------------
func _test_movement_splits_across_turn() -> void:
	print("_test_movement_splits_across_turn")
	var e := ActionEconomy.new(30)
	e.start_turn()
	_check(e.use_movement(10) == true, "move 10 ft succeeds")
	_check(e.movement_remaining_ft == 20, "20 ft remaining after 10 ft move")
	_check(e.use_movement(15) == true, "move another 15 ft succeeds")
	_check(e.movement_remaining_ft == 5, "5 ft remaining after 25 ft total")
	_check(e.use_movement(5) == true, "final 5 ft succeeds")
	_check(e.movement_remaining_ft == 0, "0 ft remaining after full speed used")


# ---------------------------------------------------------------------------
# Movement cannot exceed remaining speed
# ---------------------------------------------------------------------------
func _test_movement_cannot_exceed_speed() -> void:
	print("_test_movement_cannot_exceed_speed")
	var e := ActionEconomy.new(30)
	e.start_turn()
	_check(e.use_movement(31) == false, "moving 31 ft with 30 speed denied")
	_check(e.movement_remaining_ft == 30, "remaining unchanged after failed move")
	# Exact speed is still allowed
	_check(e.use_movement(30) == true, "moving exactly 30 ft allowed")
	_check(e.movement_remaining_ft == 0, "0 ft remaining")


# ---------------------------------------------------------------------------
# start_turn() resets Action for next turn
# ---------------------------------------------------------------------------
func _test_start_turn_resets_action() -> void:
	print("_test_start_turn_resets_action")
	var e := ActionEconomy.new(30)
	e.start_turn()
	e.use_action()
	e.start_turn()
	_check(e.is_action_available(), "action reset by start_turn")
	_check(e.use_action() == true, "use_action succeeds after reset")


# ---------------------------------------------------------------------------
# start_turn() resets Bonus Action for next turn
# ---------------------------------------------------------------------------
func _test_start_turn_resets_bonus_action() -> void:
	print("_test_start_turn_resets_bonus_action")
	var e := ActionEconomy.new(30)
	e.start_turn()
	e.use_bonus_action()
	e.start_turn()
	_check(e.is_bonus_action_available(), "bonus action reset by start_turn")
	_check(e.use_bonus_action() == true, "use_bonus_action succeeds after reset")


# ---------------------------------------------------------------------------
# start_turn() restores full speed
# ---------------------------------------------------------------------------
func _test_start_turn_resets_movement() -> void:
	print("_test_start_turn_resets_movement")
	var e := ActionEconomy.new(30)
	e.start_turn()
	e.use_movement(30)
	e.start_turn()
	_check(e.movement_remaining_ft == 30, "movement restored to full speed by start_turn")
	_check(e.use_movement(30) == true, "full movement available after reset")


# ---------------------------------------------------------------------------
# Reaction resets at the start of the actor's OWN turn (start_turn())
# ---------------------------------------------------------------------------
func _test_start_turn_resets_reaction() -> void:
	print("_test_start_turn_resets_reaction")
	var e := ActionEconomy.new(30)
	e.start_turn()
	e.use_reaction()
	_check(e.is_reaction_available() == false, "reaction spent")
	e.start_turn()
	_check(e.is_reaction_available(), "reaction reset at start of actor's own turn")
	_check(e.use_reaction() == true, "use_reaction succeeds after reset")


# ---------------------------------------------------------------------------
# Reaction is NOT reset by other combatants' turns (no start_turn() call)
# ---------------------------------------------------------------------------
func _test_reaction_not_reset_between_others_turns() -> void:
	print("_test_reaction_not_reset_between_others_turns")
	var e := ActionEconomy.new(30)
	e.start_turn()
	e.use_reaction()
	# Simulate other combatants' turns passing without calling start_turn()
	_check(e.is_reaction_available() == false, "reaction still spent mid-round")
	_check(e.use_reaction() == false, "cannot use reaction again mid-round")


# ---------------------------------------------------------------------------
# is_*_available() helpers reflect current state accurately
# ---------------------------------------------------------------------------
func _test_availability_helpers() -> void:
	print("_test_availability_helpers")
	var e := ActionEconomy.new(30)
	e.start_turn()
	_check(e.is_action_available() == true, "action available initially")
	_check(e.is_bonus_action_available() == true, "bonus action available initially")
	_check(e.is_reaction_available() == true, "reaction available initially")
	e.use_action()
	e.use_bonus_action()
	e.use_reaction()
	_check(e.is_action_available() == false, "action unavailable after use")
	_check(e.is_bonus_action_available() == false, "bonus action unavailable after use")
	_check(e.is_reaction_available() == false, "reaction unavailable after use")


# ---------------------------------------------------------------------------
# Negative movement values are rejected
# ---------------------------------------------------------------------------
func _test_movement_negative_feet_rejected() -> void:
	print("_test_movement_negative_feet_rejected")
	var e := ActionEconomy.new(30)
	e.start_turn()
	_check(e.use_movement(-1) == false, "negative movement rejected")
	_check(e.movement_remaining_ft == 30, "remaining movement unchanged after rejection")
