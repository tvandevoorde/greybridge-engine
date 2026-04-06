## test_visibility_calculator.gd
## Unit tests for VisibilityCalculator
## (src/rules_engine/core/visibility_calculator.gd).
##
## Run headlessly from the Godot project root (src/) with:
##   godot --headless --script ./tests/unit/rules_engine/test_visibility_calculator.gd
##
## Exit code 0 = all assertions passed; 1 = one or more assertions failed.
extends SceneTree

const VisibilityCalculatorClass = preload("res://rules_engine/core/visibility_calculator.gd")

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
	_test_radius_zero_returns_only_center()
	_test_radius_one_returns_nine_tiles()
	_test_radius_two_returns_twenty_five_tiles()
	_test_center_is_included()
	_test_tiles_are_within_chebyshev_radius()
	_test_no_duplicate_tiles()
	_test_negative_radius_treated_as_zero()
	_test_non_origin_center()
	_test_all_corners_included_radius_one()


# ---------------------------------------------------------------------------
# Radius 0 — only the center tile
# ---------------------------------------------------------------------------
func _test_radius_zero_returns_only_center() -> void:
	print("_test_radius_zero_returns_only_center")
	var calc := VisibilityCalculatorClass.new()
	var tiles := calc.compute_visible_tiles(Vector2i(3, 4), 0)
	_check(tiles.size() == 1, "radius 0 returns exactly one tile")
	_check(tiles[0] == Vector2i(3, 4), "that tile is the center itself")


# ---------------------------------------------------------------------------
# Radius 1 — 3×3 square = 9 tiles
# ---------------------------------------------------------------------------
func _test_radius_one_returns_nine_tiles() -> void:
	print("_test_radius_one_returns_nine_tiles")
	var calc := VisibilityCalculatorClass.new()
	var tiles := calc.compute_visible_tiles(Vector2i(0, 0), 1)
	_check(tiles.size() == 9, "radius 1 returns 9 tiles (3×3 square)")


# ---------------------------------------------------------------------------
# Radius 2 — 5×5 square = 25 tiles
# ---------------------------------------------------------------------------
func _test_radius_two_returns_twenty_five_tiles() -> void:
	print("_test_radius_two_returns_twenty_five_tiles")
	var calc := VisibilityCalculatorClass.new()
	var tiles := calc.compute_visible_tiles(Vector2i(0, 0), 2)
	_check(tiles.size() == 25, "radius 2 returns 25 tiles (5×5 square)")


# ---------------------------------------------------------------------------
# Center tile is always included
# ---------------------------------------------------------------------------
func _test_center_is_included() -> void:
	print("_test_center_is_included")
	var calc := VisibilityCalculatorClass.new()
	var center := Vector2i(5, 7)
	var tiles := calc.compute_visible_tiles(center, 3)
	_check(tiles.has(center), "center tile is always included in visible set")


# ---------------------------------------------------------------------------
# All returned tiles are within the Chebyshev radius
# ---------------------------------------------------------------------------
func _test_tiles_are_within_chebyshev_radius() -> void:
	print("_test_tiles_are_within_chebyshev_radius")
	var calc := VisibilityCalculatorClass.new()
	var center := Vector2i(10, 10)
	var radius: int = 4
	var tiles := calc.compute_visible_tiles(center, radius)
	var all_within: bool = true
	for tile: Vector2i in tiles:
		var dx: int = abs(tile.x - center.x)
		var dy: int = abs(tile.y - center.y)
		if maxi(dx, dy) > radius:
			all_within = false
			break
	_check(all_within, "every returned tile is within the Chebyshev radius")


# ---------------------------------------------------------------------------
# No duplicate tiles
# ---------------------------------------------------------------------------
func _test_no_duplicate_tiles() -> void:
	print("_test_no_duplicate_tiles")
	var calc := VisibilityCalculatorClass.new()
	var tiles := calc.compute_visible_tiles(Vector2i(0, 0), 3)
	var seen: Dictionary = {}
	var has_dup: bool = false
	for tile: Vector2i in tiles:
		var key: String = "%d,%d" % [tile.x, tile.y]
		if seen.has(key):
			has_dup = true
			break
		seen[key] = true
	_check(not has_dup, "no duplicate tiles in the visible set")


# ---------------------------------------------------------------------------
# Negative radius is treated as 0
# ---------------------------------------------------------------------------
func _test_negative_radius_treated_as_zero() -> void:
	print("_test_negative_radius_treated_as_zero")
	var calc := VisibilityCalculatorClass.new()
	var tiles := calc.compute_visible_tiles(Vector2i(2, 2), -3)
	_check(tiles.size() == 1, "negative radius returns exactly one tile (clamped to 0)")
	_check(tiles[0] == Vector2i(2, 2), "that tile is the center itself")


# ---------------------------------------------------------------------------
# Non-origin center offset is applied correctly
# ---------------------------------------------------------------------------
func _test_non_origin_center() -> void:
	print("_test_non_origin_center")
	var calc := VisibilityCalculatorClass.new()
	var center := Vector2i(5, 3)
	var tiles := calc.compute_visible_tiles(center, 1)
	_check(tiles.has(Vector2i(4, 2)), "top-left neighbor included")
	_check(tiles.has(Vector2i(5, 2)), "top neighbor included")
	_check(tiles.has(Vector2i(6, 2)), "top-right neighbor included")
	_check(tiles.has(Vector2i(4, 3)), "left neighbor included")
	_check(tiles.has(Vector2i(6, 3)), "right neighbor included")
	_check(tiles.has(Vector2i(4, 4)), "bottom-left neighbor included")
	_check(tiles.has(Vector2i(5, 4)), "bottom neighbor included")
	_check(tiles.has(Vector2i(6, 4)), "bottom-right neighbor included")


# ---------------------------------------------------------------------------
# Corners of the bounding square are included for radius 1
# ---------------------------------------------------------------------------
func _test_all_corners_included_radius_one() -> void:
	print("_test_all_corners_included_radius_one")
	var calc := VisibilityCalculatorClass.new()
	var center := Vector2i(0, 0)
	var tiles := calc.compute_visible_tiles(center, 1)
	_check(tiles.has(Vector2i(-1, -1)), "top-left corner included")
	_check(tiles.has(Vector2i(1, -1)), "top-right corner included")
	_check(tiles.has(Vector2i(-1, 1)), "bottom-left corner included")
	_check(tiles.has(Vector2i(1, 1)), "bottom-right corner included")
