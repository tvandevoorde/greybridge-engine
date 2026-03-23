## test_turn_lifecycle_controller.gd
## Unit tests for TurnLifecycleController (src/combat_runtime/turn_lifecycle_controller.gd).
##
## Run headlessly from the Godot project root (src/) with:
##   godot --headless --script ./tests/unit/combat_runtime/test_turn_lifecycle_controller.gd
##
## Exit code 0 = all assertions passed; 1 = one or more assertions failed.
extends SceneTree

const TurnLifecycleControllerClass = preload("res://combat_runtime/turn_lifecycle_controller.gd")
const CombatStateManagerClass = preload("res://combat_runtime/combat_state_manager.gd")
const ActionEconomyClass = preload("res://rules_engine/core/action_economy.gd")

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
	_test_initial_phase_is_idle()
	_test_begin_turn_no_op_before_setup()
	_test_begin_turn_no_op_when_combat_inactive()
	_test_begin_turn_resets_action_economy()
	_test_begin_turn_emits_turn_started()
	_test_begin_turn_emits_phase_changed_start()
	_test_begin_turn_emits_phase_changed_movement()
	_test_begin_turn_phase_is_movement_after_begin()
	_test_end_turn_no_op_when_idle()
	_test_end_turn_no_op_when_combat_inactive()
	_test_end_turn_emits_turn_ended()
	_test_end_turn_emits_phase_changed_end()
	_test_end_turn_advances_to_next_actor()
	_test_end_turn_emits_turn_advanced()
	_test_end_turn_phase_is_idle_after_end()
	_test_end_turn_emits_round_started_when_round_increments()
	_test_end_turn_no_round_started_within_same_round()
	_test_full_cycle_two_actors()
	_test_turn_started_carries_correct_round()
	_test_get_input_lock_returns_non_null()
	_test_input_lock_locked_during_start_phase()
	_test_input_lock_unlocked_during_movement_phase()
	_test_input_lock_locked_during_end_phase()
	_test_input_lock_locked_after_end_turn()
	_test_input_lock_unlocked_for_second_turn()
	_test_input_lock_external_dice_resolution()


# ---------------------------------------------------------------------------
# Initial state
# ---------------------------------------------------------------------------
func _test_initial_phase_is_idle() -> void:
	print("_test_initial_phase_is_idle")
	var tlc := TurnLifecycleControllerClass.new()
	_check(tlc.get_current_phase() == TurnLifecycleControllerClass.TurnPhase.IDLE,
		"controller starts in IDLE phase")
	tlc.free()


# ---------------------------------------------------------------------------
# begin_turn — guard conditions
# ---------------------------------------------------------------------------
func _test_begin_turn_no_op_before_setup() -> void:
	print("_test_begin_turn_no_op_before_setup")
	var tlc := TurnLifecycleControllerClass.new()
	var emitted: bool = false
	tlc.turn_started.connect(func(_id: String, _r: int) -> void: emitted = true)
	tlc.begin_turn()
	_check(emitted == false, "turn_started not emitted before setup()")
	_check(tlc.get_current_phase() == TurnLifecycleControllerClass.TurnPhase.IDLE,
		"phase remains IDLE before setup()")
	tlc.free()


func _test_begin_turn_no_op_when_combat_inactive() -> void:
	print("_test_begin_turn_no_op_when_combat_inactive")
	var tlc := TurnLifecycleControllerClass.new()
	var sm := CombatStateManagerClass.new()
	tlc.setup(sm, {})
	var emitted: bool = false
	tlc.turn_started.connect(func(_id: String, _r: int) -> void: emitted = true)
	tlc.begin_turn()
	_check(emitted == false, "turn_started not emitted when combat is inactive")
	_check(tlc.get_current_phase() == TurnLifecycleControllerClass.TurnPhase.IDLE,
		"phase remains IDLE when combat is inactive")
	tlc.free()


# ---------------------------------------------------------------------------
# begin_turn — action economy
# ---------------------------------------------------------------------------
func _test_begin_turn_resets_action_economy() -> void:
	print("_test_begin_turn_resets_action_economy")
	var tlc := TurnLifecycleControllerClass.new()
	var sm := CombatStateManagerClass.new()
	sm.start_combat([{"id": "player"}], ["player"])
	var economy := ActionEconomyClass.new(30)
	tlc.setup(sm, {"player": economy})
	tlc.begin_turn()
	_check(economy.is_action_available() == true,
		"action is available after begin_turn() resets economy")
	_check(economy.is_bonus_action_available() == true,
		"bonus action is available after begin_turn() resets economy")
	_check(economy.movement_remaining_ft == 30,
		"movement is restored to full speed after begin_turn()")
	tlc.free()


