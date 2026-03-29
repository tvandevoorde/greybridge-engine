## test_trigger_tile_controller.gd
## Unit tests for TriggerTileController
## (src/overworld/trigger_tile_controller.gd).
##
## Run headlessly from the Godot project root (src/) with:
##   godot --headless --script ./tests/unit/overworld/test_trigger_tile_controller.gd
##
## Exit code 0 = all assertions passed; 1 = one or more assertions failed.
extends SceneTree

const TriggerTileControllerClass = preload("res://overworld/trigger_tile_controller.gd")

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
	_test_no_trigger_on_empty_tile()
	_test_combat_trigger_fired_on_combat_start()
	_test_combat_trigger_carries_encounter_id()
	_test_dialogue_trigger_fired_on_dialogue_start()
	_test_dialogue_trigger_carries_dialogue_id()
	_test_flag_trigger_fired_on_set_flag()
	_test_flag_trigger_carries_key_and_value()
	_test_teleport_trigger_fired_on_teleport()
	_test_teleport_trigger_carries_map_and_pos()
	_test_one_time_trigger_fires_only_once()
	_test_repeatable_trigger_fires_multiple_times()
	_test_condition_blocks_trigger_when_flag_unmet()
	_test_condition_allows_trigger_when_flag_met()
	_test_load_triggers_clears_previous_map()
	_test_set_quest_flags_updates_evaluation()
	_test_from_parameter_ignored_for_trigger_lookup()


# ---------------------------------------------------------------------------
# Helper — build a minimal 5×5 trigger layer with one trigger at (2, 2)
# ---------------------------------------------------------------------------
func _make_layer(tile: Vector2i, trigger: Dictionary) -> Array:
	var layer: Array = []
	for row in range(5):
		var row_arr: Array = []
		for col in range(5):
			if Vector2i(col, row) == tile:
				row_arr.append(trigger)
			else:
				row_arr.append(null)
		layer.append(row_arr)
	return layer


# ---------------------------------------------------------------------------
# Empty tile
# ---------------------------------------------------------------------------
func _test_no_trigger_on_empty_tile() -> void:
	print("_test_no_trigger_on_empty_tile")
	var ctrl := TriggerTileControllerClass.new()
	ctrl.load_triggers(_make_layer(Vector2i(2, 2), {"type": "combat_start", "encounter_id": "x"}))
	var events: Array = []
	ctrl.combat_trigger_fired.connect(func(_id: String) -> void: events.append(true))
	ctrl.on_stepped(Vector2i(0, 0), Vector2i(1, 1))  # tile (1,1) has no trigger
	_check(events.size() == 0, "no signal when stepping onto an empty tile")
	ctrl.free()


# ---------------------------------------------------------------------------
# combat_start
# ---------------------------------------------------------------------------
func _test_combat_trigger_fired_on_combat_start() -> void:
	print("_test_combat_trigger_fired_on_combat_start")
	var ctrl := TriggerTileControllerClass.new()
	ctrl.load_triggers(_make_layer(Vector2i(2, 2), {"type": "combat_start", "encounter_id": "enc_1"}))
	var events: Array = []
	ctrl.combat_trigger_fired.connect(func(_id: String) -> void: events.append(true))
	ctrl.on_stepped(Vector2i(1, 2), Vector2i(2, 2))
	_check(events.size() == 1, "combat_trigger_fired emitted once on combat_start tile")
	ctrl.free()


func _test_combat_trigger_carries_encounter_id() -> void:
	print("_test_combat_trigger_carries_encounter_id")
	var ctrl := TriggerTileControllerClass.new()
	ctrl.load_triggers(_make_layer(Vector2i(2, 2), {"type": "combat_start", "encounter_id": "bandit_ambush"}))
	var ids: Array[String] = []
	ctrl.combat_trigger_fired.connect(func(id: String) -> void: ids.append(id))
	ctrl.on_stepped(Vector2i(1, 2), Vector2i(2, 2))
	_check(ids.size() == 1 and ids[0] == "bandit_ambush",
		"combat_trigger_fired carries the correct encounter_id")
	ctrl.free()


