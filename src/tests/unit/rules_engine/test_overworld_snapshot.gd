## test_overworld_snapshot.gd
## Unit tests for OverworldSnapshot (src/rules_engine/core/overworld_snapshot.gd).
##
## Run headlessly from the Godot project root (src/) with:
##   godot --headless --script ./tests/unit/rules_engine/test_overworld_snapshot.gd
##
## Exit code 0 = all assertions passed; 1 = one or more assertions failed.
extends SceneTree

const OverworldSnapshotClass = preload("res://rules_engine/core/overworld_snapshot.gd")

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
	_test_default_values()
	_test_to_dict_map_id()
	_test_to_dict_player_position()
	_test_to_dict_player_facing()
	_test_to_dict_opened_chest_ids()
	_test_to_dict_door_states()
	_test_to_dict_quest_flags()
	_test_to_dict_fired_trigger_ids()
	_test_to_dict_independence()
	_test_from_dict_map_id()
	_test_from_dict_player_position()
	_test_from_dict_player_facing()
	_test_from_dict_opened_chest_ids()
	_test_from_dict_door_states()
	_test_from_dict_quest_flags()
	_test_from_dict_fired_trigger_ids()
	_test_from_dict_missing_keys_use_defaults()
	_test_from_dict_empty_dict_safe()
	_test_roundtrip()


# ---------------------------------------------------------------------------
# Default field values
# ---------------------------------------------------------------------------
func _test_default_values() -> void:
	print("_test_default_values")
	var snap := OverworldSnapshotClass.new()
	_check(snap.map_id == "", "map_id defaults to empty string")
	_check(snap.player_position == Vector2i.ZERO, "player_position defaults to (0,0)")
	_check(snap.player_facing == Vector2i(0, 1), "player_facing defaults to (0,1) south")
	_check(snap.opened_chest_ids.size() == 0, "opened_chest_ids defaults to empty array")
	_check(snap.door_states.is_empty(), "door_states defaults to empty dictionary")
	_check(snap.quest_flags.is_empty(), "quest_flags defaults to empty dictionary")
	_check(snap.fired_trigger_ids.size() == 0, "fired_trigger_ids defaults to empty array")


# ---------------------------------------------------------------------------
# to_dict — map_id
# ---------------------------------------------------------------------------
func _test_to_dict_map_id() -> void:
	print("_test_to_dict_map_id")
	var snap := OverworldSnapshotClass.new()
	snap.map_id = "road_to_greybridge"
	var d: Dictionary = snap.to_dict()
	_check(d.get("map_id") == "road_to_greybridge", "to_dict() contains map_id")


# ---------------------------------------------------------------------------
# to_dict — player_position serialized as x/y ints
# ---------------------------------------------------------------------------
func _test_to_dict_player_position() -> void:
	print("_test_to_dict_player_position")
	var snap := OverworldSnapshotClass.new()
	snap.player_position = Vector2i(3, 7)
	var d: Dictionary = snap.to_dict()
	var pos: Dictionary = d.get("player_position", {})
	_check(pos.get("x") == 3, "to_dict() player_position.x == 3")
	_check(pos.get("y") == 7, "to_dict() player_position.y == 7")


# ---------------------------------------------------------------------------
# to_dict — player_facing serialized as x/y ints
# ---------------------------------------------------------------------------
func _test_to_dict_player_facing() -> void:
	print("_test_to_dict_player_facing")
	var snap := OverworldSnapshotClass.new()
	snap.player_facing = Vector2i(1, 0)
	var d: Dictionary = snap.to_dict()
	var facing: Dictionary = d.get("player_facing", {})
	_check(facing.get("x") == 1, "to_dict() player_facing.x == 1")
	_check(facing.get("y") == 0, "to_dict() player_facing.y == 0")


# ---------------------------------------------------------------------------
# to_dict — opened_chest_ids
# ---------------------------------------------------------------------------
func _test_to_dict_opened_chest_ids() -> void:
	print("_test_to_dict_opened_chest_ids")
	var snap := OverworldSnapshotClass.new()
	snap.opened_chest_ids = ["chest_1", "chest_bandit_stash"]
	var d: Dictionary = snap.to_dict()
	var ids: Array = d.get("opened_chest_ids", [])
	_check(ids.size() == 2, "to_dict() opened_chest_ids has 2 entries")
	_check(ids.has("chest_1"), "to_dict() opened_chest_ids contains chest_1")
	_check(ids.has("chest_bandit_stash"), "to_dict() opened_chest_ids contains chest_bandit_stash")


