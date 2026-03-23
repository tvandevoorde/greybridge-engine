## test_overworld_camera_controller.gd
## Unit tests for OverworldCameraController (src/overworld/overworld_camera_controller.gd).
##
## Run headlessly from the Godot project root (src/) with:
##   godot --headless --script ./tests/unit/overworld/test_overworld_camera_controller.gd
##
## Exit code 0 = all assertions passed; 1 = one or more assertions failed.
extends SceneTree

const OverworldCameraControllerClass = preload("res://overworld/overworld_camera_controller.gd")

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
	_test_initial_follow_position_is_zero()
	_test_follow_target_updates_position()
	_test_follow_target_emits_signal()
	_test_signal_carries_correct_position()
	_test_successive_follow_updates_position()
	_test_successive_follow_emits_each_time()
	_test_no_bounds_passes_position_through()
	_test_set_map_bounds_clamps_x_over_max()
	_test_set_map_bounds_clamps_y_over_max()
	_test_set_map_bounds_clamps_x_under_min()
	_test_set_map_bounds_clamps_y_under_min()
	_test_set_map_bounds_position_inside_bounds_unchanged()
	_test_clamped_position_is_stored_as_follow_position()
	_test_signal_carries_clamped_position()


# ---------------------------------------------------------------------------
# Initial follow position is Vector2.ZERO
# ---------------------------------------------------------------------------
func _test_initial_follow_position_is_zero() -> void:
	print("_test_initial_follow_position_is_zero")
	var cc := OverworldCameraControllerClass.new()
	_check(cc.get_follow_position() == Vector2.ZERO, "initial follow position is Vector2.ZERO")
	cc.free()


# ---------------------------------------------------------------------------
# follow_target() updates the stored follow position
# ---------------------------------------------------------------------------
func _test_follow_target_updates_position() -> void:
	print("_test_follow_target_updates_position")
	var cc := OverworldCameraControllerClass.new()
	cc.follow_target(Vector2(64.0, 96.0))
	_check(cc.get_follow_position() == Vector2(64.0, 96.0), "follow position updated after follow_target()")
	cc.free()


# ---------------------------------------------------------------------------
# follow_target() emits camera_follow_requested
# ---------------------------------------------------------------------------
func _test_follow_target_emits_signal() -> void:
	print("_test_follow_target_emits_signal")
	var cc := OverworldCameraControllerClass.new()
	var signal_events: Array = []
	cc.camera_follow_requested.connect(func(_pos: Vector2) -> void:
		signal_events.append(true)
	)
	cc.follow_target(Vector2(32.0, 32.0))
	_check(signal_events.size() == 1, "camera_follow_requested emitted once")
	cc.free()


# ---------------------------------------------------------------------------
# camera_follow_requested carries the correct position
# ---------------------------------------------------------------------------
func _test_signal_carries_correct_position() -> void:
	print("_test_signal_carries_correct_position")
	var cc := OverworldCameraControllerClass.new()
	var received: Array = []
	cc.camera_follow_requested.connect(func(pos: Vector2) -> void:
		received.append(pos)
	)
	cc.follow_target(Vector2(128.0, 256.0))
	_check(received.size() == 1, "signal emitted once")
	_check(received[0] == Vector2(128.0, 256.0), "signal carries correct position")
	cc.free()


# ---------------------------------------------------------------------------
# Calling follow_target() again updates to the new position
# ---------------------------------------------------------------------------
func _test_successive_follow_updates_position() -> void:
	print("_test_successive_follow_updates_position")
	var cc := OverworldCameraControllerClass.new()
	cc.follow_target(Vector2(32.0, 32.0))
	cc.follow_target(Vector2(160.0, 224.0))
	_check(cc.get_follow_position() == Vector2(160.0, 224.0), "follow position updated on second call")
	cc.free()


# ---------------------------------------------------------------------------
# follow_target() emits signal on every call
# ---------------------------------------------------------------------------
func _test_successive_follow_emits_each_time() -> void:
	print("_test_successive_follow_emits_each_time")
	var cc := OverworldCameraControllerClass.new()
	var signal_events: Array = []
	cc.camera_follow_requested.connect(func(_pos: Vector2) -> void:
		signal_events.append(true)
	)
	cc.follow_target(Vector2(10.0, 10.0))
	cc.follow_target(Vector2(20.0, 20.0))
	cc.follow_target(Vector2(30.0, 30.0))
	_check(signal_events.size() == 3, "camera_follow_requested emitted 3 times for 3 calls")
	cc.free()


