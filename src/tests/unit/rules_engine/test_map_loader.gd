## test_map_loader.gd
## Unit tests for MapLoader (src/rules_engine/core/map_loader.gd)
## and MapDefinition (src/rules_engine/core/map_definition.gd).
##
## Run headlessly from the Godot project root (src/) with:
##   godot --headless --script ./tests/unit/rules_engine/test_map_loader.gd
##
## Exit code 0 = all assertions passed; 1 = one or more assertions failed.
extends SceneTree

const MapLoaderClass     = preload("res://rules_engine/core/map_loader.gd")
const MapDefinitionClass = preload("res://rules_engine/core/map_definition.gd")

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
	_test_load_from_dict_returns_definition()
	_test_load_from_dict_populates_tileset_ref()
	_test_load_from_dict_populates_map_size()
	_test_load_from_dict_populates_layers()
	_test_load_from_dict_missing_tileset_ref_returns_null()
	_test_load_from_dict_missing_map_width_returns_null()
	_test_load_from_dict_missing_map_height_returns_null()
	_test_load_from_dict_no_layers_key_leaves_layers_empty()
	_test_load_from_json_returns_definition()
	_test_load_from_json_malformed_returns_null()
	_test_load_from_json_non_dict_root_returns_null()
	_test_load_from_json_populates_all_four_layers()
	_test_map_definition_is_valid_true()
	_test_map_definition_is_valid_empty_tileset_ref()
	_test_map_definition_is_valid_zero_width()
	_test_map_definition_is_valid_zero_height()
	_test_load_from_dict_layer_count()
	_test_load_from_dict_ground_layer_row_count()
	_test_load_from_dict_collision_layer_values()
	_test_load_from_dict_triggers_layer_null_and_dict()
	_test_get_blocked_tiles_empty_when_no_collision_layer()
	_test_get_blocked_tiles_returns_blocked_positions()
	_test_get_blocked_tiles_all_passable_returns_empty()
	_test_get_blocked_tiles_multiple_rows()


# ---------------------------------------------------------------------------
# load_from_dict — happy path
# ---------------------------------------------------------------------------
func _test_load_from_dict_returns_definition() -> void:
	print("_test_load_from_dict_returns_definition")
	var loader := MapLoaderClass.new()
	var data := {
		"tileset_ref": "res://content/tilesets/test.tres",
		"map_width": 4,
		"map_height": 3,
	}
	var def = loader.load_from_dict(data)
	_check(def != null, "load_from_dict returns non-null for valid input")


func _test_load_from_dict_populates_tileset_ref() -> void:
	print("_test_load_from_dict_populates_tileset_ref")
	var loader := MapLoaderClass.new()
	var data := {
		"tileset_ref": "res://content/tilesets/dungeon.tres",
		"map_width": 2,
		"map_height": 2,
	}
	var def = loader.load_from_dict(data)
	_check(def.tileset_ref == "res://content/tilesets/dungeon.tres", "tileset_ref matches input")


func _test_load_from_dict_populates_map_size() -> void:
	print("_test_load_from_dict_populates_map_size")
	var loader := MapLoaderClass.new()
	var data := {"tileset_ref": "ts", "map_width": 10, "map_height": 8}
	var def = loader.load_from_dict(data)
	_check(def.map_width == 10, "map_width is 10")
	_check(def.map_height == 8, "map_height is 8")


func _test_load_from_dict_populates_layers() -> void:
	print("_test_load_from_dict_populates_layers")
	var loader := MapLoaderClass.new()
	var ground := [[1, 2], [3, 4]]
	var data := {
		"tileset_ref": "ts",
		"map_width": 2,
		"map_height": 2,
		"layers": {"ground": ground},
	}
	var def = loader.load_from_dict(data)
	_check(def.layers.has("ground"), "layers dict contains 'ground' key")
	_check(def.layers["ground"][0][1] == 2, "ground layer value [0][1] is 2")


# ---------------------------------------------------------------------------
# load_from_dict — missing required fields → null
# ---------------------------------------------------------------------------
func _test_load_from_dict_missing_tileset_ref_returns_null() -> void:
	print("_test_load_from_dict_missing_tileset_ref_returns_null")
	var loader := MapLoaderClass.new()
	var data := {"map_width": 4, "map_height": 3}
	var def = loader.load_from_dict(data)
	_check(def == null, "returns null when tileset_ref is absent")


func _test_load_from_dict_missing_map_width_returns_null() -> void:
	print("_test_load_from_dict_missing_map_width_returns_null")
	var loader := MapLoaderClass.new()
	var data := {"tileset_ref": "ts", "map_height": 3}
	var def = loader.load_from_dict(data)
	_check(def == null, "returns null when map_width is absent")


func _test_load_from_dict_missing_map_height_returns_null() -> void:
	print("_test_load_from_dict_missing_map_height_returns_null")
	var loader := MapLoaderClass.new()
	var data := {"tileset_ref": "ts", "map_width": 4}
	var def = loader.load_from_dict(data)
	_check(def == null, "returns null when map_height is absent")


