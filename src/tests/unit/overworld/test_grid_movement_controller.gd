## test_grid_movement_controller.gd
## Unit tests for GridMovementController
## (src/overworld/grid_movement_controller.gd).
##
## Run headlessly from the Godot project root (src/) with:
##   godot --headless --script ./tests/unit/overworld/test_grid_movement_controller.gd
##
## Exit code 0 = all assertions passed; 1 = one or more assertions failed.
extends SceneTree

const GridMovementControllerClass = preload("res://overworld/grid_movement_controller.gd")

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
	_test_controls_unlocked_by_default()
	_test_request_step_moves_position()
	_test_request_step_emits_stepped_signal()
	_test_request_step_stepped_from_and_to()
	_test_request_step_blocked_tile_does_not_move()
	_test_request_step_blocked_emits_move_blocked()
	_test_request_step_invalid_direction_emits_move_blocked()
	_test_request_step_does_not_emit_stepped_when_blocked()
	_test_lock_controls_prevents_movement()
	_test_lock_controls_no_signal_emitted()
	_test_unlock_controls_restores_movement()
	_test_set_position_updates_position()
	_test_set_position_does_not_emit_stepped()
	_test_set_blocked_tiles_affects_movement()
	_test_set_blocked_tiles_duplicates_input()
	_test_multiple_steps_accumulate()
	_test_lock_clears_hold_state()
	_test_request_step_emits_footstep_requested_on_success()
	_test_request_step_footstep_position_is_new_position()
	_test_request_step_no_footstep_when_blocked()
	_test_request_step_no_footstep_when_locked()


# ---------------------------------------------------------------------------
# Initial state
# ---------------------------------------------------------------------------
func _test_initial_position_is_origin() -> void:
	print("_test_initial_position_is_origin")
	var ctrl := GridMovementControllerClass.new()
	_check(ctrl.current_position == Vector2i(0, 0), "current_position defaults to (0, 0)")
	ctrl.free()


func _test_controls_unlocked_by_default() -> void:
	print("_test_controls_unlocked_by_default")
	var ctrl := GridMovementControllerClass.new()
	_check(ctrl.is_controls_locked() == false, "controls are unlocked by default")
	ctrl.free()


# ---------------------------------------------------------------------------
# request_step — successful movement
# ---------------------------------------------------------------------------
func _test_request_step_moves_position() -> void:
	print("_test_request_step_moves_position")
	var ctrl := GridMovementControllerClass.new()
	ctrl.request_step(Vector2i(1, 0))
	_check(ctrl.current_position == Vector2i(1, 0), "position updated after east step")
	ctrl.free()


func _test_request_step_emits_stepped_signal() -> void:
	print("_test_request_step_emits_stepped_signal")
	var ctrl := GridMovementControllerClass.new()
	var events: Array = []
	ctrl.stepped.connect(func(_f: Vector2i, _t: Vector2i) -> void: events.append(true))
	ctrl.request_step(Vector2i(0, 1))
	_check(events.size() == 1, "stepped signal emitted once on successful step")
	ctrl.free()


func _test_request_step_stepped_from_and_to() -> void:
	print("_test_request_step_stepped_from_and_to")
	var ctrl := GridMovementControllerClass.new()
	ctrl.set_position(Vector2i(3, 4))
	var from_values: Array[Vector2i] = []
	var to_values: Array[Vector2i] = []
	ctrl.stepped.connect(func(f: Vector2i, t: Vector2i) -> void:
		from_values.append(f)
		to_values.append(t)
	)
	ctrl.request_step(Vector2i(0, -1))
	_check(from_values.size() == 1 and from_values[0] == Vector2i(3, 4),
		"stepped signal carries correct from position")
	_check(to_values.size() == 1 and to_values[0] == Vector2i(3, 3),
		"stepped signal carries correct to position")
	ctrl.free()


# ---------------------------------------------------------------------------
# request_step — blocked movement
# ---------------------------------------------------------------------------
func _test_request_step_blocked_tile_does_not_move() -> void:
	print("_test_request_step_blocked_tile_does_not_move")
	var ctrl := GridMovementControllerClass.new()
	ctrl.set_blocked_tiles([Vector2i(1, 0)])
	ctrl.request_step(Vector2i(1, 0))
	_check(ctrl.current_position == Vector2i(0, 0),
		"position unchanged when destination is blocked")
	ctrl.free()


