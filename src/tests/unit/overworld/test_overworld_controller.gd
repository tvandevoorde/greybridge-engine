## test_overworld_controller.gd
## Unit tests for OverworldController (src/overworld/overworld_controller.gd).
##
## Run headlessly from the Godot project root (src/) with:
##   godot --headless --script ../tests/unit/overworld/test_overworld_controller.gd
##
## Exit code 0 = all assertions passed; 1 = one or more assertions failed.
extends SceneTree

const DiceRollerClass = preload("res://rules_engine/core/dice_roller.gd")
const OverworldControllerClass = preload("res://overworld/overworld_controller.gd")
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
	_test_controls_unlocked_by_default()
	_test_lock_controls()
	_test_unlock_controls()
	_test_controls_locked_changed_signal()
	_test_start_combat_locks_controls()
	_test_start_combat_emits_combat_ready()
	_test_start_combat_turn_order_sorted()
	_test_start_combat_clears_pending_rewards()
	_test_start_combat_saves_player_tile()
	_test_start_combat_default_player_tile_is_origin()
	_test_return_from_combat_unlocks_controls()
	_test_return_from_combat_stores_rewards()
	_test_return_from_combat_emits_combat_resolved()
	_test_return_from_combat_empty_rewards()
	_test_current_music_track_empty_by_default()
	_test_set_current_music_track()
	_test_start_combat_emits_combat_music_requested()
	_test_return_from_combat_emits_overworld_music_resumed()
	_test_return_from_combat_music_resumed_with_stored_track()
	_test_return_from_combat_music_resumed_empty_when_no_track_set()
	_test_start_map_transition_locks_controls()
	_test_start_map_transition_emits_signal()
	_test_start_map_transition_signal_carries_target_map()
	_test_start_map_transition_signal_carries_target_spawn()
	_test_set_current_map()
	_test_on_player_state_changed()
	_test_on_chest_opened_adds_id()
	_test_on_chest_opened_no_duplicates()
	_test_on_door_state_changed_open()
	_test_on_door_state_changed_close()
	_test_on_quest_flag_set()
	_test_on_trigger_fired_adds_id()
	_test_on_trigger_fired_no_duplicates()
	_test_capture_state_returns_snapshot()
	_test_capture_state_map_id()
	_test_capture_state_player_state()
	_test_capture_state_opened_chest_ids()
	_test_capture_state_door_states()
	_test_capture_state_quest_flags()
	_test_capture_state_fired_trigger_ids()
	_test_capture_state_independence()
	_test_restore_state_updates_internal_state()
	_test_restore_state_emits_signal()
	_test_restore_state_signal_carries_snapshot()
	_test_restore_state_overwrites_previous_state()


# ---------------------------------------------------------------------------
# controls_locked is false by default
# ---------------------------------------------------------------------------
func _test_controls_unlocked_by_default() -> void:
	print("_test_controls_unlocked_by_default")
	var oc := OverworldControllerClass.new()
	_check(oc.controls_locked == false, "controls_locked is false by default")
	oc.free()


# ---------------------------------------------------------------------------
# lock_controls() sets controls_locked to true
# ---------------------------------------------------------------------------
func _test_lock_controls() -> void:
	print("_test_lock_controls")
	var oc := OverworldControllerClass.new()
	oc.lock_controls()
	_check(oc.controls_locked == true, "controls_locked is true after lock_controls()")
	oc.free()


# ---------------------------------------------------------------------------
# unlock_controls() sets controls_locked to false
# ---------------------------------------------------------------------------
func _test_unlock_controls() -> void:
	print("_test_unlock_controls")
	var oc := OverworldControllerClass.new()
	oc.lock_controls()
	oc.unlock_controls()
	_check(oc.controls_locked == false, "controls_locked is false after unlock_controls()")
	oc.free()


# ---------------------------------------------------------------------------
# controls_locked_changed emits the correct values
# ---------------------------------------------------------------------------
func _test_controls_locked_changed_signal() -> void:
	print("_test_controls_locked_changed_signal")
	var oc := OverworldControllerClass.new()
	var signal_values: Array = []
	oc.controls_locked_changed.connect(func(locked: bool) -> void:
		signal_values.append(locked)
	)
	oc.lock_controls()
	oc.unlock_controls()
	_check(signal_values.size() == 2, "controls_locked_changed emitted twice")
	_check(signal_values[0] == true, "first emission: locked=true")
	_check(signal_values[1] == false, "second emission: locked=false")
	oc.free()


