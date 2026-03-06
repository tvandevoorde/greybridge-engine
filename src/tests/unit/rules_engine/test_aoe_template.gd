## test_aoe_template.gd
## Unit tests for AoETemplate (src/rules_engine/core/aoe_template.gd).
##
## Run headlessly from the Godot project root (src/) with:
##   godot --headless --script ../tests/unit/rules_engine/test_aoe_template.gd
extends SceneTree

const AoETemplateClass = preload("res://rules_engine/core/aoe_template.gd")

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
	# Factory key tests
	_test_make_radius_keys()
	_test_make_cone_keys()
	_test_make_cone_normalises_direction()

	# Radius tile geometry
	_test_radius_includes_center()
	_test_radius_includes_tiles_within_range()
	_test_radius_excludes_tiles_outside_range()
	_test_radius_1_tile()

	# Cone tile geometry
	_test_cone_includes_tile_directly_ahead()
	_test_cone_includes_tile_on_45_degree_edge()
	_test_cone_excludes_tile_behind_origin()
	_test_cone_excludes_origin_tile()
	_test_cone_excludes_tile_beyond_length()
	_test_cone_excludes_tile_outside_half_angle()


# ---------------------------------------------------------------------------
# Factory — make_radius
# ---------------------------------------------------------------------------
func _test_make_radius_keys() -> void:
	print("_test_make_radius_keys")
	var t: Dictionary = AoETemplateClass.make_radius(Vector2i(3, 4), 20)
	_check(t["type"] == AoETemplateClass.TYPE_RADIUS,  "type is TYPE_RADIUS")
	_check(t["center"] == Vector2i(3, 4),          "center stored")
	_check(t["radius_ft"] == 20,                   "radius_ft stored")


# ---------------------------------------------------------------------------
# Factory — make_cone
# ---------------------------------------------------------------------------
func _test_make_cone_keys() -> void:
	print("_test_make_cone_keys")
	var t: Dictionary = AoETemplateClass.make_cone(Vector2i(0, 0), Vector2(1, 0), 15)
	_check(t["type"] == AoETemplateClass.TYPE_CONE,  "type is TYPE_CONE")
	_check(t["origin"] == Vector2i(0, 0),        "origin stored")
	_check(t["length_ft"] == 15,                 "length_ft stored")
	_check(t.has("direction"),                   "direction key present")


func _test_make_cone_normalises_direction() -> void:
	print("_test_make_cone_normalises_direction")
	# Pass an un-normalised direction; factory must normalise it.
	var t: Dictionary = AoETemplateClass.make_cone(Vector2i(0, 0), Vector2(3, 0), 10)
	var dir: Vector2 = t["direction"]
	_check(absf(dir.length() - 1.0) < 0.001, "direction is unit-length after make_cone")


# ---------------------------------------------------------------------------
# Radius — centre tile is always included
# ---------------------------------------------------------------------------
func _test_radius_includes_center() -> void:
	print("_test_radius_includes_center")
	var t: Dictionary = AoETemplateClass.make_radius(Vector2i(5, 3), 10)
	var tiles: Array[Vector2i] = AoETemplateClass.get_affected_tiles(t)
	_check(Vector2i(5, 3) in tiles, "center tile is in radius area")


# ---------------------------------------------------------------------------
# Radius — tiles within the radius are included
# ---------------------------------------------------------------------------
func _test_radius_includes_tiles_within_range() -> void:
	print("_test_radius_includes_tiles_within_range")
	# 10 ft radius = 2 tiles.  (2,0) offset has dist=2 == radius → included.
	var t: Dictionary = AoETemplateClass.make_radius(Vector2i(0, 0), 10)
	var tiles: Array[Vector2i] = AoETemplateClass.get_affected_tiles(t)
	_check(Vector2i(2, 0) in tiles,  "tile at exact radius distance included")
	_check(Vector2i(1, 1) in tiles,  "diagonal tile within radius included")
	_check(Vector2i(0, 2) in tiles,  "tile directly above within radius included")


# ---------------------------------------------------------------------------
# Radius — tiles outside the radius are excluded
# ---------------------------------------------------------------------------
func _test_radius_excludes_tiles_outside_range() -> void:
	print("_test_radius_excludes_tiles_outside_range")
	# 10 ft radius = 2 tiles.  (3,0) has dist=3 > 2 → excluded.
	var t: Dictionary = AoETemplateClass.make_radius(Vector2i(0, 0), 10)
	var tiles: Array[Vector2i] = AoETemplateClass.get_affected_tiles(t)
	_check(not (Vector2i(3, 0) in tiles), "tile beyond radius excluded")
	_check(not (Vector2i(2, 2) in tiles), "corner tile beyond radius excluded")


