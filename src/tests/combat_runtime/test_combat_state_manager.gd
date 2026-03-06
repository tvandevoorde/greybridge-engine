## test_combat_state_manager.gd
## Unit tests for CombatStateManager (src/combat_runtime/combat_state_manager.gd)
##
## Run headlessly from the Godot project root (src/) with:
##   godot --headless --script ../tests/unit/combat_runtime/test_combat_state_manager.gd
extends SceneTree

const CombatStateManager = preload("res://combat_runtime/combat_state_manager.gd")

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
	_test_initial_state_inactive()
	_test_start_combat_sets_active()
	_test_start_combat_stores_participants()
	_test_start_combat_stores_initiative_order()
	_test_start_combat_sets_round_to_one()
	_test_start_combat_sets_turn_index_to_zero()
	_test_get_current_combatant_id()
	_test_advance_turn_increments_index()
	_test_advance_turn_wraps_and_increments_round()
	_test_end_combat_clears_state()
	_test_advance_turn_no_op_when_inactive()
	_test_get_current_combatant_id_when_inactive()
	_test_start_combat_resets_previous_state()


# ---------------------------------------------------------------------------
# Initial state
# ---------------------------------------------------------------------------
func _test_initial_state_inactive() -> void:
	print("_test_initial_state_inactive")
	var m := CombatStateManager.new()
	_check(m.is_active() == false, "new manager is inactive")
	_check(m.get_round() == 0, "round is 0 before combat starts")
	_check(m.get_current_turn_index() == 0, "turn index is 0 before combat starts")
	_check(m.get_participants().size() == 0, "no participants before combat starts")
	_check(m.get_initiative_order().size() == 0, "no initiative order before combat starts")


# ---------------------------------------------------------------------------
# start_combat
# ---------------------------------------------------------------------------
func _test_start_combat_sets_active() -> void:
	print("_test_start_combat_sets_active")
	var m := CombatStateManager.new()
	m.start_combat([{"id": "player"}], ["player"])
	_check(m.is_active() == true, "combat is active after start_combat")


func _test_start_combat_stores_participants() -> void:
	print("_test_start_combat_stores_participants")
	var m := CombatStateManager.new()
	var participants := [{"id": "player"}, {"id": "goblin"}]
	m.start_combat(participants, ["player", "goblin"])
	_check(m.get_participants().size() == 2, "two participants stored")
	_check(m.get_participants()[0]["id"] == "player", "first participant is player")
	_check(m.get_participants()[1]["id"] == "goblin", "second participant is goblin")


func _test_start_combat_stores_initiative_order() -> void:
	print("_test_start_combat_stores_initiative_order")
	var m := CombatStateManager.new()
	m.start_combat([{"id": "player"}, {"id": "goblin"}], ["goblin", "player"])
	var order := m.get_initiative_order()
	_check(order.size() == 2, "initiative order has two entries")
	_check(order[0] == "goblin", "goblin goes first in initiative order")
	_check(order[1] == "player", "player goes second in initiative order")


func _test_start_combat_sets_round_to_one() -> void:
	print("_test_start_combat_sets_round_to_one")
	var m := CombatStateManager.new()
	m.start_combat([{"id": "player"}], ["player"])
	_check(m.get_round() == 1, "round is 1 at combat start")


func _test_start_combat_sets_turn_index_to_zero() -> void:
	print("_test_start_combat_sets_turn_index_to_zero")
	var m := CombatStateManager.new()
	m.start_combat([{"id": "player"}], ["player"])
	_check(m.get_current_turn_index() == 0, "turn index is 0 at combat start")


# ---------------------------------------------------------------------------
# get_current_combatant_id
# ---------------------------------------------------------------------------
func _test_get_current_combatant_id() -> void:
	print("_test_get_current_combatant_id")
	var m := CombatStateManager.new()
	m.start_combat([{"id": "player"}, {"id": "orc"}], ["orc", "player"])
	_check(m.get_current_combatant_id() == "orc", "first active combatant is orc")


# ---------------------------------------------------------------------------
# advance_turn
# ---------------------------------------------------------------------------
func _test_advance_turn_increments_index() -> void:
	print("_test_advance_turn_increments_index")
	var m := CombatStateManager.new()
	m.start_combat([{"id": "player"}, {"id": "orc"}], ["orc", "player"])
	m.advance_turn()
	_check(m.get_current_turn_index() == 1, "turn index advances to 1")
	_check(m.get_current_combatant_id() == "player", "player is active after advance")
	_check(m.get_round() == 1, "still round 1 after one advance")


func _test_advance_turn_wraps_and_increments_round() -> void:
	print("_test_advance_turn_wraps_and_increments_round")
	var m := CombatStateManager.new()
	m.start_combat([{"id": "player"}, {"id": "orc"}], ["orc", "player"])
	m.advance_turn()  # index → 1
	m.advance_turn()  # index wraps to 0, round → 2
	_check(m.get_current_turn_index() == 0, "turn index wraps back to 0")
	_check(m.get_round() == 2, "round increments to 2 after full cycle")
	_check(m.get_current_combatant_id() == "orc", "orc active again at start of round 2")


# ---------------------------------------------------------------------------
# end_combat
# ---------------------------------------------------------------------------
func _test_end_combat_clears_state() -> void:
	print("_test_end_combat_clears_state")
	var m := CombatStateManager.new()
	m.start_combat([{"id": "player"}, {"id": "orc"}], ["orc", "player"])
	m.advance_turn()
	m.end_combat()
	_check(m.is_active() == false, "combat inactive after end_combat")
	_check(m.get_round() == 0, "round reset to 0 after end_combat")
	_check(m.get_current_turn_index() == 0, "turn index reset to 0 after end_combat")
	_check(m.get_participants().size() == 0, "participants cleared after end_combat")
	_check(m.get_initiative_order().size() == 0, "initiative order cleared after end_combat")


# ---------------------------------------------------------------------------
# Guards: inactive state
# ---------------------------------------------------------------------------
func _test_advance_turn_no_op_when_inactive() -> void:
	print("_test_advance_turn_no_op_when_inactive")
	var m := CombatStateManager.new()
	m.advance_turn()
	_check(m.get_current_turn_index() == 0, "turn index unchanged when inactive")
	_check(m.get_round() == 0, "round unchanged when inactive")


func _test_get_current_combatant_id_when_inactive() -> void:
	print("_test_get_current_combatant_id_when_inactive")
	var m := CombatStateManager.new()
	_check(m.get_current_combatant_id() == "", "returns empty string when inactive")


# ---------------------------------------------------------------------------
# start_combat resets existing state
# ---------------------------------------------------------------------------
func _test_start_combat_resets_previous_state() -> void:
	print("_test_start_combat_resets_previous_state")
	var m := CombatStateManager.new()
	m.start_combat([{"id": "player"}, {"id": "orc"}], ["orc", "player"])
	m.advance_turn()
	m.advance_turn()  # round 2
	m.start_combat([{"id": "player"}, {"id": "bandit"}], ["player", "bandit"])
	_check(m.get_round() == 1, "round reset to 1 on new combat start")
	_check(m.get_current_turn_index() == 0, "turn index reset to 0 on new combat start")
	_check(m.get_participants().size() == 2, "new participants loaded")
	_check(m.get_participants()[1]["id"] == "bandit", "bandit is participant in new combat")
