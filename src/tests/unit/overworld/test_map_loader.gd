## test_map_loader.gd
## Unit tests for MapLoader (src/overworld/map_loader.gd).
##
## Run headlessly from the Godot project root (src/) with:
##   godot --headless --script ./tests/unit/overworld/test_map_loader.gd
##
## Exit code 0 = all assertions passed; 1 = one or more assertions failed.
extends SceneTree

const MapLoaderClass = preload("res://overworld/map_loader.gd")
const MapDefinitionClass = preload("res://overworld/map_definition.gd")

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
	_test_load_from_dict_map_id()
	_test_load_from_dict_spawn_point()
	_test_load_from_dict_collision_layer()
	_test_load_from_dict_interaction_layer()
	_test_load_from_dict_defaults()
	_test_load_from_dict_is_valid()
	_test_load_from_dict_empty_is_invalid()
	_test_load_from_dict_music_track()
	_test_load_from_dict_music_track_default_empty()
	_test_load_from_path_missing_file_returns_null()
	_test_load_from_path_valid_json()
	_test_load_from_dict_blocked_tiles_parsed()
	_test_load_from_dict_blocked_tiles_default_empty()
	_test_load_from_dict_blocked_tiles_as_vector2i()
	_test_load_from_path_blocked_tiles_from_json()


# ---------------------------------------------------------------------------
# load_from_dict — map_id is parsed
# ---------------------------------------------------------------------------
func _test_load_from_dict_map_id() -> void:
	print("_test_load_from_dict_map_id")
	var data := {
		"map_id": "road_to_greybridge",
		"spawn_point": {"x": 2, "y": 3},
		"collision_layer": 1,
		"interaction_layer": 2,
	}
	var def := MapLoaderClass.load_from_dict(data)
	_check(def != null, "load_from_dict returns non-null")
	_check(def.map_id == "road_to_greybridge", "map_id parsed correctly")


# ---------------------------------------------------------------------------
# load_from_dict — spawn_point is parsed as Vector2i
# ---------------------------------------------------------------------------
func _test_load_from_dict_spawn_point() -> void:
	print("_test_load_from_dict_spawn_point")
	var data := {
		"map_id": "test_map",
		"spawn_point": {"x": 5, "y": 7},
		"collision_layer": 1,
		"interaction_layer": 2,
	}
	var def := MapLoaderClass.load_from_dict(data)
	_check(def.spawn_point == Vector2i(5, 7), "spawn_point parsed as Vector2i(5, 7)")


# ---------------------------------------------------------------------------
# load_from_dict — collision_layer is parsed
# ---------------------------------------------------------------------------
func _test_load_from_dict_collision_layer() -> void:
	print("_test_load_from_dict_collision_layer")
	var data := {
		"map_id": "test_map",
		"spawn_point": {"x": 0, "y": 0},
		"collision_layer": 3,
		"interaction_layer": 4,
	}
	var def := MapLoaderClass.load_from_dict(data)
	_check(def.collision_layer == 3, "collision_layer parsed correctly")


# ---------------------------------------------------------------------------
# load_from_dict — interaction_layer is parsed
# ---------------------------------------------------------------------------
func _test_load_from_dict_interaction_layer() -> void:
	print("_test_load_from_dict_interaction_layer")
	var data := {
		"map_id": "test_map",
		"spawn_point": {"x": 0, "y": 0},
		"collision_layer": 1,
		"interaction_layer": 4,
	}
	var def := MapLoaderClass.load_from_dict(data)
	_check(def.interaction_layer == 4, "interaction_layer parsed correctly")


# ---------------------------------------------------------------------------
# load_from_dict — missing keys use defaults
# ---------------------------------------------------------------------------
func _test_load_from_dict_defaults() -> void:
	print("_test_load_from_dict_defaults")
	var def := MapLoaderClass.load_from_dict({})
	_check(def.map_id == "", "default map_id is empty string")
	_check(def.spawn_point == Vector2i(0, 0), "default spawn_point is Vector2i(0,0)")
	_check(def.collision_layer == 1, "default collision_layer is 1")
	_check(def.interaction_layer == 2, "default interaction_layer is 2")


# ---------------------------------------------------------------------------
# load_from_dict — valid map returns is_valid() == true
# ---------------------------------------------------------------------------
func _test_load_from_dict_is_valid() -> void:
	print("_test_load_from_dict_is_valid")
	var data := {
		"map_id": "road_to_greybridge",
		"spawn_point": {"x": 0, "y": 0},
		"collision_layer": 1,
		"interaction_layer": 2,
	}
	var def := MapLoaderClass.load_from_dict(data)
	_check(def.is_valid() == true, "map with non-empty id is valid")


# ---------------------------------------------------------------------------
# load_from_dict — empty map_id returns is_valid() == false
# ---------------------------------------------------------------------------
func _test_load_from_dict_empty_is_invalid() -> void:
	print("_test_load_from_dict_empty_is_invalid")
	var def := MapLoaderClass.load_from_dict({})
	_check(def.is_valid() == false, "map with empty id is invalid")


