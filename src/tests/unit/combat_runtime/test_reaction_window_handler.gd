## test_reaction_window_handler.gd
## Unit tests for ReactionWindowHandler (src/combat_runtime/reaction_window_handler.gd).
##
## Run headlessly from the Godot project root (src/) with:
##   godot --headless --script ./tests/unit/combat_runtime/test_reaction_window_handler.gd
##
## Exit code 0 = all assertions passed; 1 = one or more assertions failed.
extends SceneTree

const ReactionWindowHandlerClass = preload("res://combat_runtime/reaction_window_handler.gd")
const ActionEconomyClass = preload("res://rules_engine/core/action_economy.gd")
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
	_test_initial_state_window_not_open()
	_test_open_window_returns_false_with_null_economy()
	_test_open_window_returns_false_when_reaction_spent()
	_test_open_window_returns_false_for_unknown_trigger_type()
	_test_open_window_returns_false_when_already_open()
	_test_open_window_returns_true_for_valid_being_hit()
	_test_open_window_returns_true_for_valid_creature_leaves_reach()
	_test_open_window_emits_reaction_window_opened()
	_test_open_window_sets_window_open()
	_test_select_reaction_returns_false_when_window_not_open()
	_test_select_reaction_returns_false_for_invalid_reaction_id()
	_test_select_reaction_spends_reaction_slot()
	_test_select_reaction_emits_reaction_selected()
	_test_select_reaction_closes_window()
	_test_select_reaction_emits_reaction_window_closed()
	_test_decline_no_op_when_window_not_open()
	_test_decline_closes_window_and_emits_declined()
	_test_decline_emits_reaction_window_closed()
	_test_force_timeout_no_op_when_window_not_open()
	_test_force_timeout_closes_window_and_emits_declined()
	_test_force_timeout_emits_reaction_window_closed()
	_test_one_reaction_per_round_second_window_fails_after_reaction_spent()
	_test_window_can_reopen_after_close()


# ---------------------------------------------------------------------------
# Initial state
# ---------------------------------------------------------------------------
func _test_initial_state_window_not_open() -> void:
	print("_test_initial_state_window_not_open")
	var handler := ReactionWindowHandlerClass.new()
	_check(handler.is_window_open() == false, "window is not open on initialisation")
	handler.free()


# ---------------------------------------------------------------------------
# open_window — guard conditions
# ---------------------------------------------------------------------------
func _test_open_window_returns_false_with_null_economy() -> void:
	print("_test_open_window_returns_false_with_null_economy")
	var handler := ReactionWindowHandlerClass.new()
	var opened: bool = false
	handler.reaction_window_opened.connect(func(_t: int, _id: String) -> void: opened = true)
	var result := handler.open_window(ReactionTriggerClass.TriggerType.BEING_HIT, "player", null)
	_check(result == false, "open_window returns false with null economy")
	_check(opened == false, "reaction_window_opened not emitted with null economy")
	_check(handler.is_window_open() == false, "window remains closed with null economy")
	handler.free()


func _test_open_window_returns_false_when_reaction_spent() -> void:
	print("_test_open_window_returns_false_when_reaction_spent")
	var handler := ReactionWindowHandlerClass.new()
	var economy := ActionEconomyClass.new(30)
	economy.start_turn()
	economy.use_reaction()  # spend the reaction slot
	var result := handler.open_window(
		ReactionTriggerClass.TriggerType.BEING_HIT, "player", economy
	)
	_check(result == false, "open_window returns false when reaction slot is spent")
	_check(handler.is_window_open() == false, "window remains closed when reaction spent")
	handler.free()


func _test_open_window_returns_false_for_unknown_trigger_type() -> void:
	print("_test_open_window_returns_false_for_unknown_trigger_type")
	var handler := ReactionWindowHandlerClass.new()
	var economy := ActionEconomyClass.new(30)
	economy.start_turn()
	var result := handler.open_window(999, "player", economy)
	_check(result == false, "open_window returns false for unknown trigger type")
	_check(handler.is_window_open() == false, "window remains closed for unknown trigger type")
	handler.free()