func _test_load_from_dict_no_layers_key_leaves_layers_empty() -> void:
	print("_test_load_from_dict_no_layers_key_leaves_layers_empty")
	var loader := MapLoaderClass.new()
	var data := {"tileset_ref": "ts", "map_width": 4, "map_height": 3}
	var def = loader.load_from_dict(data)
	_check(def.layers.size() == 0, "layers is empty when 'layers' key is absent")


# ---------------------------------------------------------------------------
# load_from_json — happy path
# ---------------------------------------------------------------------------
func _test_load_from_json_returns_definition() -> void:
	print("_test_load_from_json_returns_definition")
	var loader := MapLoaderClass.new()
	var json := '{"tileset_ref":"ts","map_width":5,"map_height":4}'
	var def = loader.load_from_json(json)
	_check(def != null, "load_from_json returns non-null for valid JSON")
	_check(def.tileset_ref == "ts", "tileset_ref parsed from JSON")
	_check(def.map_width == 5, "map_width parsed from JSON")
	_check(def.map_height == 4, "map_height parsed from JSON")


func _test_load_from_json_malformed_returns_null() -> void:
	print("_test_load_from_json_malformed_returns_null")
	var loader := MapLoaderClass.new()
	var def = loader.load_from_json("{not valid json{{")
	_check(def == null, "returns null for malformed JSON")


func _test_load_from_json_non_dict_root_returns_null() -> void:
	print("_test_load_from_json_non_dict_root_returns_null")
	var loader := MapLoaderClass.new()
	var def = loader.load_from_json("[1, 2, 3]")
	_check(def == null, "returns null when JSON root is not a Dictionary")


func _test_load_from_json_populates_all_four_layers() -> void:
	print("_test_load_from_json_populates_all_four_layers")
	var loader := MapLoaderClass.new()
	var json := JSON.stringify({
		"tileset_ref": "ts",
		"map_width": 2,
		"map_height": 1,
		"layers": {
			"ground":    [[1, 2]],
			"props":     [[0, 3]],
			"collision": [[0, 1]],
			"triggers":  [[null, {"type": "combat_start", "encounter_id": "test"}]],
		}
	})
	var def = loader.load_from_json(json)
	_check(def != null, "definition loaded from JSON with all four layers")
	_check(def.layers.has("ground"),    "ground layer present")
	_check(def.layers.has("props"),     "props layer present")
	_check(def.layers.has("collision"), "collision layer present")
	_check(def.layers.has("triggers"),  "triggers layer present")


# ---------------------------------------------------------------------------
# MapDefinition.is_valid()
# ---------------------------------------------------------------------------
func _test_map_definition_is_valid_true() -> void:
	print("_test_map_definition_is_valid_true")
	var def := MapDefinitionClass.new()
	def.tileset_ref = "ts"
	def.map_width   = 5
	def.map_height  = 4
	_check(def.is_valid() == true, "is_valid returns true for complete definition")


func _test_map_definition_is_valid_empty_tileset_ref() -> void:
	print("_test_map_definition_is_valid_empty_tileset_ref")
	var def := MapDefinitionClass.new()
	def.tileset_ref = ""
	def.map_width   = 5
	def.map_height  = 4
	_check(def.is_valid() == false, "is_valid returns false when tileset_ref is empty")


func _test_map_definition_is_valid_zero_width() -> void:
	print("_test_map_definition_is_valid_zero_width")
	var def := MapDefinitionClass.new()
	def.tileset_ref = "ts"
	def.map_width   = 0
	def.map_height  = 4
	_check(def.is_valid() == false, "is_valid returns false when map_width is 0")


func _test_map_definition_is_valid_zero_height() -> void:
	print("_test_map_definition_is_valid_zero_height")
	var def := MapDefinitionClass.new()
	def.tileset_ref = "ts"
	def.map_width   = 5
	def.map_height  = 0
	_check(def.is_valid() == false, "is_valid returns false when map_height is 0")


# ---------------------------------------------------------------------------
# Layer shape validation via load_from_dict
# ---------------------------------------------------------------------------
func _test_load_from_dict_layer_count() -> void:
	print("_test_load_from_dict_layer_count")
	var loader := MapLoaderClass.new()
	var data := {
		"tileset_ref": "ts",
		"map_width": 3,
		"map_height": 2,
		"layers": {
			"ground":    [[1, 2, 3], [4, 5, 6]],
			"props":     [[0, 0, 0], [0, 3, 0]],
			"collision": [[0, 0, 0], [0, 1, 0]],
			"triggers":  [[null, null, null], [null, null, null]],
		}
	}
	var def = loader.load_from_dict(data)
	_check(def.layers.size() == 4, "layers dict has 4 entries")


func _test_load_from_dict_ground_layer_row_count() -> void:
	print("_test_load_from_dict_ground_layer_row_count")
	var loader := MapLoaderClass.new()
	var data := {
		"tileset_ref": "ts",
		"map_width": 3,
		"map_height": 2,
		"layers": {"ground": [[1, 2, 3], [4, 5, 6]]},
	}
	var def = loader.load_from_dict(data)
	_check(def.layers["ground"].size() == 2, "ground layer has 2 rows")
	_check(def.layers["ground"][0].size() == 3, "ground layer row 0 has 3 columns")