func _test_request_step_blocked_emits_move_blocked() -> void:
	print("_test_request_step_blocked_emits_move_blocked")
	var ctrl := GridMovementControllerClass.new()
	ctrl.set_blocked_tiles([Vector2i(0, 1)])
	var blocked_events: Array = []
	ctrl.move_blocked.connect(func(_p: Vector2i, _d: Vector2i, _r: String) -> void:
		blocked_events.append(true)
	)
	ctrl.request_step(Vector2i(0, 1))
	_check(blocked_events.size() == 1, "move_blocked emitted when destination is blocked")
	ctrl.free()


func _test_request_step_invalid_direction_emits_move_blocked() -> void:
	print("_test_request_step_invalid_direction_emits_move_blocked")
	var ctrl := GridMovementControllerClass.new()
	var reasons: Array[String] = []
	ctrl.move_blocked.connect(func(_p: Vector2i, _d: Vector2i, r: String) -> void:
		reasons.append(r)
	)
	ctrl.request_step(Vector2i(1, 1))
	_check(reasons.size() == 1, "move_blocked emitted for invalid direction")
	_check(reasons[0] == "invalid_direction", "reason is invalid_direction")
	ctrl.free()


func _test_request_step_does_not_emit_stepped_when_blocked() -> void:
	print("_test_request_step_does_not_emit_stepped_when_blocked")
	var ctrl := GridMovementControllerClass.new()
	ctrl.set_blocked_tiles([Vector2i(0, -1)])
	var stepped_events: Array = []
	ctrl.stepped.connect(func(_f: Vector2i, _t: Vector2i) -> void: stepped_events.append(true))
	ctrl.request_step(Vector2i(0, -1))
	_check(stepped_events.size() == 0, "stepped not emitted when move is blocked")
	ctrl.free()


# ---------------------------------------------------------------------------
# Controls lock / unlock
# ---------------------------------------------------------------------------
func _test_lock_controls_prevents_movement() -> void:
	print("_test_lock_controls_prevents_movement")
	var ctrl := GridMovementControllerClass.new()
	ctrl.lock_controls()
	ctrl.request_step(Vector2i(1, 0))
	_check(ctrl.current_position == Vector2i(0, 0),
		"position unchanged when controls are locked")
	ctrl.free()


func _test_lock_controls_no_signal_emitted() -> void:
	print("_test_lock_controls_no_signal_emitted")
	var ctrl := GridMovementControllerClass.new()
	ctrl.lock_controls()
	var stepped_events: Array = []
	var blocked_events: Array = []
	ctrl.stepped.connect(func(_f: Vector2i, _t: Vector2i) -> void: stepped_events.append(true))
	ctrl.move_blocked.connect(func(_p: Vector2i, _d: Vector2i, _r: String) -> void:
		blocked_events.append(true)
	)
	ctrl.request_step(Vector2i(1, 0))
	_check(stepped_events.size() == 0, "stepped not emitted when controls locked")
	_check(blocked_events.size() == 0, "move_blocked not emitted when controls locked")
	ctrl.free()


func _test_unlock_controls_restores_movement() -> void:
	print("_test_unlock_controls_restores_movement")
	var ctrl := GridMovementControllerClass.new()
	ctrl.lock_controls()
	ctrl.unlock_controls()
	ctrl.request_step(Vector2i(0, 1))
	_check(ctrl.current_position == Vector2i(0, 1),
		"position updated after unlock_controls()")
	ctrl.free()


# ---------------------------------------------------------------------------
# set_position
# ---------------------------------------------------------------------------
func _test_set_position_updates_position() -> void:
	print("_test_set_position_updates_position")
	var ctrl := GridMovementControllerClass.new()
	ctrl.set_position(Vector2i(7, 3))
	_check(ctrl.current_position == Vector2i(7, 3),
		"current_position updated by set_position()")
	ctrl.free()


func _test_set_position_does_not_emit_stepped() -> void:
	print("_test_set_position_does_not_emit_stepped")
	var ctrl := GridMovementControllerClass.new()
	var events: Array = []
	ctrl.stepped.connect(func(_f: Vector2i, _t: Vector2i) -> void: events.append(true))
	ctrl.set_position(Vector2i(5, 5))
	_check(events.size() == 0, "stepped not emitted by set_position()")
	ctrl.free()


# ---------------------------------------------------------------------------
# set_blocked_tiles
# ---------------------------------------------------------------------------
func _test_set_blocked_tiles_affects_movement() -> void:
	print("_test_set_blocked_tiles_affects_movement")
	var ctrl := GridMovementControllerClass.new()
	ctrl.set_blocked_tiles([Vector2i(1, 0)])
	var stepped_events: Array = []
	ctrl.stepped.connect(func(_f: Vector2i, _t: Vector2i) -> void: stepped_events.append(true))
	ctrl.request_step(Vector2i(1, 0))
	_check(ctrl.current_position == Vector2i(0, 0), "blocked by set_blocked_tiles()")
	_check(stepped_events.size() == 0, "stepped not emitted for blocked tile")
	ctrl.free()