# ---------------------------------------------------------------------------
# begin_turn — signals
# ---------------------------------------------------------------------------
func _test_begin_turn_emits_turn_started() -> void:
	print("_test_begin_turn_emits_turn_started")
	var tlc := TurnLifecycleControllerClass.new()
	var sm := CombatStateManagerClass.new()
	sm.start_combat([{"id": "player"}], ["player"])
	tlc.setup(sm, {})
	var received_ids: Array = []
	var received_rounds: Array = []
	tlc.turn_started.connect(func(id: String, r: int) -> void:
		received_ids.append(id)
		received_rounds.append(r)
	)
	tlc.begin_turn()
	_check(received_ids.size() == 1, "turn_started emitted once")
	_check(received_ids[0] == "player", "turn_started carries correct combatant_id")
	_check(received_rounds[0] == 1, "turn_started carries correct round number")
	tlc.free()


func _test_begin_turn_emits_phase_changed_start() -> void:
	print("_test_begin_turn_emits_phase_changed_start")
	var tlc := TurnLifecycleControllerClass.new()
	var sm := CombatStateManagerClass.new()
	sm.start_combat([{"id": "player"}], ["player"])
	tlc.setup(sm, {})
	var phases_seen: Array = []
	tlc.phase_changed.connect(func(p: TurnLifecycleControllerClass.TurnPhase, _id: String) -> void:
		phases_seen.append(p)
	)
	tlc.begin_turn()
	_check(phases_seen.has(TurnLifecycleControllerClass.TurnPhase.START),
		"phase_changed emitted for START during begin_turn()")
	tlc.free()


func _test_begin_turn_emits_phase_changed_movement() -> void:
	print("_test_begin_turn_emits_phase_changed_movement")
	var tlc := TurnLifecycleControllerClass.new()
	var sm := CombatStateManagerClass.new()
	sm.start_combat([{"id": "player"}], ["player"])
	tlc.setup(sm, {})
	var phases_seen: Array = []
	tlc.phase_changed.connect(func(p: TurnLifecycleControllerClass.TurnPhase, _id: String) -> void:
		phases_seen.append(p)
	)
	tlc.begin_turn()
	_check(phases_seen.has(TurnLifecycleControllerClass.TurnPhase.MOVEMENT),
		"phase_changed emitted for MOVEMENT during begin_turn()")
	tlc.free()


func _test_begin_turn_phase_is_movement_after_begin() -> void:
	print("_test_begin_turn_phase_is_movement_after_begin")
	var tlc := TurnLifecycleControllerClass.new()
	var sm := CombatStateManagerClass.new()
	sm.start_combat([{"id": "player"}], ["player"])
	tlc.setup(sm, {})
	tlc.begin_turn()
	_check(tlc.get_current_phase() == TurnLifecycleControllerClass.TurnPhase.MOVEMENT,
		"current phase is MOVEMENT immediately after begin_turn()")
	tlc.free()


# ---------------------------------------------------------------------------
# end_turn — guard conditions
# ---------------------------------------------------------------------------
func _test_end_turn_no_op_when_idle() -> void:
	print("_test_end_turn_no_op_when_idle")
	var tlc := TurnLifecycleControllerClass.new()
	var sm := CombatStateManagerClass.new()
	sm.start_combat([{"id": "player"}, {"id": "orc"}], ["player", "orc"])
	tlc.setup(sm, {})
	var emitted: bool = false
	tlc.turn_ended.connect(func(_id: String) -> void: emitted = true)
	tlc.end_turn()  # called without begin_turn() first — should be a no-op
	_check(emitted == false, "turn_ended not emitted when controller is IDLE")
	_check(sm.get_current_turn_index() == 0, "state manager not advanced when controller is IDLE")
	tlc.free()


func _test_end_turn_no_op_when_combat_inactive() -> void:
	print("_test_end_turn_no_op_when_combat_inactive")
	var tlc := TurnLifecycleControllerClass.new()
	var sm := CombatStateManagerClass.new()
	tlc.setup(sm, {})
	# Force the controller into a non-IDLE phase by directly calling begin_turn
	# on an active combat, then end combat before calling end_turn.
	sm.start_combat([{"id": "player"}], ["player"])
	tlc.begin_turn()
	sm.end_combat()
	var emitted: bool = false
	tlc.turn_ended.connect(func(_id: String) -> void: emitted = true)
	tlc.end_turn()
	_check(emitted == false, "turn_ended not emitted when combat is inactive")
	tlc.free()


