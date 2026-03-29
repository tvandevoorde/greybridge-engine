## test_door_state.gd
## Unit tests for DoorState (src/rules_engine/core/door_state.gd).
##
## Run headlessly from the Godot project root (src/) with:
##   godot --headless --script ./tests/unit/rules_engine/test_door_state.gd
##
## Exit code 0 = all assertions passed; 1 = one or more assertions failed.
extends SceneTree

const DoorStateClass = preload("res://rules_engine/core/door_state.gd")

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
	_test_default_position_is_zero()
	_test_is_blocking_when_closed()
	_test_not_blocking_when_open()
	_test_open_sets_is_open_true()
	_test_close_sets_is_open_false()
	_test_toggle_opens_closed_door()
	_test_toggle_closes_open_door()
	_test_toggle_twice_returns_to_original()
	_test_from_dict_closed_door()
	_test_from_dict_open_door()
	_test_from_dict_position()
	_test_from_dict_defaults_closed()


# ---------------------------------------------------------------------------
# Default state
# ---------------------------------------------------------------------------
func _test_default_is_closed() -> void:
	print("_test_default_is_closed")
	var state := DoorStateClass.new()
	_check(state.is_open == false, "is_open defaults to false")


func _test_default_position_is_zero() -> void:
	print("_test_default_position_is_zero")
	var state := DoorStateClass.new()
	_check(state.position == Vector2i.ZERO, "position defaults to Vector2i.ZERO")


# ---------------------------------------------------------------------------
# is_blocking
# ---------------------------------------------------------------------------
func _test_is_blocking_when_closed() -> void:
	print("_test_is_blocking_when_closed")
	var state := DoorStateClass.new()
	state.is_open = false
	_check(state.is_blocking() == true, "is_blocking() returns true when closed")


func _test_not_blocking_when_open() -> void:
	print("_test_not_blocking_when_open")
	var state := DoorStateClass.new()
	state.is_open = true
	_check(state.is_blocking() == false, "is_blocking() returns false when open")


# ---------------------------------------------------------------------------
# open / close
# ---------------------------------------------------------------------------
func _test_open_sets_is_open_true() -> void:
	print("_test_open_sets_is_open_true")
	var state := DoorStateClass.new()
	state.is_open = false
	state.open()
	_check(state.is_open == true, "open() sets is_open to true")


func _test_close_sets_is_open_false() -> void:
	print("_test_close_sets_is_open_false")
	var state := DoorStateClass.new()
	state.is_open = true
	state.close()
	_check(state.is_open == false, "close() sets is_open to false")


# ---------------------------------------------------------------------------
# toggle
# ---------------------------------------------------------------------------
func _test_toggle_opens_closed_door() -> void:
	print("_test_toggle_opens_closed_door")
	var state := DoorStateClass.new()
	state.is_open = false
	state.toggle()
	_check(state.is_open == true, "toggle() opens a closed door")


func _test_toggle_closes_open_door() -> void:
	print("_test_toggle_closes_open_door")
	var state := DoorStateClass.new()
	state.is_open = true
	state.toggle()
	_check(state.is_open == false, "toggle() closes an open door")


func _test_toggle_twice_returns_to_original() -> void:
	print("_test_toggle_twice_returns_to_original")
	var state := DoorStateClass.new()
	state.is_open = false
	state.toggle()
	state.toggle()
	_check(state.is_open == false, "toggle() twice returns to original state")


# ---------------------------------------------------------------------------
# from_dict
# ---------------------------------------------------------------------------
func _test_from_dict_closed_door() -> void:
	print("_test_from_dict_closed_door")
	var data := {"position": {"x": 0, "y": 0}, "is_open": false}
	var state = DoorStateClass.from_dict(data)
	_check(state.is_open == false, "from_dict() constructs closed door from is_open:false")


func _test_from_dict_open_door() -> void:
	print("_test_from_dict_open_door")
	var data := {"position": {"x": 0, "y": 0}, "is_open": true}
	var state = DoorStateClass.from_dict(data)
	_check(state.is_open == true, "from_dict() constructs open door from is_open:true")


func _test_from_dict_position() -> void:
	print("_test_from_dict_position")
	var data := {"position": {"x": 3, "y": 5}, "is_open": false}
	var state = DoorStateClass.from_dict(data)
	_check(state.position == Vector2i(3, 5), "from_dict() parses position correctly")


func _test_from_dict_defaults_closed() -> void:
	print("_test_from_dict_defaults_closed")
	var data := {"position": {"x": 1, "y": 1}}
	var state = DoorStateClass.from_dict(data)
	_check(state.is_open == false, "from_dict() defaults is_open to false when key absent")