# ---------------------------------------------------------------------------
# to_dict — door_states
# ---------------------------------------------------------------------------
func _test_to_dict_door_states() -> void:
	print("_test_to_dict_door_states")
	var snap := OverworldSnapshotClass.new()
	snap.door_states = {"5,3": true, "2,8": false}
	var d: Dictionary = snap.to_dict()
	var ds: Dictionary = d.get("door_states", {})
	_check(ds.get("5,3") == true, "to_dict() door at 5,3 is open")
	_check(ds.get("2,8") == false, "to_dict() door at 2,8 is closed")


# ---------------------------------------------------------------------------
# to_dict — quest_flags
# ---------------------------------------------------------------------------
func _test_to_dict_quest_flags() -> void:
	print("_test_to_dict_quest_flags")
	var snap := OverworldSnapshotClass.new()
	snap.quest_flags = {"met_merchant": true, "bandit_count": 3}
	var d: Dictionary = snap.to_dict()
	var qf: Dictionary = d.get("quest_flags", {})
	_check(qf.get("met_merchant") == true, "to_dict() met_merchant flag is true")
	_check(qf.get("bandit_count") == 3, "to_dict() bandit_count is 3")


# ---------------------------------------------------------------------------
# to_dict — fired_trigger_ids
# ---------------------------------------------------------------------------
func _test_to_dict_fired_trigger_ids() -> void:
	print("_test_to_dict_fired_trigger_ids")
	var snap := OverworldSnapshotClass.new()
	snap.fired_trigger_ids = ["bandit_ambush"]
	var d: Dictionary = snap.to_dict()
	var ids: Array = d.get("fired_trigger_ids", [])
	_check(ids.size() == 1, "to_dict() fired_trigger_ids has 1 entry")
	_check(ids.has("bandit_ambush"), "to_dict() fired_trigger_ids contains bandit_ambush")


# ---------------------------------------------------------------------------
# to_dict returns independent copies (mutations don't affect snapshot)
# ---------------------------------------------------------------------------
func _test_to_dict_independence() -> void:
	print("_test_to_dict_independence")
	var snap := OverworldSnapshotClass.new()
	snap.opened_chest_ids = ["chest_1"]
	snap.quest_flags = {"met_merchant": true}
	var d: Dictionary = snap.to_dict()
	d["opened_chest_ids"].append("new_chest")
	d["quest_flags"]["new_flag"] = false
	_check(snap.opened_chest_ids.size() == 1,
		"mutating to_dict() result does not affect snapshot.opened_chest_ids")
	_check(not snap.quest_flags.has("new_flag"),
		"mutating to_dict() result does not affect snapshot.quest_flags")


# ---------------------------------------------------------------------------
# from_dict — map_id
# ---------------------------------------------------------------------------
func _test_from_dict_map_id() -> void:
	print("_test_from_dict_map_id")
	var snap := OverworldSnapshotClass.from_dict({"map_id": "greybridge_town"})
	_check(snap.map_id == "greybridge_town", "from_dict() restores map_id")


# ---------------------------------------------------------------------------
# from_dict — player_position
# ---------------------------------------------------------------------------
func _test_from_dict_player_position() -> void:
	print("_test_from_dict_player_position")
	var snap := OverworldSnapshotClass.from_dict({
		"player_position": {"x": 5, "y": 9}
	})
	_check(snap.player_position == Vector2i(5, 9), "from_dict() restores player_position")


# ---------------------------------------------------------------------------
# from_dict — player_facing
# ---------------------------------------------------------------------------
func _test_from_dict_player_facing() -> void:
	print("_test_from_dict_player_facing")
	var snap := OverworldSnapshotClass.from_dict({
		"player_facing": {"x": -1, "y": 0}
	})
	_check(snap.player_facing == Vector2i(-1, 0), "from_dict() restores player_facing")


# ---------------------------------------------------------------------------
# from_dict — opened_chest_ids
# ---------------------------------------------------------------------------
func _test_from_dict_opened_chest_ids() -> void:
	print("_test_from_dict_opened_chest_ids")
	var snap := OverworldSnapshotClass.from_dict({
		"opened_chest_ids": ["chest_1", "chest_bandit_stash"]
	})
	_check(snap.opened_chest_ids.size() == 2, "from_dict() restores 2 chest ids")
	_check(snap.opened_chest_ids.has("chest_1"), "from_dict() chest_1 present")
	_check(snap.opened_chest_ids.has("chest_bandit_stash"), "from_dict() chest_bandit_stash present")


