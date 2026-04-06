## test_door_interactable.gd
## Unit tests for DoorInteractable (src/overworld/door_interactable.gd).
##
## Run headlessly from the Godot project root (src/) with:
##   godot --headless --script ./tests/unit/overworld/test_door_interactable.gd
##
## Exit code 0 = all assertions passed; 1 = one or more assertions failed.
extends SceneTree

const DoorInteractableClass = preload("res://overworld/door_interactable.gd")

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
	_test_default_is_closed()
	_test_default_is_blocking()
	_test_default_tile_position_is_zero()
	_test_interact_opens_closed_door()
	_test_interact_emits_door_state_changed()
	_test_interact_signal_carries_is_open_true()
	_test_interact_signal_carries_position()
	_test_interact_twice_closes_door()
	_test_is_open_returns_true_when_open()
	_test_is_not_blocking_when_open()
	_test_set_tile_position()
	_test_from_dict_closed()
	_test_from_dict_open()
	_test_from_dict_position()
	_test_interact_blocked_when_required_flags_not_met()
	_test_interact_allowed_when_required_flags_met()
	_test_interaction_blocked_signal_emitted_when_flags_not_met()
	_test_set_quest_flags_updates_immediately()
	_test_from_dict_parses_required_flags()
	_test_from_dict_required_flags_defaults_empty()
	_test_set_required_flags_stores_copy()


# ---------------------------------------------------------------------------
# Default state
# ---------------------------------------------------------------------------
func _test_default_is_closed() -> void:
	print("_test_default_is_closed")
	var door := DoorInteractableClass.new()
	_check(door.is_open() == false, "door is closed by default")
	door.free()


func _test_default_is_blocking() -> void:
	print("_test_default_is_blocking")
	var door := DoorInteractableClass.new()
	_check(door.is_blocking() == true, "closed door is blocking")
	door.free()


func _test_default_tile_position_is_zero() -> void:
	print("_test_default_tile_position_is_zero")
	var door := DoorInteractableClass.new()
	_check(door.get_tile_position() == Vector2i.ZERO, "tile position defaults to Vector2i.ZERO")
	door.free()


# ---------------------------------------------------------------------------
# interact
# ---------------------------------------------------------------------------
func _test_interact_opens_closed_door() -> void:
	print("_test_interact_opens_closed_door")
	var door := DoorInteractableClass.new()
	door.interact()
	_check(door.is_open() == true, "interact() opens a closed door")
	door.free()


func _test_interact_emits_door_state_changed() -> void:
	print("_test_interact_emits_door_state_changed")
	var door := DoorInteractableClass.new()
	var signal_events: Array = []
	door.door_state_changed.connect(func(_pos, _open): signal_events.append(true))
	door.interact()
	_check(signal_events.size() == 1, "interact() emits door_state_changed")
	door.free()


func _test_interact_signal_carries_is_open_true() -> void:
	print("_test_interact_signal_carries_is_open_true")
	var door := DoorInteractableClass.new()
	var received_open_values: Array = []
	door.door_state_changed.connect(func(_pos, open): received_open_values.append(open))
	door.interact()
	_check(received_open_values.size() == 1 and received_open_values[0] == true,
		"signal carries is_open = true after opening")
	door.free()


func _test_interact_signal_carries_position() -> void:
	print("_test_interact_signal_carries_position")
	var door := DoorInteractableClass.new()
	door.set_tile_position(Vector2i(4, 2))
	var received_positions: Array = []
	door.door_state_changed.connect(func(pos, _open): received_positions.append(pos))
	door.interact()
	_check(received_positions.size() == 1 and received_positions[0] == Vector2i(4, 2),
		"signal carries correct tile position")
	door.free()


func _test_interact_twice_closes_door() -> void:
	print("_test_interact_twice_closes_door")
	var door := DoorInteractableClass.new()
	door.interact()
	door.interact()
	_check(door.is_open() == false, "interact() twice closes the door again")
	door.free()


# ---------------------------------------------------------------------------
# is_open / is_blocking
# ---------------------------------------------------------------------------
func _test_is_open_returns_true_when_open() -> void:
	print("_test_is_open_returns_true_when_open")
	var door := DoorInteractableClass.new()
	door.interact()
	_check(door.is_open() == true, "is_open() returns true when door is open")
	door.free()


func _test_is_not_blocking_when_open() -> void:
	print("_test_is_not_blocking_when_open")
	var door := DoorInteractableClass.new()
	door.interact()
	_check(door.is_blocking() == false, "is_blocking() returns false when door is open")
	door.free()