# ---------------------------------------------------------------------------
# dialogue_start
# ---------------------------------------------------------------------------
func _test_dialogue_trigger_fired_on_dialogue_start() -> void:
	print("_test_dialogue_trigger_fired_on_dialogue_start")
	var ctrl := TriggerTileControllerClass.new()
	ctrl.load_triggers(_make_layer(Vector2i(0, 0), {"type": "dialogue_start", "dialogue_id": "d1"}))
	var events: Array = []
	ctrl.dialogue_trigger_fired.connect(func(_id: String) -> void: events.append(true))
	ctrl.on_stepped(Vector2i(0, 1), Vector2i(0, 0))
	_check(events.size() == 1, "dialogue_trigger_fired emitted on dialogue_start tile")
	ctrl.free()


func _test_dialogue_trigger_carries_dialogue_id() -> void:
	print("_test_dialogue_trigger_carries_dialogue_id")
	var ctrl := TriggerTileControllerClass.new()
	ctrl.load_triggers(_make_layer(Vector2i(0, 0), {"type": "dialogue_start", "dialogue_id": "town_intro"}))
	var ids: Array[String] = []
	ctrl.dialogue_trigger_fired.connect(func(id: String) -> void: ids.append(id))
	ctrl.on_stepped(Vector2i(0, 1), Vector2i(0, 0))
	_check(ids.size() == 1 and ids[0] == "town_intro",
		"dialogue_trigger_fired carries the correct dialogue_id")
	ctrl.free()


# ---------------------------------------------------------------------------
# set_flag
# ---------------------------------------------------------------------------
func _test_flag_trigger_fired_on_set_flag() -> void:
	print("_test_flag_trigger_fired_on_set_flag")
	var ctrl := TriggerTileControllerClass.new()
	ctrl.load_triggers(_make_layer(Vector2i(1, 1), {
		"type": "set_flag", "flag_key": "road_cleared", "flag_value": true
	}))
	var events: Array = []
	ctrl.flag_trigger_fired.connect(func(_k: String, _v: bool) -> void: events.append(true))
	ctrl.on_stepped(Vector2i(0, 1), Vector2i(1, 1))
	_check(events.size() == 1, "flag_trigger_fired emitted on set_flag tile")
	ctrl.free()


func _test_flag_trigger_carries_key_and_value() -> void:
	print("_test_flag_trigger_carries_key_and_value")
	var ctrl := TriggerTileControllerClass.new()
	ctrl.load_triggers(_make_layer(Vector2i(1, 1), {
		"type": "set_flag", "flag_key": "road_cleared", "flag_value": true
	}))
	var keys: Array[String] = []
	var values: Array[bool] = []
	ctrl.flag_trigger_fired.connect(func(k: String, v: bool) -> void:
		keys.append(k)
		values.append(v)
	)
	ctrl.on_stepped(Vector2i(0, 1), Vector2i(1, 1))
	_check(keys.size() == 1 and keys[0] == "road_cleared",
		"flag_trigger_fired carries the correct flag_key")
	_check(values.size() == 1 and values[0] == true,
		"flag_trigger_fired carries the correct flag_value")
	ctrl.free()


# ---------------------------------------------------------------------------
# teleport
# ---------------------------------------------------------------------------
func _test_teleport_trigger_fired_on_teleport() -> void:
	print("_test_teleport_trigger_fired_on_teleport")
	var ctrl := TriggerTileControllerClass.new()
	ctrl.load_triggers(_make_layer(Vector2i(3, 3), {
		"type": "teleport",
		"target_map": "greybridge_gate",
		"target_pos": {"x": 5, "y": 2}
	}))
	var events: Array = []
	ctrl.teleport_trigger_fired.connect(func(_m: String, _p: Vector2i) -> void: events.append(true))
	ctrl.on_stepped(Vector2i(2, 3), Vector2i(3, 3))
	_check(events.size() == 1, "teleport_trigger_fired emitted on teleport tile")
	ctrl.free()


