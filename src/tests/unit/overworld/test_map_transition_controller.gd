## test_map_transition_controller.gd
## Unit tests for MapTransitionController
## (src/overworld/map_transition_controller.gd).
##
## Run headlessly from the Godot project root (src/) with:
##   godot --headless --script ./tests/unit/overworld/test_map_transition_controller.gd
##
## Exit code 0 = all assertions passed; 1 = one or more assertions failed.
extends SceneTree

const MapTransitionControllerClass = preload("res://overworld/map_transition_controller.gd")

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


func _make_raw_transition(tx: int, ty: int, map: String, sx: int, sy: int,
		flags: Dictionary = {}) -> Dictionary:
	return {
		"tile": {"x": tx, "y": ty},
		"target_map": map,
		"target_spawn": {"x": sx, "y": sy},
		"required_flags": flags,
	}


func _run_all_tests() -> void:
	_test_no_transition_triggered_on_non_transition_tile()
	_test_transition_triggered_on_matching_tile()
	_test_transition_triggered_carries_target_map()
	_test_transition_triggered_carries_target_spawn()
	_test_conditional_transition_blocked_when_flag_missing()
	_test_conditional_transition_fires_when_flag_present()
	_test_set_quest_flags_updates_resolution()
	_test_load_transitions_discards_invalid_entries()
	_test_load_transitions_clears_previous()
	_test_stepped_from_is_not_checked_only_to()
	_test_multiple_transitions_correct_one_fires()


# ---------------------------------------------------------------------------
# No signal on non-transition tile
# ---------------------------------------------------------------------------
func _test_no_transition_triggered_on_non_transition_tile() -> void:
	print("_test_no_transition_triggered_on_non_transition_tile")
	var ctrl := MapTransitionControllerClass.new()
	var fired: Array = []
	ctrl.transition_triggered.connect(func(_m: String, _s: Vector2i) -> void:
		fired.append(true)
	)
	ctrl.load_transitions([_make_raw_transition(5, 0, "greybridge_town", 1, 8)])
	ctrl.on_player_stepped(Vector2i(3, 0), Vector2i(4, 0))
	_check(fired.size() == 0, "transition_triggered not emitted for non-transition tile")
	ctrl.free()


# ---------------------------------------------------------------------------
# Signal emitted when stepping onto a transition tile
# ---------------------------------------------------------------------------
func _test_transition_triggered_on_matching_tile() -> void:
	print("_test_transition_triggered_on_matching_tile")
	var ctrl := MapTransitionControllerClass.new()
	var fired: Array = []
	ctrl.transition_triggered.connect(func(_m: String, _s: Vector2i) -> void:
		fired.append(true)
	)
	ctrl.load_transitions([_make_raw_transition(5, 0, "greybridge_town", 1, 8)])
	ctrl.on_player_stepped(Vector2i(4, 0), Vector2i(5, 0))
	_check(fired.size() == 1, "transition_triggered emitted when player steps on transition tile")
	ctrl.free()


# ---------------------------------------------------------------------------
# Signal carries target_map
# ---------------------------------------------------------------------------
func _test_transition_triggered_carries_target_map() -> void:
	print("_test_transition_triggered_carries_target_map")
	var ctrl := MapTransitionControllerClass.new()
	var maps: Array[String] = []
	ctrl.transition_triggered.connect(func(m: String, _s: Vector2i) -> void:
		maps.append(m)
	)
	ctrl.load_transitions([_make_raw_transition(5, 0, "greybridge_town", 1, 8)])
	ctrl.on_player_stepped(Vector2i(4, 0), Vector2i(5, 0))
	_check(maps.size() == 1 and maps[0] == "greybridge_town",
		"transition_triggered carries correct target_map")
	ctrl.free()


# ---------------------------------------------------------------------------
# Signal carries target_spawn
# ---------------------------------------------------------------------------
func _test_transition_triggered_carries_target_spawn() -> void:
	print("_test_transition_triggered_carries_target_spawn")
	var ctrl := MapTransitionControllerClass.new()
	var spawns: Array[Vector2i] = []
	ctrl.transition_triggered.connect(func(_m: String, s: Vector2i) -> void:
		spawns.append(s)
	)
	ctrl.load_transitions([_make_raw_transition(5, 0, "greybridge_town", 3, 9)])
	ctrl.on_player_stepped(Vector2i(4, 0), Vector2i(5, 0))
	_check(spawns.size() == 1 and spawns[0] == Vector2i(3, 9),
		"transition_triggered carries correct target_spawn")
	ctrl.free()


# ---------------------------------------------------------------------------
# Conditional transition — flag missing → no signal
# ---------------------------------------------------------------------------
func _test_conditional_transition_blocked_when_flag_missing() -> void:
	print("_test_conditional_transition_blocked_when_flag_missing")
	var ctrl := MapTransitionControllerClass.new()
	var fired: Array = []
	ctrl.transition_triggered.connect(func(_m: String, _s: Vector2i) -> void:
		fired.append(true)
	)
	ctrl.load_transitions([
		_make_raw_transition(5, 0, "greybridge_town", 1, 8, {"gate_open": true})
	])
	ctrl.set_quest_flags({})
	ctrl.on_player_stepped(Vector2i(4, 0), Vector2i(5, 0))
	_check(fired.size() == 0,
		"transition_triggered not emitted when required flag is absent")
	ctrl.free()