# ---------------------------------------------------------------------------
# start_combat() locks overworld controls
# ---------------------------------------------------------------------------
func _test_start_combat_locks_controls() -> void:
	print("_test_start_combat_locks_controls")
	var oc := OverworldControllerClass.new()
	var roller := DiceRollerClass.new(42)
	var actors: Array = [{"id": "hero", "dex_score": 14}]
	var positions: Dictionary = {"hero": Vector2i(0, 0)}
	oc.start_combat(actors, positions, roller)
	_check(oc.controls_locked == true, "controls_locked is true after start_combat()")
	oc.free()


# ---------------------------------------------------------------------------
# start_combat() emits combat_ready with turn_order and positions
# ---------------------------------------------------------------------------
func _test_start_combat_emits_combat_ready() -> void:
	print("_test_start_combat_emits_combat_ready")
	var oc := OverworldControllerClass.new()
	var roller := DiceRollerClass.new(10)
	var actors: Array = [
		{"id": "fighter", "dex_score": 12},
		{"id": "bandit", "dex_score": 10},
	]
	var positions: Dictionary = {"fighter": Vector2i(0, 0), "bandit": Vector2i(4, 0)}
	var received_order: Array = []
	var received_positions: Dictionary = {}
	oc.combat_ready.connect(func(to: Array, pos: Dictionary) -> void:
		received_order.append_array(to)
		received_positions.merge(pos)
	)
	oc.start_combat(actors, positions, roller)
	_check(received_order.size() == 2, "combat_ready received turn_order with 2 entries")
	_check(received_positions.has("fighter"), "combat_ready received positions with fighter key")
	_check(received_positions.has("bandit"), "combat_ready received positions with bandit key")
	oc.free()


# ---------------------------------------------------------------------------
# start_combat() turn order is sorted descending by initiative total
# ---------------------------------------------------------------------------
func _test_start_combat_turn_order_sorted() -> void:
	print("_test_start_combat_turn_order_sorted")
	var oc := OverworldControllerClass.new()
	var roller := DiceRollerClass.new(5)
	var actors: Array = [
		{"id": "a", "dex_score": 10},
		{"id": "b", "dex_score": 14},
		{"id": "c", "dex_score": 8},
	]
	var received_order: Array = []
	oc.combat_ready.connect(func(to: Array, _pos: Dictionary) -> void:
		received_order.append_array(to)
	)
	oc.start_combat(actors, {}, roller)
	_check(received_order.size() == 3, "turn order has 3 entries")
	for i: int in range(received_order.size() - 1):
		_check(
			received_order[i]["total"] >= received_order[i + 1]["total"],
			"entry %d total >= entry %d total" % [i, i + 1]
		)
	oc.free()


# ---------------------------------------------------------------------------
# start_combat() clears pending_rewards from a previous encounter
# ---------------------------------------------------------------------------
func _test_start_combat_clears_pending_rewards() -> void:
	print("_test_start_combat_clears_pending_rewards")
	var oc := OverworldControllerClass.new()
	oc.pending_rewards = ["gold_piece"]
	var roller := DiceRollerClass.new(0)
	oc.start_combat([{"id": "hero", "dex_score": 10}], {}, roller)
	_check(oc.pending_rewards.size() == 0, "pending_rewards cleared on start_combat()")
	oc.free()


# ---------------------------------------------------------------------------
# return_from_combat() unlocks controls
# ---------------------------------------------------------------------------
func _test_return_from_combat_unlocks_controls() -> void:
	print("_test_return_from_combat_unlocks_controls")
	var oc := OverworldControllerClass.new()
	oc.lock_controls()
	oc.return_from_combat([])
	_check(oc.controls_locked == false, "controls_locked is false after return_from_combat()")
	oc.free()