func _test_teleport_trigger_carries_map_and_pos() -> void:
	print("_test_teleport_trigger_carries_map_and_pos")
	var ctrl := TriggerTileControllerClass.new()
	ctrl.load_triggers(_make_layer(Vector2i(3, 3), {
		"type": "teleport",
		"target_map": "greybridge_gate",
		"target_pos": {"x": 5, "y": 2}
	}))
	var maps: Array[String] = []
	var positions: Array[Vector2i] = []
	ctrl.teleport_trigger_fired.connect(func(m: String, p: Vector2i) -> void:
		maps.append(m)
		positions.append(p)
	)
	ctrl.on_stepped(Vector2i(2, 3), Vector2i(3, 3))
	_check(maps.size() == 1 and maps[0] == "greybridge_gate",
		"teleport_trigger_fired carries the correct target_map")
	_check(positions.size() == 1 and positions[0] == Vector2i(5, 2),
		"teleport_trigger_fired carries the correct target_pos")
	ctrl.free()


# ---------------------------------------------------------------------------
# One-time vs repeatable
# ---------------------------------------------------------------------------
func _test_one_time_trigger_fires_only_once() -> void:
	print("_test_one_time_trigger_fires_only_once")
	var ctrl := TriggerTileControllerClass.new()
	ctrl.load_triggers(_make_layer(Vector2i(2, 2), {
		"id": "bandit_ambush_trigger",
		"type": "combat_start",
		"encounter_id": "bandit_ambush",
		"one_time": true
	}))
	var events: Array = []
	ctrl.combat_trigger_fired.connect(func(_id: String) -> void: events.append(true))
	ctrl.on_stepped(Vector2i(1, 2), Vector2i(2, 2))
	ctrl.on_stepped(Vector2i(2, 2), Vector2i(1, 2))  # step away
	ctrl.on_stepped(Vector2i(1, 2), Vector2i(2, 2))  # step back
	_check(events.size() == 1, "one_time trigger fires exactly once across multiple entries")
	ctrl.free()


func _test_repeatable_trigger_fires_multiple_times() -> void:
	print("_test_repeatable_trigger_fires_multiple_times")
	var ctrl := TriggerTileControllerClass.new()
	ctrl.load_triggers(_make_layer(Vector2i(2, 2), {
		"id": "alarm_zone",
		"type": "combat_start",
		"encounter_id": "patrol",
		"one_time": false
	}))
	var events: Array = []
	ctrl.combat_trigger_fired.connect(func(_id: String) -> void: events.append(true))
	ctrl.on_stepped(Vector2i(1, 2), Vector2i(2, 2))
	ctrl.on_stepped(Vector2i(2, 2), Vector2i(1, 2))
	ctrl.on_stepped(Vector2i(1, 2), Vector2i(2, 2))
	_check(events.size() == 2, "repeatable trigger fires each time the tile is entered")
	ctrl.free()


# ---------------------------------------------------------------------------
# Condition gating
# ---------------------------------------------------------------------------
func _test_condition_blocks_trigger_when_flag_unmet() -> void:
	print("_test_condition_blocks_trigger_when_flag_unmet")
	var ctrl := TriggerTileControllerClass.new()
	ctrl.load_triggers(_make_layer(Vector2i(2, 2), {
		"type": "combat_start",
		"encounter_id": "boss",
		"conditions": [{"flag": "boss_arena_unlocked", "value": true}]
	}))
	ctrl.set_quest_flags({"boss_arena_unlocked": false})
	var events: Array = []
	ctrl.combat_trigger_fired.connect(func(_id: String) -> void: events.append(true))
	ctrl.on_stepped(Vector2i(1, 2), Vector2i(2, 2))
	_check(events.size() == 0, "no signal when condition flag is not met")
	ctrl.free()