# ---------------------------------------------------------------------------
# Radius — 5 ft (1 tile) radius
# ---------------------------------------------------------------------------
func _test_radius_1_tile() -> void:
	print("_test_radius_1_tile")
	# 5 ft radius = 1 tile.  Only tiles at distance <= 1.
	var t: Dictionary = AoETemplateClass.make_radius(Vector2i(0, 0), 5)
	var tiles: Array[Vector2i] = AoETemplateClass.get_affected_tiles(t)
	_check(Vector2i(0, 0) in tiles,       "centre tile included for 5ft radius")
	_check(Vector2i(1, 0) in tiles,       "adjacent tile at distance 1 included")
	_check(not (Vector2i(2, 0) in tiles), "tile at distance 2 excluded for 5ft radius")


# ---------------------------------------------------------------------------
# Cone — tile directly ahead is included
# ---------------------------------------------------------------------------
func _test_cone_includes_tile_directly_ahead() -> void:
	print("_test_cone_includes_tile_directly_ahead")
	# Direction: right (+x).  Tiles (1,0), (2,0), (3,0) for 15 ft = 3 tiles.
	var t: Dictionary = AoETemplateClass.make_cone(Vector2i(0, 0), Vector2(1, 0), 15)
	var tiles: Array[Vector2i] = AoETemplateClass.get_affected_tiles(t)
	_check(Vector2i(1, 0) in tiles, "tile 1 ahead on axis included")
	_check(Vector2i(2, 0) in tiles, "tile 2 ahead on axis included")
	_check(Vector2i(3, 0) in tiles, "tile 3 ahead on axis (at max range) included")


# ---------------------------------------------------------------------------
# Cone — tile on the 45-degree edge is included
# ---------------------------------------------------------------------------
func _test_cone_includes_tile_on_45_degree_edge() -> void:
	print("_test_cone_includes_tile_on_45_degree_edge")
	# Direction: right (+x).  At (2,2): proj=2, perp=2, perp==proj → on edge → IN.
	var t: Dictionary = AoETemplateClass.make_cone(Vector2i(0, 0), Vector2(1, 0), 15)
	var tiles: Array[Vector2i] = AoETemplateClass.get_affected_tiles(t)
	_check(Vector2i(2, 2) in tiles,  "tile on 45-degree edge (above) included")
	_check(Vector2i(2, -2) in tiles, "tile on 45-degree edge (below) included")


# ---------------------------------------------------------------------------
# Cone — tile behind the origin is excluded
# ---------------------------------------------------------------------------
func _test_cone_excludes_tile_behind_origin() -> void:
	print("_test_cone_excludes_tile_behind_origin")
	var t: Dictionary = AoETemplateClass.make_cone(Vector2i(0, 0), Vector2(1, 0), 15)
	var tiles: Array[Vector2i] = AoETemplateClass.get_affected_tiles(t)
	_check(not (Vector2i(-1, 0) in tiles), "tile directly behind origin excluded")
	_check(not (Vector2i(-2, 1) in tiles), "tile behind-and-above origin excluded")


# ---------------------------------------------------------------------------
# Cone — the origin tile itself is excluded (tip of the cone)
# ---------------------------------------------------------------------------
func _test_cone_excludes_origin_tile() -> void:
	print("_test_cone_excludes_origin_tile")
	var t: Dictionary = AoETemplateClass.make_cone(Vector2i(0, 0), Vector2(1, 0), 15)
	var tiles: Array[Vector2i] = AoETemplateClass.get_affected_tiles(t)
	_check(not (Vector2i(0, 0) in tiles), "origin tile (caster) excluded from cone")


# ---------------------------------------------------------------------------
# Cone — tile beyond the cone's length is excluded
# ---------------------------------------------------------------------------
func _test_cone_excludes_tile_beyond_length() -> void:
	print("_test_cone_excludes_tile_beyond_length")
	# 15 ft = 3 tiles; tile 4 ahead is out of range.
	var t: Dictionary = AoETemplateClass.make_cone(Vector2i(0, 0), Vector2(1, 0), 15)
	var tiles: Array[Vector2i] = AoETemplateClass.get_affected_tiles(t)
	_check(not (Vector2i(4, 0) in tiles), "tile beyond cone length excluded")


# ---------------------------------------------------------------------------
# Cone — tile outside the 45-degree half-angle is excluded
# ---------------------------------------------------------------------------
func _test_cone_excludes_tile_outside_half_angle() -> void:
	print("_test_cone_excludes_tile_outside_half_angle")
	# Direction: right (+x).  At (2,3): proj=2, perp=3 > proj → outside cone.
	var t: Dictionary = AoETemplateClass.make_cone(Vector2i(0, 0), Vector2(1, 0), 15)
	var tiles: Array[Vector2i] = AoETemplateClass.get_affected_tiles(t)
	_check(not (Vector2i(2, 3) in tiles), "tile outside 45-degree half-angle excluded")
	_check(not (Vector2i(1, 2) in tiles), "narrow tile outside half-angle excluded")