# ---------------------------------------------------------------------------
# return_from_combat() stores rewards in pending_rewards
# ---------------------------------------------------------------------------
func _test_return_from_combat_stores_rewards() -> void:
	print("_test_return_from_combat_stores_rewards")
	var oc := OverworldControllerClass.new()
	oc.return_from_combat(["gold_piece", "dagger"])
	_check(oc.pending_rewards.size() == 2, "pending_rewards contains 2 items")
	_check(oc.pending_rewards.has("gold_piece"), "gold_piece in pending_rewards")
	_check(oc.pending_rewards.has("dagger"), "dagger in pending_rewards")
	oc.free()


# ---------------------------------------------------------------------------
# return_from_combat() emits combat_resolved with the reward list
# ---------------------------------------------------------------------------
func _test_return_from_combat_emits_combat_resolved() -> void:
	print("_test_return_from_combat_emits_combat_resolved")
	var oc := OverworldControllerClass.new()
	var received_rewards: Array = []
	oc.combat_resolved.connect(func(r: Array) -> void:
		received_rewards.append_array(r)
	)
	oc.return_from_combat(["sword"])
	_check(received_rewards.size() == 1, "combat_resolved emitted with one reward")
	_check(received_rewards.has("sword"), "sword present in combat_resolved payload")
	oc.free()


# ---------------------------------------------------------------------------
# return_from_combat() with empty rewards list
# ---------------------------------------------------------------------------
func _test_return_from_combat_empty_rewards() -> void:
	print("_test_return_from_combat_empty_rewards")
	var oc := OverworldControllerClass.new()
	var signal_events: Array = []
	var received_rewards: Array = ["sentinel"]
	oc.combat_resolved.connect(func(r: Array) -> void:
		signal_events.append(true)
		received_rewards.clear()
		received_rewards.append_array(r)
	)
	oc.return_from_combat([])
	_check(signal_events.size() == 1, "combat_resolved emitted once with empty rewards")
	_check(received_rewards.size() == 0, "combat_resolved payload is empty array")
	oc.free()


# ---------------------------------------------------------------------------
# current_music_track is empty string by default
# ---------------------------------------------------------------------------
func _test_current_music_track_empty_by_default() -> void:
	print("_test_current_music_track_empty_by_default")
	var oc := OverworldControllerClass.new()
	_check(oc.current_music_track == "", "current_music_track is empty string by default")
# start_combat() saves player tile for return
# ---------------------------------------------------------------------------
func _test_start_combat_saves_player_tile() -> void:
	print("_test_start_combat_saves_player_tile")
	var oc := OverworldControllerClass.new()
	var roller := DiceRollerClass.new(1)
	var actors: Array = [{"id": "hero", "dex_score": 14}]
	oc.start_combat(actors, {}, roller, Vector2i(3, 7))
	_check(oc.saved_player_tile == Vector2i(3, 7),
		"saved_player_tile stores the tile passed to start_combat()")
	oc.free()


# ---------------------------------------------------------------------------
# set_current_music_track() stores the track id
# ---------------------------------------------------------------------------
func _test_set_current_music_track() -> void:
	print("_test_set_current_music_track")
	var oc := OverworldControllerClass.new()
	oc.set_current_music_track("road_theme")
	_check(oc.current_music_track == "road_theme", "current_music_track set by set_current_music_track()")
# start_combat() default player_tile is origin when not provided
# ---------------------------------------------------------------------------
func _test_start_combat_default_player_tile_is_origin() -> void:
	print("_test_start_combat_default_player_tile_is_origin")
	var oc := OverworldControllerClass.new()
	var roller := DiceRollerClass.new(1)
	oc.start_combat([{"id": "hero", "dex_score": 10}], {}, roller)
	_check(oc.saved_player_tile == Vector2i(0, 0),
		"saved_player_tile defaults to (0,0) when not provided")
	oc.free()


# ---------------------------------------------------------------------------
# start_combat() emits combat_music_requested
# ---------------------------------------------------------------------------
func _test_start_combat_emits_combat_music_requested() -> void:
	print("_test_start_combat_emits_combat_music_requested")
	var oc := OverworldControllerClass.new()
	var events: Array = []
	oc.combat_music_requested.connect(func() -> void:
		events.append(true)
	)
	var roller := DiceRollerClass.new(0)
	oc.start_combat([{"id": "hero", "dex_score": 10}], {}, roller)
	_check(events.size() == 1, "combat_music_requested emitted once on start_combat()")