# ---------------------------------------------------------------------------
# Without bounds set, follow_target passes position through unchanged
# ---------------------------------------------------------------------------
func _test_no_bounds_passes_position_through() -> void:
	print("_test_no_bounds_passes_position_through")
	var cc := OverworldCameraControllerClass.new()
	cc.follow_target(Vector2(9999.0, 9999.0))
	_check(cc.get_follow_position() == Vector2(9999.0, 9999.0), "position unchanged when no bounds set")
	cc.free()


# ---------------------------------------------------------------------------
# X position above map width is clamped to map_width_px
# ---------------------------------------------------------------------------
func _test_set_map_bounds_clamps_x_over_max() -> void:
	print("_test_set_map_bounds_clamps_x_over_max")
	var cc := OverworldCameraControllerClass.new()
	cc.set_map_bounds(640.0, 480.0)
	cc.follow_target(Vector2(700.0, 240.0))
	_check(cc.get_follow_position().x == 640.0, "x clamped to map_width_px when over max")
	cc.free()


# ---------------------------------------------------------------------------
# Y position above map height is clamped to map_height_px
# ---------------------------------------------------------------------------
func _test_set_map_bounds_clamps_y_over_max() -> void:
	print("_test_set_map_bounds_clamps_y_over_max")
	var cc := OverworldCameraControllerClass.new()
	cc.set_map_bounds(640.0, 480.0)
	cc.follow_target(Vector2(320.0, 600.0))
	_check(cc.get_follow_position().y == 480.0, "y clamped to map_height_px when over max")
	cc.free()


# ---------------------------------------------------------------------------
# X position below 0 is clamped to 0
# ---------------------------------------------------------------------------
func _test_set_map_bounds_clamps_x_under_min() -> void:
	print("_test_set_map_bounds_clamps_x_under_min")
	var cc := OverworldCameraControllerClass.new()
	cc.set_map_bounds(640.0, 480.0)
	cc.follow_target(Vector2(-50.0, 240.0))
	_check(cc.get_follow_position().x == 0.0, "x clamped to 0 when under min")
	cc.free()


# ---------------------------------------------------------------------------
# Y position below 0 is clamped to 0
# ---------------------------------------------------------------------------
func _test_set_map_bounds_clamps_y_under_min() -> void:
	print("_test_set_map_bounds_clamps_y_under_min")
	var cc := OverworldCameraControllerClass.new()
	cc.set_map_bounds(640.0, 480.0)
	cc.follow_target(Vector2(320.0, -10.0))
	_check(cc.get_follow_position().y == 0.0, "y clamped to 0 when under min")
	cc.free()


# ---------------------------------------------------------------------------
# Position inside bounds is not modified
# ---------------------------------------------------------------------------
func _test_set_map_bounds_position_inside_bounds_unchanged() -> void:
	print("_test_set_map_bounds_position_inside_bounds_unchanged")
	var cc := OverworldCameraControllerClass.new()
	cc.set_map_bounds(640.0, 480.0)
	cc.follow_target(Vector2(320.0, 240.0))
	_check(cc.get_follow_position() == Vector2(320.0, 240.0), "position inside bounds unchanged")
	cc.free()


# ---------------------------------------------------------------------------
# Stored follow position reflects the clamped value, not the raw input
# ---------------------------------------------------------------------------
func _test_clamped_position_is_stored_as_follow_position() -> void:
	print("_test_clamped_position_is_stored_as_follow_position")
	var cc := OverworldCameraControllerClass.new()
	cc.set_map_bounds(320.0, 240.0)
	cc.follow_target(Vector2(500.0, 400.0))
	_check(cc.get_follow_position() == Vector2(320.0, 240.0), "stored position is clamped, not raw")
	cc.free()


# ---------------------------------------------------------------------------
# Signal carries the clamped position, not the raw input
# ---------------------------------------------------------------------------
func _test_signal_carries_clamped_position() -> void:
	print("_test_signal_carries_clamped_position")
	var cc := OverworldCameraControllerClass.new()
	cc.set_map_bounds(320.0, 240.0)
	var received: Array = []
	cc.camera_follow_requested.connect(func(pos: Vector2) -> void:
		received.append(pos)
	)
	cc.follow_target(Vector2(999.0, 999.0))
	_check(received.size() == 1, "signal emitted once")
	_check(received[0] == Vector2(320.0, 240.0), "signal carries clamped position")
	cc.free()
