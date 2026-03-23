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
	oc.free()


# ---------------------------------------------------------------------------
# set_current_music_track() stores the track id
# ---------------------------------------------------------------------------
func _test_set_current_music_track() -> void:
	print("_test_set_current_music_track")
	var oc := OverworldControllerClass.new()
	oc.set_current_music_track("road_theme")
	_check(oc.current_music_track == "road_theme", "current_music_track set by set_current_music_track()")
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