# start_map_transition() locks overworld controls
# ---------------------------------------------------------------------------
func _test_start_map_transition_locks_controls() -> void:
	print("_test_start_map_transition_locks_controls")
	var oc := OverworldControllerClass.new()
	oc.start_map_transition("greybridge_town", Vector2i(1, 8))
	_check(oc.controls_locked == true,
		"controls_locked is true after start_map_transition()")
	oc.free()


# ---------------------------------------------------------------------------
# return_from_combat() emits overworld_music_resumed
# ---------------------------------------------------------------------------
func _test_return_from_combat_emits_overworld_music_resumed() -> void:
	print("_test_return_from_combat_emits_overworld_music_resumed")
	var oc := OverworldControllerClass.new()
	var events: Array = []
	oc.overworld_music_resumed.connect(func(_track_id: String) -> void:
		events.append(true)
	)
	oc.return_from_combat([])
	_check(events.size() == 1, "overworld_music_resumed emitted once on return_from_combat()")
# start_map_transition() emits map_transition_started
# ---------------------------------------------------------------------------
func _test_start_map_transition_emits_signal() -> void:
	print("_test_start_map_transition_emits_signal")
	var oc := OverworldControllerClass.new()
	var fired: Array = []
	oc.map_transition_started.connect(func(_m: String, _s: Vector2i) -> void:
		fired.append(true)
	)
	oc.start_map_transition("greybridge_town", Vector2i(1, 8))
	_check(fired.size() == 1, "map_transition_started emitted once")
	oc.free()


# ---------------------------------------------------------------------------
# return_from_combat() emits overworld_music_resumed with the stored track
# ---------------------------------------------------------------------------
func _test_return_from_combat_music_resumed_with_stored_track() -> void:
	print("_test_return_from_combat_music_resumed_with_stored_track")
	var oc := OverworldControllerClass.new()
	oc.set_current_music_track("forest_theme")
	var received_tracks: Array = []
	oc.overworld_music_resumed.connect(func(track_id: String) -> void:
		received_tracks.append(track_id)
	)
	oc.return_from_combat([])
	_check(received_tracks.size() == 1, "overworld_music_resumed emitted once")
	_check(received_tracks[0] == "forest_theme",
		"overworld_music_resumed carries the stored music track id")
# map_transition_started carries the target_map
# ---------------------------------------------------------------------------
func _test_start_map_transition_signal_carries_target_map() -> void:
	print("_test_start_map_transition_signal_carries_target_map")
	var oc := OverworldControllerClass.new()
	var maps: Array[String] = []
	oc.map_transition_started.connect(func(m: String, _s: Vector2i) -> void:
		maps.append(m)
	)
	oc.start_map_transition("greybridge_town", Vector2i(1, 8))
	_check(maps.size() == 1 and maps[0] == "greybridge_town",
		"map_transition_started carries correct target_map")
	oc.free()


# ---------------------------------------------------------------------------
# return_from_combat() emits overworld_music_resumed with empty string when no track set
# ---------------------------------------------------------------------------
func _test_return_from_combat_music_resumed_empty_when_no_track_set() -> void:
	print("_test_return_from_combat_music_resumed_empty_when_no_track_set")
	var oc := OverworldControllerClass.new()
	var received_tracks: Array = []
	oc.overworld_music_resumed.connect(func(track_id: String) -> void:
		received_tracks.append(track_id)
	)
	oc.return_from_combat([])
	_check(received_tracks.size() == 1, "overworld_music_resumed emitted once")
	_check(received_tracks[0] == "",
		"overworld_music_resumed carries empty string when no track was set")
	oc.free()
# map_transition_started carries the target_spawn
# ---------------------------------------------------------------------------
func _test_start_map_transition_signal_carries_target_spawn() -> void:
	print("_test_start_map_transition_signal_carries_target_spawn")
	var oc := OverworldControllerClass.new()
	var spawns: Array[Vector2i] = []
	oc.map_transition_started.connect(func(_m: String, s: Vector2i) -> void:
		spawns.append(s)
	)
	oc.start_map_transition("greybridge_town", Vector2i(3, 9))
	_check(spawns.size() == 1 and spawns[0] == Vector2i(3, 9),
		"map_transition_started carries correct target_spawn")
	oc.free()