# ---------------------------------------------------------------------------
# load_from_dict — music_track is parsed
# ---------------------------------------------------------------------------
func _test_load_from_dict_music_track() -> void:
	print("_test_load_from_dict_music_track")
	var data := {
		"map_id": "test_map",
		"spawn_point": {"x": 0, "y": 0},
		"collision_layer": 1,
		"interaction_layer": 2,
		"music_track": "dungeon_theme",
	}
	var def := MapLoaderClass.load_from_dict(data)
	_check(def.music_track == "dungeon_theme", "music_track parsed correctly")


# ---------------------------------------------------------------------------
# load_from_dict — missing music_track defaults to empty string
# ---------------------------------------------------------------------------
func _test_load_from_dict_music_track_default_empty() -> void:
	print("_test_load_from_dict_music_track_default_empty")
	var def := MapLoaderClass.load_from_dict({"map_id": "test_map"})
	_check(def.music_track == "", "music_track defaults to empty string when absent")


# ---------------------------------------------------------------------------
# load_from_path — missing file returns null
# ---------------------------------------------------------------------------
func _test_load_from_path_missing_file_returns_null() -> void:
	print("_test_load_from_path_missing_file_returns_null")
	var def := MapLoaderClass.load_from_path("res://content/maps/nonexistent_map.json")
	_check(def == null, "load_from_path returns null for missing file")


# ---------------------------------------------------------------------------
# load_from_path — valid JSON file returns correct MapDefinition
# ---------------------------------------------------------------------------
func _test_load_from_path_valid_json() -> void:
	print("_test_load_from_path_valid_json")
	var def := MapLoaderClass.load_from_path("res://content/maps/road_to_greybridge.json")
	_check(def != null, "load_from_path returns non-null for valid JSON file")
	if def != null:
		_check(def.map_id == "road_to_greybridge", "loaded map_id matches JSON")
		_check(def.spawn_point == Vector2i(4, 3), "loaded spawn_point matches JSON")
		_check(def.collision_layer == 1, "loaded collision_layer matches JSON")
		_check(def.interaction_layer == 2, "loaded interaction_layer matches JSON")
		_check(def.music_track == "road_to_greybridge_theme", "loaded music_track matches JSON")
		_check(def.is_valid() == true, "loaded map is valid")


# ---------------------------------------------------------------------------
# load_from_dict — blocked_tiles is parsed from array of {x, y} dicts
# ---------------------------------------------------------------------------
func _test_load_from_dict_blocked_tiles_parsed() -> void:
	print("_test_load_from_dict_blocked_tiles_parsed")
	var data := {
		"map_id": "test_map",
		"spawn_point": {"x": 0, "y": 0},
		"collision_layer": 1,
		"interaction_layer": 2,
		"blocked_tiles": [
			{"x": 3, "y": 1},
			{"x": 7, "y": 4},
		],
	}
	var def := MapLoaderClass.load_from_dict(data)
	_check(def.blocked_tiles.size() == 2, "blocked_tiles has 2 entries")
	_check(def.blocked_tiles.has(Vector2i(3, 1)), "blocked tile (3,1) is present")
	_check(def.blocked_tiles.has(Vector2i(7, 4)), "blocked tile (7,4) is present")


# ---------------------------------------------------------------------------
# load_from_dict — missing blocked_tiles key defaults to empty array
# ---------------------------------------------------------------------------
func _test_load_from_dict_blocked_tiles_default_empty() -> void:
	print("_test_load_from_dict_blocked_tiles_default_empty")
	var data := {
		"map_id": "test_map",
		"spawn_point": {"x": 0, "y": 0},
		"collision_layer": 1,
		"interaction_layer": 2,
	}
	var def := MapLoaderClass.load_from_dict(data)
	_check(def.blocked_tiles.size() == 0, "blocked_tiles defaults to empty array")


# ---------------------------------------------------------------------------
# load_from_dict — blocked_tiles entries are Vector2i
# ---------------------------------------------------------------------------
func _test_load_from_dict_blocked_tiles_as_vector2i() -> void:
	print("_test_load_from_dict_blocked_tiles_as_vector2i")
	var data := {
		"map_id": "test_map",
		"spawn_point": {"x": 0, "y": 0},
		"collision_layer": 1,
		"interaction_layer": 2,
		"blocked_tiles": [{"x": 5, "y": 2}],
	}
	var def := MapLoaderClass.load_from_dict(data)
	_check(def.blocked_tiles.size() == 1, "blocked_tiles has one entry")
	_check(def.blocked_tiles[0] is Vector2i, "blocked_tiles entry is a Vector2i")
	_check(def.blocked_tiles[0] == Vector2i(5, 2), "blocked_tiles[0] equals Vector2i(5,2)")


# ---------------------------------------------------------------------------
# load_from_path — blocked_tiles loaded from road_to_greybridge.json
# ---------------------------------------------------------------------------
func _test_load_from_path_blocked_tiles_from_json() -> void:
	print("_test_load_from_path_blocked_tiles_from_json")
	var def := MapLoaderClass.load_from_path("res://content/maps/road_to_greybridge.json")
	if def == null:
		_check(false, "loaded map is non-null (skipped — file missing)")
		return
	_check(def.blocked_tiles.size() > 0, "road_to_greybridge has at least one blocked tile")
	_check(def.blocked_tiles.has(Vector2i(0, 1)), "blocked tile (0,1) is present")
	_check(def.blocked_tiles.has(Vector2i(8, 1)), "blocked tile (8,1) is present")

