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
	_test_facing_defaults_to_south()
	_test_controls_unlocked_by_default()
	_test_update_facing_north()
	_test_update_facing_south()
	_test_update_facing_west()
	_test_update_facing_east()
	_test_request_interact_emits_interact_empty_when_nothing_found()
	_test_request_interact_emits_interacted_with_npc()
	_test_request_interact_emits_interacted_with_door()
	_test_request_interact_emits_interacted_with_chest()
	_test_request_interact_checks_tile_in_front()
	_test_request_interact_uses_current_facing()
	_test_request_interact_locked_does_not_emit()
	_test_lock_controls_prevents_interact()
	_test_unlock_controls_restores_interact()
	_test_set_interactables_duplicates_input()
	_test_interact_target_changes_with_facing()
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
func _test_facing_defaults_to_south() -> void:
	print("_test_facing_defaults_to_south")
	var ctrl := InteractionControllerClass.new()
	_check(ctrl.facing == Vector2i(0, 1), "facing defaults to south (0, 1)")
	ctrl.free()


func _test_controls_unlocked_by_default() -> void:
	print("_test_controls_unlocked_by_default")
	var ctrl := InteractionControllerClass.new()
	_check(ctrl.is_controls_locked() == false, "controls are unlocked by default")
func _test_initial_position_is_origin() -> void:
	print("_test_initial_position_is_origin")
	var ctrl := InteractionControllerClass.new()
	_check(ctrl.current_position == Vector2i(0, 0), "current_position defaults to (0, 0)")
	ctrl.free()


# ---------------------------------------------------------------------------
# update_facing — tracks player direction
# ---------------------------------------------------------------------------
func _test_update_facing_north() -> void:
	print("_test_update_facing_north")
	var ctrl := InteractionControllerClass.new()
	ctrl.update_facing(Vector2i(0, -1))
	_check(ctrl.facing == Vector2i(0, -1), "facing is north after update_facing(north)")
	ctrl.free()


func _test_update_facing_south() -> void:
	print("_test_update_facing_south")
	var ctrl := InteractionControllerClass.new()
	ctrl.update_facing(Vector2i(0, 1))
	_check(ctrl.facing == Vector2i(0, 1), "facing is south after update_facing(south)")
	ctrl.free()


func _test_update_facing_west() -> void:
	print("_test_update_facing_west")
	var ctrl := InteractionControllerClass.new()
	ctrl.update_facing(Vector2i(-1, 0))
	_check(ctrl.facing == Vector2i(-1, 0), "facing is west after update_facing(west)")
	ctrl.free()


func _test_update_facing_east() -> void:
	print("_test_update_facing_east")
	var ctrl := InteractionControllerClass.new()
	ctrl.update_facing(Vector2i(1, 0))
	_check(ctrl.facing == Vector2i(1, 0), "facing is east after update_facing(east)")
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
# request_interact — interaction resolution
# ---------------------------------------------------------------------------
func _test_request_interact_emits_interact_empty_when_nothing_found() -> void:
	print("_test_request_interact_emits_interact_empty_when_nothing_found")
	var ctrl := InteractionControllerClass.new()
	var empty_events: Array[Vector2i] = []
	ctrl.interact_empty.connect(func(t: Vector2i) -> void: empty_events.append(t))
	ctrl.request_interact(Vector2i(3, 3))
	_check(empty_events.size() == 1, "interact_empty emitted when no interactable found")
	ctrl.free()


func _test_request_interact_emits_interacted_with_npc() -> void:
	print("_test_request_interact_emits_interacted_with_npc")
	var ctrl := InteractionControllerClass.new()
	# Facing south (default); player at (3, 3); target tile = (3, 4).
	ctrl.set_interactables([{"id": "npc_elder", "position": Vector2i(3, 4)}])
	var interacted_ids: Array[String] = []
	ctrl.interacted.connect(func(_t: Vector2i, id: String) -> void: interacted_ids.append(id))
	ctrl.request_interact(Vector2i(3, 3))
	_check(interacted_ids.size() == 1, "interacted emitted for NPC")
	_check(interacted_ids[0] == "npc_elder", "interacted carries correct NPC id")
	ctrl.free()


func _test_request_interact_emits_interacted_with_door() -> void:
	print("_test_request_interact_emits_interacted_with_door")
	var ctrl := InteractionControllerClass.new()
	ctrl.update_facing(Vector2i(1, 0))  # face east
	ctrl.set_interactables([{"id": "door_north", "position": Vector2i(5, 2)}])
	var interacted_ids: Array[String] = []
	ctrl.interacted.connect(func(_t: Vector2i, id: String) -> void: interacted_ids.append(id))
	ctrl.request_interact(Vector2i(4, 2))
	_check(interacted_ids.size() == 1, "interacted emitted for door")
	_check(interacted_ids[0] == "door_north", "interacted carries correct door id")
	ctrl.free()


func _test_request_interact_emits_interacted_with_chest() -> void:
	print("_test_request_interact_emits_interacted_with_chest")
	var ctrl := InteractionControllerClass.new()
	ctrl.update_facing(Vector2i(0, -1))  # face north
	ctrl.set_interactables([{"id": "chest_1", "position": Vector2i(2, 5)}])
	var interacted_ids: Array[String] = []
	ctrl.interacted.connect(func(_t: Vector2i, id: String) -> void: interacted_ids.append(id))
	ctrl.request_interact(Vector2i(2, 6))
	_check(interacted_ids.size() == 1, "interacted emitted for chest")
	_check(interacted_ids[0] == "chest_1", "interacted carries correct chest id")
	ctrl.free()


