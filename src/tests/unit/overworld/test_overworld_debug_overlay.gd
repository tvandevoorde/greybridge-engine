## test_overworld_debug_overlay.gd
## Unit tests for OverworldDebugOverlay
## (src/overworld/overworld_debug_overlay.gd).
##
## Run headlessly from the Godot project root (src/) with:
##   godot --headless --script ./tests/unit/overworld/test_overworld_debug_overlay.gd
##
## Exit code 0 = all assertions passed; 1 = one or more assertions failed.
extends SceneTree

const OverworldDebugOverlayClass = preload("res://overworld/overworld_debug_overlay.gd")

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
	_test_collision_debug_invisible_by_default()
	_test_trigger_debug_invisible_by_default()
	_test_player_tile_zero_by_default()
	_test_quest_flags_empty_by_default()
	_test_toggle_collision_debug_turns_on()
	_test_toggle_collision_debug_turns_off_after_second_call()
	_test_toggle_collision_debug_emits_signal()
	_test_toggle_trigger_debug_turns_on()
	_test_toggle_trigger_debug_turns_off_after_second_call()
	_test_toggle_trigger_debug_emits_signal()
	_test_collision_and_trigger_toggle_independently()
	_test_update_player_tile_stores_tile()
	_test_update_player_tile_emits_signal()
	_test_update_player_tile_emits_correct_value()
	_test_update_quest_flags_stores_flags()
	_test_update_quest_flags_emits_signal()
	_test_update_quest_flags_emits_copy()
	_test_update_quest_flags_stores_copy()
	_test_get_quest_flags_returns_copy()


# ---------------------------------------------------------------------------
# Default state
# ---------------------------------------------------------------------------
func _test_collision_debug_invisible_by_default() -> void:
	print("_test_collision_debug_invisible_by_default")
	var overlay := OverworldDebugOverlayClass.new()
	_check(overlay.is_collision_debug_visible() == false,
		"collision debug is invisible by default")
	overlay.free()


func _test_trigger_debug_invisible_by_default() -> void:
	print("_test_trigger_debug_invisible_by_default")
	var overlay := OverworldDebugOverlayClass.new()
	_check(overlay.is_trigger_debug_visible() == false,
		"trigger debug is invisible by default")
	overlay.free()


func _test_player_tile_zero_by_default() -> void:
	print("_test_player_tile_zero_by_default")
	var overlay := OverworldDebugOverlayClass.new()
	_check(overlay.get_player_tile() == Vector2i(0, 0),
		"player tile is (0, 0) by default")
	overlay.free()


func _test_quest_flags_empty_by_default() -> void:
	print("_test_quest_flags_empty_by_default")
	var overlay := OverworldDebugOverlayClass.new()
	_check(overlay.get_quest_flags().is_empty(),
		"quest flags dictionary is empty by default")
	overlay.free()


# ---------------------------------------------------------------------------
# toggle_collision_debug
# ---------------------------------------------------------------------------
func _test_toggle_collision_debug_turns_on() -> void:
	print("_test_toggle_collision_debug_turns_on")
	var overlay := OverworldDebugOverlayClass.new()
	overlay.toggle_collision_debug()
	_check(overlay.is_collision_debug_visible() == true,
		"collision debug is visible after first toggle")
	overlay.free()


func _test_toggle_collision_debug_turns_off_after_second_call() -> void:
	print("_test_toggle_collision_debug_turns_off_after_second_call")
	var overlay := OverworldDebugOverlayClass.new()
	overlay.toggle_collision_debug()
	overlay.toggle_collision_debug()
	_check(overlay.is_collision_debug_visible() == false,
		"collision debug is invisible after second toggle")
	overlay.free()


func _test_toggle_collision_debug_emits_signal() -> void:
	print("_test_toggle_collision_debug_emits_signal")
	var overlay := OverworldDebugOverlayClass.new()
	var received: Array = []
	overlay.collision_debug_toggled.connect(func(v: bool) -> void:
		received.append(v)
	)
	overlay.toggle_collision_debug()
	_check(received.size() == 1, "collision_debug_toggled emitted once on first toggle")
	_check(received[0] == true, "signal payload is true on first toggle")
	overlay.toggle_collision_debug()
	_check(received.size() == 2, "collision_debug_toggled emitted again on second toggle")
	_check(received[1] == false, "signal payload is false on second toggle")
	overlay.free()


# ---------------------------------------------------------------------------
# toggle_trigger_debug
# ---------------------------------------------------------------------------
func _test_toggle_trigger_debug_turns_on() -> void:
	print("_test_toggle_trigger_debug_turns_on")
	var overlay := OverworldDebugOverlayClass.new()
	overlay.toggle_trigger_debug()
	_check(overlay.is_trigger_debug_visible() == true,
		"trigger debug is visible after first toggle")
	overlay.free()


func _test_toggle_trigger_debug_turns_off_after_second_call() -> void:
	print("_test_toggle_trigger_debug_turns_off_after_second_call")
	var overlay := OverworldDebugOverlayClass.new()
	overlay.toggle_trigger_debug()
	overlay.toggle_trigger_debug()
	_check(overlay.is_trigger_debug_visible() == false,
		"trigger debug is invisible after second toggle")
	overlay.free()