# ---------------------------------------------------------------------------
# Conditional transition — flag present → signal emitted
# ---------------------------------------------------------------------------
func _test_conditional_transition_fires_when_flag_present() -> void:
	print("_test_conditional_transition_fires_when_flag_present")
	var ctrl := MapTransitionControllerClass.new()
	var fired: Array = []
	ctrl.transition_triggered.connect(func(_m: String, _s: Vector2i) -> void:
		fired.append(true)
	)
	ctrl.load_transitions([
		_make_raw_transition(5, 0, "greybridge_town", 1, 8, {"gate_open": true})
	])
	ctrl.set_quest_flags({"gate_open": true})
	ctrl.on_player_stepped(Vector2i(4, 0), Vector2i(5, 0))
	_check(fired.size() == 1,
		"transition_triggered emitted when required flag is satisfied")
	ctrl.free()


# ---------------------------------------------------------------------------
# set_quest_flags updates resolution
# ---------------------------------------------------------------------------
func _test_set_quest_flags_updates_resolution() -> void:
	print("_test_set_quest_flags_updates_resolution")
	var ctrl := MapTransitionControllerClass.new()
	var fired: Array = []
	ctrl.transition_triggered.connect(func(_m: String, _s: Vector2i) -> void:
		fired.append(true)
	)
	ctrl.load_transitions([
		_make_raw_transition(5, 0, "greybridge_town", 1, 8, {"gate_open": true})
	])
	ctrl.set_quest_flags({})
	ctrl.on_player_stepped(Vector2i(4, 0), Vector2i(5, 0))
	_check(fired.size() == 0, "transition blocked before flag update")

	ctrl.set_quest_flags({"gate_open": true})
	ctrl.on_player_stepped(Vector2i(4, 0), Vector2i(5, 0))
	_check(fired.size() == 1, "transition fires after set_quest_flags satisfies condition")
	ctrl.free()


# ---------------------------------------------------------------------------
# load_transitions discards invalid entries
# ---------------------------------------------------------------------------
func _test_load_transitions_discards_invalid_entries() -> void:
	print("_test_load_transitions_discards_invalid_entries")
	var ctrl := MapTransitionControllerClass.new()
	var fired: Array = []
	ctrl.transition_triggered.connect(func(_m: String, _s: Vector2i) -> void:
		fired.append(true)
	)
	# Entry missing target_map → invalid, should be discarded.
	ctrl.load_transitions([{"tile": {"x": 5, "y": 0}, "target_spawn": {"x": 1, "y": 8}}])
	ctrl.on_player_stepped(Vector2i(4, 0), Vector2i(5, 0))
	_check(fired.size() == 0, "invalid transition (no target_map) is discarded")
	ctrl.free()


# ---------------------------------------------------------------------------
# load_transitions clears previous transitions
# ---------------------------------------------------------------------------
func _test_load_transitions_clears_previous() -> void:
	print("_test_load_transitions_clears_previous")
	var ctrl := MapTransitionControllerClass.new()
	var fired: Array = []
	ctrl.transition_triggered.connect(func(_m: String, _s: Vector2i) -> void:
		fired.append(true)
	)
	ctrl.load_transitions([_make_raw_transition(5, 0, "greybridge_town", 1, 8)])
	# Reload with an empty set — previous transition should be gone.
	ctrl.load_transitions([])
	ctrl.on_player_stepped(Vector2i(4, 0), Vector2i(5, 0))
	_check(fired.size() == 0,
		"load_transitions clears previously loaded transitions")
	ctrl.free()


# ---------------------------------------------------------------------------
# The "from" tile is not checked — only "to" triggers
# ---------------------------------------------------------------------------
func _test_stepped_from_is_not_checked_only_to() -> void:
	print("_test_stepped_from_is_not_checked_only_to")
	var ctrl := MapTransitionControllerClass.new()
	var fired: Array = []
	ctrl.transition_triggered.connect(func(_m: String, _s: Vector2i) -> void:
		fired.append(true)
	)
	# Transition at (5, 0).  Step from (5, 0) to (6, 0) — "from" is transition, "to" is not.
	ctrl.load_transitions([_make_raw_transition(5, 0, "greybridge_town", 1, 8)])
	ctrl.on_player_stepped(Vector2i(5, 0), Vector2i(6, 0))
	_check(fired.size() == 0,
		"transition_triggered not emitted when only the 'from' tile matches")
	ctrl.free()


# ---------------------------------------------------------------------------
# Multiple transitions — correct one fires
# ---------------------------------------------------------------------------
func _test_multiple_transitions_correct_one_fires() -> void:
	print("_test_multiple_transitions_correct_one_fires")
	var ctrl := MapTransitionControllerClass.new()
	var maps: Array[String] = []
	ctrl.transition_triggered.connect(func(m: String, _s: Vector2i) -> void:
		maps.append(m)
	)
	ctrl.load_transitions([
		_make_raw_transition(5, 0, "greybridge_town", 1, 8),
		_make_raw_transition(10, 0, "bandit_camp", 2, 5),
	])
	ctrl.on_player_stepped(Vector2i(9, 0), Vector2i(10, 0))
	_check(maps.size() == 1 and maps[0] == "bandit_camp",
		"correct transition fires when multiple transitions are loaded")
	ctrl.free()
