## test_interaction_controller.gd
## Unit tests for InteractionController
## (src/overworld/interaction_controller.gd).
##
## Run headlessly from the Godot project root (src/) with:
##   godot --headless --script ./tests/unit/overworld/test_interaction_controller.gd
##
## Exit code 0 = all assertions passed; 1 = one or more assertions failed.
extends SceneTree

const InteractionControllerClass = preload("res://overworld/interaction_controller.gd")

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
	_test_initial_position_is_origin()
	_test_register_interactable_stores_entry()
	_test_unregister_interactable_removes_entry()
	_test_prompt_show_emitted_when_player_moves_adjacent()
	_test_prompt_show_carries_correct_handler_id()
	_test_prompt_hide_emitted_when_player_moves_away()
	_test_no_prompt_show_when_not_adjacent()
	_test_no_duplicate_prompt_show_for_same_interactable()
	_test_prompt_show_updates_when_player_moves_to_different_interactable()
	_test_interaction_triggered_when_adjacent()
	_test_interaction_triggered_carries_correct_handler_id()
	_test_no_interaction_triggered_when_not_adjacent()
	_test_unregister_suppresses_prompt_show()
	_test_unregister_active_interactable_emits_prompt_hide()
	_test_register_multiple_interactables()


# ---------------------------------------------------------------------------
# Initial state
# ---------------------------------------------------------------------------
func _test_initial_position_is_origin() -> void:
	print("_test_initial_position_is_origin")
	var ctrl := InteractionControllerClass.new()
	_check(ctrl.current_position == Vector2i(0, 0), "current_position defaults to (0, 0)")
	ctrl.free()


# ---------------------------------------------------------------------------
# register / unregister
# ---------------------------------------------------------------------------
func _test_register_interactable_stores_entry() -> void:
	print("_test_register_interactable_stores_entry")
	var ctrl := InteractionControllerClass.new()
	ctrl.register_interactable(Vector2i(2, 3), "door_01")
	# Move adjacent so the controller can find it
	var show_events: Array[String] = []
	ctrl.prompt_show.connect(func(h: String) -> void: show_events.append(h))
	ctrl.update_player_position(Vector2i(2, 2))  # north of (2, 3)
	_check(show_events.size() == 1, "prompt_show fires after registering an interactable")
	_check(show_events[0] == "door_01", "prompt_show carries the registered handler_id")
	ctrl.free()


func _test_unregister_interactable_removes_entry() -> void:
	print("_test_unregister_interactable_removes_entry")
	var ctrl := InteractionControllerClass.new()
	ctrl.register_interactable(Vector2i(5, 5), "chest_01")
	ctrl.unregister_interactable(Vector2i(5, 5))
	var show_events: Array = []
	ctrl.prompt_show.connect(func(_h: String) -> void: show_events.append(true))
	ctrl.update_player_position(Vector2i(5, 4))  # would be adjacent if still registered
	_check(show_events.size() == 0, "no prompt_show after unregistering the interactable")
	ctrl.free()


# ---------------------------------------------------------------------------
# prompt_show
# ---------------------------------------------------------------------------
func _test_prompt_show_emitted_when_player_moves_adjacent() -> void:
	print("_test_prompt_show_emitted_when_player_moves_adjacent")
	var ctrl := InteractionControllerClass.new()
	ctrl.register_interactable(Vector2i(1, 1), "npc_01")
	var show_events: Array = []
	ctrl.prompt_show.connect(func(_h: String) -> void: show_events.append(true))
	ctrl.update_player_position(Vector2i(1, 0))  # north of (1, 1)
	_check(show_events.size() == 1, "prompt_show emitted when player moves adjacent")
	ctrl.free()


func _test_prompt_show_carries_correct_handler_id() -> void:
	print("_test_prompt_show_carries_correct_handler_id")
	var ctrl := InteractionControllerClass.new()
	ctrl.register_interactable(Vector2i(4, 6), "sign_east")
	var received: Array[String] = []
	ctrl.prompt_show.connect(func(h: String) -> void: received.append(h))
	ctrl.update_player_position(Vector2i(3, 6))  # west of (4, 6)
	_check(received.size() == 1, "prompt_show emitted once")
	_check(received[0] == "sign_east", "prompt_show carries 'sign_east'")
	ctrl.free()


func _test_prompt_hide_emitted_when_player_moves_away() -> void:
	print("_test_prompt_hide_emitted_when_player_moves_away")
	var ctrl := InteractionControllerClass.new()
	ctrl.register_interactable(Vector2i(0, 0), "barrel")
	ctrl.update_player_position(Vector2i(1, 0))  # east — adjacent
	var hide_events: Array = []
	ctrl.prompt_hide.connect(func() -> void: hide_events.append(true))
	ctrl.update_player_position(Vector2i(2, 0))  # further east — no longer adjacent
	_check(hide_events.size() == 1, "prompt_hide emitted when player moves out of range")
	ctrl.free()


func _test_no_prompt_show_when_not_adjacent() -> void:
	print("_test_no_prompt_show_when_not_adjacent")
	var ctrl := InteractionControllerClass.new()
	ctrl.register_interactable(Vector2i(5, 5), "chest_02")
	var show_events: Array = []
	ctrl.prompt_show.connect(func(_h: String) -> void: show_events.append(true))
	ctrl.update_player_position(Vector2i(3, 3))  # far away
	_check(show_events.size() == 0, "no prompt_show when player is not adjacent")
	ctrl.free()