func _test_set_blocked_tiles_duplicates_input() -> void:
	print("_test_set_blocked_tiles_duplicates_input")
	var ctrl := GridMovementControllerClass.new()
	var original: Array = [Vector2i(2, 2)]
	ctrl.set_blocked_tiles(original)
	original.clear()
	# Modifying original after set_blocked_tiles must not affect the controller.
	ctrl.request_step(Vector2i(1, 0))
	_check(ctrl.current_position == Vector2i(1, 0),
		"blocked_tiles is a copy; modifying original does not affect controller")
	ctrl.free()


# ---------------------------------------------------------------------------
# Sequential movement
# ---------------------------------------------------------------------------
func _test_multiple_steps_accumulate() -> void:
	print("_test_multiple_steps_accumulate")
	var ctrl := GridMovementControllerClass.new()
	ctrl.request_step(Vector2i(1, 0))
	ctrl.request_step(Vector2i(1, 0))
	ctrl.request_step(Vector2i(0, 1))
	_check(ctrl.current_position == Vector2i(2, 1),
		"position accumulates across multiple steps")
	ctrl.free()


# ---------------------------------------------------------------------------
# lock_controls clears held-input state
# ---------------------------------------------------------------------------
func _test_lock_clears_hold_state() -> void:
	print("_test_lock_clears_hold_state")
	var ctrl := GridMovementControllerClass.new()
	# Simulate steps to confirm movement works, then lock and verify no further steps.
	var stepped_events: Array = []
	ctrl.stepped.connect(func(_f: Vector2i, _t: Vector2i) -> void: stepped_events.append(true))

	ctrl.request_step(Vector2i(1, 0))
	_check(stepped_events.size() == 1, "step fires before lock")

	ctrl.lock_controls()
	# After locking, driving _process with a simulated delta must produce no movement.
	# Because lock_controls() clears _held_direction, _process returns early.
	ctrl._process(1.0)
	_check(ctrl.current_position == Vector2i(1, 0),
		"position unchanged after lock_controls() even when _process is driven")
	_check(stepped_events.size() == 1, "no additional stepped events after lock_controls()")
	ctrl.free()


# ---------------------------------------------------------------------------
# footstep_requested
# ---------------------------------------------------------------------------
func _test_request_step_emits_footstep_requested_on_success() -> void:
	print("_test_request_step_emits_footstep_requested_on_success")
	var ctrl := GridMovementControllerClass.new()
	var footstep_events: Array = []
	ctrl.footstep_requested.connect(func(pos: Vector2i) -> void:
		footstep_events.append(pos)
	)
	ctrl.request_step(Vector2i(1, 0))
	_check(footstep_events.size() == 1, "footstep_requested emitted once on successful step")
	ctrl.free()


func _test_request_step_footstep_position_is_new_position() -> void:
	print("_test_request_step_footstep_position_is_new_position")
	var ctrl := GridMovementControllerClass.new()
	ctrl.set_position(Vector2i(3, 4))
	var footstep_positions: Array = []
	ctrl.footstep_requested.connect(func(pos: Vector2i) -> void:
		footstep_positions.append(pos)
	)
	ctrl.request_step(Vector2i(0, 1))
	_check(footstep_positions.size() == 1, "footstep_requested emitted once")
	_check(footstep_positions[0] == Vector2i(3, 5),
		"footstep_requested position is the tile just stepped onto")
	ctrl.free()


func _test_request_step_no_footstep_when_blocked() -> void:
	print("_test_request_step_no_footstep_when_blocked")
	var ctrl := GridMovementControllerClass.new()
	ctrl.set_blocked_tiles([Vector2i(1, 0)])
	var footstep_events: Array = []
	ctrl.footstep_requested.connect(func(pos: Vector2i) -> void:
		footstep_events.append(pos)
	)
	ctrl.request_step(Vector2i(1, 0))
	_check(footstep_events.size() == 0, "footstep_requested not emitted when step is blocked")
	ctrl.free()


func _test_request_step_no_footstep_when_locked() -> void:
	print("_test_request_step_no_footstep_when_locked")
	var ctrl := GridMovementControllerClass.new()
	ctrl.lock_controls()
	var footstep_events: Array = []
	ctrl.footstep_requested.connect(func(pos: Vector2i) -> void:
		footstep_events.append(pos)
	)
	ctrl.request_step(Vector2i(1, 0))
	_check(footstep_events.size() == 0, "footstep_requested not emitted when controls are locked")
	ctrl.free()