func _test_open_window_returns_false_when_already_open() -> void:
	print("_test_open_window_returns_false_when_already_open")
	var handler := ReactionWindowHandlerClass.new()
	var economy := ActionEconomyClass.new(30)
	economy.start_turn()
	handler.open_window(ReactionTriggerClass.TriggerType.BEING_HIT, "player", economy)
	var second_result := handler.open_window(
		ReactionTriggerClass.TriggerType.BEING_HIT, "orc", economy
	)
	_check(second_result == false, "open_window returns false when a window is already open")
	handler.free()


# ---------------------------------------------------------------------------
# open_window — success cases
# ---------------------------------------------------------------------------
func _test_open_window_returns_true_for_valid_being_hit() -> void:
	print("_test_open_window_returns_true_for_valid_being_hit")
	var handler := ReactionWindowHandlerClass.new()
	var economy := ActionEconomyClass.new(30)
	economy.start_turn()
	var result := handler.open_window(
		ReactionTriggerClass.TriggerType.BEING_HIT, "player", economy
	)
	_check(result == true, "open_window returns true for BEING_HIT with reaction available")
	handler.free()


func _test_open_window_returns_true_for_valid_creature_leaves_reach() -> void:
	print("_test_open_window_returns_true_for_valid_creature_leaves_reach")
	var handler := ReactionWindowHandlerClass.new()
	var economy := ActionEconomyClass.new(30)
	economy.start_turn()
	var result := handler.open_window(
		ReactionTriggerClass.TriggerType.CREATURE_LEAVES_REACH, "orc", economy
	)
	_check(result == true,
		"open_window returns true for CREATURE_LEAVES_REACH with reaction available")
	handler.free()


func _test_open_window_emits_reaction_window_opened() -> void:
	print("_test_open_window_emits_reaction_window_opened")
	var handler := ReactionWindowHandlerClass.new()
	var economy := ActionEconomyClass.new(30)
	economy.start_turn()
	var trigger_types: Array = []
	var reactor_ids: Array = []
	handler.reaction_window_opened.connect(func(t: int, id: String) -> void:
		trigger_types.append(t)
		reactor_ids.append(id)
	)
	handler.open_window(ReactionTriggerClass.TriggerType.BEING_HIT, "player", economy)
	_check(trigger_types.size() == 1, "reaction_window_opened emitted once")
	_check(trigger_types[0] == ReactionTriggerClass.TriggerType.BEING_HIT,
		"reaction_window_opened carries correct trigger_type")
	_check(reactor_ids[0] == "player", "reaction_window_opened carries correct reactor_id")
	handler.free()


func _test_open_window_sets_window_open() -> void:
	print("_test_open_window_sets_window_open")
	var handler := ReactionWindowHandlerClass.new()
	var economy := ActionEconomyClass.new(30)
	economy.start_turn()
	handler.open_window(ReactionTriggerClass.TriggerType.BEING_HIT, "player", economy)
	_check(handler.is_window_open() == true, "is_window_open returns true after open_window")
	handler.free()


# ---------------------------------------------------------------------------
# select_reaction — guard conditions
# ---------------------------------------------------------------------------
func _test_select_reaction_returns_false_when_window_not_open() -> void:
	print("_test_select_reaction_returns_false_when_window_not_open")
	var handler := ReactionWindowHandlerClass.new()
	var result := handler.select_reaction("shield")
	_check(result == false, "select_reaction returns false when window is not open")
	handler.free()


func _test_select_reaction_returns_false_for_invalid_reaction_id() -> void:
	print("_test_select_reaction_returns_false_for_invalid_reaction_id")
	var handler := ReactionWindowHandlerClass.new()
	var economy := ActionEconomyClass.new(30)
	economy.start_turn()
	handler.open_window(ReactionTriggerClass.TriggerType.BEING_HIT, "player", economy)
	var result_invalid := handler.select_reaction("fireball")
	_check(result_invalid == false, "select_reaction returns false for unknown reaction id")
	var result_empty := handler.select_reaction("")
	_check(result_empty == false, "select_reaction returns false for empty reaction id")
	_check(handler.is_window_open() == true, "window remains open after rejected selection")
	handler.free()


