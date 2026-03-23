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
	var signal_count: int = 0
	cc.camera_follow_requested.connect(func(_pos: Vector2) -> void:
		signal_count += 1
	)
	cc.follow_target(Vector2(32.0, 32.0))
	_check(signal_count == 1, "camera_follow_requested emitted once")
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
	var signal_count: int = 0
	cc.camera_follow_requested.connect(func(_pos: Vector2) -> void:
		signal_count += 1
	)
	cc.follow_target(Vector2(10.0, 10.0))
	cc.follow_target(Vector2(20.0, 20.0))
	cc.follow_target(Vector2(30.0, 30.0))
	_check(signal_count == 3, "camera_follow_requested emitted 3 times for 3 calls")
	cc.free()