# ---------------------------------------------------------------------------
# from_dict — door_states
# ---------------------------------------------------------------------------
func _test_from_dict_door_states() -> void:
	print("_test_from_dict_door_states")
	var snap := OverworldSnapshotClass.from_dict({
		"door_states": {"3,4": true, "7,2": false}
	})
	_check(snap.door_states.get("3,4") == true, "from_dict() door at 3,4 is open")
	_check(snap.door_states.get("7,2") == false, "from_dict() door at 7,2 is closed")


# ---------------------------------------------------------------------------
# from_dict — quest_flags
# ---------------------------------------------------------------------------
func _test_from_dict_quest_flags() -> void:
	print("_test_from_dict_quest_flags")
	var snap := OverworldSnapshotClass.from_dict({
		"quest_flags": {"scout_rescued": true}
	})
	_check(snap.quest_flags.get("scout_rescued") == true, "from_dict() restores quest_flags")


# ---------------------------------------------------------------------------
# from_dict — fired_trigger_ids
# ---------------------------------------------------------------------------
func _test_from_dict_fired_trigger_ids() -> void:
	print("_test_from_dict_fired_trigger_ids")
	var snap := OverworldSnapshotClass.from_dict({
		"fired_trigger_ids": ["encounter_road_1"]
	})
	_check(snap.fired_trigger_ids.size() == 1, "from_dict() restores 1 fired trigger id")
	_check(snap.fired_trigger_ids.has("encounter_road_1"),
		"from_dict() encounter_road_1 present")


# ---------------------------------------------------------------------------
# from_dict — missing keys fall back to safe defaults
# ---------------------------------------------------------------------------
func _test_from_dict_missing_keys_use_defaults() -> void:
	print("_test_from_dict_missing_keys_use_defaults")
	var snap := OverworldSnapshotClass.from_dict({"map_id": "road_to_greybridge"})
	_check(snap.player_position == Vector2i.ZERO, "missing player_position defaults to (0,0)")
	_check(snap.player_facing == Vector2i(0, 1), "missing player_facing defaults to (0,1)")
	_check(snap.opened_chest_ids.size() == 0, "missing opened_chest_ids defaults to []")
	_check(snap.door_states.is_empty(), "missing door_states defaults to {}")
	_check(snap.quest_flags.is_empty(), "missing quest_flags defaults to {}")
	_check(snap.fired_trigger_ids.size() == 0, "missing fired_trigger_ids defaults to []")


# ---------------------------------------------------------------------------
# from_dict with completely empty dict is safe
# ---------------------------------------------------------------------------
func _test_from_dict_empty_dict_safe() -> void:
	print("_test_from_dict_empty_dict_safe")
	var snap := OverworldSnapshotClass.from_dict({})
	_check(snap.map_id == "", "empty dict: map_id is empty string")
	_check(snap.player_position == Vector2i.ZERO, "empty dict: player_position is (0,0)")


# ---------------------------------------------------------------------------
# Full round-trip: populate → to_dict → from_dict → verify
# ---------------------------------------------------------------------------
func _test_roundtrip() -> void:
	print("_test_roundtrip")
	var original := OverworldSnapshotClass.new()
	original.map_id = "road_to_greybridge"
	original.player_position = Vector2i(4, 3)
	original.player_facing = Vector2i(0, -1)
	original.opened_chest_ids = ["chest_1"]
	original.door_states = {"5,3": true}
	original.quest_flags = {"met_merchant": true, "bandit_ambush_cleared": false}
	original.fired_trigger_ids = ["bandit_ambush"]

	var restored := OverworldSnapshotClass.from_dict(original.to_dict())

	_check(restored.map_id == "road_to_greybridge", "roundtrip: map_id matches")
	_check(restored.player_position == Vector2i(4, 3), "roundtrip: player_position matches")
	_check(restored.player_facing == Vector2i(0, -1), "roundtrip: player_facing matches")
	_check(restored.opened_chest_ids.size() == 1, "roundtrip: 1 opened chest id")
	_check(restored.opened_chest_ids.has("chest_1"), "roundtrip: chest_1 present")
	_check(restored.door_states.get("5,3") == true, "roundtrip: door at 5,3 is open")
	_check(restored.quest_flags.get("met_merchant") == true,
		"roundtrip: met_merchant flag is true")
	_check(restored.quest_flags.get("bandit_ambush_cleared") == false,
		"roundtrip: bandit_ambush_cleared flag is false")
	_check(restored.fired_trigger_ids.has("bandit_ambush"),
		"roundtrip: bandit_ambush in fired_trigger_ids")