# ---------------------------------------------------------------------------
# set_tile_position
# ---------------------------------------------------------------------------
func _test_set_tile_position() -> void:
	print("_test_set_tile_position")
	var door := DoorInteractableClass.new()
	door.set_tile_position(Vector2i(3, 7))
	_check(door.get_tile_position() == Vector2i(3, 7), "set_tile_position() updates tile position")
	door.free()


# ---------------------------------------------------------------------------
# from_dict
# ---------------------------------------------------------------------------
func _test_from_dict_closed() -> void:
	print("_test_from_dict_closed")
	var data := {"position": {"x": 1, "y": 2}, "is_open": false}
	var door = DoorInteractableClass.from_dict(data)
	_check(door.is_open() == false, "from_dict() creates a closed door")
	door.free()


func _test_from_dict_open() -> void:
	print("_test_from_dict_open")
	var data := {"position": {"x": 1, "y": 2}, "is_open": true}
	var door = DoorInteractableClass.from_dict(data)
	_check(door.is_open() == true, "from_dict() creates an open door")
	door.free()


func _test_from_dict_position() -> void:
	print("_test_from_dict_position")
	var data := {"position": {"x": 5, "y": 3}, "is_open": false}
	var door = DoorInteractableClass.from_dict(data)
	_check(door.get_tile_position() == Vector2i(5, 3), "from_dict() parses position correctly")
	door.free()


# ---------------------------------------------------------------------------
# required_flags gating
# ---------------------------------------------------------------------------
func _test_interact_blocked_when_required_flags_not_met() -> void:
	print("_test_interact_blocked_when_required_flags_not_met")
	var door := DoorInteractableClass.new()
	door.set_required_flags({"door_key_found": true})
	door.interact()
	_check(door.is_open() == false, "door stays closed when required_flags not met")
	door.free()


func _test_interact_allowed_when_required_flags_met() -> void:
	print("_test_interact_allowed_when_required_flags_met")
	var door := DoorInteractableClass.new()
	door.set_required_flags({"door_key_found": true})
	door.set_quest_flags({"door_key_found": true})
	door.interact()
	_check(door.is_open() == true, "door opens when required_flags are satisfied")
	door.free()


func _test_interaction_blocked_signal_emitted_when_flags_not_met() -> void:
	print("_test_interaction_blocked_signal_emitted_when_flags_not_met")
	var door := DoorInteractableClass.new()
	door.set_required_flags({"bridge_repaired": true})
	var blocked_reasons: Array[String] = []
	door.interaction_blocked.connect(func(reason: String) -> void:
		blocked_reasons.append(reason)
	)
	door.interact()
	_check(blocked_reasons.size() == 1,
		"interaction_blocked emitted when required_flags not met")
	_check(blocked_reasons[0] == "missing_flag",
		"reason is missing_flag")
	door.free()


func _test_set_quest_flags_updates_immediately() -> void:
	print("_test_set_quest_flags_updates_immediately")
	var door := DoorInteractableClass.new()
	door.set_required_flags({"pass_granted": true})
	# First attempt blocked.
	door.interact()
	_check(door.is_open() == false, "door blocked before set_quest_flags")
	# Set the flag — immediately enables interaction.
	door.set_quest_flags({"pass_granted": true})
	door.interact()
	_check(door.is_open() == true, "door opens after set_quest_flags sets required flag")
	door.free()


func _test_from_dict_parses_required_flags() -> void:
	print("_test_from_dict_parses_required_flags")
	var data := {
		"position": {"x": 2, "y": 4},
		"is_open": false,
		"required_flags": {"quest_done": true}
	}
	var door = DoorInteractableClass.from_dict(data)
	_check(door.required_flags.has("quest_done"),
		"from_dict() parses required_flags key")
	_check(door.required_flags["quest_done"] == true,
		"from_dict() required_flags value is true")
	door.free()


func _test_from_dict_required_flags_defaults_empty() -> void:
	print("_test_from_dict_required_flags_defaults_empty")
	var data := {"position": {"x": 1, "y": 1}, "is_open": false}
	var door = DoorInteractableClass.from_dict(data)
	_check(door.required_flags.is_empty(),
		"from_dict() required_flags defaults to empty when omitted")
	door.free()


func _test_set_required_flags_stores_copy() -> void:
	print("_test_set_required_flags_stores_copy")
	var door := DoorInteractableClass.new()
	var original_req := {"key_held": true}
	door.set_required_flags(original_req)
	original_req.clear()
	# The stored copy should still block (key_held not in quest flags).
	var blocked_events: Array = []
	door.interaction_blocked.connect(func(_r: String) -> void:
		blocked_events.append(true)
	)
	door.interact()
	_check(blocked_events.size() == 1,
		"set_required_flags stores a copy; clearing original does not clear door flags")
	door.free()