# ---------------------------------------------------------------------------
# set_current_map() stores the map id
# ---------------------------------------------------------------------------
func _test_set_current_map() -> void:
	print("_test_set_current_map")
	var oc := OverworldControllerClass.new()
	oc.set_current_map("road_to_greybridge")
	var snap := oc.capture_state()
	_check(snap.map_id == "road_to_greybridge",
		"capture_state().map_id reflects set_current_map()")
	oc.free()


# ---------------------------------------------------------------------------
# on_player_state_changed() updates tracked position and facing
# ---------------------------------------------------------------------------
func _test_on_player_state_changed() -> void:
	print("_test_on_player_state_changed")
	var oc := OverworldControllerClass.new()
	oc.on_player_state_changed(Vector2i(5, 9), Vector2i(-1, 0))
	var snap := oc.capture_state()
	_check(snap.player_position == Vector2i(5, 9),
		"capture_state().player_position reflects on_player_state_changed()")
	_check(snap.player_facing == Vector2i(-1, 0),
		"capture_state().player_facing reflects on_player_state_changed()")
	oc.free()


# ---------------------------------------------------------------------------
# on_chest_opened() appends chest id
# ---------------------------------------------------------------------------
func _test_on_chest_opened_adds_id() -> void:
	print("_test_on_chest_opened_adds_id")
	var oc := OverworldControllerClass.new()
	oc.on_chest_opened("chest_1")
	var snap := oc.capture_state()
	_check(snap.opened_chest_ids.has("chest_1"),
		"capture_state().opened_chest_ids contains chest_1 after on_chest_opened()")
	oc.free()


# ---------------------------------------------------------------------------
# on_chest_opened() does not duplicate ids
# ---------------------------------------------------------------------------
func _test_on_chest_opened_no_duplicates() -> void:
	print("_test_on_chest_opened_no_duplicates")
	var oc := OverworldControllerClass.new()
	oc.on_chest_opened("chest_1")
	oc.on_chest_opened("chest_1")
	var snap := oc.capture_state()
	_check(snap.opened_chest_ids.size() == 1,
		"on_chest_opened() does not duplicate the same chest id")
	oc.free()


# ---------------------------------------------------------------------------
# on_door_state_changed() records open state
# ---------------------------------------------------------------------------
func _test_on_door_state_changed_open() -> void:
	print("_test_on_door_state_changed_open")
	var oc := OverworldControllerClass.new()
	oc.on_door_state_changed(Vector2i(3, 4), true)
	var snap := oc.capture_state()
	_check(snap.door_states.get("3,4") == true,
		"capture_state().door_states door at 3,4 is true after on_door_state_changed(open)")
	oc.free()


# ---------------------------------------------------------------------------
# on_door_state_changed() records closed state
# ---------------------------------------------------------------------------
func _test_on_door_state_changed_close() -> void:
	print("_test_on_door_state_changed_close")
	var oc := OverworldControllerClass.new()
	oc.on_door_state_changed(Vector2i(3, 4), true)
	oc.on_door_state_changed(Vector2i(3, 4), false)
	var snap := oc.capture_state()
	_check(snap.door_states.get("3,4") == false,
		"capture_state().door_states door at 3,4 is false after toggling closed")
	oc.free()


# ---------------------------------------------------------------------------
# on_quest_flag_set() stores the flag
# ---------------------------------------------------------------------------
func _test_on_quest_flag_set() -> void:
	print("_test_on_quest_flag_set")
	var oc := OverworldControllerClass.new()
	oc.on_quest_flag_set("met_merchant", true)
	var snap := oc.capture_state()
	_check(snap.quest_flags.get("met_merchant") == true,
		"capture_state().quest_flags contains met_merchant after on_quest_flag_set()")
	oc.free()


# ---------------------------------------------------------------------------
# on_trigger_fired() appends encounter id
# ---------------------------------------------------------------------------
func _test_on_trigger_fired_adds_id() -> void:
	print("_test_on_trigger_fired_adds_id")
	var oc := OverworldControllerClass.new()
	oc.on_trigger_fired("bandit_ambush")
	var snap := oc.capture_state()
	_check(snap.fired_trigger_ids.has("bandit_ambush"),
		"capture_state().fired_trigger_ids contains bandit_ambush after on_trigger_fired()")
	oc.free()