# ---------------------------------------------------------------------------
# end_turn — signals
# ---------------------------------------------------------------------------
func _test_end_turn_emits_turn_ended() -> void:
	print("_test_end_turn_emits_turn_ended")
	var tlc := TurnLifecycleControllerClass.new()
	var sm := CombatStateManagerClass.new()
	sm.start_combat([{"id": "player"}, {"id": "orc"}], ["player", "orc"])
	tlc.setup(sm, {})
	tlc.begin_turn()
	var received_ids: Array = []
	tlc.turn_ended.connect(func(id: String) -> void: received_ids.append(id))
	tlc.end_turn()
	_check(received_ids.size() == 1, "turn_ended emitted once")
	_check(received_ids[0] == "player", "turn_ended carries the ending combatant_id")
	tlc.free()


func _test_end_turn_emits_phase_changed_end() -> void:
	print("_test_end_turn_emits_phase_changed_end")
	var tlc := TurnLifecycleControllerClass.new()
	var sm := CombatStateManagerClass.new()
	sm.start_combat([{"id": "player"}, {"id": "orc"}], ["player", "orc"])
	tlc.setup(sm, {})
	tlc.begin_turn()
	var phases_seen: Array = []
	tlc.phase_changed.connect(func(p: TurnLifecycleControllerClass.TurnPhase, _id: String) -> void:
		phases_seen.append(p)
	)
	tlc.end_turn()
	_check(phases_seen.has(TurnLifecycleControllerClass.TurnPhase.END),
		"phase_changed emitted for END during end_turn()")
	tlc.free()


# ---------------------------------------------------------------------------
# end_turn — state manager advancement
# ---------------------------------------------------------------------------
func _test_end_turn_advances_to_next_actor() -> void:
	print("_test_end_turn_advances_to_next_actor")
	var tlc := TurnLifecycleControllerClass.new()
	var sm := CombatStateManagerClass.new()
	sm.start_combat([{"id": "player"}, {"id": "orc"}], ["player", "orc"])
	tlc.setup(sm, {})
	tlc.begin_turn()
	tlc.end_turn()
	_check(sm.get_current_combatant_id() == "orc",
		"state manager advances to next actor after end_turn()")
	_check(sm.get_current_turn_index() == 1, "turn index is 1 after first end_turn()")
	tlc.free()


func _test_end_turn_emits_turn_advanced() -> void:
	print("_test_end_turn_emits_turn_advanced")
	var tlc := TurnLifecycleControllerClass.new()
	var sm := CombatStateManagerClass.new()
	sm.start_combat([{"id": "player"}, {"id": "orc"}], ["player", "orc"])
	tlc.setup(sm, {})
	tlc.begin_turn()
	var advanced_ids: Array = []
	var advanced_rounds: Array = []
	tlc.turn_advanced.connect(func(id: String, r: int) -> void:
		advanced_ids.append(id)
		advanced_rounds.append(r)
	)
	tlc.end_turn()
	_check(advanced_ids.size() == 1, "turn_advanced emitted once")
	_check(advanced_ids[0] == "orc", "turn_advanced carries the new combatant_id")
	_check(advanced_rounds[0] == 1, "turn_advanced carries the correct round (still 1)")
	tlc.free()


# ---------------------------------------------------------------------------
# end_turn — phase reset
# ---------------------------------------------------------------------------
func _test_end_turn_phase_is_idle_after_end() -> void:
	print("_test_end_turn_phase_is_idle_after_end")
	var tlc := TurnLifecycleControllerClass.new()
	var sm := CombatStateManagerClass.new()
	sm.start_combat([{"id": "player"}, {"id": "orc"}], ["player", "orc"])
	tlc.setup(sm, {})
	tlc.begin_turn()
	tlc.end_turn()
	_check(tlc.get_current_phase() == TurnLifecycleControllerClass.TurnPhase.IDLE,
		"phase resets to IDLE after end_turn()")
	tlc.free()


# ---------------------------------------------------------------------------
# round_started signal
# ---------------------------------------------------------------------------
func _test_end_turn_emits_round_started_when_round_increments() -> void:
	print("_test_end_turn_emits_round_started_when_round_increments")
	var tlc := TurnLifecycleControllerClass.new()
	var sm := CombatStateManagerClass.new()
	sm.start_combat([{"id": "player"}, {"id": "orc"}], ["player", "orc"])
	tlc.setup(sm, {})
	var round_events: Array = []
	tlc.round_started.connect(func(r: int) -> void: round_events.append(r))

	# Player's turn.
	tlc.begin_turn()
	tlc.end_turn()
	_check(round_events.size() == 0, "round_started not emitted after first actor's turn")

	# Orc's turn — completing this cycle wraps back to index 0 and increments round.
	tlc.begin_turn()
	tlc.end_turn()
	_check(round_events.size() == 1, "round_started emitted once after full initiative cycle")
	_check(round_events[0] == 2, "round_started carries round number 2")
	tlc.free()


