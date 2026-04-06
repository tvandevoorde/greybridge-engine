## test_fog_of_war_controller.gd
## Unit tests for FogOfWarController
## (src/overworld/fog_of_war_controller.gd).
##
## Run headlessly from the Godot project root (src/) with:
##   godot --headless --script ./tests/unit/overworld/test_fog_of_war_controller.gd
##
## Exit code 0 = all assertions passed; 1 = one or more assertions failed.
extends SceneTree

const FogOfWarControllerClass = preload("res://overworld/fog_of_war_controller.gd")

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
	_test_fog_disabled_by_default()
	_test_default_visibility_radius()
	_test_get_visible_tiles_empty_by_default()
	_test_enable_sets_fog_enabled()
	_test_enable_sets_visibility_radius()
	_test_disable_clears_fog_enabled()
	_test_update_position_no_effect_when_disabled()
	_test_update_position_emits_visibility_changed()
	_test_update_position_correct_tile_count_radius_one()
	_test_update_position_includes_player_tile()
	_test_update_position_updates_get_visible_tiles()
	_test_disable_emits_visibility_changed_empty()
	_test_visibility_changed_on_each_move()
	_test_update_position_no_signal_when_fog_disabled()


# ---------------------------------------------------------------------------
# Default state
# ---------------------------------------------------------------------------
func _test_fog_disabled_by_default() -> void:
	print("_test_fog_disabled_by_default")
	var ctrl := FogOfWarControllerClass.new()
	_check(ctrl.fog_enabled == false, "fog_enabled is false by default")
	ctrl.free()


func _test_default_visibility_radius() -> void:
	print("_test_default_visibility_radius")
	var ctrl := FogOfWarControllerClass.new()
	_check(ctrl.visibility_radius == 5, "visibility_radius defaults to 5")
	ctrl.free()


func _test_get_visible_tiles_empty_by_default() -> void:
	print("_test_get_visible_tiles_empty_by_default")
	var ctrl := FogOfWarControllerClass.new()
	_check(ctrl.get_visible_tiles().size() == 0, "get_visible_tiles() returns empty array by default")
	ctrl.free()


# ---------------------------------------------------------------------------
# enable()
# ---------------------------------------------------------------------------
func _test_enable_sets_fog_enabled() -> void:
	print("_test_enable_sets_fog_enabled")
	var ctrl := FogOfWarControllerClass.new()
	ctrl.enable(4)
	_check(ctrl.fog_enabled == true, "fog_enabled is true after enable()")
	ctrl.free()


func _test_enable_sets_visibility_radius() -> void:
	print("_test_enable_sets_visibility_radius")
	var ctrl := FogOfWarControllerClass.new()
	ctrl.enable(7)
	_check(ctrl.visibility_radius == 7, "visibility_radius updated by enable()")
	ctrl.free()


# ---------------------------------------------------------------------------
# disable()
# ---------------------------------------------------------------------------
func _test_disable_clears_fog_enabled() -> void:
	print("_test_disable_clears_fog_enabled")
	var ctrl := FogOfWarControllerClass.new()
	ctrl.enable(3)
	ctrl.disable()
	_check(ctrl.fog_enabled == false, "fog_enabled is false after disable()")
	ctrl.free()


func _test_disable_emits_visibility_changed_empty() -> void:
	print("_test_disable_emits_visibility_changed_empty")
	var ctrl := FogOfWarControllerClass.new()
	ctrl.enable(3)
	ctrl.update_position(Vector2i(2, 2))
	var received: Array = []
	ctrl.visibility_changed.connect(func(tiles: Array) -> void:
		received.append(tiles.duplicate())
	)
	ctrl.disable()
	_check(received.size() == 1, "visibility_changed emitted once on disable()")
	_check(received[0].size() == 0, "payload is empty array when fog is disabled")
	ctrl.free()


# ---------------------------------------------------------------------------
# update_position() — fog disabled
# ---------------------------------------------------------------------------
func _test_update_position_no_effect_when_disabled() -> void:
	print("_test_update_position_no_effect_when_disabled")
	var ctrl := FogOfWarControllerClass.new()
	ctrl.update_position(Vector2i(5, 5))
	_check(ctrl.get_visible_tiles().size() == 0,
		"update_position() has no effect when fog is disabled")
	ctrl.free()


func _test_update_position_no_signal_when_fog_disabled() -> void:
	print("_test_update_position_no_signal_when_fog_disabled")
	var ctrl := FogOfWarControllerClass.new()
	var events: Array = []
	ctrl.visibility_changed.connect(func(_tiles: Array) -> void: events.append(true))
	ctrl.update_position(Vector2i(3, 3))
	_check(events.size() == 0, "visibility_changed not emitted when fog is disabled")
	ctrl.free()


# ---------------------------------------------------------------------------
# update_position() — fog enabled
# ---------------------------------------------------------------------------
func _test_update_position_emits_visibility_changed() -> void:
	print("_test_update_position_emits_visibility_changed")
	var ctrl := FogOfWarControllerClass.new()
	ctrl.enable(2)
	var events: Array = []
	ctrl.visibility_changed.connect(func(_tiles: Array) -> void: events.append(true))
	ctrl.update_position(Vector2i(0, 0))
	_check(events.size() == 1, "visibility_changed emitted once on update_position()")
	ctrl.free()


func _test_update_position_correct_tile_count_radius_one() -> void:
	print("_test_update_position_correct_tile_count_radius_one")
	var ctrl := FogOfWarControllerClass.new()
	ctrl.enable(1)
	var received_tiles: Array = []
	ctrl.visibility_changed.connect(func(tiles: Array) -> void:
		received_tiles.append(tiles.duplicate())
	)
	ctrl.update_position(Vector2i(4, 4))
	_check(received_tiles.size() == 1, "visibility_changed emitted once")
	_check(received_tiles[0].size() == 9, "radius 1 produces 9 visible tiles (3×3)")
	ctrl.free()


func _test_update_position_includes_player_tile() -> void:
	print("_test_update_position_includes_player_tile")
	var ctrl := FogOfWarControllerClass.new()
	ctrl.enable(3)
	var received_tiles: Array = []
	ctrl.visibility_changed.connect(func(tiles: Array) -> void:
		received_tiles.append(tiles.duplicate())
	)
	var player_pos := Vector2i(6, 2)
	ctrl.update_position(player_pos)
	_check(received_tiles[0].has(player_pos), "player's own tile is always visible")
	ctrl.free()


func _test_update_position_updates_get_visible_tiles() -> void:
	print("_test_update_position_updates_get_visible_tiles")
	var ctrl := FogOfWarControllerClass.new()
	ctrl.enable(1)
	ctrl.update_position(Vector2i(3, 3))
	var tiles := ctrl.get_visible_tiles()
	_check(tiles.size() == 9, "get_visible_tiles() returns 9 tiles after update with radius 1")
	_check(tiles.has(Vector2i(3, 3)), "player tile is in get_visible_tiles()")
	ctrl.free()


# ---------------------------------------------------------------------------
# visibility_changed emitted on each move
# ---------------------------------------------------------------------------
func _test_visibility_changed_on_each_move() -> void:
	print("_test_visibility_changed_on_each_move")
	var ctrl := FogOfWarControllerClass.new()
	ctrl.enable(2)
	var events: Array = []
	ctrl.visibility_changed.connect(func(_tiles: Array) -> void: events.append(true))
	ctrl.update_position(Vector2i(0, 0))
	ctrl.update_position(Vector2i(1, 0))
	ctrl.update_position(Vector2i(2, 0))
	_check(events.size() == 3, "visibility_changed emitted for each update_position() call")
	ctrl.free()