# ---------------------------------------------------------------------------
# select_reaction — success path
# ---------------------------------------------------------------------------
func _test_select_reaction_spends_reaction_slot() -> void:
	print("_test_select_reaction_spends_reaction_slot")
	var handler := ReactionWindowHandlerClass.new()
	var economy := ActionEconomyClass.new(30)
	economy.start_turn()
	handler.open_window(ReactionTriggerClass.TriggerType.BEING_HIT, "player", economy)
	handler.select_reaction("shield")
	_check(economy.is_reaction_available() == false,
		"reaction slot is spent after select_reaction")


func _test_select_reaction_emits_reaction_selected() -> void:
	print("_test_select_reaction_emits_reaction_selected")
	var handler := ReactionWindowHandlerClass.new()
	var economy := ActionEconomyClass.new(30)
	economy.start_turn()
	handler.open_window(ReactionTriggerClass.TriggerType.BEING_HIT, "player", economy)
	var reactor_ids: Array = []
	var reaction_ids: Array = []
	handler.reaction_selected.connect(func(rid: String, rxn: String) -> void:
		reactor_ids.append(rid)
		reaction_ids.append(rxn)
	)
	handler.select_reaction("shield")
	_check(reactor_ids.size() == 1, "reaction_selected emitted once")
	_check(reactor_ids[0] == "player", "reaction_selected carries correct reactor_id")
	_check(reaction_ids[0] == "shield", "reaction_selected carries correct reaction_id")
	handler.free()


func _test_select_reaction_closes_window() -> void:
	print("_test_select_reaction_closes_window")
	var handler := ReactionWindowHandlerClass.new()
	var economy := ActionEconomyClass.new(30)
	economy.start_turn()
	handler.open_window(ReactionTriggerClass.TriggerType.BEING_HIT, "player", economy)
	handler.select_reaction("shield")
	_check(handler.is_window_open() == false, "window is closed after select_reaction")
	handler.free()


func _test_select_reaction_emits_reaction_window_closed() -> void:
	print("_test_select_reaction_emits_reaction_window_closed")
	var handler := ReactionWindowHandlerClass.new()
	var economy := ActionEconomyClass.new(30)
	economy.start_turn()
	handler.open_window(ReactionTriggerClass.TriggerType.BEING_HIT, "player", economy)
	var closed_ids: Array = []
	handler.reaction_window_closed.connect(func(id: String) -> void: closed_ids.append(id))
	handler.select_reaction("shield")
	_check(closed_ids.size() == 1, "reaction_window_closed emitted once after select_reaction")
	_check(closed_ids[0] == "player",
		"reaction_window_closed carries correct reactor_id after select_reaction")
	handler.free()


# ---------------------------------------------------------------------------
# decline
# ---------------------------------------------------------------------------
func _test_decline_no_op_when_window_not_open() -> void:
	print("_test_decline_no_op_when_window_not_open")
	var handler := ReactionWindowHandlerClass.new()
	var declined: bool = false
	handler.reaction_declined.connect(func(_id: String) -> void: declined = true)
	handler.decline()
	_check(declined == false, "reaction_declined not emitted when window is not open")
	handler.free()


func _test_decline_closes_window_and_emits_declined() -> void:
	print("_test_decline_closes_window_and_emits_declined")
	var handler := ReactionWindowHandlerClass.new()
	var economy := ActionEconomyClass.new(30)
	economy.start_turn()
	handler.open_window(ReactionTriggerClass.TriggerType.BEING_HIT, "player", economy)
	var declined_ids: Array = []
	handler.reaction_declined.connect(func(id: String) -> void: declined_ids.append(id))
	handler.decline()
	_check(handler.is_window_open() == false, "window is closed after decline()")
	_check(declined_ids.size() == 1, "reaction_declined emitted once")
	_check(declined_ids[0] == "player", "reaction_declined carries correct reactor_id")
	_check(economy.is_reaction_available() == true,
		"reaction slot is NOT spent when player declines")
	handler.free()


func _test_decline_emits_reaction_window_closed() -> void:
	print("_test_decline_emits_reaction_window_closed")
	var handler := ReactionWindowHandlerClass.new()
	var economy := ActionEconomyClass.new(30)
	economy.start_turn()
	handler.open_window(ReactionTriggerClass.TriggerType.BEING_HIT, "player", economy)
	var closed_ids: Array = []
	handler.reaction_window_closed.connect(func(id: String) -> void: closed_ids.append(id))
	handler.decline()
	_check(closed_ids.size() == 1, "reaction_window_closed emitted once after decline()")
	_check(closed_ids[0] == "player",
		"reaction_window_closed carries correct reactor_id after decline()")
	handler.free()