func _test_no_duplicate_prompt_show_for_same_interactable() -> void:
	print("_test_no_duplicate_prompt_show_for_same_interactable")
	var ctrl := InteractionControllerClass.new()
	ctrl.register_interactable(Vector2i(0, 1), "lever_01")
	var show_events: Array = []
	ctrl.prompt_show.connect(func(_h: String) -> void: show_events.append(true))
	ctrl.update_player_position(Vector2i(0, 0))   # north — adjacent
	ctrl.update_player_position(Vector2i(0, 0))   # same position again
	_check(show_events.size() == 1, "prompt_show not duplicated for same interactable")
	ctrl.free()


func _test_prompt_show_updates_when_player_moves_to_different_interactable() -> void:
	print("_test_prompt_show_updates_when_player_moves_to_different_interactable")
	var ctrl := InteractionControllerClass.new()
	ctrl.register_interactable(Vector2i(0, 1), "interactable_a")
	ctrl.register_interactable(Vector2i(5, 0), "interactable_b")
	var received: Array[String] = []
	ctrl.prompt_show.connect(func(h: String) -> void: received.append(h))
	ctrl.update_player_position(Vector2i(0, 0))  # adjacent to interactable_a
	ctrl.update_player_position(Vector2i(4, 0))  # adjacent to interactable_b
	_check(received.size() == 2, "prompt_show fired twice for two different interactables")
	_check(received[0] == "interactable_a", "first show was for interactable_a")
	_check(received[1] == "interactable_b", "second show was for interactable_b")
	ctrl.free()


# ---------------------------------------------------------------------------
# interaction_triggered
# ---------------------------------------------------------------------------
func _test_interaction_triggered_when_adjacent() -> void:
	print("_test_interaction_triggered_when_adjacent")
	var ctrl := InteractionControllerClass.new()
	ctrl.register_interactable(Vector2i(2, 2), "gate_01")
	ctrl.update_player_position(Vector2i(2, 1))  # adjacent north
	var triggered: Array = []
	ctrl.interaction_triggered.connect(func(_h: String) -> void: triggered.append(true))
	ctrl.request_interact()
	_check(triggered.size() == 1, "interaction_triggered emitted when adjacent")
	ctrl.free()


func _test_interaction_triggered_carries_correct_handler_id() -> void:
	print("_test_interaction_triggered_carries_correct_handler_id")
	var ctrl := InteractionControllerClass.new()
	ctrl.register_interactable(Vector2i(7, 3), "vendor_01")
	ctrl.update_player_position(Vector2i(7, 4))  # adjacent south
	var received: Array[String] = []
	ctrl.interaction_triggered.connect(func(h: String) -> void: received.append(h))
	ctrl.request_interact()
	_check(received.size() == 1, "interaction_triggered emitted once")
	_check(received[0] == "vendor_01", "interaction_triggered carries 'vendor_01'")
	ctrl.free()


func _test_no_interaction_triggered_when_not_adjacent() -> void:
	print("_test_no_interaction_triggered_when_not_adjacent")
	var ctrl := InteractionControllerClass.new()
	ctrl.register_interactable(Vector2i(10, 10), "door_far")
	ctrl.update_player_position(Vector2i(0, 0))  # far away
	var triggered: Array = []
	ctrl.interaction_triggered.connect(func(_h: String) -> void: triggered.append(true))
	ctrl.request_interact()
	_check(triggered.size() == 0, "no interaction_triggered when player is not adjacent")
	ctrl.free()


# ---------------------------------------------------------------------------
# unregister edge cases
# ---------------------------------------------------------------------------
func _test_unregister_suppresses_prompt_show() -> void:
	print("_test_unregister_suppresses_prompt_show")
	var ctrl := InteractionControllerClass.new()
	ctrl.register_interactable(Vector2i(3, 3), "crate_01")
	ctrl.unregister_interactable(Vector2i(3, 3))
	var show_events: Array = []
	ctrl.prompt_show.connect(func(_h: String) -> void: show_events.append(true))
	ctrl.update_player_position(Vector2i(3, 2))  # would be adjacent north if registered
	_check(show_events.size() == 0, "prompt_show not emitted after unregistering interactable")
	ctrl.free()


func _test_unregister_active_interactable_emits_prompt_hide() -> void:
	print("_test_unregister_active_interactable_emits_prompt_hide")
	var ctrl := InteractionControllerClass.new()
	ctrl.register_interactable(Vector2i(0, 1), "pillar_01")
	ctrl.update_player_position(Vector2i(0, 0))  # adjacent — prompt is now showing
	var hide_events: Array = []
	ctrl.prompt_hide.connect(func() -> void: hide_events.append(true))
	ctrl.unregister_interactable(Vector2i(0, 1))
	_check(hide_events.size() == 1, "prompt_hide emitted when active interactable is unregistered")
	ctrl.free()


# ---------------------------------------------------------------------------
# Multiple interactables
# ---------------------------------------------------------------------------
func _test_register_multiple_interactables() -> void:
	print("_test_register_multiple_interactables")
	var ctrl := InteractionControllerClass.new()
	ctrl.register_interactable(Vector2i(0, 1), "obj_a")
	ctrl.register_interactable(Vector2i(5, 5), "obj_b")
	var show_ids: Array[String] = []
	ctrl.prompt_show.connect(func(h: String) -> void: show_ids.append(h))

	ctrl.update_player_position(Vector2i(5, 4))  # adjacent north of obj_b
	_check(show_ids.size() == 1, "prompt_show fires for obj_b")
	_check(show_ids[0] == "obj_b", "correct handler_id for obj_b")
	ctrl.free()