func _test_load_from_dict_collision_layer_values() -> void:
	print("_test_load_from_dict_collision_layer_values")
	var loader := MapLoaderClass.new()
	var data := {
		"tileset_ref": "ts",
		"map_width": 2,
		"map_height": 2,
		"layers": {"collision": [[0, 1], [1, 0]]},
	}
	var def = loader.load_from_dict(data)
	_check(def.layers["collision"][0][0] == 0, "collision[0][0] is passable (0)")
	_check(def.layers["collision"][0][1] == 1, "collision[0][1] is blocked (1)")
	_check(def.layers["collision"][1][0] == 1, "collision[1][0] is blocked (1)")
	_check(def.layers["collision"][1][1] == 0, "collision[1][1] is passable (0)")


func _test_load_from_dict_triggers_layer_null_and_dict() -> void:
	print("_test_load_from_dict_triggers_layer_null_and_dict")
	var loader := MapLoaderClass.new()
	var trigger := {"type": "combat_start", "encounter_id": "bandit_ambush"}
	var data := {
		"tileset_ref": "ts",
		"map_width": 2,
		"map_height": 1,
		"layers": {"triggers": [[null, trigger]]},
	}
	var def = loader.load_from_dict(data)
	_check(def.layers["triggers"][0][0] == null, "triggers[0][0] is null")
	_check(def.layers["triggers"][0][1] is Dictionary, "triggers[0][1] is a Dictionary")
	_check(def.layers["triggers"][0][1]["type"] == "combat_start",
		"trigger type is 'combat_start'")
	_check(def.layers["triggers"][0][1]["encounter_id"] == "bandit_ambush",
		"trigger encounter_id is 'bandit_ambush'")


# ---------------------------------------------------------------------------
# get_blocked_tiles — no collision layer → empty array
# ---------------------------------------------------------------------------
func _test_get_blocked_tiles_empty_when_no_collision_layer() -> void:
	print("_test_get_blocked_tiles_empty_when_no_collision_layer")
	var def := MapDefinitionClass.new()
	def.tileset_ref = "ts"
	def.map_width   = 2
	def.map_height  = 2
	# No collision layer in layers dict.
	var tiles: Array = def.get_blocked_tiles()
	_check(tiles.size() == 0, "get_blocked_tiles returns empty array when no collision layer")


# ---------------------------------------------------------------------------
# get_blocked_tiles — blocked tiles returned as Vector2i positions
# ---------------------------------------------------------------------------
func _test_get_blocked_tiles_returns_blocked_positions() -> void:
	print("_test_get_blocked_tiles_returns_blocked_positions")
	var loader := MapLoaderClass.new()
	var data := {
		"tileset_ref": "ts",
		"map_width": 2,
		"map_height": 2,
		"layers": {"collision": [[0, 1], [1, 0]]},
	}
	var def = loader.load_from_dict(data)
	var tiles: Array = def.get_blocked_tiles()
	_check(tiles.size() == 2, "get_blocked_tiles returns 2 blocked tiles")
	_check(tiles.has(Vector2i(1, 0)), "blocked tile (1, 0) is present")
	_check(tiles.has(Vector2i(0, 1)), "blocked tile (0, 1) is present")


# ---------------------------------------------------------------------------
# get_blocked_tiles — all passable → empty array
# ---------------------------------------------------------------------------
func _test_get_blocked_tiles_all_passable_returns_empty() -> void:
	print("_test_get_blocked_tiles_all_passable_returns_empty")
	var loader := MapLoaderClass.new()
	var data := {
		"tileset_ref": "ts",
		"map_width": 3,
		"map_height": 2,
		"layers": {"collision": [[0, 0, 0], [0, 0, 0]]},
	}
	var def = loader.load_from_dict(data)
	var tiles: Array = def.get_blocked_tiles()
	_check(tiles.size() == 0, "get_blocked_tiles returns empty array when all tiles are passable")


# ---------------------------------------------------------------------------
# get_blocked_tiles — multiple rows all blocked
# ---------------------------------------------------------------------------
func _test_get_blocked_tiles_multiple_rows() -> void:
	print("_test_get_blocked_tiles_multiple_rows")
	var loader := MapLoaderClass.new()
	var data := {
		"tileset_ref": "ts",
		"map_width": 3,
		"map_height": 3,
		"layers": {
			"collision": [
				[1, 0, 1],
				[0, 1, 0],
				[1, 0, 0],
			]
		},
	}
	var def = loader.load_from_dict(data)
	var tiles: Array = def.get_blocked_tiles()
	_check(tiles.size() == 4, "get_blocked_tiles returns 4 blocked tiles")
	_check(tiles.has(Vector2i(0, 0)), "blocked tile (0, 0) is present")
	_check(tiles.has(Vector2i(2, 0)), "blocked tile (2, 0) is present")
	_check(tiles.has(Vector2i(1, 1)), "blocked tile (1, 1) is present")
	_check(tiles.has(Vector2i(0, 2)), "blocked tile (0, 2) is present")
