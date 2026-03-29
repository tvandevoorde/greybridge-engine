## test_collision_debug_overlay.gd
## Unit tests for CollisionDebugOverlay
## (src/overworld/collision_debug_overlay.gd).
##
## Run headlessly from the Godot project root (src/) with:
##   godot --headless --script ./tests/unit/overworld/test_collision_debug_overlay.gd
##
## Exit code 0 = all assertions passed; 1 = one or more assertions failed.
extends SceneTree

const CollisionDebugOverlayClass = preload("res://overworld/collision_debug_overlay.gd")

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
	_test_debug_invisible_by_default()
	_test_tiles_empty_by_default()
	_test_tile_size_default()
	_test_set_tiles_stores_tiles()
	_test_set_tiles_stores_tile_size()
	_test_set_tiles_duplicates_input()
	_test_set_debug_visible_true()
	_test_set_debug_visible_false()
	_test_set_debug_visible_emits_signal_on_change()
	_test_set_debug_visible_no_signal_when_same_value()
	_test_set_debug_visible_toggle_sequence()
	_test_get_tiles_returns_copy()


# ---------------------------------------------------------------------------
# Default state
# ---------------------------------------------------------------------------
func _test_debug_invisible_by_default() -> void:
	print("_test_debug_invisible_by_default")
	var overlay := CollisionDebugOverlayClass.new()
	_check(overlay.is_debug_visible() == false, "debug overlay is invisible by default")
	overlay.free()


func _test_tiles_empty_by_default() -> void:
	print("_test_tiles_empty_by_default")
	var overlay := CollisionDebugOverlayClass.new()
	_check(overlay.get_tiles().size() == 0, "tiles array is empty by default")
	overlay.free()


func _test_tile_size_default() -> void:
	print("_test_tile_size_default")
	var overlay := CollisionDebugOverlayClass.new()
	_check(overlay.get_tile_size() == 32, "default tile size is 32")
	overlay.free()


# ---------------------------------------------------------------------------
# set_tiles
# ---------------------------------------------------------------------------
func _test_set_tiles_stores_tiles() -> void:
	print("_test_set_tiles_stores_tiles")
	var overlay := CollisionDebugOverlayClass.new()
	var tiles := [Vector2i(1, 2), Vector2i(3, 4)]
	overlay.set_tiles(tiles, 32)
	var stored := overlay.get_tiles()
	_check(stored.size() == 2, "set_tiles stores 2 tile positions")
	_check(stored.has(Vector2i(1, 2)), "stored tiles contain (1, 2)")
	_check(stored.has(Vector2i(3, 4)), "stored tiles contain (3, 4)")
	overlay.free()


func _test_set_tiles_stores_tile_size() -> void:
	print("_test_set_tiles_stores_tile_size")
	var overlay := CollisionDebugOverlayClass.new()
	overlay.set_tiles([], 64)
	_check(overlay.get_tile_size() == 64, "set_tiles stores the tile size")
	overlay.free()


func _test_set_tiles_duplicates_input() -> void:
	print("_test_set_tiles_duplicates_input")
	var overlay := CollisionDebugOverlayClass.new()
	var original := [Vector2i(5, 5)]
	overlay.set_tiles(original, 32)
	original.clear()
	_check(overlay.get_tiles().size() == 1,
		"set_tiles duplicates the input array (modifying original does not affect overlay)")
	overlay.free()


# ---------------------------------------------------------------------------
# set_debug_visible
# ---------------------------------------------------------------------------
func _test_set_debug_visible_true() -> void:
	print("_test_set_debug_visible_true")
	var overlay := CollisionDebugOverlayClass.new()
	overlay.set_debug_visible(true)
	_check(overlay.is_debug_visible() == true, "is_debug_visible returns true after set_debug_visible(true)")
	overlay.free()


func _test_set_debug_visible_false() -> void:
	print("_test_set_debug_visible_false")
	var overlay := CollisionDebugOverlayClass.new()
	overlay.set_debug_visible(true)
	overlay.set_debug_visible(false)
	_check(overlay.is_debug_visible() == false,
		"is_debug_visible returns false after set_debug_visible(false)")
	overlay.free()


func _test_set_debug_visible_emits_signal_on_change() -> void:
	print("_test_set_debug_visible_emits_signal_on_change")
	var overlay := CollisionDebugOverlayClass.new()
	var received: Array = []
	overlay.debug_visibility_changed.connect(func(v: bool) -> void:
		received.append(v)
	)
	overlay.set_debug_visible(true)
	_check(received.size() == 1, "debug_visibility_changed emitted once when toggled on")
	_check(received[0] == true, "signal payload is true when toggling on")
	overlay.set_debug_visible(false)
	_check(received.size() == 2, "debug_visibility_changed emitted again when toggled off")
	_check(received[1] == false, "signal payload is false when toggling off")
	overlay.free()


func _test_set_debug_visible_no_signal_when_same_value() -> void:
	print("_test_set_debug_visible_no_signal_when_same_value")
	var overlay := CollisionDebugOverlayClass.new()
	var received: Array = []
	overlay.debug_visibility_changed.connect(func(v: bool) -> void:
		received.append(v)
	)
	overlay.set_debug_visible(false)
	_check(received.size() == 0, "no signal emitted when visibility is already false")
	overlay.set_debug_visible(true)
	overlay.set_debug_visible(true)
	_check(received.size() == 1, "no duplicate signal when set_debug_visible called twice with true")
	overlay.free()


func _test_set_debug_visible_toggle_sequence() -> void:
	print("_test_set_debug_visible_toggle_sequence")
	var overlay := CollisionDebugOverlayClass.new()
	_check(overlay.is_debug_visible() == false, "starts invisible")
	overlay.set_debug_visible(true)
	_check(overlay.is_debug_visible() == true, "visible after first toggle")
	overlay.set_debug_visible(false)
	_check(overlay.is_debug_visible() == false, "invisible after second toggle")
	overlay.free()


# ---------------------------------------------------------------------------
# get_tiles returns a copy
# ---------------------------------------------------------------------------
func _test_get_tiles_returns_copy() -> void:
	print("_test_get_tiles_returns_copy")
	var overlay := CollisionDebugOverlayClass.new()
	overlay.set_tiles([Vector2i(2, 2)], 32)
	var copy := overlay.get_tiles()
	copy.clear()
	_check(overlay.get_tiles().size() == 1,
		"get_tiles returns a copy; clearing it does not affect stored tiles")
	overlay.free()