func _test_condition_allows_trigger_when_flag_met() -> void:
	print("_test_condition_allows_trigger_when_flag_met")
	var ctrl := TriggerTileControllerClass.new()
	ctrl.load_triggers(_make_layer(Vector2i(2, 2), {
		"type": "combat_start",
		"encounter_id": "boss",
		"conditions": [{"flag": "boss_arena_unlocked", "value": true}]
	}))
	ctrl.set_quest_flags({"boss_arena_unlocked": true})
	var events: Array = []
	ctrl.combat_trigger_fired.connect(func(_id: String) -> void: events.append(true))
	ctrl.on_stepped(Vector2i(1, 2), Vector2i(2, 2))
	_check(events.size() == 1, "signal emitted when condition flag is met")
	ctrl.free()


# ---------------------------------------------------------------------------
# load_triggers — clears previous data
# ---------------------------------------------------------------------------
func _test_load_triggers_clears_previous_map() -> void:
	print("_test_load_triggers_clears_previous_map")
	var ctrl := TriggerTileControllerClass.new()
	ctrl.load_triggers(_make_layer(Vector2i(2, 2), {"type": "combat_start", "encounter_id": "old"}))
	# Re-load with an empty layer.
	var empty_layer: Array = []
	for _r in range(5):
		var row: Array = []
		for _c in range(5):
			row.append(null)
		empty_layer.append(row)
	ctrl.load_triggers(empty_layer)
	var events: Array = []
	ctrl.combat_trigger_fired.connect(func(_id: String) -> void: events.append(true))
	ctrl.on_stepped(Vector2i(1, 2), Vector2i(2, 2))
	_check(events.size() == 0, "no signal after load_triggers replaces map with empty layer")
	ctrl.free()


# ---------------------------------------------------------------------------
# set_quest_flags
# ---------------------------------------------------------------------------
func _test_set_quest_flags_updates_evaluation() -> void:
	print("_test_set_quest_flags_updates_evaluation")
	var ctrl := TriggerTileControllerClass.new()
	ctrl.load_triggers(_make_layer(Vector2i(2, 2), {
		"type": "dialogue_start",
		"dialogue_id": "secret_path",
		"conditions": [{"flag": "found_map", "value": true}]
	}))
	ctrl.set_quest_flags({"found_map": false})
	var events: Array = []
	ctrl.dialogue_trigger_fired.connect(func(_id: String) -> void: events.append(true))
	ctrl.on_stepped(Vector2i(1, 2), Vector2i(2, 2))
	_check(events.size() == 0, "no signal before flag is set")

	ctrl.set_quest_flags({"found_map": true})
	ctrl.on_stepped(Vector2i(2, 2), Vector2i(1, 2))
	ctrl.on_stepped(Vector2i(1, 2), Vector2i(2, 2))
	_check(events.size() == 1, "signal fires after set_quest_flags updates the flag")
	ctrl.free()


# ---------------------------------------------------------------------------
# from parameter is not used for trigger lookup (only to matters)
# ---------------------------------------------------------------------------
func _test_from_parameter_ignored_for_trigger_lookup() -> void:
	print("_test_from_parameter_ignored_for_trigger_lookup")
	var ctrl := TriggerTileControllerClass.new()
	# Trigger at (0, 0) — from will be (0, 0) but to will be (1, 0).
	ctrl.load_triggers(_make_layer(Vector2i(0, 0), {"type": "combat_start", "encounter_id": "x"}))
	var events: Array = []
	ctrl.combat_trigger_fired.connect(func(_id: String) -> void: events.append(true))
	# Player steps FROM the trigger tile, not onto it.
	ctrl.on_stepped(Vector2i(0, 0), Vector2i(1, 0))
	_check(events.size() == 0, "trigger does not fire when player leaves the tile (from != to lookup)")
	ctrl.free()