func _test_end_turn_no_round_started_within_same_round() -> void:
	print("_test_end_turn_no_round_started_within_same_round")
	var tlc := TurnLifecycleControllerClass.new()
	var sm := CombatStateManagerClass.new()
	sm.start_combat(
		[{"id": "player"}, {"id": "orc"}, {"id": "goblin"}],
		["player", "orc", "goblin"]
	)
	tlc.setup(sm, {})
	var round_events: Array = []
	tlc.round_started.connect(func(r: int) -> void: round_events.append(r))

	# First two turns within round 1.
	tlc.begin_turn()
	tlc.end_turn()
	tlc.begin_turn()
	tlc.end_turn()
	_check(round_events.size() == 0, "round_started not emitted within the same round")
	tlc.free()


# ---------------------------------------------------------------------------
# Full turn cycle
# ---------------------------------------------------------------------------
func _test_full_cycle_two_actors() -> void:
	print("_test_full_cycle_two_actors")
	var tlc := TurnLifecycleControllerClass.new()
	var sm := CombatStateManagerClass.new()
	sm.start_combat([{"id": "player"}, {"id": "orc"}], ["player", "orc"])
	var economy_player := ActionEconomyClass.new(30)
	var economy_orc := ActionEconomyClass.new(25)
	tlc.setup(sm, {"player": economy_player, "orc": economy_orc})

	# --- Player's turn ---
	tlc.begin_turn()
	_check(sm.get_current_combatant_id() == "player", "player is active at start of their turn")
	_check(economy_player.is_action_available() == true, "player action available after begin_turn")
	_check(economy_player.movement_remaining_ft == 30, "player movement restored at begin_turn")
	tlc.end_turn()

	# --- Orc's turn ---
	_check(sm.get_current_combatant_id() == "orc", "orc is active after player's turn ends")
	_check(sm.get_round() == 1, "still round 1 after one end_turn")
	tlc.begin_turn()
	_check(economy_orc.is_action_available() == true, "orc action available after begin_turn")
	_check(economy_orc.movement_remaining_ft == 25, "orc movement restored at begin_turn")
	tlc.end_turn()

	# --- New round ---
	_check(sm.get_round() == 2, "round increments to 2 after full initiative cycle")
	_check(sm.get_current_combatant_id() == "player", "player is first again in round 2")
	_check(tlc.get_current_phase() == TurnLifecycleControllerClass.TurnPhase.IDLE,
		"controller is IDLE at the start of round 2")
	tlc.free()


# ---------------------------------------------------------------------------
# turn_started round number
# ---------------------------------------------------------------------------
func _test_turn_started_carries_correct_round() -> void:
	print("_test_turn_started_carries_correct_round")
	var tlc := TurnLifecycleControllerClass.new()
	var sm := CombatStateManagerClass.new()
	sm.start_combat([{"id": "player"}, {"id": "orc"}], ["player", "orc"])
	tlc.setup(sm, {})
	var turn_start_rounds: Array = []
	tlc.turn_started.connect(func(_id: String, r: int) -> void: turn_start_rounds.append(r))

	tlc.begin_turn()  # round 1, player
	tlc.end_turn()
	tlc.begin_turn()  # round 1, orc
	tlc.end_turn()
	tlc.begin_turn()  # round 2, player
	tlc.end_turn()

	_check(turn_start_rounds.size() == 3, "turn_started emitted three times")
	_check(turn_start_rounds[0] == 1, "first turn_started is in round 1")
	_check(turn_start_rounds[1] == 1, "second turn_started is in round 1")
	_check(turn_start_rounds[2] == 2, "third turn_started is in round 2")
	tlc.free()



# ---------------------------------------------------------------------------
# Input lock — get_input_lock
# ---------------------------------------------------------------------------
func _test_get_input_lock_returns_non_null() -> void:
	print("_test_get_input_lock_returns_non_null")
	var tlc := TurnLifecycleControllerClass.new()
	_check(tlc.get_input_lock() != null, "get_input_lock() returns a non-null lock")
	tlc.free()