func _test_request_interact_checks_tile_in_front() -> void:
	print("_test_request_interact_checks_tile_in_front")
	var ctrl := InteractionControllerClass.new()
	# Facing south (default); player at (0, 0) → target tile (0, 1).
	ctrl.set_interactables([{"id": "sign_post", "position": Vector2i(0, 1)}])
	var interacted_tiles: Array[Vector2i] = []
	ctrl.interacted.connect(func(t: Vector2i, _id: String) -> void: interacted_tiles.append(t))
	ctrl.request_interact(Vector2i(0, 0))
	_check(interacted_tiles.size() == 1, "interacted emitted when interactable is directly in front")
	_check(interacted_tiles[0] == Vector2i(0, 1),
		"interacted carries the correct target tile in front of player")
	ctrl.free()


func _test_request_interact_uses_current_facing() -> void:
	print("_test_request_interact_uses_current_facing")
	var ctrl := InteractionControllerClass.new()
	# NPC is north; player faces south (default) → should NOT find it.
	ctrl.set_interactables([{"id": "npc_guard", "position": Vector2i(5, 4)}])
	var interacted_events: Array = []
	var empty_events: Array = []
	ctrl.interacted.connect(func(_t: Vector2i, _id: String) -> void: interacted_events.append(true))
	ctrl.interact_empty.connect(func(_t: Vector2i) -> void: empty_events.append(true))
	ctrl.request_interact(Vector2i(5, 5))  # facing south → target = (5, 6), not (5, 4)
	_check(interacted_events.size() == 0, "interacted not emitted when NPC is behind player")
	_check(empty_events.size() == 1, "interact_empty emitted when facing away from NPC")

	# Now face north → should find the NPC.
	interacted_events.clear()
	empty_events.clear()
	ctrl.update_facing(Vector2i(0, -1))
	ctrl.request_interact(Vector2i(5, 5))  # facing north → target = (5, 4)
	_check(interacted_events.size() == 1, "interacted emitted after turning to face NPC")
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
# Controls lock / unlock
# ---------------------------------------------------------------------------
func _test_request_interact_locked_does_not_emit() -> void:
	print("_test_request_interact_locked_does_not_emit")
	var ctrl := InteractionControllerClass.new()
	ctrl.set_interactables([{"id": "npc_guard", "position": Vector2i(0, 1)}])
	ctrl.lock_controls()
	var interacted_events: Array = []
	var empty_events: Array = []
	ctrl.interacted.connect(func(_t: Vector2i, _id: String) -> void: interacted_events.append(true))
	ctrl.interact_empty.connect(func(_t: Vector2i) -> void: empty_events.append(true))
	ctrl.request_interact(Vector2i(0, 0))
	_check(interacted_events.size() == 0, "interacted not emitted when controls locked")
	_check(empty_events.size() == 0, "interact_empty not emitted when controls locked")
	ctrl.free()


func _test_lock_controls_prevents_interact() -> void:
	print("_test_lock_controls_prevents_interact")
	var ctrl := InteractionControllerClass.new()
	ctrl.lock_controls()
	_check(ctrl.is_controls_locked() == true, "is_controls_locked returns true after lock_controls()")
	ctrl.free()


func _test_unlock_controls_restores_interact() -> void:
	print("_test_unlock_controls_restores_interact")
	var ctrl := InteractionControllerClass.new()
	ctrl.lock_controls()
	ctrl.unlock_controls()
	ctrl.set_interactables([{"id": "chest_2", "position": Vector2i(0, 1)}])
	var interacted_events: Array = []
	ctrl.interacted.connect(func(_t: Vector2i, _id: String) -> void: interacted_events.append(true))
	ctrl.request_interact(Vector2i(0, 0))
	_check(interacted_events.size() == 1, "interacted emitted after unlock_controls()")
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
# set_interactables
# ---------------------------------------------------------------------------
func _test_set_interactables_duplicates_input() -> void:
	print("_test_set_interactables_duplicates_input")
	var ctrl := InteractionControllerClass.new()
	var original: Array = [{"id": "chest_3", "position": Vector2i(0, 1)}]
	ctrl.set_interactables(original)
	original.clear()
	# Modifying original after set_interactables must not affect the controller.
	var interacted_events: Array = []
	ctrl.interacted.connect(func(_t: Vector2i, _id: String) -> void: interacted_events.append(true))
	ctrl.request_interact(Vector2i(0, 0))
	_check(interacted_events.size() == 1,
		"interactables is a copy; modifying original does not affect controller")
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
# Target tile changes with facing direction
# ---------------------------------------------------------------------------
func _test_interact_target_changes_with_facing() -> void:
	print("_test_interact_target_changes_with_facing")
	var ctrl := InteractionControllerClass.new()
	var empty_tiles: Array[Vector2i] = []
	ctrl.interact_empty.connect(func(t: Vector2i) -> void: empty_tiles.append(t))

	# Face north — target should be (5, 4) when at (5, 5).
	ctrl.update_facing(Vector2i(0, -1))
	ctrl.request_interact(Vector2i(5, 5))
	_check(empty_tiles.size() == 1 and empty_tiles[0] == Vector2i(5, 4),
		"target tile is north of player when facing north")

	# Face east — target should be (6, 5).
	empty_tiles.clear()
	ctrl.update_facing(Vector2i(1, 0))
	ctrl.request_interact(Vector2i(5, 5))
	_check(empty_tiles.size() == 1 and empty_tiles[0] == Vector2i(6, 5),
		"target tile is east of player when facing east")

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