# ---------------------------------------------------------------------------
# on_trigger_fired() does not duplicate ids
# ---------------------------------------------------------------------------
func _test_on_trigger_fired_no_duplicates() -> void:
	print("_test_on_trigger_fired_no_duplicates")
	var oc := OverworldControllerClass.new()
	oc.on_trigger_fired("bandit_ambush")
	oc.on_trigger_fired("bandit_ambush")
	var snap := oc.capture_state()
	_check(snap.fired_trigger_ids.size() == 1,
		"on_trigger_fired() does not duplicate the same encounter id")
	oc.free()


# ---------------------------------------------------------------------------
# capture_state() returns an OverworldSnapshot instance
# ---------------------------------------------------------------------------
func _test_capture_state_returns_snapshot() -> void:
	print("_test_capture_state_returns_snapshot")
	var oc := OverworldControllerClass.new()
	var snap := oc.capture_state()
	_check(snap != null, "capture_state() returns a non-null snapshot")
	_check(snap is OverworldSnapshotClass, "capture_state() returns an OverworldSnapshot")
	oc.free()


# ---------------------------------------------------------------------------
# capture_state() includes map_id
# ---------------------------------------------------------------------------
func _test_capture_state_map_id() -> void:
	print("_test_capture_state_map_id")
	var oc := OverworldControllerClass.new()
	oc.set_current_map("greybridge_town")
	var snap := oc.capture_state()
	_check(snap.map_id == "greybridge_town", "capture_state() map_id is greybridge_town")
	oc.free()


# ---------------------------------------------------------------------------
# capture_state() includes player position and facing
# ---------------------------------------------------------------------------
func _test_capture_state_player_state() -> void:
	print("_test_capture_state_player_state")
	var oc := OverworldControllerClass.new()
	oc.on_player_state_changed(Vector2i(2, 6), Vector2i(0, 1))
	var snap := oc.capture_state()
	_check(snap.player_position == Vector2i(2, 6), "capture_state() player_position is (2,6)")
	_check(snap.player_facing == Vector2i(0, 1), "capture_state() player_facing is (0,1)")
	oc.free()


# ---------------------------------------------------------------------------
# capture_state() includes opened_chest_ids
# ---------------------------------------------------------------------------
func _test_capture_state_opened_chest_ids() -> void:
	print("_test_capture_state_opened_chest_ids")
	var oc := OverworldControllerClass.new()
	oc.on_chest_opened("chest_1")
	oc.on_chest_opened("chest_bandit_stash")
	var snap := oc.capture_state()
	_check(snap.opened_chest_ids.size() == 2, "capture_state() has 2 opened chest ids")
	_check(snap.opened_chest_ids.has("chest_1"), "capture_state() chest_1 present")
	_check(snap.opened_chest_ids.has("chest_bandit_stash"),
		"capture_state() chest_bandit_stash present")
	oc.free()


# ---------------------------------------------------------------------------
# capture_state() includes door_states
# ---------------------------------------------------------------------------
func _test_capture_state_door_states() -> void:
	print("_test_capture_state_door_states")
	var oc := OverworldControllerClass.new()
	oc.on_door_state_changed(Vector2i(5, 3), true)
	var snap := oc.capture_state()
	_check(snap.door_states.get("5,3") == true, "capture_state() door at 5,3 is open")
	oc.free()


# ---------------------------------------------------------------------------
# capture_state() includes quest_flags
# ---------------------------------------------------------------------------
func _test_capture_state_quest_flags() -> void:
	print("_test_capture_state_quest_flags")
	var oc := OverworldControllerClass.new()
	oc.on_quest_flag_set("scout_rescued", true)
	var snap := oc.capture_state()
	_check(snap.quest_flags.get("scout_rescued") == true,
		"capture_state() quest_flags contains scout_rescued")
	oc.free()


# ---------------------------------------------------------------------------
# capture_state() includes fired_trigger_ids
# ---------------------------------------------------------------------------
func _test_capture_state_fired_trigger_ids() -> void:
	print("_test_capture_state_fired_trigger_ids")
	var oc := OverworldControllerClass.new()
	oc.on_trigger_fired("encounter_road_1")
	var snap := oc.capture_state()
	_check(snap.fired_trigger_ids.has("encounter_road_1"),
		"capture_state() fired_trigger_ids contains encounter_road_1")
	oc.free()


