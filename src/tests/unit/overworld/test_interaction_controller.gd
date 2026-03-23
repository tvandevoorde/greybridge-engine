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

	ctrl.free()
