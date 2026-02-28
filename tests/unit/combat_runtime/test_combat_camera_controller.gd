## test_combat_camera_controller.gd
## Unit tests for CombatCameraController
## (src/combat_runtime/combat_camera_controller.gd).
##
## Run headlessly from the Godot project root (src/) with:
##   godot --headless --script ../tests/unit/combat_runtime/test_combat_camera_controller.gd
##
## Exit code 0 = all assertions passed; 1 = one or more assertions failed.
extends SceneTree

const CombatCameraController = preload("res://combat_runtime/combat_camera_controller.gd")

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
	_test_on_turn_started_emits_focus_and_highlight()
	_test_on_turn_started_updates_state()
	_test_on_attack_declared_emits_target_focus()
	_test_on_attack_resolved_returns_to_active_position()
	_test_on_attack_resolved_emits_focus_returned()
	_test_default_attack_focus_duration()
	_test_successive_turns_update_active_state()


# ---------------------------------------------------------------------------
# on_turn_started emits camera_focus_requested and actor_highlighted
# ---------------------------------------------------------------------------
func _test_on_turn_started_emits_focus_and_highlight() -> void:
	print("_test_on_turn_started_emits_focus_and_highlight")
	var ctrl := CombatCameraController.new()

	var focus_positions: Array[Vector2] = []
	var highlighted_ids: Array[String] = []
	ctrl.camera_focus_requested.connect(func(p: Vector2) -> void: focus_positions.append(p))
	ctrl.actor_highlighted.connect(func(id: String) -> void: highlighted_ids.append(id))

	ctrl.on_turn_started("hero", Vector2(100.0, 200.0))

	_check(focus_positions.size() == 1, "camera_focus_requested emitted once")
	_check(focus_positions[0] == Vector2(100.0, 200.0),
		"camera_focus_requested position == (100, 200)")
	_check(highlighted_ids.size() == 1, "actor_highlighted emitted once")
	_check(highlighted_ids[0] == "hero", "actor_highlighted id == 'hero'")

	ctrl.free()


# ---------------------------------------------------------------------------
# on_turn_started updates internal state readable via accessors
# ---------------------------------------------------------------------------
func _test_on_turn_started_updates_state() -> void:
	print("_test_on_turn_started_updates_state")
	var ctrl := CombatCameraController.new()

	ctrl.on_turn_started("bandit", Vector2(32.0, 64.0))

	_check(ctrl.get_active_actor_id() == "bandit",
		"get_active_actor_id returns 'bandit' after on_turn_started")
	_check(ctrl.get_active_position() == Vector2(32.0, 64.0),
		"get_active_position returns (32, 64) after on_turn_started")

	ctrl.free()


# ---------------------------------------------------------------------------
# on_attack_declared emits camera_focus_requested with the target position
# ---------------------------------------------------------------------------
func _test_on_attack_declared_emits_target_focus() -> void:
	print("_test_on_attack_declared_emits_target_focus")
	var ctrl := CombatCameraController.new()

	ctrl.on_turn_started("hero", Vector2(0.0, 0.0))

	var focus_positions: Array[Vector2] = []
	ctrl.camera_focus_requested.connect(func(p: Vector2) -> void: focus_positions.append(p))

	ctrl.on_attack_declared(Vector2(300.0, 150.0))

	_check(focus_positions.size() == 1, "camera_focus_requested emitted once for attack target")
	_check(focus_positions[0] == Vector2(300.0, 150.0),
		"camera_focus_requested position == target (300, 150)")

	ctrl.free()


# ---------------------------------------------------------------------------
# on_attack_resolved emits camera_focus_requested back to the active position
# ---------------------------------------------------------------------------
func _test_on_attack_resolved_returns_to_active_position() -> void:
	print("_test_on_attack_resolved_returns_to_active_position")
	var ctrl := CombatCameraController.new()

	ctrl.on_turn_started("hero", Vector2(50.0, 75.0))
	ctrl.on_attack_declared(Vector2(400.0, 400.0))

	var focus_positions: Array[Vector2] = []
	ctrl.camera_focus_requested.connect(func(p: Vector2) -> void: focus_positions.append(p))

	ctrl.on_attack_resolved()

	_check(focus_positions.size() == 1, "camera_focus_requested emitted once on resolve")
	_check(focus_positions[0] == Vector2(50.0, 75.0),
		"camera_focus_requested returns to active position (50, 75)")

	ctrl.free()


# ---------------------------------------------------------------------------
# on_attack_resolved emits focus_returned with the active position
# ---------------------------------------------------------------------------
func _test_on_attack_resolved_emits_focus_returned() -> void:
	print("_test_on_attack_resolved_emits_focus_returned")
	var ctrl := CombatCameraController.new()

	ctrl.on_turn_started("hero", Vector2(10.0, 20.0))

	var returned_positions: Array[Vector2] = []
	ctrl.focus_returned.connect(func(p: Vector2) -> void: returned_positions.append(p))

	ctrl.on_attack_resolved()

	_check(returned_positions.size() == 1, "focus_returned emitted once on resolve")
	_check(returned_positions[0] == Vector2(10.0, 20.0),
		"focus_returned position == active position (10, 20)")

	ctrl.free()


# ---------------------------------------------------------------------------
# Default attack_focus_duration is 0.8 seconds
# ---------------------------------------------------------------------------
func _test_default_attack_focus_duration() -> void:
	print("_test_default_attack_focus_duration")
	var ctrl := CombatCameraController.new()
	_check(ctrl.attack_focus_duration == 0.8,
		"default attack_focus_duration is 0.8")
	ctrl.free()


# ---------------------------------------------------------------------------
# Calling on_turn_started a second time updates the tracked actor and position
# ---------------------------------------------------------------------------
func _test_successive_turns_update_active_state() -> void:
	print("_test_successive_turns_update_active_state")
	var ctrl := CombatCameraController.new()

	ctrl.on_turn_started("hero", Vector2(0.0, 0.0))
	ctrl.on_turn_started("bandit", Vector2(256.0, 128.0))

	_check(ctrl.get_active_actor_id() == "bandit",
		"active actor updated to 'bandit' on second on_turn_started")
	_check(ctrl.get_active_position() == Vector2(256.0, 128.0),
		"active position updated to (256, 128) on second on_turn_started")

	ctrl.free()