func _test_toggle_trigger_debug_emits_signal() -> void:
	print("_test_toggle_trigger_debug_emits_signal")
	var overlay := OverworldDebugOverlayClass.new()
	var received: Array = []
	overlay.trigger_debug_toggled.connect(func(v: bool) -> void:
		received.append(v)
	)
	overlay.toggle_trigger_debug()
	_check(received.size() == 1, "trigger_debug_toggled emitted once on first toggle")
	_check(received[0] == true, "signal payload is true on first toggle")
	overlay.toggle_trigger_debug()
	_check(received.size() == 2, "trigger_debug_toggled emitted again on second toggle")
	_check(received[1] == false, "signal payload is false on second toggle")
	overlay.free()


func _test_collision_and_trigger_toggle_independently() -> void:
	print("_test_collision_and_trigger_toggle_independently")
	var overlay := OverworldDebugOverlayClass.new()
	overlay.toggle_collision_debug()
	_check(overlay.is_collision_debug_visible() == true,
		"collision debug on after toggle")
	_check(overlay.is_trigger_debug_visible() == false,
		"trigger debug remains off when only collision is toggled")
	overlay.toggle_trigger_debug()
	_check(overlay.is_collision_debug_visible() == true,
		"collision debug stays on when trigger is toggled")
	_check(overlay.is_trigger_debug_visible() == true,
		"trigger debug on after its own toggle")
	overlay.free()


# ---------------------------------------------------------------------------
# update_player_tile
# ---------------------------------------------------------------------------
func _test_update_player_tile_stores_tile() -> void:
	print("_test_update_player_tile_stores_tile")
	var overlay := OverworldDebugOverlayClass.new()
	overlay.update_player_tile(Vector2i(5, 7))
	_check(overlay.get_player_tile() == Vector2i(5, 7),
		"get_player_tile returns the tile set by update_player_tile")
	overlay.free()


func _test_update_player_tile_emits_signal() -> void:
	print("_test_update_player_tile_emits_signal")
	var overlay := OverworldDebugOverlayClass.new()
	var received: Array = []
	overlay.player_tile_changed.connect(func(t: Vector2i) -> void:
		received.append(t)
	)
	overlay.update_player_tile(Vector2i(3, 4))
	_check(received.size() == 1, "player_tile_changed emitted once")
	overlay.free()


func _test_update_player_tile_emits_correct_value() -> void:
	print("_test_update_player_tile_emits_correct_value")
	var overlay := OverworldDebugOverlayClass.new()
	var tiles: Array[Vector2i] = []
	overlay.player_tile_changed.connect(func(t: Vector2i) -> void:
		tiles.append(t)
	)
	overlay.update_player_tile(Vector2i(9, 2))
	_check(tiles.size() == 1, "player_tile_changed emitted once")
	_check(tiles[0] == Vector2i(9, 2), "signal carries the correct tile value")
	overlay.free()


# ---------------------------------------------------------------------------
# update_quest_flags
# ---------------------------------------------------------------------------
func _test_update_quest_flags_stores_flags() -> void:
	print("_test_update_quest_flags_stores_flags")
	var overlay := OverworldDebugOverlayClass.new()
	overlay.update_quest_flags({"merchant_met": true, "chest_opened": false})
	var flags := overlay.get_quest_flags()
	_check(flags.get("merchant_met") == true, "merchant_met flag stored correctly")
	_check(flags.get("chest_opened") == false, "chest_opened flag stored correctly")
	overlay.free()


func _test_update_quest_flags_emits_signal() -> void:
	print("_test_update_quest_flags_emits_signal")
	var overlay := OverworldDebugOverlayClass.new()
	var received: Array = []
	overlay.quest_flags_changed.connect(func(f: Dictionary) -> void:
		received.append(f)
	)
	overlay.update_quest_flags({"flag_a": true})
	_check(received.size() == 1, "quest_flags_changed emitted once")
	overlay.free()


func _test_update_quest_flags_emits_copy() -> void:
	print("_test_update_quest_flags_emits_copy")
	var overlay := OverworldDebugOverlayClass.new()
	var snapshots: Array = []
	overlay.quest_flags_changed.connect(func(f: Dictionary) -> void:
		snapshots.append(f)
	)
	overlay.update_quest_flags({"flag_a": true})
	# Mutating the emitted snapshot must not affect stored flags.
	if snapshots.size() > 0:
		snapshots[0]["injected"] = true
	_check(not overlay.get_quest_flags().has("injected"),
		"mutating emitted flags copy does not affect stored flags")
	overlay.free()


func _test_update_quest_flags_stores_copy() -> void:
	print("_test_update_quest_flags_stores_copy")
	var overlay := OverworldDebugOverlayClass.new()
	var original := {"flag_b": true}
	overlay.update_quest_flags(original)
	original["injected"] = true
	_check(not overlay.get_quest_flags().has("injected"),
		"update_quest_flags stores a copy; mutating original does not affect stored flags")
	overlay.free()


func _test_get_quest_flags_returns_copy() -> void:
	print("_test_get_quest_flags_returns_copy")
	var overlay := OverworldDebugOverlayClass.new()
	overlay.update_quest_flags({"flag_c": true})
	var copy := overlay.get_quest_flags()
	copy["injected"] = true
	_check(not overlay.get_quest_flags().has("injected"),
		"get_quest_flags returns a copy; mutating it does not affect stored flags")
	overlay.free()