# ---------------------------------------------------------------------------
# force_timeout
# ---------------------------------------------------------------------------
func _test_force_timeout_no_op_when_window_not_open() -> void:
	print("_test_force_timeout_no_op_when_window_not_open")
	var handler := ReactionWindowHandlerClass.new()
	var declined: bool = false
	handler.reaction_declined.connect(func(_id: String) -> void: declined = true)
	handler.force_timeout()
	_check(declined == false, "reaction_declined not emitted when window is not open")
	handler.free()


func _test_force_timeout_closes_window_and_emits_declined() -> void:
	print("_test_force_timeout_closes_window_and_emits_declined")
	var handler := ReactionWindowHandlerClass.new()
	var economy := ActionEconomyClass.new(30)
	economy.start_turn()
	handler.open_window(ReactionTriggerClass.TriggerType.BEING_HIT, "player", economy)
	var declined_ids: Array = []
	handler.reaction_declined.connect(func(id: String) -> void: declined_ids.append(id))
	handler.force_timeout()
	_check(handler.is_window_open() == false, "window is closed after force_timeout()")
	_check(declined_ids.size() == 1, "reaction_declined emitted once after timeout")
	_check(declined_ids[0] == "player", "reaction_declined carries correct reactor_id on timeout")
	_check(economy.is_reaction_available() == true,
		"reaction slot is NOT spent when window times out")
	handler.free()


func _test_force_timeout_emits_reaction_window_closed() -> void:
	print("_test_force_timeout_emits_reaction_window_closed")
	var handler := ReactionWindowHandlerClass.new()
	var economy := ActionEconomyClass.new(30)
	economy.start_turn()
	handler.open_window(ReactionTriggerClass.TriggerType.BEING_HIT, "player", economy)
	var closed_ids: Array = []
	handler.reaction_window_closed.connect(func(id: String) -> void: closed_ids.append(id))
	handler.force_timeout()
	_check(closed_ids.size() == 1, "reaction_window_closed emitted once after force_timeout()")
	_check(closed_ids[0] == "player",
		"reaction_window_closed carries correct reactor_id after force_timeout()")
	handler.free()


# ---------------------------------------------------------------------------
# One reaction per round enforcement
# ---------------------------------------------------------------------------
func _test_one_reaction_per_round_second_window_fails_after_reaction_spent() -> void:
	print("_test_one_reaction_per_round_second_window_fails_after_reaction_spent")
	var handler := ReactionWindowHandlerClass.new()
	var economy := ActionEconomyClass.new(30)
	economy.start_turn()

	# First window: player uses their reaction.
	handler.open_window(ReactionTriggerClass.TriggerType.BEING_HIT, "player", economy)
	handler.select_reaction("shield")
	_check(economy.is_reaction_available() == false, "reaction is spent after first use")

	# Second window attempt: reaction slot already spent this round.
	var second_result := handler.open_window(
		ReactionTriggerClass.TriggerType.BEING_HIT, "player", economy
	)
	_check(second_result == false,
		"open_window returns false when reaction already spent this round")
	_check(handler.is_window_open() == false,
		"window does not open when reaction already spent this round")
	handler.free()


# ---------------------------------------------------------------------------
# Window can reopen after closing
# ---------------------------------------------------------------------------
func _test_window_can_reopen_after_close() -> void:
	print("_test_window_can_reopen_after_close")
	var handler := ReactionWindowHandlerClass.new()
	var economy := ActionEconomyClass.new(30)
	economy.start_turn()

	# Open then decline.
	handler.open_window(ReactionTriggerClass.TriggerType.BEING_HIT, "player", economy)
	handler.decline()
	_check(handler.is_window_open() == false, "window is closed after decline()")

	# Reaction slot still available; open again (e.g., for a different trigger).
	var second_result := handler.open_window(
		ReactionTriggerClass.TriggerType.CREATURE_LEAVES_REACH, "player", economy
	)
	_check(second_result == true,
		"window can reopen for a new trigger when reaction slot is still available")
	_check(handler.is_window_open() == true, "is_window_open is true after second open_window")
	handler.free()