# ---------------------------------------------------------------------------
# capture_state() snapshot is independent of the controller's internal arrays
# ---------------------------------------------------------------------------
func _test_capture_state_independence() -> void:
	print("_test_capture_state_independence")
	var oc := OverworldControllerClass.new()
	oc.on_chest_opened("chest_1")
	var snap := oc.capture_state()
	oc.on_chest_opened("chest_2")
	_check(snap.opened_chest_ids.size() == 1,
		"snapshot opened_chest_ids is independent of controller (captured before second chest)")
	oc.free()


# ---------------------------------------------------------------------------
# restore_state() restores all internal state fields
# ---------------------------------------------------------------------------
func _test_restore_state_updates_internal_state() -> void:
	print("_test_restore_state_updates_internal_state")
	var oc := OverworldControllerClass.new()
	var snap := OverworldSnapshotClass.new()
	snap.map_id = "road_to_greybridge"
	snap.player_position = Vector2i(4, 3)
	snap.player_facing = Vector2i(0, -1)
	snap.opened_chest_ids = ["chest_1"]
	snap.door_states = {"5,3": true}
	snap.quest_flags = {"met_merchant": true}
	snap.fired_trigger_ids = ["bandit_ambush"]
	oc.restore_state(snap)
	var captured := oc.capture_state()
	_check(captured.map_id == "road_to_greybridge", "restore_state() map_id restored")
	_check(captured.player_position == Vector2i(4, 3),
		"restore_state() player_position restored")
	_check(captured.player_facing == Vector2i(0, -1),
		"restore_state() player_facing restored")
	_check(captured.opened_chest_ids.has("chest_1"),
		"restore_state() opened_chest_ids restored")
	_check(captured.door_states.get("5,3") == true, "restore_state() door_states restored")
	_check(captured.quest_flags.get("met_merchant") == true,
		"restore_state() quest_flags restored")
	_check(captured.fired_trigger_ids.has("bandit_ambush"),
		"restore_state() fired_trigger_ids restored")
	oc.free()


# ---------------------------------------------------------------------------
# restore_state() emits overworld_state_restored
# ---------------------------------------------------------------------------
func _test_restore_state_emits_signal() -> void:
	print("_test_restore_state_emits_signal")
	var oc := OverworldControllerClass.new()
	var events: Array = []
	oc.overworld_state_restored.connect(func(_s) -> void:
		events.append(true)
	)
	oc.restore_state(OverworldSnapshotClass.new())
	_check(events.size() == 1, "overworld_state_restored emitted once after restore_state()")
	oc.free()


# ---------------------------------------------------------------------------
# restore_state() signal carries the snapshot
# ---------------------------------------------------------------------------
func _test_restore_state_signal_carries_snapshot() -> void:
	print("_test_restore_state_signal_carries_snapshot")
	var oc := OverworldControllerClass.new()
	var received: Array = []
	oc.overworld_state_restored.connect(func(s) -> void:
		received.append(s)
	)
	var snap := OverworldSnapshotClass.new()
	snap.map_id = "greybridge_town"
	oc.restore_state(snap)
	_check(received.size() == 1, "overworld_state_restored received one payload")
	_check(received[0].map_id == "greybridge_town",
		"overworld_state_restored payload has correct map_id")
	oc.free()


# ---------------------------------------------------------------------------
# restore_state() overwrites previously tracked state
# ---------------------------------------------------------------------------
func _test_restore_state_overwrites_previous_state() -> void:
	print("_test_restore_state_overwrites_previous_state")
	var oc := OverworldControllerClass.new()
	oc.set_current_map("old_map")
	oc.on_chest_opened("chest_old")
	var snap := OverworldSnapshotClass.new()
	snap.map_id = "new_map"
	snap.opened_chest_ids = ["chest_new"]
	oc.restore_state(snap)
	var captured := oc.capture_state()
	_check(captured.map_id == "new_map",
		"restore_state() overwrites map_id from previous state")
	_check(not captured.opened_chest_ids.has("chest_old"),
		"restore_state() clears previous opened_chest_ids")
	_check(captured.opened_chest_ids.has("chest_new"),
		"restore_state() installs new opened_chest_ids")
	oc.free()