# ---------------------------------------------------------------------------
# Input lock — locked during START phase
# ---------------------------------------------------------------------------
func _test_input_lock_locked_during_start_phase() -> void:
	print("_test_input_lock_locked_during_start_phase")
	var tlc := TurnLifecycleControllerClass.new()
	var sm := CombatStateManagerClass.new()
	sm.start_combat([{"id": "player"}], ["player"])
	tlc.setup(sm, {})
	var lock_state_at_start: bool = false
	tlc.phase_changed.connect(func(p: TurnLifecycleControllerClass.TurnPhase, _id: String) -> void:
		if p == TurnLifecycleControllerClass.TurnPhase.START:
			lock_state_at_start = tlc.get_input_lock().is_locked()
	)
	tlc.begin_turn()
	_check(lock_state_at_start == true, "input lock is locked when START phase is entered")
	tlc.free()


# ---------------------------------------------------------------------------
# Input lock — unlocked when MOVEMENT phase begins
# ---------------------------------------------------------------------------
func _test_input_lock_unlocked_during_movement_phase() -> void:
	print("_test_input_lock_unlocked_during_movement_phase")
	var tlc := TurnLifecycleControllerClass.new()
	var sm := CombatStateManagerClass.new()
	sm.start_combat([{"id": "player"}], ["player"])
	tlc.setup(sm, {})
	tlc.begin_turn()
	_check(tlc.get_input_lock().is_locked() == false,
		"input lock is unlocked after begin_turn() enters MOVEMENT phase")
	tlc.free()


# ---------------------------------------------------------------------------
# Input lock — locked during END phase
# ---------------------------------------------------------------------------
func _test_input_lock_locked_during_end_phase() -> void:
	print("_test_input_lock_locked_during_end_phase")
	var tlc := TurnLifecycleControllerClass.new()
	var sm := CombatStateManagerClass.new()
	sm.start_combat([{"id": "player"}, {"id": "orc"}], ["player", "orc"])
	tlc.setup(sm, {})
	tlc.begin_turn()
	var lock_state_at_end: bool = false
	tlc.phase_changed.connect(func(p: TurnLifecycleControllerClass.TurnPhase, _id: String) -> void:
		if p == TurnLifecycleControllerClass.TurnPhase.END:
			lock_state_at_end = tlc.get_input_lock().is_locked()
	)
	tlc.end_turn()
	_check(lock_state_at_end == true, "input lock is locked when END phase is entered")
	tlc.free()


# ---------------------------------------------------------------------------
# Input lock — remains locked after end_turn (IDLE, between turns)
# ---------------------------------------------------------------------------
func _test_input_lock_locked_after_end_turn() -> void:
	print("_test_input_lock_locked_after_end_turn")
	var tlc := TurnLifecycleControllerClass.new()
	var sm := CombatStateManagerClass.new()
	sm.start_combat([{"id": "player"}, {"id": "orc"}], ["player", "orc"])
	tlc.setup(sm, {})
	tlc.begin_turn()
	tlc.end_turn()
	_check(tlc.get_input_lock().is_locked() == true,
		"input lock remains locked in IDLE state between turns")
	tlc.free()


# ---------------------------------------------------------------------------
# Input lock — unlocked again when the second actor's turn begins
# ---------------------------------------------------------------------------
func _test_input_lock_unlocked_for_second_turn() -> void:
	print("_test_input_lock_unlocked_for_second_turn")
	var tlc := TurnLifecycleControllerClass.new()
	var sm := CombatStateManagerClass.new()
	sm.start_combat([{"id": "player"}, {"id": "orc"}], ["player", "orc"])
	tlc.setup(sm, {})
	tlc.begin_turn()
	tlc.end_turn()
	tlc.begin_turn()  # orc's turn
	_check(tlc.get_input_lock().is_locked() == false,
		"input lock is unlocked when second actor's MOVEMENT phase begins")
	tlc.free()


# ---------------------------------------------------------------------------
# Input lock — external dice resolution locking via get_input_lock()
# ---------------------------------------------------------------------------
func _test_input_lock_external_dice_resolution() -> void:
	print("_test_input_lock_external_dice_resolution")
	var tlc := TurnLifecycleControllerClass.new()
	var sm := CombatStateManagerClass.new()
	sm.start_combat([{"id": "player"}, {"id": "orc"}], ["player", "orc"])
	tlc.setup(sm, {})
	tlc.begin_turn()  # input unlocked (MOVEMENT phase)
	_check(tlc.get_input_lock().is_locked() == false, "input unlocked before dice resolution")
	# Simulate dice resolution lock/unlock from the combat runtime.
	tlc.get_input_lock().lock("dice_resolution")
	_check(tlc.get_input_lock().is_locked() == true, "input locked during dice resolution")
	tlc.get_input_lock().unlock()
	_check(tlc.get_input_lock().is_locked() == false, "input unlocked after dice resolution")
	tlc.free()
